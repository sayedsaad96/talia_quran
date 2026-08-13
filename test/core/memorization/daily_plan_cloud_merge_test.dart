import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/daily_plan_cloud_merge.dart';

void main() {
  group('DailyPlanCloudMerge', () {
    final remote = DateTime.utc(2026, 8, 8, 12);
    final olderLocal = DateTime.utc(2026, 8, 8, 10);
    final newerLocal = DateTime.utc(2026, 8, 8, 14);

    test('never applies remote while local is dirty', () {
      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: true,
          localGeneratedAt: olderLocal,
          remoteGeneratedAt: remote,
        ),
        isFalse,
      );
    });

    test('applies remote when there is no local plan', () {
      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: false,
          localGeneratedAt: null,
          remoteGeneratedAt: remote,
        ),
        isTrue,
      );
    });

    test('applies remote when it is strictly newer', () {
      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: false,
          localGeneratedAt: olderLocal,
          remoteGeneratedAt: remote,
        ),
        isTrue,
      );
    });

    test('keeps local when remote is not newer', () {
      expect(
        DailyPlanCloudMerge.shouldApplyRemote(
          localDirty: false,
          localGeneratedAt: newerLocal,
          remoteGeneratedAt: remote,
        ),
        isFalse,
      );
    });
  });
}