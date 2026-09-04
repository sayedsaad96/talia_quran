import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';

void main() {
  late KhatmahRepositoryImpl repository;
  late RecordKhatmahReadingUsecase usecase;
  final plan = KhatmahPlan(
    id: 'plan-1',
    title: 'Ramadan Khatmah',
    targetPagesPerDay: 4,
    targetDays: 151,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 6, 1),
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repository = KhatmahRepositoryImpl(
      KhatmahLocalDatasource(await SharedPreferences.getInstance()),
    );
    usecase = RecordKhatmahReadingUsecase(repository);
  });
  test('digital reading records exactly the requested page durably', () async {
    await repository.createPlan(plan);
    final result = await usecase(
      (await repository.getActivePlan())!,
      100,
      source: KhatmahReadingSource.digital,
      readAt: DateTime(2026, 2, 1),
    );
    expect(result.newlyCompletedPages, {100});
    final persisted = (await repository.getActivePlan())!;
    expect(persisted.completedPages, {100});
    expect(persisted.lastReadDate, DateTime(2026, 2, 1));
    expect(await repository.getHistory(), isEmpty);
  });
  test(
    'physical reading records the inclusive range from next unread page',
    () async {
      await repository.createPlan(plan.copyWith(completedPages: {1}));
      final result = await usecase(
        (await repository.getActivePlan())!,
        4,
        source: KhatmahReadingSource.physical,
      );
      expect(result.newlyCompletedPages, {2, 3, 4});
      expect((await repository.getActivePlan())!.completedPages, {1, 2, 3, 4});
    },
  );
  test('paused plans reject progress without persisting', () async {
    await repository.createPlan(plan.copyWith(status: KhatmahStatus.paused));
    final paused = (await repository.getActivePlan())!;
    await expectLater(
      usecase(paused, 1, source: KhatmahReadingSource.digital),
      throwsA(isA<KhatmahProgressException>()),
    );
    expect((await repository.getActivePlan())!.completedPages, isEmpty);
    expect((await repository.getActivePlan())!.status, KhatmahStatus.paused);
  });
  test('rejects page numbers outside the Quran bounds', () async {
    await repository.createPlan(plan);
    for (final page in [0, 605]) {
      await expectLater(
        usecase(
          (await repository.getActivePlan())!,
          page,
          source: KhatmahReadingSource.digital,
        ),
        throwsA(isA<KhatmahProgressException>()),
      );
    }
    expect((await repository.getActivePlan())!.completedPages, isEmpty);
  });
  test('persists incomplete readings without completing the plan', () async {
    await repository.createPlan(plan);
    final result = await usecase(
      (await repository.getActivePlan())!,
      1,
      source: KhatmahReadingSource.digital,
    );
    expect(result.completed, isFalse);
    expect((await repository.getActivePlan())!.completedPages, {1});
    expect(await repository.getHistory(), isEmpty);
  });
  test(
    'returns the persisted history entry when final coverage completes',
    () async {
      await repository.createPlan(
        plan.copyWith(completedPages: {for (var p = 1; p < 604; p++) p}),
      );
      final result = await usecase(
        (await repository.getActivePlan())!,
        604,
        source: KhatmahReadingSource.digital,
        readAt: DateTime(2026, 2, 1),
      );
      expect(result.completed, isTrue);
      expect(result.plan.status, KhatmahStatus.completed);
      expect(result.historyEntry, (await repository.getHistory()).single);
      expect(result.historyEntry!.completedDate, DateTime(2026, 2, 1));
      expect(result.historyEntry!.certificateId, 'khatmah-plan-1');
      expect(await repository.getActivePlan(), isNull);
    },
  );
}
