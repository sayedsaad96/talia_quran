import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_history_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';

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

    test('savePlan saves plan and sets cloud dirty flag', () async {
      final plan = KhatmahPlanModel(
        id: 'plan-1',
        title: 'Active Plan',
        startPage: 1,
        currentPage: 15,
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
      expect(prefs.getBool('khatmah_cloud_dirty'), isTrue);
    });

    test('deletePlan removes active plan and sets cloud dirty flag', () async {
      final plan = KhatmahPlanModel(
        id: 'plan-1',
        title: 'Active Plan',
        startPage: 1,
        currentPage: 15,
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
      expect(prefs.getBool('khatmah_cloud_dirty'), isTrue);
    });

    test('getActivePlan returns null when stored JSON is corrupted', () async {
      await prefs.setString('khatmah_active_plan', '{broken json...');

      final plan = await datasource.getActivePlan();
      expect(plan, isNull);
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
      expect(prefs.getBool('khatmah_cloud_dirty'), isTrue);
    });

    test('getHistory returns empty list when stored JSON is corrupted', () async {
      await prefs.setString('khatmah_history', 'corrupted data');

      final history = await datasource.getHistory();
      expect(history, isEmpty);
    });

    test('data isolation: khatmah keys do not interfere with read_pages', () async {
      await prefs.setString('read_pages', '[1, 2, 3]');

      final plan = KhatmahPlanModel(
        id: 'plan-isolated',
        title: 'Isolated',
        startPage: 1,
        currentPage: 5,
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
