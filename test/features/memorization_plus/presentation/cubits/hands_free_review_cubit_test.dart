import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_state.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/services/hands_free_media_delegate.dart';
import 'package:audio_service/audio_service.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_review_source.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_practice_audio.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_audio_session.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/hands_free_review_cubit.dart';

class _Audio implements HandsFreePracticeAudio {
  final tones = <HandsFreeGrade>[];
  Completer<bool>? prompt;
  int stops = 0;
  Completer<void>? shutdown;
  @override
  Future<bool> playPrompt(ListeningAyahRef ref) async =>
      prompt == null ? true : prompt!.future;
  @override
  Future<void> playFeedback(HandsFreeGrade grade) async {
    tones.add(grade);
  }

  @override
  Future<void> stop() async {
    stops++;
    await shutdown?.future;
  }

  @override
  Future<void> dispose() async {}
}

class _Capture implements ListeningRecitationCapture, ListeningCaptureHealth {
  @override
  bool hadError = false;
  ListeningCaptureReadiness readiness = ListeningCaptureReadiness.ready;
  void Function()? ended;
  String words = 'sample target';
  int cancels = 0;
  Completer<void>? starting;
  @override
  Future<ListeningCaptureReadiness> prepare() async => readiness;
  @override
  Future<void> start(
    void Function(String) onWords, {
    required void Function() onStopped,
  }) async {
    ended = onStopped;
    await starting?.future;
  }

  @override
  Future<String> stop() async => words;
  @override
  Future<void> cancel() async {
    cancels++;
  }
}

class _Session implements HandsFreeAudioSession {
  final events = StreamController<void>.broadcast(sync: true);
  @override
  Stream<void> get interruptions => events.stream;
  @override
  Future<void> activate() async {}
  @override
  Future<void> release() async {}
  @override
  Future<void> dispose() => events.close();
}

