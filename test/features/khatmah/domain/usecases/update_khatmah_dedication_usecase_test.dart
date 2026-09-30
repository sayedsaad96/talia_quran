import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/update_khatmah_dedication_usecase.dart';

void main() {
  late KhatmahRepositoryImpl repository;
  late UpdateKhatmahDedicationUsecase usecase;

  final pausedPlan = KhatmahPlan(
    id: 'plan-1',
    title: KhatmahPlan.defaultTitle,
    completedPages: const {1, 2},
    targetPagesPerDay: 5,
    targetDays: 121,
    status: KhatmahStatus.paused,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 5, 1),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = KhatmahRepositoryImpl(
      KhatmahLocalDatasource(await SharedPreferences.getInstance()),
    );
    usecase = UpdateKhatmahDedicationUsecase(repository);
  });

  test(
    'updates dedication and title on a paused plan without touching progress',
    () async {
      await repository.createPlan(pausedPlan);
      const dedication = KhatmahDedication(
        isDedicated: true,
        recipientName: ' فاطمة ',
        recipientGender: DedicationGender.female,
      );

      final updated = await usecase(
        (await repository.getActivePlan())!,
        dedication,
      );

      final persisted = (await repository.getActivePlan())!;
      expect(updated.title, 'فاطمة');
      expect(persisted.title, 'فاطمة');
      expect(persisted.dedication, dedication);
      expect(persisted.completedPages, {1, 2});
      expect(persisted.status, KhatmahStatus.paused);
    },
  );

  test('clearing the dedication restores the default title', () async {
    await repository.createPlan(
      pausedPlan.copyWith(
        title: 'فاطمة',
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'فاطمة',
        ),
      ),
    );

    final updated = await usecase(
      (await repository.getActivePlan())!,
      KhatmahDedication.none,
    );

    expect(updated.title, KhatmahPlan.defaultTitle);
    expect(updated.dedication, KhatmahDedication.none);
  });
}
