import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/v2/session_adapters.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/services/achievement_service.dart';
import 'package:talia_quran/core/services/streak_service.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_result.dart';
import 'package:talia_quran/features/xp/domain/entities/xp_gain_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KidsModeCubit', () {
    late _FakeMemorizationPlusRepository repository;
    late _FakeAchievementService achievementService;
    late _UnusedQuranRepository quranRepository;
    late _FakeStreakService streakService;
    late _FakeXpService xpService;
    late KidsModeCubit cubit;

    KidsModeCubit buildCubit({required KidsRecitationRecorder recorder}) =>
        KidsModeCubit(
          GetKidsProgressUsecase(repository),
          AwardKidsPointsUsecase(repository),
          SaveKidsSessionLogUsecase(repository),
          achievementService,
          quranRepository,
          V2SessionEngine(),
          V2SessionReviewAdapter(
            repository: repository,
            scheduler: const ScheduleNextReviewUsecase(),
          ),
          streakService,
          xpService,
          recorder,
        );

    setUp(() {
      repository = _FakeMemorizationPlusRepository();
      achievementService = _FakeAchievementService();
      quranRepository = _UnusedQuranRepository();
      streakService = _FakeStreakService();
      xpService = _FakeXpService();

      cubit = buildCubit(recorder: _FakeKidsRecitationRecorder());
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'rapid duplicate markCompleted calls award side effects once',
      () async {
        final awardCompleter =
            Completer<Either<Failure, KidsCompletionResult>>();
        repository.awardCompleter = awardCompleter;

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        final firstCompletion = cubit.markCompleted();
        await Future<void>.delayed(Duration.zero);
        final duplicateCompletion = cubit.markCompleted();
        await Future<void>.delayed(Duration.zero);

        expect(repository.awardCalls, 1);

        awardCompleter.complete(
          Right(
            KidsCompletionResult(
              progress: const KidsProgress.initial().addPoints(14),
              pointsEarned: 14,
              starsEarned: 1,
              alreadyCompleted: false,
            ),
          ),
        );

        await Future.wait([firstCompletion, duplicateCompletion]);

        expect(repository.awardCalls, 1);
        expect(repository.markCalls, 1);
        expect(streakService.recordCalls, 1);
        expect(xpService.addCalls, 1);
        expect(repository.saveLogCalls, 1);
        expect(achievementService.checkCalls, 1);
      },
    );

    test(
      'startRecording does not complete when no recitation is captured',
      () async {
        await cubit.close();
        cubit = buildCubit(
          recorder: _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.stoppedByUser(),
          ),
        );

        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        await cubit.startRecording();

        final state = cubit.state as KidsModeLoaded;
        expect(state.isCompleted, isFalse);
        expect(state.isRecording, isFalse);
        expect(
          state.recordingError,
          CubitMessageCodes.kidsRecordingNotCaptured,
        );
        expect(repository.awardCalls, 0);
        expect(repository.markCalls, 0);
        expect(repository.saveLogCalls, 0);
      },
    );

    test('startRecording completes after recitation is captured', () async {
      repository.awardCompleter = Completer()
        ..complete(
          Right(
            KidsCompletionResult(
              progress: const KidsProgress.initial().addPoints(14),
              pointsEarned: 14,
              starsEarned: 1,
              alreadyCompleted: false,
            ),
          ),
        );

      cubit = buildCubit(
        recorder: _FakeKidsRecitationRecorder(
          result: const KidsRecitationCaptureResult.captured(words: 'ayah text'),
        ),
      );

      await cubit.load(114, 1, 'ayah text');
      cubit.debugSetLoopCount(3);

      await cubit.startRecording();

      final state = cubit.state as KidsModeLoaded;
      expect(state.isCompleted, isTrue);
      expect(repository.awardCalls, 1);
      expect(repository.markCalls, 1);
      expect(repository.saveLogCalls, 1);
    });

    test(
      'markCompleted records StreakService activity as the single streak source',
      () async {
        await cubit.load(114, 1, 'ayah text');
        cubit.debugSetLoopCount(3);

        repository.awardCompleter = Completer()
          ..complete(
            const Right(
              KidsCompletionResult(
                progress: KidsProgress(
                  totalPoints: 14,
                  currentLevel: 1,
                  currentStreak: 5,
                  starsEarned: 1,
                  ayahsCompleted: 1,
                  lastSessionAt: null,
                ),
                pointsEarned: 14,
                starsEarned: 1,
                alreadyCompleted: false,
              ),
            ),
          );

        await cubit.markCompleted();

        expect(streakService.recordCalls, 1);
        final state = cubit.state as KidsModeLoaded;
        expect(state.progress.currentStreak, 5);
      },
    );
  });
}

KidsSessionLog _sessionLog() => KidsSessionLog(
  id: '114_1',
  surahId: 114,
  ayahNumber: 1,
  repeatsCompleted: 3,
  pointsEarned: 14,
  completedAt: DateTime.now().toUtc(),
);

class _FakeMemorizationPlusRepository implements MemorizationPlusRepository {
  Completer<Either<Failure, KidsCompletionResult>>? awardCompleter;
  int awardCalls = 0;
  int markCalls = 0;
  int saveLogCalls = 0;

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async =>
      const Right(KidsProgress.initial());

  @override
  Future<Either<Failure, KidsCompletionResult>> awardKidsPoints({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
  }) {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    expect(repeatsCompleted, 3);
    awardCalls++;
    return awardCompleter!.future;
  }

  @override
  Future<Either<Failure, AyahReviewRecord?>> getReviewRecord(
    int surahId,
    int ayahNumber, {
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> saveReviewRecord(
    AyahReviewRecord record,
  ) async {
    expect(record.surahId, 114);
    expect(record.ayahNumber, 1);
    expect(record.createdByMode, ReviewRecordCreatedByMode.kidsMode);
    markCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, KidsSessionLog>> saveKidsSessionLog({
    required int surahId,
    required int ayahNumber,
    required int repeatsCompleted,
    required int pointsEarned,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    expect(repeatsCompleted, 3);
    expect(pointsEarned, 14);
    saveLogCalls++;
    return Right(_sessionLog());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAchievementService implements AchievementService {
  int checkCalls = 0;

  @override
  Future<List<CertificateAward>> checkAndUnlockCertificates({required bool isKids}) async {
    checkCalls++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStreakService implements StreakService {
  int recordCalls = 0;

  @override
  Future<StreakResult> recordActivity({int activityDelta = 1}) async {
    expect(activityDelta, 1);
    recordCalls++;
    return const StreakResult.sameDay();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeXpService implements XpService {
  int addCalls = 0;

  @override
  Future<XpGainResult> addXp(String eventKey) async {
    expect(eventKey, 'ayah_memorized');
    addCalls++;
    return const XpGainResult.zero();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeKidsRecitationRecorder implements KidsRecitationRecorder {
  _FakeKidsRecitationRecorder({
    this.result = const KidsRecitationCaptureResult.stoppedByUser(),
  });

  final KidsRecitationCaptureResult result;

  @override
  Future<KidsRecitationCaptureResult> capture({
    Completer<KidsRecitationCaptureResult>? externalCompleter,
  }) async => result;

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
