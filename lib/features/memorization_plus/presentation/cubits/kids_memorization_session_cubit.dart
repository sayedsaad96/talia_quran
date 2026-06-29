// lib/features/memorization_plus/presentation/cubits/kids_memorization_session_cubit.dart
//
// Kids V2 Memorization Session Cubit — drives the
//   Listen → Try to Remember → Complete
// flow for children, reusing:
//   - V2SessionEngine for state machine
//   - V2SessionReviewAdapter for SM-2 scheduling
//   - Kids gamification: AwardKidsPointsUsecase + MarkAyahMemorizedUsecase
//
// No STT is used. The child completes an ayah by manually tapping "Complete"
// after listening and trying to remember, matching the existing KidsModeCubit UX.

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';

import '../../../../core/memorization/v2/session_adapters.dart';
import '../../../../core/memorization/v2/session_engine.dart';
import '../../../../core/memorization/v2/session_state.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../memorization_plus/domain/entities/memorization_entities.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../../quran/domain/repositories/quran_repository.dart';

// ─── States ──────────────────────────────────────────────────────────────────

@immutable
abstract class KidsMemorizationSessionState extends Equatable {
  const KidsMemorizationSessionState();

  @override
  List<Object?> get props => [];
}

class KMSInitial extends KidsMemorizationSessionState {
  const KMSInitial();
}

class KMSLoading extends KidsMemorizationSessionState {
  const KMSLoading();
}

class KMSError extends KidsMemorizationSessionState {
  const KMSError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Active state — the child is in Listen or Try phases.
class KMSActive extends KidsMemorizationSessionState {
  const KMSActive({
    required this.sessionState,
    required this.isPlaying,
    required this.listenLoopCount,
    required this.maxListenLoops,
  });

  final V2SessionState sessionState;

  /// Whether audio is currently playing.
  final bool isPlaying;

  /// Number of times the current ayah audio has completed.
  final int listenLoopCount;

  /// Required listen loops before "Complete" is enabled.
  final int maxListenLoops;

  /// True once the child has listened enough times.
  bool get canComplete => listenLoopCount >= maxListenLoops;

  KMSActive copyWith({
    V2SessionState? sessionState,
    bool? isPlaying,
    int? listenLoopCount,
  }) =>
      KMSActive(
        sessionState: sessionState ?? this.sessionState,
        isPlaying: isPlaying ?? this.isPlaying,
        listenLoopCount: listenLoopCount ?? this.listenLoopCount,
        maxListenLoops: maxListenLoops,
      );

  @override
  List<Object?> get props => [
        sessionState,
        isPlaying,
        listenLoopCount,
        maxListenLoops,
      ];
}

/// Completion state — block fully done.
class KMSCompleted extends KidsMemorizationSessionState {
  const KMSCompleted({
    required this.finalState,
    required this.awards,
    required this.starsEarned,
  });

  final V2SessionState finalState;
  final List<CertificateAward> awards;
  final int starsEarned;

