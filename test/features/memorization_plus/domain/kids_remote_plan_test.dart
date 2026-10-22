import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_child_policy_sync.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_remote_plan.dart';

void main() {
  const plan = KidsRemotePlan(
    nextSurahId: 114,
    ayahsPerSession: 10,
    practiceDays: 65,
  );

  test('legacy cache has no remote overrides', () {
    expect(ParentSettingsModel.fromJson({}).remotePlan, const KidsRemotePlan());
    expect(
      KidsChildPolicySync.policyFromRow({'version': 1})!.remotePlan,
      const KidsRemotePlan(),
    );
  });

  test('plan survives settings JSON and policy copies', () {
    const settings = ParentSettingsModel(remotePlan: plan, pinHash: 'existing');
    final restored = ParentSettingsModel.fromJson(settings.toJson());
    expect(restored.remotePlan, plan);
    expect(restored.pinHash, 'existing');
    expect(
      ParentSettingsModel.fromEntity(
        restored.copyWith(reminderHour: 8),
      ).remotePlan,
      plan,
    );
    expect(
      KidsChildPolicy.fromSettings(
        restored,
      ).copyWith(reduceMotion: true).remotePlan,
      plan,
    );
  });

  test(
    'server fields preserve explicit nullable clears and v1 args stay exact',
    () {
      const policy = KidsChildPolicy(remotePlan: plan);
      final v1 = KidsChildPolicySync.casParams('child', policy, 4);
      expect(
        v1.keys,
        unorderedEquals([
          'p_child_user_id',
          'p_expected_version',
          'p_reduce_motion',
          'p_max_daily_suggestions',
          'p_home_missions_enabled',
          'p_session_goal_minutes',
        ]),
      );
      final v2 = KidsChildPolicySync.casParamsV2('child', policy, 4);
      expect(v2['p_next_surah_id'], 114);
      expect(v2['p_ayahs_per_session'], 10);
      expect(v2['p_practice_days'], 65);
      final cleared = KidsChildPolicySync.casParamsV2(
        'child',
        policy.copyWith(remotePlan: const KidsRemotePlan()),
        4,
      );
      expect(cleared.containsKey('p_next_surah_id'), isTrue);
      expect(cleared['p_next_surah_id'], isNull);
      expect(cleared['p_practice_days'], isNull);
    },
  );

  test(
    'row hints are strict bounded integers, zero weekdays is meaningful',
    () {
      final parsed = KidsChildPolicySync.policyFromRow({
        'next_surah_id': 114,
        'ayahs_per_session': 10,
        'practice_days': 0,
      })!;
      expect(
        parsed.remotePlan,
        const KidsRemotePlan(
          nextSurahId: 114,
          ayahsPerSession: 10,
          practiceDays: 0,
        ),
      );
      for (final bad in [null, -1, 115, 1.5, '1', true]) {
        expect(
          KidsRemotePlan.fromJson({'nextSurahId': bad}).nextSurahId,
          isNull,
        );
      }
      for (final bad in [-1, 0, 11, 3.5, '7']) {
        expect(
          KidsRemotePlan.fromJson({'ayahsPerSession': bad}).ayahsPerSession,
          isNull,
        );
      }
      for (final bad in [-1, 128, 65.5, '65']) {
        expect(
          KidsRemotePlan.fromJson({'practiceDays': bad}).practiceDays,
          isNull,
        );
      }
    },
  );

  test('Monday bit0 and Sunday bit6 only filter reminders', () {
    final monday = DateTime(2026, 10, 19);
    for (var day = 0; day < 7; day++) {
      final date = monday.add(Duration(days: day));
      expect(plan.shouldRemindOn(date), day == 0 || day == 6);
      expect(const KidsRemotePlan().shouldRemindOn(date), isTrue);
      expect(
        const KidsRemotePlan(practiceDays: 0).shouldRemindOn(date),
        isFalse,
      );
    }
  });
}
