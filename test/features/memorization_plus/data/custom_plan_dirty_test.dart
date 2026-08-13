import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/plan_cloud_dirty_keys.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_custom_plan_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';

void main() {
  group('custom plan dirty flag', () {
    late SharedPreferences prefs;
    late MemorizationCustomPlanService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = MemorizationCustomPlanService(
        MemorizationPlusLocalDatasourceImpl(prefs),
        prefs,
      );
    });

    CustomMemorizationPlan plan() => CustomMemorizationPlan(
          name: 'Test',
          startSurahId: 1,
          endSurahId: 2,
          newAyahsPerDay: 5,
          availableDaysPerWeek: 5,
          sessionMinutes: 20,
          difficulty: MemorizationDifficulty.moderate,
          enableNearRevision: true,
          enableFarRevision: true,
          nearRevisionCount: 10,
          farRevisionCount: 5,
          startAyah: 1,
          createdAt: DateTime.utc(2026, 8, 8),
        );

    test('save marks custom_plan_cloud_dirty', () async {
      final result = await service.saveCustomPlan(plan());
      expect(result.isRight(), isTrue);
      expect(prefs.getBool(PlanCloudDirtyKeys.customPlan), isTrue);
    });

    test('delete marks custom_plan_cloud_dirty', () async {
      await service.saveCustomPlan(plan());
      await prefs.setBool(PlanCloudDirtyKeys.customPlan, false);

      final result = await service.deleteCustomPlan();
      expect(result.isRight(), isTrue);
      expect(prefs.getBool(PlanCloudDirtyKeys.customPlan), isTrue);
    });
  });
}