import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/hands_free/hands_free_warning_store.dart';

class _Owner implements RecordOwnerProvider {
  @override
  String currentOwnerId = 'owner-a';
  @override
  bool get isSignedIn => true;
}

void main() {
  late SharedPreferences prefs;
  late AccountDataBarrier barrier;
  late _Owner owner;
  late HandsFreeWarningStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _Owner();
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    store = HandsFreeWarningStore(prefs, owner, barrier);
  });
  test('acceptance survives reopen for that owner only', () async {
    expect(store.hasAccepted, isFalse);
    await store.accept();
    expect(HandsFreeWarningStore(prefs, owner, barrier).hasAccepted, isTrue);
    barrier.prepareOwner('owner-b');
    owner.currentOwnerId = 'owner-b';
    await barrier.markOwnerReady('owner-b');
    expect(store.hasAccepted, isFalse);
    expect(prefs.getBool('hands_free_warning_seen|owner-b'), isNull);
  });
  test('account reset namespace includes warning acceptance', () {
    expect(
      AccountDataReset.clearedPreferencePrefixes.any(
        'hands_free_warning_seen|owner-a'.startsWith,
      ),
      isTrue,
    );
  });
  test('invalidated authority cannot accept for the new owner', () async {
    barrier.invalidate();
    await expectLater(
      store.accept(),
      throwsA(isA<AccountDataUnavailableException>()),
    );
    expect(prefs.getBool('hands_free_warning_seen|owner-a'), isNull);
  });
}
