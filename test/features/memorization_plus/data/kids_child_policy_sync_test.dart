import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_child_policy_sync.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/parent_dashboard.dart';

class _MutableOwner implements RecordOwnerProvider {
  _MutableOwner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

Map<String, dynamic> _row({
  bool reduceMotion = false,
  Object? maxDaily = 3,
  bool homeMissions = true,
  Object? sessionGoal,
  Object? version = 1,
}) => {
  'child_user_id': 'child-1',
  'reduce_motion': reduceMotion,
  'max_daily_suggestions': maxDaily,
  'home_missions_enabled': homeMissions,
  'session_goal_minutes': sessionGoal,
  'version': version,
  'updated_by': 'parent-1',
  'updated_at': '2026-10-02T08:00:00Z',
};

/// Records every CAS call and answers with the queued jsonb payloads.
class _FakeCas {
  _FakeCas(this.responses);

  final List<Object> responses;
  final calls = <Map<String, dynamic>>[];

  Future<Object?> call(Map<String, dynamic> params) async {
    calls.add(Map<String, dynamic>.from(params));
    final next = responses.removeAt(0);
    if (next is Exception || next is Error) throw next;
    return next;
  }
}

void main() {
  const ownerId = 'child-1';
  late SharedPreferences prefs;
  late _MutableOwner owner;
  late MemorizationPlusLocalDatasourceImpl datasource;
  late KidsChildPolicySync sync;
  late int changedCalls;

  /// A confirmed-linked child whose last server-acknowledged version is 3.
  const stored = ParentSettings(
    pinHash: 'secure-v2',
    localChildNickname: 'Talia',
    reminderHour: 7,
    sessionGoalMinutes: 8,
    maxDailySuggestions: 3,
    policyVersion: 3,
    policySyncedVersion: 3,
    policyLinkConfirmed: true,
  );

  Future<void> seed(ParentSettings settings) =>
      datasource.saveParentSettings(ParentSettingsModel.fromEntity(settings));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = _MutableOwner(ownerId);
    datasource = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    await seed(stored);
    changedCalls = 0;
    sync = KidsChildPolicySync(
      datasource,
      owner,
      onPolicyChanged: () => changedCalls++,
    );
  });

  Future<ParentSettings> local() => datasource.getParentSettings();
  final storedModel = ParentSettingsModel.fromEntity(stored);

  const edit = KidsChildPolicy(
    reduceMotion: true,
    maxDailySuggestions: 1,
    homeMissionsEnabled: false,
    sessionGoalMinutes: 10,
    version: 3,
  );

  group('child device edit', () {
    test('linked: CAS expects the synced version and stores the '
        'returned one', () async {
      final cas = _FakeCas([
        {
          'applied': true,
          'version': 4,
          'policy': _row(
            reduceMotion: true,
            maxDaily: 1,
            homeMissions: false,
            sessionGoal: 10,
            version: 4,
          ),
        },
      ]);

      final result = await sync.saveOnDevice(
        policy: edit.copyWith(version: 99),
        linkedChildUserId: ownerId,
        casRpc: cas.call,
      );

      expect(cas.calls.single, {
        'p_child_user_id': ownerId,
        'p_expected_version': 3,
        'p_reduce_motion': true,
        'p_max_daily_suggestions': 1,
        'p_home_missions_enabled': false,
        'p_session_goal_minutes': 10,
      });
      expect(result.fold((_) => null, (p) => p.version), 4);
      final saved = await local();
      expect(saved.policyVersion, 4);
      expect(saved.policySyncedVersion, 4);
      expect(saved.policyLinkConfirmed, isTrue);
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.maxDailySuggestions, 1);
      expect(saved.homeMissionsEnabled, isFalse);
      expect(saved.sessionGoalMinutes, 10);
      expect(saved.pinHash, 'secure-v2');
      expect(saved.localChildNickname, 'Talia');
      expect(changedCalls, 1);
    });

    test('linked conflict: Left(PolicyConflictFailure) and local = server '
        'row, not the edit', () async {
      final cas = _FakeCas([
        {
          'applied': false,
          'version': 7,
          'policy': _row(maxDaily: 2, sessionGoal: null, version: 7),
        },
      ]);

      final result = await sync.saveOnDevice(
        policy: edit,
        linkedChildUserId: ownerId,
        casRpc: cas.call,
      );

      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<PolicyConflictFailure>());
      expect(failure!.message, CubitMessageCodes.kidsPolicyConflict);
      final saved = await local();
      expect(saved.policyVersion, 7);
      expect(saved.policySyncedVersion, 7);
      expect(saved.policyLinkConfirmed, isTrue);
      expect(saved.kidsReduceMotion, isFalse);
      expect(saved.maxDailySuggestions, 2);
      expect(saved.homeMissionsEnabled, isTrue);
      expect(saved.sessionGoalMinutes, isNull);
      expect(saved.pinHash, 'secure-v2');
      expect(changedCalls, 1);
    });

    test('aliasing: CAS expects the synced version, never the local edit '
        'counter', () async {
      // Local edits raised the counter to 4 while the server only ever
      // acknowledged v1; the guardian meanwhile took the server to v4.
      await seed(stored.copyWith(policyVersion: 4, policySyncedVersion: 1));
      final cas = _FakeCas([
        {'applied': false, 'version': 4, 'policy': _row(version: 4)},
      ]);

      final result = await sync.saveOnDevice(
        policy: edit,
        linkedChildUserId: ownerId,
        casRpc: cas.call,
      );

      expect(cas.calls.single['p_expected_version'], 1);
      expect(result.fold((f) => f, (_) => null), isA<PolicyConflictFailure>());
      expect((await local()).policySyncedVersion, 4);
    });

    test(
      'a never-synced linked device creates with expected 0, no retry',
      () async {
        await seed(
          stored.copyWith(
            policyVersion: 4,
            policySyncedVersion: 0,
            policyLinkConfirmed: false,
          ),
        );
        final cas = _FakeCas([
          {'applied': true, 'version': 1, 'policy': _row(version: 1)},
        ]);

        await sync.saveOnDevice(
          policy: edit,
          linkedChildUserId: ownerId,
          casRpc: cas.call,
        );

        expect(cas.calls.map((c) => c['p_expected_version']), [0]);
        final saved = await local();
        expect(saved.policyVersion, 1);
        expect(saved.policySyncedVersion, 1);
        expect(saved.policyLinkConfirmed, isTrue);
      },
    );

    test('offline on a confirmed-linked device: Left(NetworkFailure), '
        'local unchanged', () async {
      final cas = _FakeCas([Exception('SocketException: offline')]);

      final result = await sync.saveOnDevice(
        policy: edit,
        linkedChildUserId: ownerId,
        casRpc: cas.call,
      );

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      expect(await local(), storedModel);
      expect(changedCalls, 0);
    });

    test(
      'offline on a device not confirmed linked: saved locally, Right',
      () async {
        await seed(stored.copyWith(clearPolicyLinkConfirmed: true));
        final cas = _FakeCas([Exception('SocketException: offline')]);

        final result = await sync.saveOnDevice(
          policy: edit,
          linkedChildUserId: ownerId,
          casRpc: cas.call,
        );

        expect(result.isRight(), isTrue);
        final saved = await local();
        expect(saved.policyVersion, 4);
        expect(saved.policySyncedVersion, 3);
        expect(saved.kidsReduceMotion, isTrue);
        expect(changedCalls, 1);
      },
    );

    test('"Child link is not active" saves locally and records the link as '
        'unconfirmed', () async {
      final cas = _FakeCas([Exception('Child link is not active')]);

      final result = await sync.saveOnDevice(
        policy: edit,
        linkedChildUserId: ownerId,
        casRpc: cas.call,
      );

      expect(result.isRight(), isTrue);
      final saved = await local();
      expect(saved.policyVersion, 4);
      expect(saved.policySyncedVersion, 3);
      expect(saved.policyLinkConfirmed, isFalse);
      expect(saved.kidsReduceMotion, isTrue);
    });

    test('unlinked: local only and policyVersion + 1', () async {
      final cas = _FakeCas([]);

      final result = await sync.saveOnDevice(
        policy: edit,
        linkedChildUserId: null,
        casRpc: cas.call,
      );

      expect(cas.calls, isEmpty);
      expect(result.fold((_) => null, (p) => p.version), 4);
      final saved = await local();
      expect(saved.policyVersion, 4);
      expect(saved.policySyncedVersion, 3);
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.maxDailySuggestions, 1);
      expect(saved.homeMissionsEnabled, isFalse);
      expect(saved.sessionGoalMinutes, 10);
      expect(saved.localChildNickname, 'Talia');
      expect(changedCalls, 1);
    });

    test('out-of-range edit values are sanitized before saving', () async {
      final result = await sync.saveOnDevice(
        policy: const KidsChildPolicy(
          maxDailySuggestions: 9,
          sessionGoalMinutes: 90,
        ),
        linkedChildUserId: null,
        casRpc: _FakeCas([]).call,
      );

      expect(result.isRight(), isTrue);
      final saved = await local();
      expect(saved.maxDailySuggestions, 3);
      expect(saved.sessionGoalMinutes, isNull);
    });
  });

  group('child device pull', () {
    test('remote v5 over synced v3 replaces the policy fields only', () async {
      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async => _row(
          reduceMotion: true,
          maxDaily: 2,
          homeMissions: false,
          sessionGoal: null,
          version: 5,
        ),
      );

      final saved = await local();
      expect(saved.policyVersion, 5);
      expect(saved.policySyncedVersion, 5);
      expect(saved.policyLinkConfirmed, isTrue);
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.maxDailySuggestions, 2);
      expect(saved.homeMissionsEnabled, isFalse);
      expect(saved.sessionGoalMinutes, isNull);
      expect(saved.pinHash, 'secure-v2');
      expect(saved.localChildNickname, 'Talia');
      expect(saved.reminderHour, 7);
      expect(changedCalls, 1);
    });

    test('remote v2 under synced v3 is ignored', () async {
      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async => _row(reduceMotion: true, version: 2),
      );

      expect(await local(), storedModel);
      expect(changedCalls, 0);
    });

    test('local v4 while unlinked, then link, then server row v1: the '
        "guardian's values apply and both versions become 1", () async {
      await seed(
        const ParentSettings(
          pinHash: 'secure-v2',
          maxDailySuggestions: 3,
          kidsReduceMotion: false,
          policyVersion: 4,
        ),
      );

      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async =>
            _row(reduceMotion: true, maxDaily: 1, sessionGoal: 6, version: 1),
      );

      final saved = await local();
      expect(saved.kidsReduceMotion, isTrue);
      expect(saved.maxDailySuggestions, 1);
      expect(saved.sessionGoalMinutes, 6);
      expect(saved.policyVersion, 1);
      expect(saved.policySyncedVersion, 1);
      expect(saved.policyLinkConfirmed, isTrue);
      expect(saved.pinHash, 'secure-v2');
    });

    test('no server row leaves local untouched', () async {
      await sync.pull(ownerId: ownerId, fetchRow: () async => null);

      expect(await local(), storedModel);
      expect(changedCalls, 0);
    });

    test('a fetch error never throws and leaves local untouched', () async {
      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async => throw Exception('relation does not exist'),
      );

      expect(await local(), storedModel);
      expect(changedCalls, 0);
    });

    test('out-of-range remote values are clamped and sanitized', () async {
      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async => _row(maxDaily: 9, sessionGoal: 90, version: '6'),
      );

      final saved = await local();
      expect(saved.policyVersion, 6);
      expect(saved.maxDailySuggestions, 3);
      expect(saved.sessionGoalMinutes, isNull);
    });

    test('an account switch during the fetch drops the row', () async {
      await sync.pull(
        ownerId: ownerId,
        fetchRow: () async {
          owner.currentOwnerId = 'someone-else';
          return _row(reduceMotion: true, version: 9);
        },
      );
      owner.currentOwnerId = ownerId;

      expect(await local(), storedModel);
    });
  });

  group('pending push after linking', () {
    const pending = ParentSettings(
      pinHash: 'secure-v2',
      kidsReduceMotion: true,
      maxDailySuggestions: 1,
      homeMissionsEnabled: false,
      sessionGoalMinutes: 10,
      policyVersion: 4,
    );

    test('a pre-link edit is created on the server and stored', () async {
      await seed(pending);
      final cas = _FakeCas([
        {
          'applied': true,
          'version': 1,
          'policy': _row(
            reduceMotion: true,
            maxDaily: 1,
            homeMissions: false,
            sessionGoal: 10,
            version: 1,
          ),
        },
      ]);

      await sync.pushPending(
        ownerId: ownerId,
        childUserId: ownerId,
        casRpc: cas.call,
      );

      expect(cas.calls.single['p_expected_version'], 0);
      expect(cas.calls.single['p_reduce_motion'], isTrue);
      expect(cas.calls.single['p_max_daily_suggestions'], 1);
      final saved = await local();
      expect(saved.policyVersion, 1);
      expect(saved.policySyncedVersion, 1);
      expect(saved.policyLinkConfirmed, isTrue);
      expect(saved.kidsReduceMotion, isTrue);
    });

    test('a conflict adopts the server row (the guardian wins)', () async {
      await seed(pending);
      final cas = _FakeCas([
        {
          'applied': false,
          'version': 2,
          'policy': _row(maxDaily: 2, version: 2),
        },
      ]);

      await sync.pushPending(
        ownerId: ownerId,
        childUserId: ownerId,
        casRpc: cas.call,
      );

      final saved = await local();
      expect(saved.kidsReduceMotion, isFalse);
      expect(saved.maxDailySuggestions, 2);
      expect(saved.homeMissionsEnabled, isTrue);
      expect(saved.policyVersion, 2);
      expect(saved.policySyncedVersion, 2);
      expect(saved.policyLinkConfirmed, isTrue);
    });

    test(
      'no active link marks the link unconfirmed and keeps the edit',
      () async {
        await seed(pending);
        final cas = _FakeCas([Exception('Child link is not active')]);

        await sync.pushPending(
          ownerId: ownerId,
          childUserId: ownerId,
          casRpc: cas.call,
        );

        final saved = await local();
        expect(saved.policyLinkConfirmed, isFalse);
        expect(saved.policyVersion, 4);
        expect(saved.policySyncedVersion, 0);
        expect(saved.kidsReduceMotion, isTrue);
      },
    );

    test(
      'a transport error leaves the edit pending and never throws',
      () async {
        await seed(pending);
        final cas = _FakeCas([Exception('SocketException: offline')]);

        await sync.pushPending(
          ownerId: ownerId,
          childUserId: ownerId,
          casRpc: cas.call,
        );

        expect(await local(), ParentSettingsModel.fromEntity(pending));
      },
    );

    test('nothing pending sends nothing', () async {
      final cas = _FakeCas([]);

      await sync.pushPending(
        ownerId: ownerId,
        childUserId: ownerId,
        casRpc: cas.call,
      );

      expect(cas.calls, isEmpty);
    });
  });

  group('guardian edit', () {
    test('CAS uses the summary version for the child id', () async {
      final cas = _FakeCas([
        {'applied': true, 'version': 3, 'policy': _row(version: 3)},
      ]);

      final result = await sync.casRemote(
        childUserId: 'remote-child',
        policy: edit,
        expectedVersion: 2,
        casRpc: cas.call,
      );

      expect(cas.calls.single['p_child_user_id'], 'remote-child');
      expect(cas.calls.single['p_expected_version'], 2);
      expect(result.fold((_) => null, (p) => p.version), 3);
      expect(
        await local(),
        storedModel,
        reason: 'guardian edits never touch the cache',
      );
      expect(changedCalls, 0);
    });

    test('a guardian conflict is a PolicyConflictFailure', () async {
      final cas = _FakeCas([
        {'applied': false, 'version': 5, 'policy': _row(version: 5)},
      ]);

      final result = await sync.casRemote(
        childUserId: 'remote-child',
        policy: edit,
        expectedVersion: 2,
        casRpc: cas.call,
      );

      expect(result.fold((f) => f, (_) => null), isA<PolicyConflictFailure>());
    });
  });

  group('parsing', () {
    test('policyFromRow tolerates numeric strings and missing keys', () {
      expect(
        KidsChildPolicySync.policyFromRow({'version': '4'}),
        const KidsChildPolicy(version: 4),
      );
      expect(KidsChildPolicySync.policyFromRow(null), isNull);
      expect(KidsChildPolicySync.policyFromRow('nope'), isNull);
    });

    test(
      'old settings JSON loads policySyncedVersion 0 and an unknown link',
      () {
        final old = ParentSettingsModel.fromJson({
          'pinHash': 'h',
          'policyVersion': 2,
        });
        expect(old.policySyncedVersion, 0);
        expect(old.policyLinkConfirmed, isNull);

        final wrongTypes = ParentSettingsModel.fromJson({
          'policySyncedVersion': 'x',
          'policyLinkConfirmed': 'yes',
        });
        expect(wrongTypes.policySyncedVersion, 0);
        expect(wrongTypes.policyLinkConfirmed, isNull);

        final roundTrip = ParentSettingsModel.fromJson(
          ParentSettingsModel.fromEntity(stored).toJson(),
        );
        expect(roundTrip.policySyncedVersion, 3);
        expect(roundTrip.policyLinkConfirmed, isTrue);
      },
    );
  });
}
