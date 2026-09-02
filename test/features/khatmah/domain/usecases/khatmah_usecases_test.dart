import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
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
      currentPage: 30,
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
      when(() => mockRepository.getActivePlan()).thenAnswer((_) async => testPlan);

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
    test('calls repository.createPlan with provided plan', () async {
      when(() => mockRepository.createPlan(any())).thenAnswer((_) async {});

      final usecase = CreateKhatmahUsecase(mockRepository);
      await usecase(testPlan);

      verify(() => mockRepository.createPlan(testPlan)).called(1);
    });
  });

  group('UpdateKhatmahProgressUsecase', () {
    test('advances currentPage, updates lastReadDate, calls repository.updatePlan, and returns updated plan', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final usecase = UpdateKhatmahProgressUsecase(mockRepository);
      final updated = await usecase(testPlan, 50);

      expect(updated.currentPage, 50);
      expect(updated.lastReadDate, isNotNull);
      verify(() => mockRepository.updatePlan(any(that: isA<KhatmahPlan>().having((p) => p.currentPage, 'currentPage', 50)))).called(1);
    });

    test('updates lastReadDate with provided custom date', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final usecase = UpdateKhatmahProgressUsecase(mockRepository);
      final customDate = DateTime(2026, 3, 10, 14, 0);
      final updated = await usecase(testPlan, 60, customDate);

      expect(updated.currentPage, 60);
      expect(updated.lastReadDate, equals(customDate));
      verify(() => mockRepository.updatePlan(any(that: isA<KhatmahPlan>().having((p) => p.currentPage, 'currentPage', 60)))).called(1);
    });
  });

  group('CompleteKhatmahUsecase', () {
    test('sets currentPage=604, status=completed, and calls repository.completePlan', () async {
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
      await usecase(testPlan);

      verify(() => mockRepository.completePlan(any(
        that: isA<KhatmahPlan>()
            .having((p) => p.currentPage, 'currentPage', 604)
            .having((p) => p.status, 'status', KhatmahStatus.completed),
      ))).called(1);
    });
  });

  group('PauseResumeKhatmahUsecase', () {
    test('pause sets status=paused, pausedAt=now, calls repository.updatePlan, and returns paused plan', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final usecase = PauseResumeKhatmahUsecase(mockRepository);
      final paused = await usecase.pause(testPlan);

      expect(paused.status, KhatmahStatus.paused);
      expect(paused.pausedAt, isNotNull);
      verify(() => mockRepository.updatePlan(any(
        that: isA<KhatmahPlan>()
            .having((p) => p.status, 'status', KhatmahStatus.paused)
            .having((p) => p.pausedAt, 'pausedAt', isNotNull),
      ))).called(1);
    });

    test('pause respects custom pause date when provided', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final usecase = PauseResumeKhatmahUsecase(mockRepository);
      final pauseDate = DateTime(2026, 2, 1, 12, 0);
      final paused = await usecase.pause(testPlan, pauseDate);

      expect(paused.status, KhatmahStatus.paused);
      expect(paused.pausedAt, equals(pauseDate));
      verify(() => mockRepository.updatePlan(any(
        that: isA<KhatmahPlan>()
            .having((p) => p.status, 'status', KhatmahStatus.paused)
            .having((p) => p.pausedAt, 'pausedAt', pauseDate),
      ))).called(1);
    });

    test('resume recalculates expectedEndDate, clears pausedAt, sets status=active, calls repository.updatePlan, and returns resumed plan', () async {
      when(() => mockRepository.updatePlan(any())).thenAnswer((_) async {});

      final pausedPlan = testPlan.copyWith(
        status: KhatmahStatus.paused,
        pausedAt: DateTime(2026, 2, 1),
      );

      final usecase = PauseResumeKhatmahUsecase(mockRepository);
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
      verify(() => mockRepository.updatePlan(any(
        that: isA<KhatmahPlan>()
            .having((p) => p.status, 'status', KhatmahStatus.active)
            .having((p) => p.pausedAt, 'pausedAt', isNull)
            .having((p) => p.expectedEndDate, 'expectedEndDate', expectedEnd),
      ))).called(1);
    });
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
