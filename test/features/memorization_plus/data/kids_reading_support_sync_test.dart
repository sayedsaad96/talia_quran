import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_support_profile_store.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_reading_support_sync.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_support_profile.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

const _withHelp = KidsLearningSupportProfile(
  reading: KidsReadingAbility.withHelp,
);
const _notYet = KidsLearningSupportProfile(
  reading: KidsReadingAbility.notYetReading,
);

Map<String, dynamic> _row(String? reading, int version) => {
  'child_user_id': 'child',
  'reading_ability': reading,
  'version': version,
};

void main() {
  late _MutableOwner owner;
  late KidsSupportProfileStore store;
  late KidsReadingSupportSync sync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    owner = _MutableOwner('child');
    store = KidsSupportProfileStore(
      await SharedPreferences.getInstance(),
      owner,
    );
    sync = KidsReadingSupportSync(store, owner);
  });

  group('pull (child device)', () {
    test('adopts a newer server answer', () async {
      await sync.pull(
        ownerId: 'child',
        fetch: (_) async => _row('withHelp', 2),
      );

      final state = store.syncState();
      expect(state.profile, _withHelp);
      expect(state.serverVersion, 2);
      expect(state.pending, isFalse);
    });

    test('ignores an older or equal version', () async {
      await store.applyServer(_notYet, version: 3);

      await sync.pull(
        ownerId: 'child',
        fetch: (_) async => _row('withHelp', 3),
      );

      expect(store.read(), _notYet);
    });

    test('the server answer wins over a pending local edit', () async {
      await store.save(_notYet);

      await sync.pull(
        ownerId: 'child',
        fetch: (_) async => _row('withHelp', 1),
      );

      expect(store.read(), _withHelp);
      expect(store.syncState().pending, isFalse);
    });

    test('an owner change during the read stores nothing', () async {
      await sync.pull(
        ownerId: 'child',
        fetch: (_) async {
          owner.currentOwnerId = 'other';
          return _row('withHelp', 1);
        },
      );
      owner.currentOwnerId = 'child';

      expect(store.read(), KidsLearningSupportProfile.unknown);
    });

    test('a missing table or network error changes nothing', () async {
      await store.save(_notYet);

      await sync.pull(
        ownerId: 'child',
        fetch: (_) async => throw StateError('relation does not exist'),
      );

      expect(store.read(), _notYet);
      expect(store.syncState().pending, isTrue);
    });
  });

  group('pushPending (child device)', () {
    test('sends nothing without a pending edit', () async {
      var calls = 0;
      await sync.pushPending(
        ownerId: 'child',
        cas: (_) async {
          calls++;
          return null;
        },
      );
      expect(calls, 0);
    });

    test('an applied push is acknowledged', () async {
      await store.save(_withHelp);
      Map<String, dynamic>? sent;

      await sync.pushPending(
        ownerId: 'child',
        cas: (params) async {
          sent = params;
          return {
            'applied': true,
            'version': 1,
            'support': _row('withHelp', 1),
          };
        },
      );

      expect(sent, {
        'p_child_user_id': 'child',
        'p_expected_version': 0,
        'p_reading_ability': 'withHelp',
      });
      final state = store.syncState();
      expect(state.pending, isFalse);
      expect(state.serverVersion, 1);
    });

    test('a conflict adopts the guardian answer on the server', () async {
      await store.save(_notYet);

      await sync.pushPending(
        ownerId: 'child',
        cas: (_) async => {
          'applied': false,
          'version': 4,
          'support': _row('withHelp', 4),
        },
      );

      expect(store.read(), _withHelp);
      expect(store.syncState().serverVersion, 4);
      expect(store.syncState().pending, isFalse);
    });

    test('a vanished row keeps the answer pending for a re-create', () async {
      await store.applyServer(_withHelp, version: 2);
      await store.save(_notYet);

      await sync.pushPending(
        ownerId: 'child',
        cas: (_) async => {'applied': false, 'version': 0, 'support': null},
      );

      final state = store.syncState();
      expect(state.profile, _notYet);
      expect(state.serverVersion, 0);
      expect(state.pending, isTrue);
    });

    test('a transport error leaves the edit pending', () async {
      await store.save(_withHelp);

      await sync.pushPending(
        ownerId: 'child',
        cas: (_) async => throw StateError('offline'),
      );

      expect(store.syncState().pending, isTrue);
    });

    test('an edit made during the push stays pending', () async {
      await store.save(_withHelp);

      await sync.pushPending(
        ownerId: 'child',
        cas: (_) async {
          await store.save(_notYet);
          return {
            'applied': true,
            'version': 1,
            'support': _row('withHelp', 1),
          };
        },
      );

      final state = store.syncState();
      expect(state.profile, _notYet);
      expect(state.serverVersion, 1);
      expect(state.pending, isTrue);
    });
  });

  group('guardian device', () {
    test('a conflict is reported, not applied', () async {
      final result = await sync.casRemote(
        childUserId: 'child',
        profile: _withHelp,
        expectedVersion: 1,
        cas: (_) async => {
          'applied': false,
          'version': 2,
          'support': _row('notYetReading', 2),
        },
      );

      expect(result.fold((f) => f, (_) => null), isA<PolicyConflictFailure>());
    });

    test('an applied save returns the new version', () async {
      final result = await sync.casRemote(
        childUserId: 'child',
        profile: _withHelp,
        expectedVersion: 1,
        cas: (_) async => {
          'applied': true,
          'version': 2,
          'support': _row('withHelp', 2),
        },
      );

      final saved = result.getOrElse(() => throw StateError('left'));
      expect(saved.profile, _withHelp);
      expect(saved.version, 2);
    });

    test('no row yet reads as unanswered at version 0', () async {
      final result = await sync.fetchRemote(
        childUserId: 'child',
        fetch: (_) async => null,
      );

      final support = result.getOrElse(() => throw StateError('left'));
      expect(support.profile, KidsLearningSupportProfile.unknown);
      expect(support.version, 0);
    });

    test('a server without the table is a failure', () async {
      final result = await sync.fetchRemote(
        childUserId: 'child',
        fetch: (_) async => throw StateError('relation does not exist'),
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('row mapping', () {
    test('unknown values read as unanswered; unanswered sends null', () {
      expect(
        KidsReadingSupportSync.supportFromRow(_row('future', 3))!.profile,
        KidsLearningSupportProfile.unknown,
      );
      expect(
        KidsReadingSupportSync.supportFromRow(_row('unknown', 3))!.profile,
        KidsLearningSupportProfile.unknown,
      );
      expect(KidsReadingSupportSync.supportFromRow('oops'), isNull);
      expect(
        KidsReadingSupportSync.casParams(
          'c',
          KidsLearningSupportProfile.unknown,
          -1,
        ),
        {
          'p_child_user_id': 'c',
          'p_expected_version': 0,
          'p_reading_ability': null,
        },
      );
    });
  });
}
