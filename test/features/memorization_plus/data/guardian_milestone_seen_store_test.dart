import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/guardian_milestone_seen_store.dart';

/// The owner changes after every read, like an account switch mid-call.
class _FlippingOwner implements RecordOwnerProvider {
  int reads = 0;

  @override
  String get currentOwnerId => 'owner-${reads++}';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GuardianMilestoneSeenStore> storeFor(String owner) async =>
      GuardianMilestoneSeenStore(
        await SharedPreferences.getInstance(),
        FixedRecordOwnerProvider(owner),
      );

  test('starts without a record and with nothing seen', () async {
    final store = await storeFor('a');

    expect(await store.hasRecord('local'), isFalse);
    expect(await store.seen('local'), isEmpty);
  });

  test(
    'marking seen adds to the set; an empty mark still makes a record',
    () async {
      final store = await storeFor('a');

      await store.markSeen('local', const []);
      expect(await store.hasRecord('local'), isTrue);

      await store.markSeen('local', ['surah:1']);
      await store.markSeen('local', ['cert:x', 'surah:1']);
      expect(await store.seen('local'), {'surah:1', 'cert:x'});
    },
  );

  test('owners and children are isolated', () async {
    await (await storeFor('a')).markSeen('c1', ['surah:1']);

    expect(await (await storeFor('b')).seen('c1'), isEmpty);
    expect(await (await storeFor('a')).seen('c2'), isEmpty);
    expect(await (await storeFor('a')).seen('c1'), {'surah:1'});
  });

  test('uses the documented key', () async {
    await (await storeFor('a')).markSeen('c1', ['surah:1']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('guardian_milestones_seen|a|c1'), '["surah:1"]');
  });

  test('the owner is captured once per write', () async {
    final owner = _FlippingOwner();
    final prefs = await SharedPreferences.getInstance();
    final store = GuardianMilestoneSeenStore(prefs, owner);

    await store.markSeen('c1', ['surah:1']);

    expect(owner.reads, 1);
    expect(prefs.getKeys(), {'guardian_milestones_seen|owner-0|c1'});
  });

  test('a corrupt value reads as empty', () async {
    SharedPreferences.setMockInitialValues({
      'guardian_milestones_seen|a|c1': '{not a list',
    });
    final store = await storeFor('a');

    expect(await store.seen('c1'), isEmpty);
  });

  test('its key is cleared with the account data', () {
    expect(
      AccountDataReset.clearedPreferencePrefixes,
      contains(GuardianMilestoneSeenStore.keyPrefix),
    );
  });
}
