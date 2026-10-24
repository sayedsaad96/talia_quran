import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/memorization/hands_free/hands_free_round_engine.dart';
import '../../../../core/memorization/hands_free/hands_free_round_state.dart';
import '../../../../core/memorization/listening/listening_question.dart';
import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../../../../core/services/hands_free_media_delegate.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../data/hands_free/hands_free_audio_session.dart';
import '../../data/hands_free/hands_free_practice_audio.dart';
import '../../data/hands_free/hands_free_review_source.dart';
import '../../data/listening/listening_recitation_capture.dart';
import 'hands_free_review_state.dart';
export 'hands_free_review_state.dart';

/// Practice effects only. No committer, stats, rewards or persistence writes.
class HandsFreeReviewCubit extends Cubit<HandsFreeReviewState>
    implements HandsFreeMediaDelegate {
  HandsFreeReviewCubit({
    required this.load,
    required this.audio,
    required this.capture,
    required this.session,
    required this.acquireMedia,
    required this.mediaTitle,
    DateTime Function()? now,
    bool Function()? isEnabled,
    bool Function()? warningAccepted,
    Future<void> Function()? saveWarning,
    void Function(HandsFreeMediaDelegate)? cancelMediaAcquisition,
    bool firstUseWarningPending = true,
    List<Stream<void>> authorityChanges = const [],
    Future<Object?> Function()? authoritySnapshot,
    this.cleanupTimeout = const Duration(seconds: 5),
    this.hardwareButtonSettle = const Duration(milliseconds: 700),
  }) : _authoritySnapshot = authoritySnapshot,
       now = now ?? DateTime.now,
       isEnabled = isEnabled ?? _alwaysEnabled,
       warningAccepted = warningAccepted ?? _warningNotAccepted,
       saveWarning = saveWarning ?? _noSave,
       cancelMediaAcquisition = cancelMediaAcquisition ?? _noCancel,
       super(
         HandsFreeReviewState(firstUseWarningPending: firstUseWarningPending),
       ) {
    _subscriptions.add(session.interruptions.listen((_) => onInterrupted()));
    if (authoritySnapshot != null && authorityChanges.isNotEmpty) {
      _authorityBaseline = _readSnapshot();
    }
    for (final changes in authorityChanges) {
      _subscriptions.add(changes.listen((_) => _authoritySignal()));
    }
    final Object status = audio;
    if (status is HandsFreePlaybackStatus) {
      _playbackSubscription = status.playing.listen((playing) {
        final ref = state.round?.currentAyah;
        if (ref != null && _valid(_epoch)) {
          final phase = state.round!.phase;
          _publish(
            ref,
            playing &&
                (phase == HandsFreePhase.prompt ||
                    phase == HandsFreePhase.feedback),
          );
        }
      });
    }
  }
  final Future<HandsFreeReviewMaterial> Function() load;
  final HandsFreePracticeAudio audio;
  final ListeningRecitationCapture capture;
  final HandsFreeAudioSession session;
  final Future<HandsFreeMediaLease?> Function(HandsFreeMediaDelegate)
  acquireMedia;
  final String Function(ListeningAyahRef) mediaTitle;
  final DateTime Function() now;
  final bool Function() isEnabled;
  final bool Function() warningAccepted;
  final Future<void> Function() saveWarning;
  final void Function(HandsFreeMediaDelegate) cancelMediaAcquisition;
  final Duration cleanupTimeout;
  final Duration hardwareButtonSettle;
  Timer? _hardwareGrade;
  final Future<Object?> Function()? _authoritySnapshot;
  Future<Object?>? _authorityBaseline;
  static bool _alwaysEnabled() => true;
  static bool _warningNotAccepted() => false;
  static Future<void> _noSave() async {}
  static void _noCancel(HandsFreeMediaDelegate _) {}
  final _subscriptions = <StreamSubscription<void>>[];
  StreamSubscription<bool>? _playbackSubscription;
  HandsFreeReviewMaterial? _material;
  HandsFreeRoundEngine? _engine;
  HandsFreeMediaLease? _media;
  Future<void> _capturePending = Future.value();
  Future<void> _sessionPending = Future.value();
  Future<void>? _cleanup;
  int _epoch = 0;
  int? _acquisitionEpoch;
  bool _grading = false, _closing = false, _blocked = false;
  bool _micReady = false, _hardBlocked = false;

  Future<void> initializeWarning() async {
    if (_closing || isClosed) return;
    try {
      emit(
        state.copyWith(
          firstUseWarningPending: !warningAccepted(),
          hasError: false,
        ),
      );
    } catch (error, stack) {
      TaliaLogger.w('Hands-free warning unavailable', error, stack);
      emit(state.copyWith(firstUseWarningPending: true, hasError: true));
    }
  }

  Future<void> acceptWarning() async {
    if (!state.firstUseWarningPending ||
        state.loading ||
        _closing ||
        isClosed) {
      return;
    }
    final epoch = _epoch;
    emit(state.copyWith(loading: true, hasError: false));
    try {
      await saveWarning();
      if (_alive(epoch)) {
        emit(state.copyWith(firstUseWarningPending: false, loading: false));
      }
    } catch (error, stack) {
      TaliaLogger.w('Hands-free warning could not be saved', error, stack);
      if (_alive(epoch)) emit(state.copyWith(loading: false, hasError: true));
    }
  }

  Future<void> start() async {
    if (!isEnabled() ||
        _closing ||
        _blocked ||
        state.loading ||
        state.firstUseWarningPending ||
        (state.round != null && !state.round!.isTerminal)) {
      return;
    }
    final epoch = ++_epoch;
    emit(state.copyWith(loading: true, hasError: false));
    try {
      await (_cleanup ?? Future.value());
      if (!_alive(epoch)) return;
      _cleanup = null;
      final material = await load().timeout(const Duration(seconds: 15));
      if (!_alive(epoch)) return;
      _material = material;
      if (!_valid(epoch)) return;
      _engine = HandsFreeRoundEngine(corpus: material.corpus);
      final round = _engine!.start(due: material.due, now: now());
      emit(state.copyWith(round: round, loading: false));
      if (round.phase == HandsFreePhase.finished) return;
      if (!_valid(epoch)) return;
      final media = await _acquire(epoch);
      if (!_valid(epoch)) {
        await media?.release();
        return;
      }
      if (media == null) throw StateError('Practice media unavailable');
      _media = media;
      await _prepare(epoch);
      if (_valid(epoch)) await _prompt(epoch);
    } catch (error, stack) {
      await _fail(epoch, error, stack);
    }
  }

  Future<HandsFreeMediaLease?> _acquire(int epoch) async {
    _acquisitionEpoch = epoch;
    try {
      return await acquireMedia(this);
    } finally {
      if (_acquisitionEpoch == epoch) _acquisitionEpoch = null;
    }
  }

  Future<void> _prepare(int epoch) async {
    _sessionPending = session.activate();
    await _sessionPending.timeout(const Duration(seconds: 5));
    if (!_valid(epoch)) return;
    _capturePending = capture.prepare().then((readiness) {
      _micReady = readiness == ListeningCaptureReadiness.ready;
      if (_valid(epoch)) emit(state.copyWith(micAvailable: _micReady));
    });
    await _capturePending;
  }

  bool _alive(int epoch) => !_closing && !isClosed && epoch == _epoch;

  bool _valid(int epoch) {
    if (!_alive(epoch)) return false;
    if (!isEnabled() ||
        _material?.isCurrent() != true ||
        (_media != null && !_media!.isCurrent)) {
      onInterrupted();
      return false;
    }
    return true;
  }

  Future<void> _prompt(int epoch) async {
    if (!_valid(epoch)) return;
    final ref = state.round!.currentAyah!;
    _publish(ref, false);
    if (!_valid(epoch)) return;
    final played = await audio.playPrompt(ref);
    if (!_valid(epoch)) return;
    if (!played) throw StateError('Practice prompt did not complete');
    _publish(ref, false);
    // A silent or failed attempt only falls back for that item; retry next.
    emit(
      state.copyWith(
        round: _engine!.onPromptFinished(state.round!),
        micAvailable: _micReady,
      ),
    );
    if (state.micAvailable) await _listen(epoch);
  }

  Future<void> _listen(int epoch) async {
    if (!_valid(epoch)) return;
    final pending = Completer<void>();
    _capturePending = pending.future;
    session.setCaptureActive(true);
    try {
      await capture.start(
        (_) {},
        onStopped: () {
          session.setCaptureActive(false);
          if (_valid(epoch)) unawaited(_automatic(epoch));
        },
      );
      pending.complete();
      if (!_valid(epoch)) {
        await capture.cancel();
        session.setCaptureActive(false);
      }
    } catch (error, stack) {
      pending.complete();
      session.setCaptureActive(false);
      if (_valid(epoch)) {
        await capture.cancel();
        emit(state.copyWith(micAvailable: false));
      }
      TaliaLogger.w('Hands-free capture unavailable', error, stack);
    }
  }

  bool _claim(int epoch) {
    if (!_valid(epoch) ||
        _grading ||
        state.round?.phase != HandsFreePhase.userTurn) {
      return false;
    }
    _grading = true;
    return true;
  }

  Future<void> _automatic(int epoch) async {
    if (!_claim(epoch)) return;
    try {
      await _capturePending;
      final words = await capture.stop();
      if (!_valid(epoch)) return;
      final Object health = capture;
      if (health is ListeningCaptureHealth && health.hadError) {
        _grading = false;
        // Microphone taken by another app (e.g. a call): stop, do not grade.
        final Object fault = capture;
        if (fault is ListeningCaptureFault && fault.audioBusy) {
          onInterrupted();
          return;
        }
        emit(state.copyWith(micAvailable: false));
        return;
      }
      final target = _material!.corpus.textOf(state.round!.currentAyah!)!;
      final result = const V2RecitationEvaluator().evaluate(
        targetText: target,
        spokenText: words,
      );
      if (result.isNoAttempt) {
        _grading = false;
        emit(state.copyWith(micAvailable: false));
        return;
      }
      await _grade(
        epoch,
        result.passed ? HandsFreeGrade.correct : HandsFreeGrade.review,
      );
    } catch (error, stack) {
      await _fail(epoch, error, stack);
    }
  }

  Future<void> _manual(HandsFreeGrade grade) async {
    final epoch = _epoch;
    if (!_claim(epoch)) return;
    try {
      await capture.cancel();
      await _capturePending;
      await capture.cancel();
      session.setCaptureActive(false);
      if (_valid(epoch)) await _grade(epoch, grade);
    } catch (error, stack) {
      await _fail(epoch, error, stack);
    }
  }

  Future<void> _grade(int epoch, HandsFreeGrade grade) async {
    if (!_valid(epoch)) return;
    emit(state.copyWith(round: _engine!.grade(state.round!, grade)));
    if (!_valid(epoch)) return;
    _publish(state.round!.currentAyah!, false);
    await audio.playFeedback(grade);
    if (!_valid(epoch)) return;
    final next = _engine!.next(state.round!);
    emit(state.copyWith(round: next));
    _grading = false;
    if (next.phase == HandsFreePhase.finished) {
      await _clean();
    } else {
      await _prompt(epoch);
    }
  }

  void _publish(ListeningAyahRef ref, bool playing) => _media?.publish(
    item: MediaItem(
      id: 'hands_free_${ref.surahId}_${ref.ayahNumber}',
      title: mediaTitle(ref),
    ),
    playing: playing,
  );

  @override
  void onPrimary() => unawaited(_manual(HandsFreeGrade.correct));
  @override
  void onSecondary() => unawaited(_manual(HandsFreeGrade.review));
  @override
  void onInterrupted() {
    _hardwareGrade?.cancel();
    unawaited(stopRound());
  }

  /// Physical keys wait [hardwareButtonSettle] so a disconnect or focus loss
  /// that follows the key (earbud removal, Bluetooth drop) cancels the grade.
  @override
  void onHardwareButton({required bool primary}) {
    if (state.round?.phase != HandsFreePhase.userTurn) return;
    _hardwareGrade?.cancel();
    final epoch = _epoch;
    _hardwareGrade = Timer(hardwareButtonSettle, () {
      _hardwareGrade = null;
      if (!_valid(epoch)) return;
      primary ? onPrimary() : onSecondary();
    });
  }

  Future<Object?> _readSnapshot() async {
    try {
      return await _authoritySnapshot!();
    } catch (_) {
      return Object(); // Unreadable authority never compares equal.
    }
  }

  /// A signal is only an authority change when the account, lease generation
  /// or profile path actually differs (barrier/path streams also fire for
  /// unrelated writes such as Khatmah saves or owner-ready marks).
  Future<void> _authoritySignal() async {
    if (_authoritySnapshot == null) {
      _authorityChanged();
      return;
    }
    final previous = await (_authorityBaseline ??= _readSnapshot());
    final next = await _readSnapshot();
    if (_closing || isClosed || next == previous) return;
    _authorityBaseline = Future.value(next);
    _authorityChanged();
  }

  void _authorityChanged() {
    _epoch++;
    _material = null;
    _engine = null;
    if (isClosed) return;
    emit(const HandsFreeReviewState());
    unawaited(stopRound());
    unawaited(initializeWarning());
  }

  Future<void> stopRound() async {
    _epoch++;
    _hardwareGrade?.cancel();
    _hardwareGrade = null;
    if (_acquisitionEpoch != null) {
      cancelMediaAcquisition(this);
      _acquisitionEpoch = null;
    }
    _grading = false;
    if (!isClosed) {
      emit(
        state.copyWith(
          loading: false,
          round: state.round == null ? null : _engine!.interrupt(state.round!),
        ),
      );
    }
    try {
      await _clean().timeout(cleanupTimeout);
    } on TimeoutException catch (error, stack) {
      // A late successful drain lifts the block (see _clean).
      _blocked = true;
      if (!isClosed) emit(state.copyWith(hasError: true));
      TaliaLogger.w('Hands-free cleanup slow; restart blocked', error, stack);
    } catch (error, stack) {
      _blocked = true;
      if (!isClosed) emit(state.copyWith(hasError: true));
      TaliaLogger.w(
        'Hands-free cleanup incomplete; restart blocked',
        error,
        stack,
      );
    }
  }

  Future<void> _clean() {
    final existing = _cleanup;
    if (existing != null) return existing;
    final run = _drain();
    _cleanup = run;
    run.then<void>((_) {
      if (_hardBlocked) return;
      final wasBlocked = _blocked;
      _blocked = false;
      if (wasBlocked && !isClosed && !_closing) {
        emit(state.copyWith(hasError: false));
      }
    }, onError: (Object _, StackTrace _) {});
    return run;
  }

  Future<void> _drain() async {
    // Invalidation happens before these awaits; ownership stays until drained.
    session.setCaptureActive(false);
    final audioStop = _safely(audio.stop);
    var captureSafe = await _safely(capture.cancel);
    try {
      await _capturePending;
    } catch (_) {}
    captureSafe = await _safely(capture.cancel) && captureSafe;
    final audioSafe = await audioStop;
    try {
      await _sessionPending;
    } catch (_) {}
    // Focus release failing must not strand the media session: the lease is
    // freed once sound and microphone are confirmed stopped.
    final sessionSafe = await _safely(session.release);
    if (!audioSafe || !captureSafe) {
      _hardBlocked = true;
      _blocked = true;
      throw StateError('Practice cleanup failed');
    }
    await _releaseMedia();
    if (!sessionSafe) {
      TaliaLogger.w('Hands-free audio focus release failed; lease freed');
    }
  }

  Future<void> _releaseMedia() async {
    final media = _media;
    _media = null;
    await _safely(() async => await media?.release());
  }

  Future<bool> _safely(Future<void> Function() work) async {
    try {
      await work();
      return true;
    } catch (error, stack) {
      TaliaLogger.w('Hands-free resource shutdown failed', error, stack);
      return false;
    }
  }

  Future<void> _fail(int epoch, Object error, StackTrace stack) async {
    if (!_alive(epoch)) return;
    TaliaLogger.w('Hands-free round stopped', error, stack);
    emit(state.copyWith(hasError: true));
    await stopRound();
  }

  @override
  Future<void> close() async {
    _closing = true;
    await stopRound();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _playbackSubscription?.cancel();
    try {
      await (_cleanup ?? Future<void>.value()).timeout(cleanupTimeout);
    } catch (error, stack) {
      TaliaLogger.w('Hands-free cleanup incomplete at close', error, stack);
    }
    // Always dispose and drop the delegate lease so a closed cubit never
    // stays attached to the media session.
    await _safely(audio.dispose);
    await _safely(session.dispose);
    await _releaseMedia();
    return super.close();
  }
}
