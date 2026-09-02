import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';

class _FailOnceDeleteDatasource extends KhatmahLocalDatasource {
  _FailOnceDeleteDatasource(super.prefs);

  var _shouldFail = true;

  @override
  Future<bool> deletePlan({String? expectedPlanId}) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw const KhatmahStorageException('Delete failed for test.');
    }
    return super.deletePlan(expectedPlanId: expectedPlanId);
  }
}

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

      final updated = testPlan.recordThroughPage(50);
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
      final completedPlan = testPlan.recordThroughPage(604);
      await repository.createPlan(completedPlan);

      await repository.completePlan(completedPlan);

      // Active plan should be deleted
      expect(await repository.getActivePlan(), isNull);

      // History should have 1 entry with khatmahNumber = 1
      final history = await repository.getHistory();
      expect(history.length, 1);
      expect(history.first.id, completedPlan.id);
      expect(history.first.khatmahNumber, 1);
      expect(history.first.title, completedPlan.title);
      expect(history.first.startDate, completedPlan.startDate);
      expect(history.first.totalDays, greaterThanOrEqualTo(1));
      expect(history.first.dedication?.recipientName, 'Father');

      // Completed count should be 1
      expect(await repository.getCompletedCount(), 1);
    });

    test('completePlan increments khatmahNumber on subsequent completions', () async {
      final completedPlan = testPlan.recordThroughPage(604);
      await repository.completePlan(completedPlan);

      final secondPlan = completedPlan.copyWith(id: 'plan-2', title: 'Second Khatmah');
      await repository.completePlan(secondPlan);

      final history = await repository.getHistory();
      expect(history.length, 2);
      expect(history[0].khatmahNumber, 1);
      expect(history[1].khatmahNumber, 2);
      expect(await repository.getCompletedCount(), 2);
    });

    test('completePlan rejects incomplete coverage without mutating storage', () async {
      final incompletePlan = testPlan.recordPage(100);
      await repository.createPlan(incompletePlan);

      await expectLater(
        () => repository.completePlan(incompletePlan),
        throwsA(isA<KhatmahProgressException>()),
      );

      expect(await repository.getActivePlan(), incompletePlan);
      expect(await repository.getHistory(), isEmpty);
    });

    test('completePlan returns the same persisted entry when retried by plan id', () async {
      final completedPlan = testPlan.recordThroughPage(604);
      final first = await repository.completePlan(completedPlan);
      final retried = await repository.completePlan(completedPlan);

      expect(retried, first);
      final history = await repository.getHistory();
      expect(history, hasLength(1));
      expect(history.single, first);
    });

    test('concurrent completion retries for one plan return one persisted entry', () async {
      final completedPlan = testPlan.recordThroughPage(604);

      final results = await Future.wait([
        repository.completePlan(completedPlan),
        repository.completePlan(completedPlan),
      ]);

      expect(results[0], results[1]);
      expect(await repository.getHistory(), hasLength(1));
    });

    test('serializes different completion writes without losing history entries', () async {
      final firstPlan = testPlan.recordThroughPage(604);
      final secondPlan = firstPlan.copyWith(id: 'plan-2', title: 'Second');

      await Future.wait([
        repository.completePlan(firstPlan),
        repository.completePlan(secondPlan),
      ]);

      final history = await repository.getHistory();
      expect(history.map((entry) => entry.id), containsAll(['plan-1', 'plan-2']));
      expect(history.map((entry) => entry.khatmahNumber), {1, 2});
    });

    test('uses lastReadDate as the persisted completion date', () async {
      final readAt = DateTime(2026, 2, 1, 10);
      final completedPlan = testPlan
          .recordThroughPage(604)
          .copyWith(lastReadDate: readAt);

      final entry = await repository.completePlan(completedPlan);

      expect(entry.completedDate, readAt);
    });

    test('retry after deletion failure returns the persisted entry and keeps a replacement plan', () async {
      final failingDatasource = _FailOnceDeleteDatasource(prefs);
      final retryRepository = KhatmahRepositoryImpl(failingDatasource);
      final completedPlan = testPlan.recordThroughPage(604);
      final replacementPlan = completedPlan.copyWith(id: 'replacement');

      await retryRepository.createPlan(completedPlan);
      await expectLater(
        () => retryRepository.completePlan(completedPlan),
        throwsA(isA<KhatmahStorageException>()),
      );

      expect(await retryRepository.getHistory(), hasLength(1));
      await retryRepository.updatePlan(replacementPlan);

      final retried = await retryRepository.completePlan(completedPlan);

      expect(retried.id, completedPlan.id);
      expect(await retryRepository.getHistory(), hasLength(1));
      expect((await retryRepository.getActivePlan())?.id, replacementPlan.id);
    });

    test('completePlan sets dedication to null when isDedicated is false', () async {
      final nonDedicatedPlan = KhatmahPlan(
        id: 'plan-no-ded',
        title: 'Solo',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 604; page++) page},
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
