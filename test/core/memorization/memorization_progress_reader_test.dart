import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_progress_reader.dart';
import 'package:talia_quran/core/memorization/memorization_snapshot.dart';
import 'package:talia_quran/core/memorization/smart_coach_engine.dart';
import 'package:talia_quran/core/memorization/smart_coach_recommendation.dart';
import 'package:talia_quran/core/memorization/usecases/get_memorization_snapshot_usecase.dart';
import 'package:talia_quran/core/memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import 'package:talia_quran/core/services/app_session_service.dart';
import 'package:talia_quran/features/hifz/domain/entities/hifz_entities.dart';
import 'package:talia_quran/features/hifz/domain/repositories/hifz_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

void main() {
  group('MemorizationProgressReader', () {
    test('returns valid snapshot for adult path with review data', () async {
      final reviewRecord = AyahReviewRecord(
        surahId: 67,
        ayahNumber: 1,
        strengthLevel: 3,
        intervalDays: 3,
        lastReviewedAt: DateTime.utc(2026, 1, 1),
        nextReviewDate: DateTime.utc(2026, 1, 4),
        totalReviews: 2,
        lastRating: PerformanceRating.average,
      );
      final profile = _profile(MemorizationPath.adult);
      final memPlus = _FakeMemPlusRepository(
        profile: profile,
        reviewRecords: [reviewRecord],
        cachedPlan: _dailyPlan(67),
      );
      final hifz = _FakeHifzRepository(
        dueReviews: [
          AyahProgress(
            surahId: 1,
            ayahNumber: 1,
            status: AyahStatus.review,
            repetitions: 2,
            nextReviewDate: DateTime.utc(2026, 1, 1),
            lastReviewDate: DateTime.utc(2025, 12, 30),
          ),
        ],
      );
      final session = await _sessionServiceWithLocation(
        '/memorization-v2/session?surahId=67',
      );
      final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

      final result = await reader.readSnapshot();
      final snapshot = result.getOrElse(() => throw StateError('failed'));

      expect(snapshot.profile, profile);
      expect(snapshot.reviewRecords, [reviewRecord]);
      expect(snapshot.cachedDailyPlan?.surahId, 67);
      expect(snapshot.hifzDueReviews, hasLength(1));
      expect(
        snapshot.lastRestorableLocation,
        '/memorization-v2/session?surahId=67',
      );
      expect(memPlus.writeCallCount, 0);
      expect(hifz.writeCallCount, 0);
    });

    test('returns valid empty snapshot when stores are empty', () async {
      final profile = MemorizationProfile.empty();
      final memPlus = _FakeMemPlusRepository(profile: profile);
      final hifz = _FakeHifzRepository();
      final session = await _sessionServiceWithLocation(null);
      final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

      final result = await reader.readSnapshot();
      final snapshot = result.getOrElse(() => throw StateError('failed'));

      expect(snapshot.profile.hasSelectedPath, isFalse);
      expect(snapshot.reviewRecords, isEmpty);
      expect(snapshot.cachedDailyPlan, isNull);
      expect(snapshot.customPlan, isNull);
      expect(snapshot.hifzDueReviews, isEmpty);
      expect(snapshot.hifzSurahProgress, isEmpty);
      expect(snapshot.kidsSessionLogs, isEmpty);
      expect(snapshot.lastRestorableLocation, isNull);
      expect(memPlus.writeCallCount, 0);
      expect(hifz.writeCallCount, 0);
    });

    test('never invokes repository write operations', () async {
      final memPlus = _FakeMemPlusRepository(
        profile: _profile(MemorizationPath.child),
        kidsProgress: const KidsProgress.initial(),
        kidsLogs: [
          KidsSessionLog(
            id: '1',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      final hifz = _FakeHifzRepository();
      final session = await _sessionServiceWithLocation(null);
      final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

      await reader.readSnapshot();

      expect(memPlus.writeCallCount, 0);
      expect(hifz.writeCallCount, 0);
    });

    test(
      'returns partial adult snapshot when Hifz optional reads fail',
      () async {
        final now = DateTime.now().toUtc();
        final reviewRecord = AyahReviewRecord(
          surahId: 67,
          ayahNumber: 5,
          strengthLevel: 1,
          intervalDays: 1,
          lastReviewedAt: now.subtract(const Duration(days: 1)),
          nextReviewDate: now.subtract(const Duration(hours: 1)),
          totalReviews: 3,
          lastRating: PerformanceRating.weak,
        );
        final memPlus = _FakeMemPlusRepository(
          profile: _profile(MemorizationPath.adult),
          reviewRecords: [reviewRecord],
        );
        final hifz = _FakeHifzRepository(
          failure: const CacheFailure('hifz unavailable'),
        );
        final session = await _sessionServiceWithLocation(null);
        final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

        final result = await reader.readSnapshot();
        final snapshot = result.getOrElse(() => throw StateError('failed'));

        expect(snapshot.reviewRecords, [reviewRecord]);
        expect(snapshot.hifzDueReviews, isEmpty);
        expect(snapshot.hifzSurahProgress, isEmpty);
      },
    );

    test(
      'returns partial kids snapshot when adult review store fails',
      () async {
        final log = KidsSessionLog(
          id: 'kid-log',
          surahId: 114,
          ayahNumber: 1,
          repeatsCompleted: 3,
          pointsEarned: 10,
          completedAt: DateTime.utc(2026, 1, 1),
        );
        final memPlus = _FakeMemPlusRepository(
          profile: _profile(MemorizationPath.child),
          kidsLogs: [log],
          reviewFailure: const CacheFailure('review store unavailable'),
        );
        final hifz = _FakeHifzRepository();
        final session = await _sessionServiceWithLocation(null);
        final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

        final result = await reader.readSnapshot();
        final snapshot = result.getOrElse(() => throw StateError('failed'));

        expect(snapshot.profile.isChild, isTrue);
        expect(snapshot.reviewRecords, isEmpty);
        expect(snapshot.kidsSessionLogs, [log]);
      },
    );

    test(
      'keeps profile failure fatal because path is required for safety',
      () async {
        final memPlus = _FakeMemPlusRepository(
          profile: _profile(MemorizationPath.adult),
          profileFailure: const CacheFailure('profile unavailable'),
        );
        final hifz = _FakeHifzRepository();
        final session = await _sessionServiceWithLocation(null);
        final reader = MemorizationProgressReaderImpl(memPlus, hifz, session);

        final result = await reader.readSnapshot();

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('GetMemorizationSnapshotUsecase', () {
    test('delegates to the reader', () async {
      final expected = MemorizationSnapshot(
        profile: MemorizationProfile.empty(),
      );
      final reader = _FakeReader(expected);
      final useCase = GetMemorizationSnapshotUsecase(reader);

      final result = await useCase();
      final snapshot = result.getOrElse(() => throw StateError('failed'));

      expect(snapshot, expected);
      expect(reader.readCount, 1);
    });
  });

  group('GetSmartCoachRecommendationUsecase partial snapshots', () {
    test(
      'recommends adult weak review when optional Hifz data fails',
      () async {
        final now = DateTime.now().toUtc();
        final memPlus = _FakeMemPlusRepository(
          profile: _profile(MemorizationPath.adult),
          reviewRecords: [
            AyahReviewRecord(
              surahId: 67,
              ayahNumber: 5,
              strengthLevel: 1,
              intervalDays: 1,
              lastReviewedAt: now.subtract(const Duration(days: 1)),
              nextReviewDate: now.subtract(const Duration(hours: 1)),
              totalReviews: 3,
              lastRating: PerformanceRating.weak,
            ),
          ],
        );
        final hifz = _FakeHifzRepository(
          failure: const CacheFailure('hifz unavailable'),
        );
        final session = await _sessionServiceWithLocation(null);
        final snapshotUsecase = GetMemorizationSnapshotUsecase(
          MemorizationProgressReaderImpl(memPlus, hifz, session),
        );
        final usecase = GetSmartCoachRecommendationUsecase(
          snapshotUsecase,
          const SmartCoachEngine(),
        );

        final result = await usecase();
        final recommendation = result.getOrElse(() => null);

        expect(
          recommendation?.kind,
          SmartCoachRecommendationKind.reviewWeakAyah,
        );
        expect(recommendation?.startAyah, 5);
      },
    );

    test('does not use adult review data for child profile', () async {
      final now = DateTime.now().toUtc();
      final memPlus = _FakeMemPlusRepository(
        profile: _profile(MemorizationPath.child),
        reviewRecords: [
          AyahReviewRecord(
            surahId: 67,
            ayahNumber: 5,
            strengthLevel: 1,
            intervalDays: 1,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            nextReviewDate: now.subtract(const Duration(hours: 1)),
            totalReviews: 3,
            lastRating: PerformanceRating.weak,
          ),
        ],
        kidsLogs: [
          KidsSessionLog(
            id: 'kid-log',
            surahId: 114,
            ayahNumber: 1,
            repeatsCompleted: 3,
            pointsEarned: 10,
            completedAt: now,
          ),
        ],
      );
      final hifz = _FakeHifzRepository();
      final session = await _sessionServiceWithLocation(null);
      final snapshotUsecase = GetMemorizationSnapshotUsecase(
        MemorizationProgressReaderImpl(memPlus, hifz, session),
      );
      final usecase = GetSmartCoachRecommendationUsecase(
        snapshotUsecase,
        const SmartCoachEngine(),
      );

      final result = await usecase();
      final recommendation = result.getOrElse(() => null);

      expect(
        recommendation?.kind,
        SmartCoachRecommendationKind.kidsCurrentMission,
      );
      expect(
        recommendation?.kind,
        isNot(SmartCoachRecommendationKind.reviewWeakAyah),
      );
      expect(recommendation?.surahId, 114);
    });
  });
}

Future<AppSessionService> _sessionServiceWithLocation(String? location) async {
  SharedPreferences.setMockInitialValues(
    location == null ? {} : {'last_restorable_location': location},
  );
  return AppSessionService(await SharedPreferences.getInstance());
}

MemorizationProfile _profile(MemorizationPath path) => MemorizationProfile(
  schemaVersion: 1,
  selectedPath: path,
  guardianLinkStatus: GuardianLinkStatus.none,
  guardianOnboardingStatus: GuardianOnboardingStatus.completed,
  isParentGuardian: false,
  createdAt: DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

DailyPlan _dailyPlan(int surahId) => DailyPlan(
  generatedAt: DateTime.utc(2026, 1, 1),
  surahId: surahId,
  newAyahs: const [],
  nearRevision: const [],
  farRevision: const [],
  completedAyahNums: const [],
);

class _FakeReader implements MemorizationProgressReader {
  _FakeReader(this._snapshot);

  final MemorizationSnapshot _snapshot;
  int readCount = 0;

  @override
  Future<Either<Failure, MemorizationSnapshot>> readSnapshot() async {
    readCount++;
    return Right(_snapshot);
  }
}

class _FakeMemPlusRepository implements MemorizationPlusRepository {
  _FakeMemPlusRepository({
    required this.profile,
    this.reviewRecords = const [],
    this.cachedPlan,
    this.kidsProgress = const KidsProgress.initial(),
    this.kidsLogs = const [],
    this.profileFailure,
    this.reviewFailure,
  });

  final MemorizationProfile profile;
  final List<AyahReviewRecord> reviewRecords;
  final DailyPlan? cachedPlan;
  final KidsProgress kidsProgress;
  final List<KidsSessionLog> kidsLogs;
  final Failure? profileFailure;
  final Failure? reviewFailure;
  int writeCallCount = 0;

  void _recordWrite() {
    writeCallCount++;
    throw StateError('write operation invoked');
  }

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    final failure = profileFailure;
    if (failure != null) return Left(failure);
    return Right(profile);
  }

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async {
    final failure = reviewFailure;
    if (failure != null) return Left(failure);
    return Right(reviewRecords);
  }

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async {
    return Right(cachedPlan);
  }

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async {
    return Right(kidsProgress);
  }

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
    return Right(kidsLogs);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name.toString().startsWith('save') ||
        name.toString().startsWith('evaluate') ||
        name.toString().startsWith('mark') ||
        name.toString().startsWith('delete') ||
        name.toString().startsWith('award') ||
        name.toString().startsWith('sync') ||
        name.toString().startsWith('accept') ||
        name.toString().startsWith('create') ||
        name.toString().startsWith('unlink') ||
        name.toString().startsWith('reset') ||
        name.toString().startsWith('set') ||
        name.toString().startsWith('select') ||
        name.toString().startsWith('continue') ||
        name.toString().startsWith('generate')) {
      _recordWrite();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHifzRepository implements HifzRepository {
  _FakeHifzRepository({this.dueReviews = const [], this.failure});

  final List<AyahProgress> dueReviews;
  final Failure? failure;
  int writeCallCount = 0;

  void _recordWrite() {
    writeCallCount++;
    throw StateError('write operation invoked');
  }

  @override
  Future<Either<Failure, List<AyahProgress>>> getDueReviews() async {
    final currentFailure = failure;
    if (currentFailure != null) return Left(currentFailure);
    return Right(dueReviews);
  }

  @override
  Future<Either<Failure, List<SurahHifzProgress>>> getAllSurahProgress() async {
    final currentFailure = failure;
    if (currentFailure != null) return Left(currentFailure);
    return const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.startsWith('save') || name.startsWith('mark')) {
      _recordWrite();
    }
    return super.noSuchMethod(invocation);
  }
}
