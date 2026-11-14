import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/backup/backup_sections.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ShareGoodLocalStore store;
  late FlutterSecureStorage secure;
  late SharedPreferences prefs;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    secure = const FlutterSecureStorage();
    prefs = await SharedPreferences.getInstance();
    store = ShareGoodLocalStore(secure, prefs);
  });
  InviteSession example(String token) => InviteSession(
    token: token,
    snapshot: ResolvedInvite(
      token: token,
      target: const QuranPageInviteTarget(1),
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.personal,
      inviter: const InviterIdentity(
        mode: InviteIdentityMode.firstName,
        visibleName: 'Name',
      ),
      status: InviteLifecycleStatus.active,
      expiresAt: DateTime.utc(2027),
    ),
    pendingStatus: InviteParticipationStatus.started,
    awaitingConsent: true,
  );
  test('concurrent participant key creation is stable', () async {
    final keys = await Future.wait(
      List.generate(20, (_) => store.participantKey()),
    );
    expect(keys.toSet(), hasLength(1));
    expect(keys.first, hasLength(43));
  });
  test('concurrent sessions retain pending and cap index', () async {
    await Future.wait(
      List.generate(25, (i) => store.saveSession(example('token$i'))),
    );
    expect(await store.sessionsWithPending(), hasLength(20));
    final session = await store.session('token24');
    expect(session?.pendingStatus, InviteParticipationStatus.started);
    expect(session?.awaitingConsent, isTrue);
    expect(session?.localSessionId, isNotEmpty);
    expect(await store.sessionByLocalId(session!.localSessionId!), session);
    expect(await store.session('token0'), isNull);
  });
  test('pending compare and acknowledge is atomic', () async {
    await store.setPendingIncomingToken('first');
    expect(await store.acknowledgePendingIncomingToken('wrong'), isFalse);
    expect(await store.pendingIncomingToken(), 'first');
    final results = await Future.wait(
      List.generate(10, (_) => store.acknowledgePendingIncomingToken('first')),
    );
    expect(results.where((value) => value), hasLength(1));
  });
  test(
    'secure snapshot uses only allowed fields and backup excludes keys',
    () async {
      await store.saveSession(example('secret-token'));
      await store.participantKey();
      await store.setPendingIncomingToken('secret-token');
      await store.setPersonalIdentityPreference(
        'owner',
        InviteIdentityMode.fullName,
      );
      final all = await secure.readAll();
      final entry = all.entries.singleWhere(
        (e) => e.key.startsWith('share_good_session_v1_'),
      );
      final json = jsonDecode(entry.value) as Map<String, dynamic>;
      expect(json.keys.toSet(), {
        'token',
        'localSessionId',
        'startedAt',
        'target',
        'moment',
        'mode',
        'identityMode',
        'visibleName',
        'status',
        'expiresAt',
        'serverStatus',
        'pendingStatus',
        'awaitingConsent',
      });
      expect(
        prefs.getKeys().any(
          (k) => prefs.get(k).toString().contains('secret-token'),
        ),
        isFalse,
      );
      for (final key in [
        ...all.keys,
        ...prefs.getKeys(),
        'share_good_prompt_v1|owner',
        'share_good_impact_seen_v1|owner',
      ]) {
        expect(BackupPreferencePolicy.backupKeyFor(key, 'owner'), isNull);
      }
      expect(
        AccountDataReset.clearedPreferencePrefixes,
        containsAll([
          'share_good_identity_pref_v1|',
          'share_good_prompt_v1|',
          'share_good_impact_seen_v1|',
        ]),
      );
    },
  );
  test('corrupted secure data never appears in parse errors', () async {
    await store.saveSession(example('secret-token'));
    final all = await secure.readAll();
    final key = all.keys.singleWhere(
      (key) => key.startsWith('share_good_session_v1_'),
    );
    await secure.write(key: key, value: '{secret-token');
    await expectLater(
      store.session('secret-token'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.toString(),
          'message',
          isNot(contains('secret-token')),
        ),
      ),
    );
    await secure.write(
      key: 'share_good_session_index_v1',
      value: '[secret-token',
    );
    await expectLater(
      store.session('secret-token'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.toString(),
          'message',
          isNot(contains('secret-token')),
        ),
      ),
    );
  });

  test('session index rejects secure keys outside its namespace', () async {
    const unrelatedKey = 'other_secure_key';
    await secure.write(key: unrelatedKey, value: 'unrelated-value');
    await secure.write(
      key: 'share_good_session_index_v1',
      value: jsonEncode([unrelatedKey]),
    );

    await expectLater(
      store.saveSession(example('new-invite')),
      throwsFormatException,
    );
    expect(await secure.read(key: unrelatedKey), 'unrelated-value');
  });

  test(
    'completion consent survives replay and explicit privacy choice wins',
    () async {
      final initial = example('complete-invite');
      await store.saveSession(initial);
      final completed = InviteSession(
        token: initial.token,
        snapshot: initial.snapshot,
        pendingStatus: InviteParticipationStatus.completedPrivate,
      );
      await store.saveSession(completed);
      expect((await store.session(initial.token))!.awaitingConsent, isTrue);
      await store.setAwaitingConsent(initial.token, false);
      await store.saveSession(completed);
      expect((await store.session(initial.token))!.awaitingConsent, isFalse);
      final restored = ShareGoodLocalStore(secure, prefs);
      expect(
        (await restored.session(initial.token))!.pendingStatus,
        InviteParticipationStatus.completedPrivate,
      );
      expect((await restored.session(initial.token))!.awaitingConsent, isFalse);
    },
  );
}
