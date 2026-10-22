import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_child_policy_sync.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_remote_plan.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';

void main() {
  late AccountDataBarrier barrier;
  late MemorizationPlusLocalDatasourceImpl source;
  late KidsChildPolicySync sync;
  const owner = FixedRecordOwnerProvider('child');
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    source = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    sync = KidsChildPolicySync(source, owner, barrier: barrier);
  });

  test(
    'a policy response begun before reset cannot change the new local plan',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final operation = sync.pull(
        ownerId: 'child',
        fetchRow: () async {
          entered.complete();
          await release.future;
          return _row;
        },
      );
      await entered.future;
      await barrier.clear(() async {});
      await source.updateKidsHouseSettings(
        (settings) => settings.copyWith(
          remotePlan: const KidsRemotePlan(
            nextSurahId: 113,
            ayahsPerSession: 2,
          ),
          kidsHouseSizesBySurah: {113: 2},
        ),
      );
      release.complete();
      await operation;
      final saved = await source.getParentSettings();
      expect(saved.remotePlan.nextSurahId, 113);
      expect(saved.remotePlan.ayahsPerSession, 2);
      expect(saved.kidsHouseSizesBySurah, {113: 2});
      expect(saved.policyVersion, 0);
    },
  );

  test(
    'a guardian policy result from before reset is not delivered to the new screen',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final operation = sync.casRemote(
        childUserId: 'linked-child',
        policy: const KidsChildPolicy(),
        expectedVersion: 0,
        useV2: true,
        casRpc: (_) async {
          entered.complete();
          await release.future;
          return {'applied': true, 'version': 1, 'policy': _row};
        },
      );
      await entered.future;
      await barrier.clear(() async {});
      release.complete();
      expect((await operation).isLeft(), isTrue);
    },
  );

  for (final pendingPush in [false, true]) {
    test(
      'stale policy ${pendingPush ? 'pending push' : 'device edit'} cannot change a replacement policy',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        Future<Object?> rpc(Map<String, dynamic> _) async {
          entered.complete();
          await release.future;
          return {'applied': true, 'version': 9, 'policy': _row};
        }

        final Future<Object?> operation = pendingPush
            ? sync.pushPending(
                ownerId: 'child',
                childUserId: 'child',
                casRpc: rpc,
              )
            : sync.saveOnDevice(
                policy: const KidsChildPolicy(),
                linkedChildUserId: 'child',
                casRpc: rpc,
              );
        await entered.future;
        await barrier.clear(() async {});
        await source.updateKidsHouseSettings(
          (settings) => settings.copyWith(
            policyVersion: 2,
            remotePlan: const KidsRemotePlan(nextSurahId: 113),
          ),
        );
        release.complete();
        await operation;
        final saved = await source.getParentSettings();
        expect(saved.policyVersion, 2);
        expect(saved.remotePlan.nextSurahId, 113);
      },
    );
  }
}

const _row = {
  'child_user_id': 'child',
  'version': 9,
  'reduce_motion': true,
  'max_daily_suggestions': 1,
  'home_missions_enabled': false,
  'session_goal_minutes': 5,
  'next_surah_id': 67,
  'ayahs_per_session': 7,
  'practice_days': 65,
};
