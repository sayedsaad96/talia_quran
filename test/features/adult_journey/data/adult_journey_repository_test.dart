import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_repository_impl.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

/// In-memory platform store whose writes and reloads can fail or be held.
class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore() : super.empty();

  bool failWrites = false;
  bool throwOnWrite = false;
  bool failReload = false;
  Completer<void>? holdWrite;
  final writeStarted = <Completer<void>>[];

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final hold = holdWrite;
    if (hold != null) {
      final started = Completer<void>();
      writeStarted.add(started);
      started.complete();
      await hold.future;
    }
    if (throwOnWrite) throw StateError('disk full');
    if (failWrites) return false;
    return super.setValue(valueType, key, value);
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) {
    if (failReload) throw StateError('reload failed');
    return super.getAllWithParameters(parameters);
  }
}

const _profile = SaveAdultProfile(
  goal: AdultJourneyGoal.memorization,
  experience: AdultJourneyExperience.continuing,
);

void main() {
  late _ControlledStore store;
  late SharedPreferences prefs;
  late _MutableOwner owner;
  late AdultJourneyRepositoryImpl repo;

  String keyA() => AdultJourneyRepositoryImpl.keyFor('owner-a');
  String keyB() => AdultJourneyRepositoryImpl.keyFor('owner-b');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    prefs = await SharedPreferences.getInstance();
    owner = _MutableOwner('owner-a');
    repo = AdultJourneyRepositoryImpl(prefs, owner);
  });

  test('key is prefixed and the owner id is URI-encoded', () {
    expect(
      AdultJourneyRepositoryImpl.keyFor('a/b c'),
      'adult_journey_v1_a%2Fb%20c',
    );
  });

  test('missing record loads as missing and writes nothing', () async {
    final result = await repo.load(expectedOwnerId: 'owner-a');
    expect(result.status, AdultJourneyLoadStatus.missing);
    expect(prefs.getKeys(), isEmpty);
  });

  test('save then load round-trips for the same owner', () async {
    final saved = await repo.update(
      expectedOwnerId: 'owner-a',
      command: _profile,
    );
    expect(saved.isSuccess, isTrue);
    final loaded = await repo.load(expectedOwnerId: 'owner-a');
    expect(loaded.preferences.goal, AdultJourneyGoal.memorization);
    expect(loaded.preferences.profileCompleted, isTrue);
  });

  test('today, profile and visit updates do not erase each other', () async {
    await repo.update(expectedOwnerId: 'owner-a', command: _profile);
    await repo.update(
      expectedOwnerId: 'owner-a',
      command: SetAdultToday(localDate: '2026-10-11', minutes: 10),
    );
    await repo.update(
      expectedOwnerId: 'owner-a',
      command: RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 8)),
    );
    final value = (await repo.load(expectedOwnerId: 'owner-a')).preferences;
    expect(value.goal, AdultJourneyGoal.memorization);
    expect(value.todayMinutes, 10);
    expect(value.lastHomeSeenAtUtc, DateTime.utc(2026, 10, 11, 8));
  });

  test('a same-day visit is unchanged and not written', () async {
    await repo.update(
      expectedOwnerId: 'owner-a',
      command: RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 8)),
    );
    store.failWrites = true; // any write would now be reported
    final second = await repo.update(
      expectedOwnerId: 'owner-a',
      command: RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 9)),
    );
    expect(second.isSuccess, isTrue);
    expect(second.changed, isFalse);
  });

  group('unreadable records', () {
    test('a newer schema is never overwritten', () async {
      final newer = jsonEncode({'schemaVersion': 2, 'goal': 'reading'});
      await prefs.setString(keyA(), newer);
      final load = await repo.load(expectedOwnerId: 'owner-a');
      expect(load.status, AdultJourneyLoadStatus.unsupported);
      final save = await repo.update(
        expectedOwnerId: 'owner-a',
        command: _profile,
      );
      expect(save.failure, AdultJourneySaveFailure.unsupportedRecord);
      expect(prefs.getString(keyA()), newer);
    });

    test('corrupt JSON survives an automatic visit write', () async {
      await prefs.setString(keyA(), '{broken');
      final save = await repo.update(
        expectedOwnerId: 'owner-a',
        command: RecordAdultHomeVisit(DateTime.utc(2026, 10, 11)),
      );
      expect(save.failure, AdultJourneySaveFailure.corruptRecord);
      expect(prefs.getString(keyA()), '{broken');
    });

    test('an explicit user choice replaces a corrupt record', () async {
      await prefs.setString(keyA(), '{broken');
      final save = await repo.update(
        expectedOwnerId: 'owner-a',
        command: _profile,
      );
      expect(save.isSuccess, isTrue);
      final load = await repo.load(expectedOwnerId: 'owner-a');
      expect(load.status, AdultJourneyLoadStatus.ready);
    });
  });

  group('write failures never report success', () {
    for (final mode in ['returns false', 'throws']) {
      test(
        'setString $mode: previous profile kept, cache reconciled',
        () async {
          await repo.update(
            expectedOwnerId: 'owner-a',
            command: const SaveAdultProfile(goal: AdultJourneyGoal.reading),
          );
          store.failWrites = mode == 'returns false';
          store.throwOnWrite = mode == 'throws';

          final failed = await repo.update(
            expectedOwnerId: 'owner-a',
            command: _profile,
          );
          expect(failed.isSuccess, isFalse);
          expect(failed.failure, AdultJourneySaveFailure.storage);

          // The rejected value must not leak from the in-memory cache.
          final loaded = await repo.load(expectedOwnerId: 'owner-a');
          expect(loaded.preferences.goal, AdultJourneyGoal.reading);

          store.failWrites = false;
          store.throwOnWrite = false;
          final today = await repo.update(
            expectedOwnerId: 'owner-a',
            command: SetAdultToday(localDate: '2026-10-11', minutes: 5),
          );
          expect(today.isSuccess, isTrue);
          final after = await repo.load(expectedOwnerId: 'owner-a');
          expect(after.preferences.goal, AdultJourneyGoal.reading);
          expect(after.preferences.todayMinutes, 5);
        },
      );
    }

    test(
      'a failed reconciliation blocks reads and writes until reload works',
      () async {
        store.failWrites = true;
        store.failReload = true;
        final failed = await repo.update(
          expectedOwnerId: 'owner-a',
          command: _profile,
        );
        expect(failed.isSuccess, isFalse);

        final blockedLoad = await repo.load(expectedOwnerId: 'owner-a');
        expect(blockedLoad.status, AdultJourneyLoadStatus.unavailable);
        store.failWrites = false;
        final blockedSave = await repo.update(
          expectedOwnerId: 'owner-a',
          command: _profile,
        );
        expect(blockedSave.failure, AdultJourneySaveFailure.storage);

        store.failReload = false;
        final load = await repo.load(expectedOwnerId: 'owner-a');
        expect(
          load.status,
          AdultJourneyLoadStatus.missing,
          reason: 'the never-stored value was dropped by the reload',
        );
      },
    );
  });

  group('account isolation', () {
    test(
      'a call for another owner is unavailable and writes nothing',
      () async {
        owner.currentOwnerId = 'owner-b';
        final save = await repo.update(
          expectedOwnerId: 'owner-a',
          command: _profile,
        );
        expect(save.failure, AdultJourneySaveFailure.unavailable);
        expect(prefs.getString(keyA()), isNull);
        expect(prefs.getString(keyB()), isNull);
        final load = await repo.load(expectedOwnerId: 'owner-a');
        expect(load.status, AdultJourneyLoadStatus.unavailable);
      },
    );

    test('owners never see each other\'s record', () async {
      await repo.update(expectedOwnerId: 'owner-a', command: _profile);
      owner.currentOwnerId = 'owner-b';
      final load = await repo.load(expectedOwnerId: 'owner-b');
      expect(load.status, AdultJourneyLoadStatus.missing);
    });

    test(
      'A to B to A during a held write: the result is not a success',
      () async {
        final barrier = AccountDataBarrier.forPreferences(prefs);
        store.holdWrite = Completer<void>();
        final pending = repo.update(
          expectedOwnerId: 'owner-a',
          command: _profile,
        );
        await Future<void>.delayed(Duration.zero);
        expect(store.writeStarted, hasLength(1));

        // Switch to B and back to A while the write is in flight; the barrier
        // generation moves even though the id matches again.
        owner.currentOwnerId = 'owner-b';
        barrier.invalidate();
        owner.currentOwnerId = 'owner-a';
        store.holdWrite!.complete();

        final result = await pending;
        expect(result.isSuccess, isFalse);
        expect(result.failure, AdultJourneySaveFailure.unavailable);
        expect(prefs.getString(keyB()), isNull);
      },
    );

    test('a write started for A never lands under B\'s key', () async {
      store.holdWrite = Completer<void>();
      final pending = repo.update(
        expectedOwnerId: 'owner-a',
        command: _profile,
      );
      await Future<void>.delayed(Duration.zero);
      owner.currentOwnerId = 'owner-b';
      store.holdWrite!.complete();
      final result = await pending;
      expect(result.isSuccess, isFalse);
      expect(prefs.getString(keyB()), isNull);
    });
  });
}
