import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    datasource = MemorizationPlusLocalDatasourceImpl(prefs);
  });

  group('MemorizationPlusLocalDatasourceImpl', () {
    test('saves and loads selected track', () async {
      await datasource.saveSelectedTrack(MemorizationTrack.kids.name);

      expect(datasource.getSelectedTrack(), MemorizationTrack.kids.name);
    });

    test(
      'ignores corrupted review records while loading all records',
      () async {
        await prefs.setString('mem_plus_review_1_1', '{bad json');
        await datasource.saveReviewRecord(AyahReviewRecordModel.initial(1, 2));

        final records = await datasource.getAllReviewRecords();

        expect(records, hasLength(1));
        expect(records.single.ayahNumber, 2);
      },
    );

    test('returns null for corrupted cached daily plan', () async {
      await prefs.setString('mem_plus_daily_plan', '{bad json');

      expect(await datasource.getCachedDailyPlan(), isNull);
    });

    test(
      'returns empty kids progress when stored value is corrupted',
      () async {
        await prefs.setString('mem_plus_kids_progress', '{bad json');

        final progress = await datasource.getKidsProgress();

        expect(progress.totalPoints, 0);
        expect(progress.currentLevel, 1);
      },
    );

    test('saves and deletes custom plan', () async {
      final plan = CustomMemorizationPlanModel(
        name: 'Plan',
        startSurahId: 1,
        endSurahId: 2,
        newAyahsPerDay: 3,
        availableDaysPerWeek: 5,
        sessionMinutes: 20,
        difficulty: MemorizationDifficulty.moderate,
        enableNearRevision: true,
        enableFarRevision: true,
        nearRevisionCount: 5,
        farRevisionCount: 5,
        startAyah: 1,
        createdAt: DateTime(2026, 5, 5),
      );

      await datasource.saveCustomPlan(plan);
      expect(await datasource.getCustomPlan(), isNotNull);

      await datasource.deleteCustomPlan();
      expect(await datasource.getCustomPlan(), isNull);
    });
  });
}
