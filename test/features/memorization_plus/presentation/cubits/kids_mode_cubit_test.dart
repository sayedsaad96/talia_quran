import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
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

    setUp(() {
      repository = _FakeMemorizationPlusRepository();
      achievementService = _FakeAchievementService();
      quranRepository = _UnusedQuranRepository();
      streakService = _FakeStreakService();
      xpService = _FakeXpService();

      cubit = KidsModeCubit(
        GetKidsProgressUsecase(repository),
        AwardKidsPointsUsecase(repository),
        MarkAyahMemorizedUsecase(repository),
        SaveKidsSessionLogUsecase(repository),
        achievementService,
        quranRepository,
        streakService,
        xpService,
        _FakeKidsRecitationRecorder(),
      );
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
        cubit = KidsModeCubit(
          GetKidsProgressUsecase(repository),
          AwardKidsPointsUsecase(repository),
          MarkAyahMemorizedUsecase(repository),
          SaveKidsSessionLogUsecase(repository),
          achievementService,
          quranRepository,
          streakService,
          xpService,
          _FakeKidsRecitationRecorder(
            result: const KidsRecitationCaptureResult.notCaptured(),
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

      await cubit.load(114, 1, 'ayah text');
      cubit.debugSetLoopCount(3);

      await cubit.startRecording();

      final state = cubit.state as KidsModeLoaded;
      expect(state.isCompleted, isTrue);
      expect(repository.awardCalls, 1);
      expect(repository.markCalls, 1);
      expect(repository.saveLogCalls, 1);
    });
  });
}

AyahReviewRecord _memorizedRecord() {
  final now = DateTime.now().toUtc();
  return AyahReviewRecord(
    surahId: 114,
    ayahNumber: 1,
    strengthLevel: 6,
    intervalDays: 1,
    lastReviewedAt: now,
    nextReviewDate: now.add(const Duration(days: 1)),
    totalReviews: 1,
    lastRating: PerformanceRating.excellent,
  );
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
  Future<Either<Failure, AyahReviewRecord>> markAyahMemorized({
    required int surahId,
    required int ayahNumber,
    ReviewRecordCreatedByMode createdByMode =
        ReviewRecordCreatedByMode.kidsMode,
  }) async {
    expect(surahId, 114);
    expect(ayahNumber, 1);
    markCalls++;
    return Right(_memorizedRecord());
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
  Future<List<CertificateAward>> checkAndUnlockCertificates() async {
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
    this.result = const KidsRecitationCaptureResult.captured(),
  });

  final KidsRecitationCaptureResult result;

  @override
  Future<KidsRecitationCaptureResult> capture() async => result;

  @override
  Future<void> dispose() async {}
}
