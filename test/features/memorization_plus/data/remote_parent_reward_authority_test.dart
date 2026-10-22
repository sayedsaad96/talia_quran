import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_gateway.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_cloud_mappers.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_kids_cloud_sync_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/parent_dashboard.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  late SharedPreferences prefs;
  late MemorizationPlusLocalDatasourceImpl source;
  late AccountDataBarrier barrier;
  late SupabaseClient client;
  late MemorizationKidsCloudSyncService service;
  late Future<http.Response> Function(http.Request) response;
  final requests = <http.Request>[];
  var enabled = true;
  const owner = FixedRecordOwnerProvider('child-a');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    source = MemorizationPlusLocalDatasourceImpl(prefs, owner: owner);
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    enabled = true;
    requests.clear();
    response = (_) async => _reply();
    client = SupabaseClient(
      'https://fixture.invalid',
      'fixture-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final reply = await response(request);
        return http.Response.bytes(
          reply.bodyBytes,
          reply.statusCode,
          headers: reply.headers,
          request: request,
        );
      }),
    );
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'fixture-token',
        'token_type': 'bearer',
        'user': {'id': 'child-a', 'app_metadata': {}, 'aud': 'authenticated'},
      }),
    );
    service = MemorizationKidsCloudSyncService(
      source,
      _Streak(),
      _Gateway(prefs, client),
      MemorizationCloudMappers(const ProgressMetricsService()),
      owner: owner,
      remotePromiseEnabled: () => enabled,
    );
  });
  tearDown(() async => client.dispose());

  test('a valid acknowledgement updates the child cache', () async {
    final result = await service.requestStoredCloudParentReward(_cloud());
    expect(
      result.isRight(),
      isTrue,
      reason: result.fold((f) => f.message, (_) => 'ok'),
    );
    expect(
      (await source.getParentRewards()).single.status,
      ParentRewardStatus.requested,
    );
  });

  test('a late acknowledgement cannot repopulate a reset account', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    response = (_) async {
      entered.complete();
      await release.future;
      return _reply();
    };
    final operation = service.requestStoredCloudParentReward(_cloud());
    await entered.future;
    await barrier.clear(() async {
      await prefs.clear();
    });
    release.complete();

    expect((await operation).isLeft(), isTrue);
    expect(await source.getParentRewards(), isEmpty);
  });

  test(
    'a response for a different reward cannot enter the child cache',
    () async {
      response = (_) async => _reply(id: 43);
      expect(
        (await service.requestStoredCloudParentReward(_cloud())).isLeft(),
        isTrue,
      );
      expect(await source.getParentRewards(), isEmpty);
    },
  );

  test('remote creation sends the milestone only through v2', () async {
    for (final flag in [false, true]) {
      enabled = flag;
      requests.clear();
      final result = await service.saveRemoteParentReward(
        childUserId: 'child-b',
        title: 'gift',
        milestoneSurahId: 67,
      );
      expect(result.isRight(), isTrue);
      final request = requests.singleWhere(
        (request) => request.url.path.contains('/rpc/'),
      );
      expect(
        request.url.path.split('/').last,
        flag ? 'create_parent_reward_v2' : 'create_parent_reward',
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('p_milestone_surah_id'), flag);
      if (flag) expect(body['p_milestone_surah_id'], 67);
    }
  });

  test(
    'a cloud milestone unlock is flag gated and acknowledged once',
    () async {
      final reward = ParentReward(
        id: '42',
        serverId: '42',
        ownerId: 'child-a',
        origin: ParentRewardOrigin.cloud,
        title: 'gift',
        status: ParentRewardStatus.locked,
        milestoneSurahId: 67,
        createdAt: DateTime.utc(2026),
      );
      await source.saveParentRewards([ParentRewardModel.fromEntity(reward)]);
      response = (_) async => _reply(status: 'unlocked');
      enabled = false;
      await service.unlockStoredCloudRewardsForCompletedSurah(67);
      expect(requests, isEmpty);
      enabled = true;
      await service.unlockStoredCloudRewardsForCompletedSurah(67);
      await service.unlockStoredCloudRewardsForCompletedSurah(67);
      expect(requests, hasLength(1));
      expect(
        requests.single.url.path,
        endsWith('/unlock_parent_reward_by_milestone'),
      );
      expect(
        (await source.getParentRewards()).single.status,
        ParentRewardStatus.unlocked,
      );
    },
  );
}

ParentReward _cloud() => ParentReward(
  id: '42',
  serverId: '42',
  origin: ParentRewardOrigin.cloud,
  ownerId: 'child-a',
  title: 'gift',
  status: ParentRewardStatus.unlocked,
  createdAt: DateTime.utc(2026),
);

http.Response _reply({int id = 42, String status = 'requested'}) =>
    http.Response(
      jsonEncode([
        {
          'id': id,
          'child_user_id': 'child-a',
          'title': 'gift',
          'status': status,
          'milestone_surah_id': 67,
          'created_at': '2026-10-21T00:00:00Z',
          'requested_at': '2026-10-21T01:00:00Z',
        },
      ]),
      200,
      headers: {'content-type': 'application/json'},
    );

class _Gateway extends MemorizationCloudGateway {
  _Gateway(super.prefs, this.client);
  final SupabaseClient client;
  @override
  Either<Failure, SupabaseClient> supabaseOrFailure() => Right(client);
}

class _Streak implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}
