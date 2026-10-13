import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/sync/cloud_sync_queue_item.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_repository_impl.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/hifz/data/models/isar_ayah_progress.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/streak/data/models/daily_activity_isar.dart';
import 'package:talia_quran/features/streak/data/models/streak_isar.dart';
import 'package:talia_quran/features/xp/data/models/xp_isar.dart';

import '../helpers/isar_test_core.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => currentOwnerId != ReviewRecordIdentity.localOwnerId;
}

/// Platform store whose next write can be held until released.
class _HoldableStore extends InMemorySharedPreferencesStore {
  _HoldableStore(super.data) : super.withData();

  Completer<void>? hold;
  int writesEntered = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    writesEntered++;
    await hold?.future;
    return super.setValue(valueType, key, value);
  }
}

const _profile = SaveAdultProfile(
  goal: AdultJourneyGoal.review,
  experience: AdultJourneyExperience.continuing,
);

/// Adult Journey Package 1, Task 6: the preferences follow the existing
/// account cleanup — no inheritance between guest/A/B, no resurrection by a
/// write that was pending during a switch or deletion.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Isar isar;
  late SharedPreferences prefs;
  late _HoldableStore store;
  late _MutableOwner owner;
  late AdultJourneyRepositoryImpl repo;
  late Directory dir;

  String key(String ownerId) => AdultJourneyRepositoryImpl.keyFor(ownerId);

  /// A write that must really land, so later "gone" checks are not vacuous.
  Future<void> saved(String ownerId, AdultJourneyUpdate command) async {
    final result = await repo.update(
      expectedOwnerId: ownerId,
      command: command,
    );
    expect(result.isSuccess, isTrue, reason: 'write for $ownerId');
    expect(prefs.getString(key(ownerId)), isNotNull);
  }

  setUp(() async {
    await initializeIsarCoreForTests();
    SharedPreferences.setMockInitialValues({});
    store = _HoldableStore({});
    SharedPreferencesStorePlatform.instance = store;
    prefs = await SharedPreferences.getInstance();
    owner = _MutableOwner(ReviewRecordIdentity.localOwnerId);
    repo = AdultJourneyRepositoryImpl(prefs, owner);
    dir = await Directory.systemTemp.createTemp('talia_aj_');
    isar = await Isar.open(
      [
        IsarAyahProgressSchema,
        IsarAyahReviewRecordSchema,
        IsarV2SessionSchema,
        StreakIsarSchema,
        XpIsarSchema,
        DailyActivityIsarSchema,
        CloudSyncQueueItemSchema,
      ],
      directory: dir.path,
      name: 'aj_${DateTime.now().microsecondsSinceEpoch}',
    );
    addTearDown(() async {
      await isar.close(deleteFromDisk: true);
      if (await dir.exists()) await dir.delete(recursive: true);
    });
  });

  Future<void> switchTo(String next) async {
    final switched = await AuthCubit.resolveOwnerChange(
      prefs: prefs,
      userId: next,
      onDepartingAccount: AccountDataReset(isar, prefs).clearAccountOwnedData,
    );
    expect(switched, isTrue);
    owner.currentOwnerId = next;
  }

  test('guest → A → B → logout: nothing is inherited at any step', () async {
    const guest = ReviewRecordIdentity.localOwnerId;
    await saved(guest, _profile);
    expect(prefs.getString(key(guest)), isNotNull);

    // Guest to account: no copy of the guest's choices (spec §5).
    owner.currentOwnerId = 'user-a';
    expect(
      (await repo.load(expectedOwnerId: 'user-a')).status,
      AdultJourneyLoadStatus.missing,
    );
    await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
    await saved('user-a', SetAdultToday(localDate: '2026-10-13', minutes: 10));

    await switchTo('user-b');
    expect(prefs.getString(key('user-a')), isNull);
    expect(
      (await repo.load(expectedOwnerId: 'user-b')).status,
      AdultJourneyLoadStatus.missing,
    );

    await saved('user-b', _profile);
    await AccountDataReset(isar, prefs).clearAccountOwnedData();
    expect(
      prefs.getKeys().where(
        (k) => k.startsWith(AdultJourneyRepositoryImpl.keyPrefix),
      ),
      isEmpty,
    );
  });

  test('a write pending during an account switch is not resurrected', () async {
    owner.currentOwnerId = 'user-a';
    await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
    store.writesEntered = 0;
    store.hold = Completer<void>();
    final pending = repo.update(expectedOwnerId: 'user-a', command: _profile);
    await Future<void>.delayed(Duration.zero);
    expect(store.writesEntered, 1, reason: 'the write is in flight');

    // The reset queues behind the in-flight write, then wipes it.
    final switching = switchTo('user-b');
    store.hold!.complete();
    store.hold = null;
    final result = await pending;
    await switching;

    expect(result.isSuccess, isFalse, reason: 'the lease was invalidated');
    expect(prefs.getString(key('user-a')), isNull);
    expect(prefs.getString(key('user-b')), isNull);
  });

  test(
    'A → B → A starts A from defaults (local data is not restored)',
    () async {
      owner.currentOwnerId = 'user-a';
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
      await saved('user-a', _profile);
      await switchTo('user-b');
      await switchTo('user-a');
      expect(
        (await repo.load(expectedOwnerId: 'user-a')).status,
        AdultJourneyLoadStatus.missing,
      );
    },
  );

  test('deleting the account erases its record', () async {
    owner.currentOwnerId = 'user-a';
    await saved('user-a', _profile);
    await AccountDataReset(
      isar,
      prefs,
      documentsDirectory: () async => dir,
    ).eraseDeletedAccountLocally(departingOwnerId: 'user-a');
    expect(prefs.getString(key('user-a')), isNull);
  });
}
