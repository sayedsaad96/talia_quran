import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_history_model.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_plan_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';

void main() {
  group('KhatmahDedicationModel', () {
    test('toJson and fromJson round trip preserves all fields', () {
      final model = KhatmahDedicationModel(
        isDedicated: true,
        recipientName: 'Ahmad',
        relationship: 'Father',
        condition: 'deceased',
        customNote: 'May Allah have mercy on his soul',
      );

      final json = model.toJson();
      final restored = KhatmahDedicationModel.fromJson(json);

      expect(restored.isDedicated, true);
      expect(restored.recipientName, 'Ahmad');
      expect(restored.relationship, 'Father');
      expect(restored.condition, 'deceased');
      expect(restored.customNote, 'May Allah have mercy on his soul');
    });

    test('fromJson handles default and null values safely', () {
      final model = KhatmahDedicationModel.fromJson({});

      expect(model.isDedicated, false);
      expect(model.recipientName, isNull);
      expect(model.relationship, isNull);
      expect(model.condition, isNull);
      expect(model.customNote, isNull);
    });

    test('fromEntity and toEntity round trip with DedicationCondition enum', () {
      const entity = KhatmahDedication(
        isDedicated: true,
        recipientName: 'Mom',
        relationship: 'Mother',
        condition: DedicationCondition.alive,
        customNote: 'Love you Mom',
      );

      final model = KhatmahDedicationModel.fromEntity(entity);
      expect(model.condition, 'alive');

      final restored = model.toEntity();
      expect(restored, entity);
    });

    test('toEntity defaults unknown condition string to alive if non-null', () {
      final model = KhatmahDedicationModel(
        isDedicated: true,
        condition: 'unknown_value',
      );
      expect(model.toEntity().condition, DedicationCondition.alive);
    });

    test('toEntity keeps condition null when condition string is null', () {
      final model = KhatmahDedicationModel(
        isDedicated: false,
        condition: null,
      );
      expect(model.toEntity().condition, isNull);
    });
  });

  group('KhatmahPlanModel', () {
    test('toJson and fromJson round trip preserves all fields', () {
      final model = KhatmahPlanModel(
        id: 'plan-123',
        title: 'Ramadan Khatmah',
        startPage: 1,
        completedPages: {50, 1, 2},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: 'active',
        dedication: KhatmahDedicationModel(
          isDedicated: true,
          recipientName: 'Uncle',
          relationship: 'Uncle',
          condition: 'sick',
          customNote: 'Shifaa',
        ),
        lastReadDate: DateTime(2026, 1, 15),
        pausedAt: DateTime(2026, 1, 16),
      );

      final json = model.toJson();
      final restored = KhatmahPlanModel.fromJson(json);

      expect(restored.id, model.id);
      expect(restored.title, model.title);
      expect(restored.startPage, 1);
      expect(restored.currentPage, 2);
      expect(restored.completedPages, {1, 2, 50});
      expect(json['completedPages'], [1, 2, 50]);
      expect(restored.targetPagesPerDay, 4);
      expect(restored.targetDays, 151);
      expect(restored.startDate, DateTime(2026, 1, 1));
      expect(restored.expectedEndDate, DateTime(2026, 6, 1));
      expect(restored.status, 'active');
      expect(restored.dedication.isDedicated, true);
      expect(restored.dedication.recipientName, 'Uncle');
      expect(restored.lastReadDate, DateTime(2026, 1, 15));
      expect(restored.pausedAt, DateTime(2026, 1, 16));
    });

    test('toEntity produces correct KhatmahPlan', () {
      final model = KhatmahPlanModel(
        id: 'plan-456',
        title: 'Daily Wird Khatmah',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 20; page++) page},
        targetPagesPerDay: 10,
        targetDays: 61,
        startDate: DateTime(2026, 2, 1),
        expectedEndDate: DateTime(2026, 4, 3),
        status: 'paused',
        dedication: KhatmahDedicationModel(isDedicated: false),
        lastReadDate: DateTime(2026, 2, 3),
        pausedAt: DateTime(2026, 2, 4),
      );

      final entity = model.toEntity();

      expect(entity.id, 'plan-456');
      expect(entity.title, 'Daily Wird Khatmah');
      expect(entity.status, KhatmahStatus.paused);
      expect(entity.currentPage, 20);
      expect(entity.dedication.isDedicated, false);
      expect(entity.lastReadDate, DateTime(2026, 2, 3));
      expect(entity.pausedAt, DateTime(2026, 2, 4));
    });

    test('migrates a legacy cursor-only plan to explicit coverage', () {
      final model = KhatmahPlanModel.fromJson({
        'id': 'legacy-plan',
        'title': 'Legacy',
        'startPage': 1,
        'currentPage': 10,
        'targetPagesPerDay': 4,
        'targetDays': 151,
        'startDate': '2026-01-01T00:00:00.000',
        'expectedEndDate': '2026-06-01T00:00:00.000',
        'dedication': <String, dynamic>{},
      });

      expect(model.completedPages, {1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
      expect(model.toEntity().completedPages, model.completedPages);
    });

    test('migrates legacy coverage from startPage and derives global cursor', () {
      final model = KhatmahPlanModel.fromJson({
        'id': 'legacy-started-late',
        'title': 'Legacy',
        'startPage': 11,
        'currentPage': 15,
        'targetPagesPerDay': 4,
        'targetDays': 151,
        'startDate': '2026-01-01T00:00:00.000',
        'expectedEndDate': '2026-06-01T00:00:00.000',
        'dedication': <String, dynamic>{},
      });

      expect(model.completedPages, {11, 12, 13, 14, 15});
      expect(model.currentPage, 0);
      expect(model.toJson()['currentPage'], 0);
    });

    test('derives serialized currentPage from normalized coverage', () {
      final model = KhatmahPlanModel(
        id: 'derived-cursor',
        title: 'Derived',
        completedPages: {1, 2, 100, 605},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        dedication: KhatmahDedicationModel(isDedicated: false),
      );

      expect(model.currentPage, 2);
      expect(model.toJson()['currentPage'], 2);
    });

    test('rejects malformed completedPages containers and members', () {
      final baseJson = {
        'id': 'malformed',
        'title': 'Malformed',
        'targetPagesPerDay': 4,
        'targetDays': 151,
        'startDate': '2026-01-01T00:00:00.000',
        'expectedEndDate': '2026-06-01T00:00:00.000',
        'dedication': <String, dynamic>{},
      };

      expect(
        () => KhatmahPlanModel.fromJson({...baseJson, 'completedPages': '1,2'}),
        throwsA(isA<KhatmahStorageException>()),
      );
      expect(
        () => KhatmahPlanModel.fromJson({...baseJson, 'completedPages': [1, '2']}),
        throwsA(isA<KhatmahStorageException>()),
      );
    });

    test('fromEntity produces correct KhatmahPlanModel', () {
      final entity = KhatmahPlan(
        id: 'plan-789',
        title: 'Completed Khatmah',
        startPage: 1,
        completedPages: {for (var page = 1; page <= 604; page++) page},
        targetPagesPerDay: 20,
        targetDays: 31,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 2, 1),
        status: KhatmahStatus.completed,
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Friend',
          relationship: 'Friend',
          condition: DedicationCondition.alive,
        ),
      );

      final model = KhatmahPlanModel.fromEntity(entity);

      expect(model.id, 'plan-789');
      expect(model.status, 'completed');
      expect(model.currentPage, 604);
      expect(model.dedication.recipientName, 'Friend');
      expect(model.toEntity(), entity);
    });
  });

  group('KhatmahHistoryModel', () {
    test('toJson and fromJson round trip preserves all fields', () {
      final model = KhatmahHistoryModel(
        id: 'hist-1',
        khatmahNumber: 3,
        title: 'Khatmah 3',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 2, 1),
        totalDays: 32,
        dedication: KhatmahDedicationModel(
          isDedicated: true,
          recipientName: 'Grandmother',
          relationship: 'Grandmother',
          condition: 'deceased',
        ),
        certificateId: 'cert-123',
      );

      final json = model.toJson();
      final restored = KhatmahHistoryModel.fromJson(json);

      expect(restored.id, 'hist-1');
      expect(restored.khatmahNumber, 3);
      expect(restored.title, 'Khatmah 3');
      expect(restored.startDate, DateTime(2026, 1, 1));
      expect(restored.completedDate, DateTime(2026, 2, 1));
      expect(restored.totalDays, 32);
      expect(restored.dedication?.recipientName, 'Grandmother');
      expect(restored.certificateId, 'cert-123');
    });

    test('fromEntity and toEntity round trip with null dedication', () {
      final entity = KhatmahHistoryEntry(
        id: 'hist-2',
        khatmahNumber: 1,
        title: 'First Khatmah',
        startDate: DateTime(2025, 1, 1),
        completedDate: DateTime(2025, 3, 1),
        totalDays: 60,
        dedication: null,
        certificateId: null,
      );

      final model = KhatmahHistoryModel.fromEntity(entity);
      expect(model.dedication, isNull);
      expect(model.certificateId, isNull);

      final restored = model.toEntity();
      expect(restored, entity);
    });
  });
}
