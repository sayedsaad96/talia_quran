import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/daily_plan_cloud_merge.dart';
import 'package:talia_quran/core/memorization/plan_cloud_dirty_keys.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_gateway.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_production_sync_service.dart';

/// Offline CUD → reconnect gate for IS-4:
/// dirty local plans must stay pending and must not be overwritten by pull.
void main() {
  group('offline plan sync gate', () {
    late SharedPreferences prefs;
    late MemorizationProductionSyncService sync;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'ayah_review_pull_cursor_pulled_at':
            DateTime.now().toUtc().toIso8601String(),
      });
      prefs = await SharedPreferences.getInstance();
      sync = MemorizationProductionSyncService(
        MemorizationPlusLocalDatasourceImpl(prefs),
        prefs,
        MemorizationCloudGateway(prefs),
        MemorizationCloudMappers(const ProgressMetricsService()),
        owner: const FixedRecordOwnerProvider('user-a'),
      );
    });

    test('dirty daily plan refuses remote merge and stays pending', () async {
      await prefs.setBool(PlanCloudDirtyKeys.dailyPlan, true);

      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: true,
          localGeneratedAt: DateTime.utc(2026, 8, 8, 10),
          remoteGeneratedAt: DateTime.utc(2026, 8, 8, 12),
        ),
        isFalse,
      );
      expect(await sync.hasPendingCloudWork(), isTrue);
    });

    test('dirty custom plan stays pending until flag cleared', () async {
      await prefs.setBool(PlanCloudDirtyKeys.customPlan, true);
      expect(await sync.hasPendingCloudWork(), isTrue);

      await prefs.setBool(PlanCloudDirtyKeys.customPlan, false);
      expect(await sync.hasPendingCloudWork(), isFalse);
    });

    test('unsynced certificates keep resume gate open', () async {
      final awardJson = jsonEncode([
        {
          'id': 'cert_juz_1',
          'titleAr': 'جزء 1',
          'type': 'juz',
          'earnedAt': '2026-08-01T00:00:00.000Z',
          'juzNumber': 1,
        },
      ]);
      await prefs.setString('earned_certificates_v2', awardJson);
      expect(await sync.hasPendingCloudWork(), isTrue);

      await prefs.setStringList('synced_certificate_ids', ['cert_juz_1']);
      expect(await sync.hasPendingCloudWork(), isFalse);
    });

    test('after dirty clears, newer remote daily plan may apply', () {
      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: false,
          localGeneratedAt: DateTime.utc(2026, 8, 8, 10),
          remoteGeneratedAt: DateTime.utc(2026, 8, 8, 12),
        ),
        isTrue,
      );
    });
  });
}
