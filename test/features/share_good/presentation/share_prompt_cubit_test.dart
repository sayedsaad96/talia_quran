import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/presentation/cubits/share_prompt_cubit.dart';

class _DelayedPreferences extends InMemorySharedPreferencesStore {
  _DelayedPreferences() : super.withData({});
  final started = Completer<void>();
  final release = Completer<void>();
  var writes = 0;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key.contains(ShareGoodLocalStore.promptPrefix)) {
      writes++;
      if (!started.isCompleted) started.complete();
      await release.future;
    }
    return super.setValue(type, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'account cleanup waits for an accepted prompt write before removing it',
    () async {
      SharedPreferences.setMockInitialValues({});
      final backend = _DelayedPreferences();
      SharedPreferencesStorePlatform.instance = backend;
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('a');
      final cubit = SharePromptCubit(
        store: ShareGoodLocalStore(const FlutterSecureStorage(), prefs),
        owner: 'a',
        barrier: barrier,
      );
      final writing = cubit.showIfEligible(DateTime.utc(2026, 11, 14));
      await backend.started.future;
      var cleared = false;
      final clearing = barrier.clear(() async {
        await prefs.remove('${ShareGoodLocalStore.promptPrefix}a');
        cleared = true;
      });
      await Future<void>.delayed(Duration.zero);
      expect(cleared, isFalse);
      backend.release.complete();
      await writing;
      await clearing;
      expect(cleared, isTrue);
      expect(
        (await backend.getAll()).keys.where(
          (key) => key.contains(ShareGoodLocalStore.promptPrefix),
        ),
        isEmpty,
      );
      expect(cubit.state, isNull);
      await cubit.close();
    },
  );
  test(
    'invalidation rejects a prompt still waiting in the account queue',
    () async {
      SharedPreferences.setMockInitialValues({});
      final backend = _DelayedPreferences();
      SharedPreferencesStorePlatform.instance = backend;
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('a');
      final hold = Completer<void>();
      final started = Completer<void>();
      final occupying = barrier.run((_) async {
        started.complete();
        await hold.future;
      });
      unawaited(occupying.catchError((_) {}));
      await started.future;
      final cubit = SharePromptCubit(
        store: ShareGoodLocalStore(const FlutterSecureStorage(), prefs),
        owner: 'a',
        barrier: barrier,
      );
      final writing = cubit.showIfEligible(DateTime.utc(2026, 11, 14));
      final clearing = barrier.clear(() async {});
      hold.complete();
      await writing;
      await clearing;
      expect(backend.writes, 0);
      await cubit.close();
    },
  );
  test(
    'education appears once and dismissal persists cooldown across screens',
    () async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = const FixedRecordOwnerProvider('a');
      final store = ShareGoodLocalStore(const FlutterSecureStorage(), prefs);
      SharePromptCubit make() =>
          SharePromptCubit(store: store, owner: 'a', barrier: barrier);
      final now = DateTime.utc(2026, 11, 7);
      final first = make();
      await first.showIfEligible(now);
      expect(first.state?.shownCount, 1);
      expect(first.showEducation, isTrue);
      await first.showIfEligible(now);
      expect(store.promptState('a').shownCount, 1);
      await first.dismiss();
      expect(store.promptState('a').dismissCount, 1);
      final second = make();
      await second.showIfEligible(now.add(const Duration(hours: 72)));
      expect(second.state, isNull);
      final third = make();
      await third.showIfEligible(now.add(const Duration(hours: 144)));
      expect(third.state?.shownCount, 2);
      expect(third.showEducation, isFalse);
      expect(store.promptState('b').shownCount, 0);
      await first.close();
      await second.close();
      await third.close();
    },
  );
}
