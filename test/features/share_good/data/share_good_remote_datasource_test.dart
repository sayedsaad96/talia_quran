import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_local_store.dart';
import 'package:talia_quran/features/share_good/data/datasources/share_good_remote_datasource.dart';
import 'package:talia_quran/features/share_good/data/repositories/share_good_repository_impl.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_activity_target.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const errors = {
    'expired': ShareGoodFailure.expired,
    'rate_limited': ShareGoodFailure.rateLimited,
    'invalid_input': ShareGoodFailure.invalidInvite,
  };
  for (final entry in errors.entries) {
    test('maps ${entry.key} from the RPC response', () async {
      final remote = _remote(
        (request) async => _json(request, {'error': entry.key}),
      );
      await expectLater(
        remote.call('resolve_share_good_invite_v1'),
        throwsA(_failure(entry.value)),
      );
    });
  }

  test('an unavailable RPC maps to featureUnavailable', () async {
    final remote = _remote(
      (request) async =>
          _json(request, {'code': 'PGRST202', 'message': 'RPC missing'}, 404),
    );
    await expectLater(
      remote.call('get_share_good_impact_v1'),
      throwsA(_failure(ShareGoodFailure.featureUnavailable)),
    );
  });

  test('create sends target identifiers and the IANA timezone', () async {
    const token = 'abcdefghijklmnopqrstuvwxyzABCDEFGH123456789';
    const context = InviteContext(
      target: QuranPageInviteTarget(42),
      moment: InviteMoment.beforeActivity,
      mode: InviteMode.personal,
      identity: InviterIdentity(mode: InviteIdentityMode.anonymous),
    );
    final remote = _remote((request) async {
      expect(request.url.path, '/rest/v1/rpc/create_share_good_invite_v1');
      expect(jsonDecode(request.body), {
        'p_target': {'v': 1, 'type': 'quran_page', 'page': 42},
        'p_moment': 'before',
        'p_mode': 'personal',
        'p_identity_mode': 'anonymous',
        'p_visible_name': null,
        'p_timezone': 'Africa/Cairo',
      });
      return _json(request, {
        'token': token,
        'target': context.target.toJson(),
        'moment': 'before',
        'mode': 'personal',
        'inviter': {'mode': 'anonymous'},
        'created_at': '2026-11-06T00:00:00Z',
        'expires_at': '2026-11-13T00:00:00Z',
      });
    });
    SharedPreferences.setMockInitialValues({});
    final repository = ShareGoodRepositoryImpl(
      remote: remote,
      local: ShareGoodLocalStore(
        const FlutterSecureStorage(),
        await SharedPreferences.getInstance(),
      ),
      links: const ShareGoodLinks('example.com'),
      timezone: () async => 'Africa/Cairo',
    );
    final result = await repository.create(context);
    result.fold((error) => fail('Unexpected error: $error'), (invite) {
      expect(invite.context, context);
      expect(invite.shareUrl, Uri.https('example.com', '/i/$token'));
    });
  });
}

ShareGoodRemoteDatasource _remote(MockClientHandler handler) {
  final client = SupabaseClient(
    'https://example.test',
    'test-key',
    httpClient: MockClient(handler),
  );
  addTearDown(client.dispose);
  return ShareGoodRemoteDatasource(client);
}

http.Response _json(
  http.Request request,
  Map<String, Object?> payload, [
  int status = 200,
]) => http.Response(
  jsonEncode(payload),
  status,
  request: request,
  headers: {'content-type': 'application/json'},
);

Matcher _failure(ShareGoodFailure failure) => isA<ShareGoodRemoteException>()
    .having((e) => e.failure, 'failure', failure);
