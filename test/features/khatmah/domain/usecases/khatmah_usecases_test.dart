import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_scheduling_engine.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';

class MockKhatmahRepository extends Mock implements KhatmahRepository {}

class FakeKhatmahPlan extends Fake implements KhatmahPlan {}

void main() {
  late MockKhatmahRepository mockRepository;
  late KhatmahPlan testPlan;

  setUpAll(() {
    registerFallbackValue(FakeKhatmahPlan());
  });

  setUp(() {
    mockRepository = MockKhatmahRepository();
    testPlan = KhatmahPlan(
      id: 'plan-1',
      title: 'Ramadan Khatmah',
      startPage: 1,
      completedPages: {for (var page = 1; page <= 30; page++) page},
      targetPagesPerDay: 4,
      targetDays: 151,
      startDate: DateTime(2026, 1, 1),
      expectedEndDate: DateTime(2026, 6, 1),
      status: KhatmahStatus.active,
      dedication: const KhatmahDedication(
        isDedicated: true,
        recipientName: 'Father',
        relationship: 'Father',
        condition: DedicationCondition.deceased,
      ),
    );
  });

  group('GetActiveKhatmahUsecase', () {
    test('returns active plan from repository when one exists', () async {
      when(
        () => mockRepository.getActivePlan(),
      ).thenAnswer((_) async => testPlan);

      final usecase = GetActiveKhatmahUsecase(mockRepository);
      final result = await usecase();

      expect(result, equals(testPlan));
      verify(() => mockRepository.getActivePlan()).called(1);
    });

    test('returns null when repository has no active plan', () async {
      when(() => mockRepository.getActivePlan()).thenAnswer((_) async => null);

      final usecase = GetActiveKhatmahUsecase(mockRepository);
      final result = await usecase();

      expect(result, isNull);
      verify(() => mockRepository.getActivePlan()).called(1);
    });
  });

  group('CreateKhatmahUsecase', () {
    test('uses atomic repository creation for the provided plan', () async {
      when(
        () => mockRepository.createPlanIfAbsent(any()),
      ).thenAnswer((_) async => null);

      final usecase = CreateKhatmahUsecase(mockRepository);
      await usecase(testPlan);

      verify(() => mockRepository.createPlanIfAbsent(testPlan)).called(1);
    });

    test('rejects creation when an active plan already exists', () async {
      when(
        () => mockRepository.createPlanIfAbsent(any()),
      ).thenAnswer((_) async => testPlan);

      final usecase = CreateKhatmahUsecase(mockRepository);

      await expectLater(
        () => usecase(testPlan.copyWith(id: 'replacement-plan')),
        throwsA(isA<KhatmahPlanAlreadyExistsException>()),
      );

      verifyNever(() => mockRepository.createPlan(any()));
    });

    test('rejects creation when a paused plan already exists', () async {
      final paused = testPlan.copyWith(status: KhatmahStatus.paused);
      when(
        () => mockRepository.createPlanIfAbsent(any()),
      ).thenAnswer((_) async => paused);

      final usecase = CreateKhatmahUsecase(mockRepository);

      await expectLater(
        () => usecase(testPlan.copyWith(id: 'replacement-plan')),
        throwsA(isA<KhatmahPlanAlreadyExistsException>()),
      );

      verifyNever(() => mockRepository.createPlan(any()));
    });

    test('allows creation after atomic terminal-plan cleanup', () async {
      when(
        () => mockRepository.createPlanIfAbsent(any()),
      ).thenAnswer((_) async => null);

      final replacement = testPlan.copyWith(id: 'replacement-plan');
      final usecase = CreateKhatmahUsecase(mockRepository);
      await usecase(replacement);

      verify(() => mockRepository.createPlanIfAbsent(replacement)).called(1);
    });
  });

  group('UpdateKhatmahProgressUsecase', () {
    test(
      'advances currentPage, updates lastReadDate, calls repository.updatePlan, and returns updated plan',
      () async {
        when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

        final usecase = UpdateKhatmahProgressUsecase(mockRepository);
        final updated = await usecase(testPlan, 50);

        expect(updated.currentPage, 30);
        expect(updated.completedPages, contains(50));
        expect(updated.lastReadDate, isNotNull);
        verify(
          () => mockRepository.updatePlan(
            any(
              that: isA<KhatmahPlan>().having(
                (p) => p.completedPages,
                'completedPages',
                contains(50),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test('updates lastReadDate with provided custom date', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final usecase = UpdateKhatmahProgressUsecase(mockRepository);
      final customDate = DateTime(2026, 3, 10, 14, 0);
      final updated = await usecase(testPlan, 60, customDate);

      expect(updated.currentPage, 30);
      expect(updated.completedPages, contains(60));
      expect(updated.lastReadDate, equals(customDate));
      verify(
        () => mockRepository.updatePlan(
          any(
            that: isA<KhatmahPlan>().having(
              (p) => p.completedPages,
              'completedPages',
              contains(60),
            ),
          ),
        ),
      ).called(1);
    });
  });

  group('CompleteKhatmahUsecase', () {
    test(
      'rejects incomplete coverage without calling repository completion',
      () async {
        when(() => mockRepository.completePlan(any())).thenAnswer(
          (_) async => KhatmahHistoryEntry(
            id: testPlan.id,
            khatmahNumber: 1,
            title: testPlan.title,
            startDate: testPlan.startDate,
            completedDate: DateTime(2026, 2, 1),
            totalDays: 32,
          ),
        );

        final usecase = CompleteKhatmahUsecase(mockRepository);
        await expectLater(
          () => usecase(testPlan),
          throwsA(isA<KhatmahProgressException>()),
        );

        verifyNever(() => mockRepository.completePlan(any()));
      },
    );
  });

  group('PauseResumeKhatmahUsecase', () {
    late KhatmahRepositoryImpl realRepository;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      realRepository = KhatmahRepositoryImpl(
        KhatmahLocalDatasource(await SharedPreferences.getInstance()),
      );
    });
    test('pause durably sets status=paused and pausedAt=now', () async {
      await realRepository.createPlan(testPlan);
      final usecase = PauseResumeKhatmahUsecase(realRepository);
      final paused = await usecase.pause(testPlan);

      expect(paused.status, KhatmahStatus.paused);
      expect(paused.pausedAt, isNotNull);
      expect(await realRepository.getActivePlan(), paused);
    });

    test('pause respects custom pause date when provided', () async {
      await realRepository.createPlan(testPlan);
      final usecase = PauseResumeKhatmahUsecase(realRepository);
      final pauseDate = DateTime(2026, 2, 1, 12, 0);
      final paused = await usecase.pause(testPlan, pauseDate);

      expect(paused.status, KhatmahStatus.paused);
      expect(paused.pausedAt, equals(pauseDate));
      expect(await realRepository.getActivePlan(), paused);
    });

    test(
      'resume durably recalculates expectedEndDate, clears pausedAt, and activates plan',
      () async {
        when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

        final pausedPlan = testPlan.copyWith(
          status: KhatmahStatus.paused,
          pausedAt: DateTime(2026, 2, 1),
        );

        await realRepository.createPlan(pausedPlan);
        final usecase = PauseResumeKhatmahUsecase(realRepository);
        final resumeDate = DateTime(2026, 2, 10);
        final resumed = await usecase.resume(pausedPlan, resumeDate);

        expect(resumed.status, KhatmahStatus.active);
        expect(resumed.pausedAt, isNull);

        final expectedEnd = KhatmahSchedulingEngine.recalculateAfterResume(
          pausedPlan.remainingPages,
          pausedPlan.targetPagesPerDay,
          resumeDate,
        );
        expect(resumed.expectedEndDate, equals(expectedEnd));
        expect(await realRepository.getActivePlan(), resumed);
      },
    );
  });

  group('DeleteKhatmahUsecase', () {
    test('calls repository.deletePlan', () async {
      when(() => mockRepository.deletePlan()).thenAnswer((_) async {});

      final usecase = DeleteKhatmahUsecase(mockRepository);
      await usecase();

      verify(() => mockRepository.deletePlan()).called(1);
    });
  });
}
