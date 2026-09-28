import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
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

  group('same-day completions from two devices are unioned (SYNC-1)', () {
    DailyPlan plan(DateTime generatedAt, {List<String> done = const []}) {
      var result = DailyPlan(
        generatedAt: generatedAt,
        surahId: 67,
        newAyahs: const [
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 1,
            ayahText: 't',
            record: null,
          ),
          DailyPlanAyah(
            surahId: 67,
            ayahNumber: 2,
            ayahText: 't',
            record: null,
          ),
        ],
        nearRevision: const [
          DailyPlanAyah(
            surahId: 36,
            ayahNumber: 5,
            ayahText: 't',
            record: null,
          ),
        ],
        farRevision: const [],
        completedAyahNums: const [],
      );
      for (final key in done) {
        final parts = key.split(':');
        result = result.withCompleted(
          int.parse(parts[1]),
          ayahSurahId: int.parse(parts[0]),
        );
      }
      return result;
    }

    test("merges the other device's completions into the local plan", () {
      final local = plan(DateTime(2026, 9, 27, 8), done: ['67:1']);
      final remote = plan(DateTime(2026, 9, 27, 9), done: ['36:5']);

      final merged = DailyPlanCloudMerge.mergeSameDay(
        local: local,
        remote: remote,
      );

      expect(merged, isNotNull);
      expect(merged!.isAyahCompleted(67, 1), isTrue);
      expect(merged.isAyahCompleted(36, 5), isTrue);
      expect(merged.isAyahCompleted(67, 2), isFalse);
    });

    test('plans from different study days are not merged', () {
      final merged = DailyPlanCloudMerge.mergeSameDay(
        local: plan(DateTime(2026, 9, 27, 8)),
        remote: plan(DateTime(2026, 9, 26, 8), done: ['67:1']),
      );

      expect(merged, isNull);
    });
  });
}
