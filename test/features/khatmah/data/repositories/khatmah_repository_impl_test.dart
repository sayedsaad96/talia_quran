import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';

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

class _BlockingDeleteDatasource extends KhatmahLocalDatasource {
  _BlockingDeleteDatasource(super.prefs);

  final deleteStarted = Completer<void>();
  final releaseDelete = Completer<void>();
  final savedPlanIds = <String>[];

  @override
  Future<void> savePlan(KhatmahPlanModel plan) async {
    savedPlanIds.add(plan.id);
    await super.savePlan(plan);
  }

  @override
  Future<bool> deletePlan({String? expectedPlanId}) async {
    if (!deleteStarted.isCompleted) deleteStarted.complete();
    await releaseDelete.future;
    return super.deletePlan(expectedPlanId: expectedPlanId);
  }
}

class _RejectOnceHistoryStore extends InMemorySharedPreferencesStore {
  _RejectOnceHistoryStore() : super.empty();

  var rejectNextHistoryWrite = true;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key.endsWith('khatmah_history') && rejectNextHistoryWrite) {
      rejectNextHistoryWrite = false;
      return false;
    }
    return super.setValue(valueType, key, value);
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

    test(
      'getActivePlan returns null when datasource has no active plan',
      () async {
        final plan = await repository.getActivePlan();
        expect(plan, isNull);
      },
    );

    test('createPlan saves plan and getActivePlan retrieves it', () async {
      await repository.createPlan(testPlan);

      final retrieved = await repository.getActivePlan();
      expect(retrieved, equals(testPlan));
    });

    test(
      'atomically creates once and returns conflict to a concurrent creator',
      () async {
        final replacement = testPlan.copyWith(id: 'plan-2');

        final results = await Future.wait([
          repository.createPlanIfAbsent(testPlan),
          repository.createPlanIfAbsent(replacement),
        ]);

        expect(results.whereType<KhatmahPlan>(), hasLength(1));
        expect((await repository.getActivePlan())?.id, testPlan.id);
      },
    );

    test(
      'completed cleanup only deletes its expected stale plan before create',
      () async {
        final staleCompleted = testPlan.copyWith(
          status: KhatmahStatus.completed,
        );
        await repository.createPlan(staleCompleted);
        final replacement = testPlan.copyWith(id: 'replacement');

        final conflict = await repository.createPlanIfAbsent(replacement);

        expect(conflict, isNull);
        expect((await repository.getActivePlan())?.id, replacement.id);
      },
    );

    test(
      'completed cleanup does not overwrite a replacement arriving before delete',
      () async {
        final blocking = _BlockingDeleteDatasource(prefs);
        final guarded = KhatmahRepositoryImpl(blocking);
        await guarded.createPlan(
          testPlan.copyWith(status: KhatmahStatus.completed),
        );
        final creating = guarded.createPlanIfAbsent(
          testPlan.copyWith(id: 'requested'),
        );
        await blocking.deleteStarted.future;
        final replacement = testPlan.copyWith(id: 'replacement');
        await datasource.savePlan(KhatmahPlanModel.fromEntity(replacement));
        blocking.releaseDelete.complete();
        expect(await creating, replacement);
        expect((await guarded.getActivePlan())?.id, 'replacement');
      },
    );

    test('scoped abandon rejects a replacement without deleting it', () async {
      await repository.createPlan(testPlan.copyWith(id: 'replacement'));
      await expectLater(
        repository.deletePlan(expectedPlanId: 'old-plan'),
        throwsA(isA<KhatmahProgressException>()),
      );
      expect((await repository.getActivePlan())?.id, 'replacement');
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

    test(
      'completePlan records history entry with correct khatmahNumber and deletes active plan',
      () async {
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
      },
    );

    test(
      'completePlan increments khatmahNumber on subsequent completions',
      () async {
        final completedPlan = testPlan.recordThroughPage(604);
        await repository.createPlan(completedPlan);
        await repository.completePlan(completedPlan);

        final secondPlan = completedPlan.copyWith(
          id: 'plan-2',
          title: 'Second Khatmah',
        );
        await repository.createPlan(secondPlan);
        await repository.completePlan(secondPlan);

        final history = await repository.getHistory();
        expect(history.length, 2);
        expect(history[0].khatmahNumber, 1);
        expect(history[1].khatmahNumber, 2);
        expect(await repository.getCompletedCount(), 2);
      },
    );

    test(
      'completePlan rejects incomplete coverage without mutating storage',
      () async {
        final incompletePlan = testPlan.recordPage(100);
        await repository.createPlan(incompletePlan);

        await expectLater(
          () => repository.completePlan(incompletePlan),
          throwsA(isA<KhatmahProgressException>()),
        );

        expect(await repository.getActivePlan(), incompletePlan);
        expect(await repository.getHistory(), isEmpty);
      },
    );

    test(
      'completePlan returns the same persisted entry when retried by plan id',
      () async {
        final completedPlan = testPlan.recordThroughPage(604);
        await repository.createPlan(completedPlan);
        final first = await repository.completePlan(completedPlan);
        final retried = await repository.completePlan(completedPlan);

        expect(retried, first);
        final history = await repository.getHistory();
        expect(history, hasLength(1));
        expect(history.single, first);
      },
    );

    test(
      'concurrent completion retries for one plan return one persisted entry',
      () async {
        final completedPlan = testPlan.recordThroughPage(604);
        await repository.createPlan(completedPlan);

        final results = await Future.wait([
          repository.completePlan(completedPlan),
          repository.completePlan(completedPlan),
        ]);

        expect(results[0], results[1]);
        expect(await repository.getHistory(), hasLength(1));
      },
    );

    test(
      'serializes different completion writes without losing history entries',
      () async {
        final firstPlan = testPlan.recordThroughPage(604);
        final secondPlan = firstPlan.copyWith(id: 'plan-2', title: 'Second');

        await repository.createPlan(firstPlan);
        final first = repository.completePlan(firstPlan);
        final second = () async {
          await repository.createPlan(secondPlan);
          return repository.completePlan(secondPlan);
        }();
        await Future.wait([first, second]);

        final history = await repository.getHistory();
        expect(
          history.map((entry) => entry.id),
          containsAll(['plan-1', 'plan-2']),
        );
        expect(history.map((entry) => entry.khatmahNumber), {1, 2});
      },
    );

    test(
      'waits for completion delete before saving a replacement plan',
      () async {
        final blockingDatasource = _BlockingDeleteDatasource(prefs);
        final queuedRepository = KhatmahRepositoryImpl(blockingDatasource);
        final completedPlan = testPlan.recordThroughPage(604);
        final replacementPlan = completedPlan.copyWith(id: 'replacement');

        await queuedRepository.createPlan(completedPlan);
        final completion = queuedRepository.completePlan(completedPlan);
        await blockingDatasource.deleteStarted.future;
        final replacement = queuedRepository.createPlan(replacementPlan);

        await Future<void>.delayed(Duration.zero);
        expect(blockingDatasource.savedPlanIds, [completedPlan.id]);

        blockingDatasource.releaseDelete.complete();
        await completion;
        await replacement;
        expect(
          (await queuedRepository.getActivePlan())?.id,
          replacementPlan.id,
        );
      },
    );

    test(
      'continues with queued mutations after a completion failure',
      () async {
        final failingDatasource = _FailOnceDeleteDatasource(prefs);
        final queuedRepository = KhatmahRepositoryImpl(failingDatasource);
        final completedPlan = testPlan.recordThroughPage(604);
        final replacementPlan = completedPlan.copyWith(id: 'replacement');
        await queuedRepository.createPlan(completedPlan);

        final completion = queuedRepository.completePlan(completedPlan);
        final replacement = queuedRepository.createPlan(replacementPlan);

        await expectLater(completion, throwsA(isA<KhatmahStorageException>()));
        await replacement;
        expect(
          (await queuedRepository.getActivePlan())?.id,
          replacementPlan.id,
        );
      },
    );

    test(
      'reloads rejected history writes before retrying completion',
      () async {
        final store = _RejectOnceHistoryStore();
        SharedPreferencesStorePlatform.instance = store;
        SharedPreferences.resetStatic();
        final rejectingPrefs = await SharedPreferences.getInstance();
        final rejectingDatasource = KhatmahLocalDatasource(rejectingPrefs);
        final retryRepository = KhatmahRepositoryImpl(rejectingDatasource);
        final completedPlan = testPlan.recordThroughPage(604);
        expect(await retryRepository.getHistory(), isEmpty);
        await retryRepository.createPlan(completedPlan);

        await expectLater(
          () => retryRepository.completePlan(completedPlan),
          throwsA(isA<KhatmahStorageException>()),
        );
        expect(await retryRepository.getHistory(), isEmpty);

        final entry = await retryRepository.completePlan(completedPlan);
        expect(entry.id, completedPlan.id);
        expect(await retryRepository.getHistory(), hasLength(1));
        expect(await retryRepository.getActivePlan(), isNull);
      },
    );

    test('uses lastReadDate as the persisted completion date', () async {
      final readAt = DateTime(2026, 2, 1, 10);
      final completedPlan = testPlan
          .recordThroughPage(604)
          .copyWith(lastReadDate: readAt);

      await repository.createPlan(completedPlan);
      final entry = await repository.completePlan(completedPlan);

      expect(entry.completedDate, readAt);
    });

    test(
      'retry after deletion failure returns the persisted entry and keeps a replacement plan',
      () async {
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
        await retryRepository.createPlan(replacementPlan);

        final retried = await retryRepository.completePlan(completedPlan);

        expect(retried.id, completedPlan.id);
        expect(await retryRepository.getHistory(), hasLength(1));
        expect((await retryRepository.getActivePlan())?.id, replacementPlan.id);
      },
    );

    test(
      'completePlan sets dedication to null when isDedicated is false',
      () async {
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

        await repository.createPlan(nonDedicatedPlan);
        await repository.completePlan(nonDedicatedPlan);

        final history = await repository.getHistory();
        expect(history.first.dedication, isNull);
      },
    );
  });
}
