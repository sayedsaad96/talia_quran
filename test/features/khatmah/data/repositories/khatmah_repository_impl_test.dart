import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';

void main() {
  late SharedPreferences prefs;
  late KhatmahLocalDatasource datasource;
  late KhatmahRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = KhatmahLocalDatasource(prefs);
    repository = KhatmahRepositoryImpl(datasource);
  });

  group('KhatmahRepositoryImpl', () {
    final testPlan = KhatmahPlan(
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

    test('getActivePlan returns null when datasource has no active plan', () async {
      final plan = await repository.getActivePlan();
      expect(plan, isNull);
    });

    test('createPlan saves plan and getActivePlan retrieves it', () async {
      await repository.createPlan(testPlan);

      final retrieved = await repository.getActivePlan();
      expect(retrieved, equals(testPlan));
    });

    test('updatePlan updates existing active plan', () async {
      await repository.createPlan(testPlan);

      final updated = testPlan.copyWith(currentPage: 50);
      await repository.updatePlan(updated);

      final retrieved = await repository.getActivePlan();
      expect(retrieved?.currentPage, 50);
    });

    test('deletePlan removes active plan from datasource', () async {
      await repository.createPlan(testPlan);
      expect(await repository.getActivePlan(), isNotNull);

      await repository.deletePlan();
      expect(await repository.getActivePlan(), isNull);
    });

    test('completePlan records history entry with correct khatmahNumber and deletes active plan', () async {
      await repository.createPlan(testPlan);

      await repository.completePlan(testPlan);

      // Active plan should be deleted
      expect(await repository.getActivePlan(), isNull);

      // History should have 1 entry with khatmahNumber = 1
      final history = await repository.getHistory();
      expect(history.length, 1);
      expect(history.first.id, testPlan.id);
      expect(history.first.khatmahNumber, 1);
      expect(history.first.title, testPlan.title);
      expect(history.first.startDate, testPlan.startDate);
      expect(history.first.totalDays, greaterThanOrEqualTo(1));
      expect(history.first.dedication?.recipientName, 'Father');

      // Completed count should be 1
      expect(await repository.getCompletedCount(), 1);
    });

    test('completePlan increments khatmahNumber on subsequent completions', () async {
      await repository.completePlan(testPlan);

      final secondPlan = testPlan.copyWith(id: 'plan-2', title: 'Second Khatmah');
      await repository.completePlan(secondPlan);

      final history = await repository.getHistory();
      expect(history.length, 2);
      expect(history[0].khatmahNumber, 1);
      expect(history[1].khatmahNumber, 2);
      expect(await repository.getCompletedCount(), 2);
    });

    test('completePlan returns the same persisted entry when retried by plan id', () async {
      final first = await repository.completePlan(testPlan);
      final retried = await repository.completePlan(testPlan);

      expect(retried, first);
      final history = await repository.getHistory();
      expect(history, hasLength(1));
      expect(history.single, first);
    });

    test('completePlan sets dedication to null when isDedicated is false', () async {
      final nonDedicatedPlan = KhatmahPlan(
        id: 'plan-no-ded',
        title: 'Solo',
        startPage: 1,
        currentPage: 604,
        targetPagesPerDay: 20,
        targetDays: 31,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 2, 1),
        dedication: const KhatmahDedication(isDedicated: false),
      );

      await repository.completePlan(nonDedicatedPlan);

      final history = await repository.getHistory();
      expect(history.first.dedication, isNull);
    });
  });
}
