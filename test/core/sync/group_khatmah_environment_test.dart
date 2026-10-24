import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/sync/group_khatmah_environment.dart';

void main() {
  test(
    'audience change revokes access synchronously and ignores an older read',
    () async {
      SharedPreferences.setMockInitialValues({});
      final barrier = AccountDataBarrier.forPreferences(
        await SharedPreferences.getInstance(),
      )..owner = const FixedRecordOwnerProvider('a');
      final changes = StreamController<void>.broadcast(sync: true);
      Completer<bool>? pending;
      var adult = true;
      var wakeRecoveries = 0;
      final environment = GroupKhatmahAppEnvironment(
        barrier: barrier,
        flags: const ExperienceFlags(_enabled),
        audienceChanges: changes.stream,
        loadAdult: () async => pending == null ? adult : pending.future,
        recoverPendingWake: () async {
          wakeRecoveries++;
        },
      );
      addTearDown(changes.close);
      addTearDown(environment.dispose);
      expect(environment.isAdult, isFalse);
      await environment.start();
      expect(environment.isAdult, isTrue);
      expect(wakeRecoveries, 1);
      barrier.notifyChanged();
      expect(wakeRecoveries, 1);
      expect(
        environment.isAdult,
        isTrue,
        reason: 'ordinary cache writes must not revoke the current audience',
      );
      pending = Completer<bool>();
      changes.add(null);
      expect(environment.isAdult, isFalse);
      final old = pending;
      pending = null;
      adult = false;
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
      old.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(environment.isAdult, isFalse);
      adult = true;
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(environment.isAdult, isTrue);
      barrier.prepareOwner('a');
      expect(environment.isAdult, isFalse);
      await barrier.markOwnerReady('a');
      await Future<void>.delayed(Duration.zero);
      expect(environment.isAdult, isTrue);
    },
  );
}

bool _enabled(String _) => true;