class _Lease implements HandsFreeMediaLease {
  bool current = true;
  @override
  bool get isCurrent => current;
  @override
  void publish({required MediaItem item, required bool playing}) {}
  @override
  Future<void> release() async {
    current = false;
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 23);
  late _Audio audio;
  late _Capture capture;
  late _Session session;
  late _Lease lease;
  late HandsFreeReviewCubit cubit;
  var authority = true;
  var cancellations = 0;
  Completer<HandsFreeMediaLease?>? acquiring;
  var warningAccepted = false;
  var warningSaves = 0;
  Completer<void>? savingWarning;
  late StreamController<void> authorityEvents;
  HandsFreeReviewMaterial material() => HandsFreeReviewMaterial(
    corpus: ListeningCorpus.fromTexts({
      1: ['sample target', 'second target'],
    }),
    due: [
      for (var a = 1; a <= 2; a++)
        AyahReviewRecord(
          surahId: 1,
          ayahNumber: a,
          strengthLevel: 6,
          intervalDays: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          nextReviewDate: now.subtract(const Duration(days: 1)),
          totalReviews: 1,
          lastRating: null,
          createdByMode: ReviewRecordCreatedByMode.v2Session,
        ),
    ],
    isCurrent: () => authority,
  );
  setUp(() {
    authority = true;
    cancellations = 0;
    acquiring = null;
    warningAccepted = false;
    warningSaves = 0;
    savingWarning = null;
    authorityEvents = StreamController<void>.broadcast(sync: true);
    audio = _Audio();
    capture = _Capture();
    session = _Session();
    lease = _Lease();
    cubit = HandsFreeReviewCubit(
      load: () async => material(),
      audio: audio,
      capture: capture,
      session: session,
      acquireMedia: (_) async => acquiring == null ? lease : acquiring!.future,
      cancelMediaAcquisition: (_) => cancellations++,
      warningAccepted: () => warningAccepted,
      saveWarning: () async {
        warningSaves++;
        await savingWarning?.future;
        warningAccepted = true;
      },
      authorityChanges: [authorityEvents.stream],
      now: () => now,
      firstUseWarningPending: false,
      mediaTitle: (_) => 'test practice',
    );
  });
  tearDown(() async {
    await cubit.close();
    await authorityEvents.close();
  });
  Future<void> settle() async {
    for (var i = 0; i < 12; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('correct transcript produces one tone then advances', () async {
    await cubit.start();
    expect(cubit.state.round!.phase, HandsFreePhase.userTurn);
    capture.ended!();
    await settle();
    expect(audio.tones, [HandsFreeGrade.correct]);
    expect(cubit.state.round!.currentIndex, 1);
  });
  test('unavailable microphone allows one manual grade', () async {
    capture.readiness = ListeningCaptureReadiness.unavailable;
    await cubit.start();
    expect(cubit.state.micAvailable, isFalse);
    cubit.onSecondary();
    cubit.onPrimary();
    await settle();
    expect(audio.tones, [HandsFreeGrade.review]);
  });
  test(
    'noisy interruption prevents a late prompt from starting capture',
    () async {
      audio.prompt = Completer<bool>();
      final starting = cubit.start();
      await settle();
      session.events.add(null);
      await settle();
      audio.prompt!.complete(true);
      await starting;
      expect(cubit.state.round!.phase, HandsFreePhase.paused);
      expect(capture.ended, isNull);
      expect(audio.tones, isEmpty);
      expect(lease.isCurrent, isFalse);
    },
  );
  test('empty recognition is ungraded and enables manual input', () async {
    capture.words = '';
    await cubit.start();
    capture.ended!();
    await settle();
    expect(audio.tones, isEmpty);
    expect(cubit.state.round!.grades.every((g) => g == null), isTrue);
    expect(cubit.state.micAvailable, isFalse);
  });
  test('owner invalidation rejects the final transcript', () async {
    await cubit.start();
    authority = false;
    capture.ended!();
    await settle();
    expect(audio.tones, isEmpty);
    expect(cubit.state.round!.phase, HandsFreePhase.paused);
  });
  test('stop releases media without changing SRS records', () async {
    await cubit.start();
    await cubit.stopRound();
    expect(lease.isCurrent, isFalse);
    expect(cubit.state.round!.grades.every((g) => g == null), isTrue);
  });
  test('recognizer error cannot grade a partial transcript', () async {
    await cubit.start();
    capture.hadError = true;
    capture.ended!();
    await settle();
    expect(audio.tones, isEmpty);
    expect(cubit.state.micAvailable, isFalse);
  });
  test('unused page never resolves reader media while closing', () async {
    await cubit.close();
    expect(cancellations, 0);
  });
  test('cancel pending media acquisition and release a late lease', () async {
    acquiring = Completer<HandsFreeMediaLease?>();
    final starting = cubit.start();
    await settle();
    await cubit.stopRound();
    expect(cancellations, 1);
    acquiring!.complete(lease);
    await starting;
    expect(lease.isCurrent, isFalse);
    expect(capture.ended, isNull);
  });
  test('close drains late microphone start before releasing media', () async {
    capture.starting = Completer<void>();
    final starting = cubit.start();
    await settle();
    var closed = false;
    final closing = cubit.close().then((_) => closed = true);
    await settle();
    expect(closed, isFalse);
    expect(lease.isCurrent, isTrue);
    capture.starting!.complete();
    await starting;
    await closing;
    expect(lease.isCurrent, isFalse);
    expect(capture.cancels, greaterThanOrEqualTo(2));
    expect(audio.tones, isEmpty);
  });
  test(
    'first-use warning is reloaded and saved before start unlocks',
    () async {
      await cubit.initializeWarning();
      await cubit.start();
      expect(cubit.state.firstUseWarningPending, isTrue);
      expect(capture.ended, isNull);
      await cubit.acceptWarning();
      expect(warningSaves, 1);
      expect(cubit.state.firstUseWarningPending, isFalse);
      await cubit.start();
      expect(cubit.state.round!.phase, HandsFreePhase.userTurn);
    },
  );
  test('late acceptance never unlocks another account', () async {
    await cubit.initializeWarning();
    savingWarning = Completer<void>();
    final accepting = cubit.acceptWarning();
    authorityEvents.add(null);
    savingWarning!.complete();
    await accepting;
    expect(cubit.state.firstUseWarningPending, isTrue);
    expect(cubit.state.round, isNull);
  });
  test('account change clears the previous round and summary', () async {
    await cubit.start();
    cubit.onSecondary();
    await settle();
    expect(cubit.state.summary.reviewCount, 1);
    authorityEvents.add(null);
    await settle();
    expect(cubit.state.round, isNull);
    expect(cubit.state.summary.reviewCount, 0);
    expect(lease.isCurrent, isFalse);
  });
}
