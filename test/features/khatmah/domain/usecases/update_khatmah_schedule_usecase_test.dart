import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_schedule_usecase.dart';

void main() {
  late KhatmahRepositoryImpl repository;
  late UpdateKhatmahScheduleUsecase usecase;

  final activePlan = KhatmahPlan(
    id: 'plan-1',
    title: 'Ramadan',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
    completedPages: const {1, 100},
    status: KhatmahStatus.active,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = KhatmahRepositoryImpl(
      KhatmahLocalDatasource(await SharedPreferences.getInstance()),
    );
    usecase = UpdateKhatmahScheduleUsecase(repository);
  });

  test(
    'updates schedule metadata on the authoritative repository plan',
    () async {
      final newEnd = DateTime(2026, 4, 1);
      await repository.createPlan(activePlan);

      final result = await usecase(
        planId: activePlan.id,
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: newEnd,
      );

      final persisted = (await repository.getActivePlan())!;
      expect(persisted.completedPages, const {1, 100});
      expect(persisted.status, KhatmahStatus.active);
      expect(persisted.targetPagesPerDay, 6);
      expect(persisted.expectedEndDate, newEnd);
      expect(result, persisted);
    },
  );

  test('rejects a schedule update for a mismatched plan id', () async {
    await repository.createPlan(activePlan);

    await expectLater(
      usecase(
        planId: 'another-plan',
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: DateTime(2026, 4, 1),
      ),
      throwsA(isA<KhatmahProgressException>()),
    );
    expect(await repository.getActivePlan(), activePlan);
  });

  test('rejects a schedule update when no active plan exists', () async {
    await expectLater(
      usecase(
        planId: activePlan.id,
        targetPagesPerDay: 6,
        targetDays: 101,
        expectedEndDate: DateTime(2026, 4, 1),
      ),
      throwsA(isA<KhatmahProgressException>()),
    );
    expect(await repository.getActivePlan(), isNull);
  });
}
