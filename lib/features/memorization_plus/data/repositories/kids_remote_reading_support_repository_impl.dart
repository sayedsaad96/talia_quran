import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_failure.dart';
import '../../domain/entities/kids_learning_support_profile.dart';
import '../../domain/repositories/kids_remote_reading_support_repository.dart';
import 'collaborators/kids_reading_support_sync.dart';
import 'collaborators/memorization_cloud_gateway.dart';

/// Guardian device: reads and CAS-writes a linked child's reading answer
/// (`kids_child_reading_support`, parent SELECT RLS). On a server without
/// the table every call is a `Left`, which the screen shows as unavailable.
class KidsRemoteReadingSupportRepositoryImpl
    implements KidsRemoteReadingSupportRepository {
  KidsRemoteReadingSupportRepositoryImpl(this._gateway, this._sync);

  final MemorizationCloudGateway _gateway;
  final KidsReadingSupportSync _sync;

  @override
  Future<Either<Failure, KidsRemoteReadingSupport>> load(String childUserId) =>
      _withClient(
        (client) => _sync.fetchRemote(
          childUserId: childUserId,
          fetch: (id) async {
            final rows = await client
                .from('kids_child_reading_support')
                .select()
                .eq('child_user_id', id)
                .limit(1);
            return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
          },
        ),
      );

  @override
  Future<Either<Failure, KidsRemoteReadingSupport>> save(
    String childUserId,
    KidsLearningSupportProfile profile, {
    required int expectedVersion,
  }) => _withClient(
    (client) => _sync.casRemote(
      childUserId: childUserId,
      profile: profile,
      expectedVersion: expectedVersion,
      cas: (params) =>
          client.rpc('compare_and_swap_child_reading_support', params: params),
    ),
  );

  Future<Either<Failure, KidsRemoteReadingSupport>> _withClient(
    Future<Either<Failure, KidsRemoteReadingSupport>> Function(
      SupabaseClient client,
    )
    run,
  ) async {
    final SupabaseClient client;
    try {
      final result = _gateway.supabaseOrFailure();
      final failure = result.fold((failure) => failure, (_) => null);
      if (failure != null) return Left(failure);
      client = result.getOrElse(() => throw StateError('unreachable'));
    } catch (e) {
      return Left(NetworkFailure.from(e));
    }
    return run(client);
  }
}
