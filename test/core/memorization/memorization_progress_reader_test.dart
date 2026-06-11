import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/memorization_progress_reader.dart';
import 'package:talia_quran/core/memorization/memorization_snapshot.dart';
import 'package:talia_quran/core/memorization/usecases/get_memorization_snapshot_usecase.dart';
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
        '/memorization-plus/daily-plan?surahId=67',
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
        '/memorization-plus/daily-plan?surahId=67',
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
  });

  final MemorizationProfile profile;
  final List<AyahReviewRecord> reviewRecords;
  final DailyPlan? cachedPlan;
  final KidsProgress kidsProgress;
  final List<KidsSessionLog> kidsLogs;
  int writeCallCount = 0;

  void _recordWrite() {
    writeCallCount++;
    throw StateError('write operation invoked');
  }

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      Right(profile);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async =>
      Right(reviewRecords);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      Right(cachedPlan);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, KidsProgress>> getKidsProgress() async =>
      Right(kidsProgress);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      Right(kidsLogs);

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
  _FakeHifzRepository({this.dueReviews = const []});

  final List<AyahProgress> dueReviews;
  int writeCallCount = 0;

  void _recordWrite() {
    writeCallCount++;
    throw StateError('write operation invoked');
  }

  @override
  Future<Either<Failure, List<AyahProgress>>> getDueReviews() async =>
      Right(dueReviews);

  @override
  Future<Either<Failure, List<SurahHifzProgress>>>
  getAllSurahProgress() async => const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString();
    if (name.startsWith('save') || name.startsWith('mark')) {
      _recordWrite();
    }
    return super.noSuchMethod(invocation);
  }
}