  @override
  List<Object?> get props => [finalState, awards, starsEarned];
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

/// Kids V2 Memorization Session Cubit.
///
/// Flow per ayah:
///   1. [KMSActive] phase=learning  → child sees ayah text + audio button
///   2. [KMSActive] phase=memorizing → child tries to remember (text hidden)
///   3. completeAyah() → records pass via [V2SessionReviewAdapter] + advances
///   4. When block done → [KMSCompleted] with gamification results
///
/// Max listen loops: 3 (matches existing KidsModeCubit behaviour).
class KidsMemorizationSessionCubit
    extends Cubit<KidsMemorizationSessionState> {
  KidsMemorizationSessionCubit({
    required QuranRepository quranRepository,
    required MemorizationPlusRepository memorizationRepository,
    required V2SessionEngine sessionEngine,
    required V2SessionReviewAdapter reviewAdapter,
    required V2SessionProgressAdapter progressAdapter,
    required V2SessionGamificationAdapter gamificationAdapter,
    required AchievementService achievementService,
    required AwardKidsPointsUsecase awardKidsPoints,
    required MarkAyahMemorizedUsecase markAyahMemorized,
    int maxListenLoops = 3,
  })  : _quranRepo = quranRepository,
        _engine = sessionEngine,
        _reviewAdapter = reviewAdapter,
        _progressAdapter = progressAdapter,
        _gamificationAdapter = gamificationAdapter,
        _achievementService = achievementService,
        _awardKidsPoints = awardKidsPoints,
        _markAyahMemorized = markAyahMemorized,
        _maxListenLoops = maxListenLoops,
        super(const KMSInitial()) {
    _playerStateSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        _onPlaybackCompleted();
      }
    });
  }

  final QuranRepository _quranRepo;
  final V2SessionEngine _engine;
  final V2SessionReviewAdapter _reviewAdapter;
  final V2SessionProgressAdapter _progressAdapter;
  final V2SessionGamificationAdapter _gamificationAdapter;
  final AchievementService _achievementService;
  final AwardKidsPointsUsecase _awardKidsPoints;
  final MarkAyahMemorizedUsecase _markAyahMemorized;
  final int _maxListenLoops;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;

  // ── Session lifecycle ─────────────────────────────────────────────────────

  /// Starts a new Kids V2 session for a single ayah (blockSize=1 for Kids).
  Future<void> startSession({
    required int surahId,
    required int startAyah,
  }) async {
    emit(const KMSLoading());

    // Load surah detail.
    final surahResult = await _quranRepo.getSurahDetail(surahId);
    if (surahResult.isLeft()) {
      emit(const KMSError(message: 'فشل في تحميل بيانات السورة'));
      return;
    }
    final surah = surahResult.getOrElse(() => throw StateError('unreachable'));
    final allAyahs = surah.ayahs;
    final blockAyahs = allAyahs
        .where((a) => a.numberInSurah == startAyah)
        .take(1)
        .toList();

    if (blockAyahs.isEmpty) {
      emit(const KMSError(message: 'الآية غير موجودة'));
      return;
    }

    // Kids mode: no block review (children ≤ 7 skip per Product Rules §14.3).
    var sessionState = V2SessionState.initial(
      surahId: surahId,
      blockAyahs: blockAyahs,
      blockReviewRequired: false,
    );
    sessionState = _engine.startLearning(sessionState);

    // Check for a previously saved session to resume.
    final savedOpt = await _progressAdapter.loadIfExists(surahId);
    savedOpt.fold(
      () {}, // no saved session
      (saved) {
        try {
          sessionState = V2SessionProgressAdapter.restore(saved, blockAyahs);
        } catch (e, stack) {
          TaliaLogger.w('KidsV2: Failed to restore session, starting fresh', e,
              stack);
        }
      },
    );

    // Prefetch audio — fire-and-forget, non-critical.
    _prefetchAudio(surahId, startAyah).ignore();

    emit(
      KMSActive(
        sessionState: sessionState,
        isPlaying: false,
        listenLoopCount: 0,
        maxListenLoops: _maxListenLoops,
      ),
    );
  }

  // ── Phase transitions ─────────────────────────────────────────────────────

  /// Advances from Learning → Memorizing.
  /// The text becomes hidden and the child tries to recall.
  void advanceToMemorizing() {
    if (state is! KMSActive) return;
    final current = state as KMSActive;
    final newSession = _engine.startMemorizing(current.sessionState);
    emit(current.copyWith(sessionState: newSession));
  }

  /// Marks current ayah as complete (pass without STT).
  ///
  /// Records the pass via SM-2 adapter, advances the engine, and either
  /// loads the next ayah or triggers block completion.
  Future<void> completeAyah() async {
    if (state is! KMSActive) return;
    final current = state as KMSActive;

    // Guard: must have listened at least once.
    if (current.listenLoopCount == 0) return;

    final session = current.sessionState;
    final ayah = session.currentAyah;

    // Record pass via SM-2 (no hint used → excellent rating).
    // Fire-and-forget: UI should not block on persistence.
    _reviewAdapter
        .recordPass(
          surahId: session.surahId,
          ayahNumber: ayah.numberInSurah,
          hintLevel: session.hintTracker.levelFor(
            session.surahId,
            ayah.numberInSurah,
          ),
        )
        .catchError(
          (Object e, StackTrace s) =>
              TaliaLogger.e('KidsV2: recordPass failed', e, s),
        )
        .ignore();

    // Advance engine: simulate a pass result.
    var newSession = session.copyWith(
      passedAyahNumbers: {...session.passedAyahNumbers, ayah.numberInSurah},
    );

    if (newSession.allAyahsPassed) {
      // Single-ayah block done → complete.
      unawaited(_onBlockCompleted(newSession));
      return;
    }

    // Move to next ayah (learning phase for it).
    newSession = _engine.startLearning(newSession.copyWith(
      currentAyahIndex: newSession.currentAyahIndex + 1,
    ));

    await _progressAdapter.save(newSession);

    emit(
      KMSActive(
        sessionState: newSession,
        isPlaying: false,
        listenLoopCount: 0,
        maxListenLoops: _maxListenLoops,
      ),
    );
  }

  // ── Block completion ───────────────────────────────────────────────────────

  Future<void> _onBlockCompleted(V2SessionState finalSession) async {
    // Kids gamification.
    int starsEarned = 0;
    try {
      final ayah = finalSession.blockAyahs.first;
      final result = await _awardKidsPoints(
        AwardKidsPointsParams(
          surahId: finalSession.surahId,
          ayahNumber: ayah.numberInSurah,
          repeatsCompleted: _maxListenLoops,
        ),
      );
      result.fold(
        (_) {},
        (completion) => starsEarned = completion.starsEarned,
      );

      await _markAyahMemorized(
        MarkAyahMemorizedParams(
          surahId: finalSession.surahId,
          ayahNumber: finalSession.blockAyahs.first.numberInSurah,
          createdByMode: ReviewRecordCreatedByMode.kidsMode,
        ),
      );
    } catch (e, stack) {
      TaliaLogger.w('KidsV2: Kids gamification failed (non-critical)', e, stack);
    }

    // Gamification (streak/XP/certificates).
    List<CertificateAward> awards = [];
    try {
      await _gamificationAdapter.onBlockCompleted(finalSession);
      awards = await _achievementService.checkAndUnlockCertificates();
    } catch (e, stack) {
      TaliaLogger.w('KidsV2: Gamification failed (non-critical)', e, stack);
    }

    await _progressAdapter.clear(finalSession.surahId);

    emit(
      KMSCompleted(
        finalState: finalSession,
        awards: awards,
        starsEarned: starsEarned,
      ),
    );
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  Future<void> playCurrentAyah() async {
    if (state is! KMSActive) return;
    final current = state as KMSActive;
    final ayah = current.sessionState.currentAyah;

    emit(current.copyWith(isPlaying: true));
    try {
      final source = await AudioCacheService.instance.getAudioSource(
        current.sessionState.surahId,
        ayah.numberInSurah,
      );
      await AudioCacheService.playFromSource(_player, source);
    } catch (e, stack) {
      TaliaLogger.e('KidsV2: Audio playback failed', e, stack);
      if (state is KMSActive) {
        emit((state as KMSActive).copyWith(isPlaying: false));
      }
    }
  }

  Future<void> stopAudio() async {
    await _player.stop();
    if (state is KMSActive) {
      emit((state as KMSActive).copyWith(isPlaying: false));
    }
  }

  void _onPlaybackCompleted() {
    if (state is! KMSActive) return;
    final current = state as KMSActive;
    emit(current.copyWith(
      isPlaying: false,
      listenLoopCount: current.listenLoopCount + 1,
    ));
  }

  Future<void> _prefetchAudio(int surahId, int ayahNumber) async {
    try {
      await AudioCacheService.instance.getAudioSource(surahId, ayahNumber);
    } catch (_) {} // Non-critical prefetch
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _playerStateSub?.cancel();
    await _player.dispose();
    return super.close();
  }
}
