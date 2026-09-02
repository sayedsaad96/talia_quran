import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_history_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';

class _RejectingPreferencesStore extends InMemorySharedPreferencesStore {
  _RejectingPreferencesStore({
    required this.rejectWrites,
    required this.rejectRemovals,
  }) : super.empty();

  final bool rejectWrites;
  final bool rejectRemovals;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (rejectWrites) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<bool> remove(String key) async {
    if (rejectRemovals) return false;
    return super.remove(key);
  }
}

class _RejectOnceRemovalStore extends InMemorySharedPreferencesStore {
  _RejectOnceRemovalStore(String rawPlan)
    : super.withData({'flutter.khatmah_active_plan': rawPlan});

  var rejectNextRemoval = true;

  @override
  Future<bool> remove(String key) async {
    if (key.endsWith('khatmah_active_plan') && rejectNextRemoval) {
      rejectNextRemoval = false;
      return false;
    }
    return super.remove(key);
  }
}

void main() {
  late SharedPreferences prefs;
  late KhatmahLocalDatasource datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = KhatmahLocalDatasource(prefs);
  });

  group('KhatmahLocalDatasource', () {
    test('getActivePlan returns null when no plan is saved', () async {
      final plan = await datasource.getActivePlan();
      expect(plan, isNull);
    });

    test('savePlan saves the plan without persisting a cloud-sync flag', () async {
      final plan = KhatmahPlanModel(
        id: 'plan-1',
        title: 'Active Plan',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 15; page++) page},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );

      await datasource.savePlan(plan);

      final retrieved = await datasource.getActivePlan();
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'plan-1');
      expect(retrieved.currentPage, 15);
      expect(prefs.getBool('khatmah_cloud_dirty'), isNull);
    });

    test('deletePlan removes the active plan without persisting a cloud-sync flag', () async {
      final plan = KhatmahPlanModel(
        id: 'plan-1',
        title: 'Active Plan',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 15; page++) page},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );

      await datasource.savePlan(plan);
      expect(await datasource.getActivePlan(), isNotNull);

      await datasource.deletePlan();

      expect(await datasource.getActivePlan(), isNull);
      expect(prefs.getBool('khatmah_cloud_dirty'), isNull);
    });

    test('deletePlan preserves the replacement when an expected id does not match', () async {
      final original = KhatmahPlanModel(
        id: 'original',
        title: 'Original',
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );
      final replacement = KhatmahPlanModel(
        id: 'replacement',
        title: original.title,
        targetPagesPerDay: original.targetPagesPerDay,
        targetDays: original.targetDays,
        startDate: original.startDate,
        expectedEndDate: original.expectedEndDate,
        status: original.status,
        dedication: original.dedication,
      );

      await datasource.savePlan(original);
      await datasource.savePlan(replacement);

      expect(await datasource.deletePlan(expectedPlanId: original.id), isFalse);
      expect((await datasource.getActivePlan())?.id, replacement.id);
    });

    test('savePlan surfaces a typed error when preferences reject a write', () async {
      SharedPreferencesStorePlatform.instance = _RejectingPreferencesStore(
        rejectWrites: true,
        rejectRemovals: false,
      );
      final rejectingDatasource = KhatmahLocalDatasource(prefs);
      final plan = KhatmahPlanModel(
        id: 'write-failure',
        title: 'Write failure',
        targetPagesPerDay: 1,
        targetDays: 1,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 1, 2),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );

      await expectLater(
        () => rejectingDatasource.savePlan(plan),
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('deletePlan surfaces a typed error when preferences reject deletion', () async {
      SharedPreferencesStorePlatform.instance = _RejectingPreferencesStore(
        rejectWrites: false,
        rejectRemovals: true,
      );
      final rejectingDatasource = KhatmahLocalDatasource(prefs);
      await prefs.setString('khatmah_active_plan', '{}');

      await expectLater(
        rejectingDatasource.deletePlan,
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('reloads rejected deletion before a later retry', () async {
      final plan = KhatmahPlanModel(
        id: 'retry-delete',
        title: 'Retry delete',
        targetPagesPerDay: 1,
        targetDays: 1,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 1, 2),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );
      SharedPreferencesStorePlatform.instance = _RejectOnceRemovalStore(
        jsonEncode(plan.toJson()),
      );
      SharedPreferences.resetStatic();
      final retryPrefs = await SharedPreferences.getInstance();
      final retryDatasource = KhatmahLocalDatasource(retryPrefs);

      await expectLater(
        retryDatasource.deletePlan,
        throwsA(isA<KhatmahStorageException>()),
      );
      expect((await retryDatasource.getActivePlan())?.id, plan.id);

      expect(await retryDatasource.deletePlan(), isTrue);
      expect(await retryDatasource.getActivePlan(), isNull);
    });

    test('getActivePlan surfaces typed storage error when stored JSON is corrupted', () async {
      await prefs.setString('khatmah_active_plan', '{broken json...');

      await expectLater(
        datasource.getActivePlan,
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('surfaces malformed completedPages instead of returning null', () async {
      await prefs.setString(
        'khatmah_active_plan',
        '{"id":"bad","title":"Bad","targetPagesPerDay":4,"targetDays":1,'
        '"startDate":"2026-01-01T00:00:00.000","expectedEndDate":"2026-01-01T00:00:00.000",'
        '"dedication":{},"completedPages":[1,"2"]}',
      );

      await expectLater(
        datasource.getActivePlan,
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('getHistory returns empty list initially', () async {
      final history = await datasource.getHistory();
      expect(history, isEmpty);
      expect(await datasource.getKhatmahCount(), 0);
    });

    test('addHistoryEntry persists entries and increments count', () async {
      final entry1 = KhatmahHistoryModel(
        id: 'hist-1',
        khatmahNumber: 1,
        title: 'First Khatmah',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 2, 1),
        totalDays: 31,
      );

      final entry2 = KhatmahHistoryModel(
        id: 'hist-2',
        khatmahNumber: 2,
        title: 'Second Khatmah',
        startDate: DateTime(2026, 2, 2),
        completedDate: DateTime(2026, 3, 2),
        totalDays: 29,
      );

      await datasource.addHistoryEntry(entry1);
      await datasource.addHistoryEntry(entry2);

      final history = await datasource.getHistory();
      expect(history.length, 2);
      expect(history[0].id, 'hist-1');
      expect(history[1].id, 'hist-2');
      expect(await datasource.getKhatmahCount(), 2);
      expect(prefs.getBool('khatmah_cloud_dirty'), isNull);
    });

    test('getHistory surfaces typed storage error when stored JSON is corrupted', () async {
      await prefs.setString('khatmah_history', 'corrupted data');

      await expectLater(
        datasource.getHistory,
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('data isolation: khatmah keys do not interfere with read_pages', () async {
      await prefs.setString('read_pages', '[1, 2, 3]');

      final plan = KhatmahPlanModel(
        id: 'plan-isolated',
        title: 'Isolated',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 5; page++) page},
        targetPagesPerDay: 5,
        targetDays: 120,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 5, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(isDedicated: false),
      );

      await datasource.savePlan(plan);
      expect(prefs.getString('read_pages'), '[1, 2, 3]');

      await datasource.deletePlan();
      expect(prefs.getString('read_pages'), '[1, 2, 3]');
    });
  });
}
