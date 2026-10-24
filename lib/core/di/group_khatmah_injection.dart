import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/group_khatmah/data/group_khatmah_remote.dart';
import '../../features/group_khatmah/data/group_khatmah_repository_impl.dart';
import '../../features/group_khatmah/data/eligibility_requesting_remote.dart';
import '../../features/group_khatmah/data/supabase_group_khatmah_remote.dart';
import '../../features/group_khatmah/domain/entities/group_khatmah.dart';
import '../../features/group_khatmah/domain/repositories/group_khatmah_repository.dart';
import '../error/app_failure.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/memorization_path_resolver.dart';
import '../sync/cloud_sync_queue.dart';
import '../sync/group_khatmah_environment.dart';
import '../sync/group_khatmah_wake_scheduler.dart';
import '../../features/memorization_plus/data/repositories/collaborators/memorization_profile_service.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

Future<void> registerGroupKhatmah(GetIt getIt) async {
  final prefs = getIt<SharedPreferences>();
  final barrier = AccountDataBarrier.forPreferences(prefs);
  final path = getIt<MemorizationPathResolver>();
  final environment = GroupKhatmahAppEnvironment(
    barrier: barrier,
    flags: getIt<ExperienceFlags>(),
    audienceChanges: path.changes,
    loadAdult: () async => (await path.currentProfile())?.isAdult == true,
    recoverPendingWake: () async {
      await getIt<GroupKhatmahRepository>().reconcilePendingWake();
    },
  );
  getIt.registerSingleton<GroupKhatmahAppEnvironment>(
    environment,
    dispose: (value) => value.dispose(),
  );
  GroupKhatmahRemote remote;
  try {
    final supabase = SupabaseGroupKhatmahRemote(Supabase.instance.client);
    remote = EligibilityRequestingRemote(
      supabase,
      requestEligibility: (ownerId) async {
        // The server decides from the synced memorization path. Older
        // installs may never have pushed it, so push an adult's path, but
        // only when the server holds none: a path set from another device
        // is never overwritten here.
        try {
          if ((await path.currentProfile())?.isAdult == true &&
              getIt.isRegistered<MemorizationPlusRepository>() &&
              await _serverPathMissing(ownerId)) {
            await prefs.setBool(
              MemorizationProfileService.kIdentityCloudDirty,
              true,
            );
            await getIt<MemorizationPlusRepository>().pushIdentityToCloud();
          }
        } catch (_) {
          // The request below still runs; the server may then refuse.
        }
        return supabase.requestEligibility(ownerId);
      },
    );
  } catch (_) {
    remote = const _UnavailableGroupRemote();
  }
  getIt.registerLazySingleton<GroupKhatmahRepository>(
    () => GroupKhatmahRepositoryImpl(
      preferences: prefs,
      owner: getIt<RecordOwnerProvider>(),
      remote: remote,
      environment: environment,
      wake: GroupKhatmahQueueWake(getIt<CloudSyncQueue>(), barrier),
    ),
    dispose: (value) => value.dispose(),
  );
  await environment.start();
}

final class _UnavailableGroupRemote implements GroupKhatmahRemote {
  const _UnavailableGroupRemote();
  @override
  Future<Map<String, dynamic>> rpc(
    String function,
    Map<String, dynamic> args, {
    required String ownerId,
  }) async => throw const NetworkFailure();
  @override
  Future<GroupKhatmahPage> fetchMine({
    required String ownerId,
    String? cursor,
  }) async => throw const NetworkFailure();
  @override
  Future<GroupKhatmah?> fetchGroup({
    required String ownerId,
    required String groupId,
  }) async => throw const NetworkFailure();
}

/// True when the account's server profile has no memorization path yet.
/// Any read failure counts as "not missing", so nothing is pushed blindly.
Future<bool> _serverPathMissing(String ownerId) async {
  try {
    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != ownerId) return false;
    final row = await client
        .from('profiles')
        .select('selected_path')
        .eq('id', ownerId)
        .maybeSingle();
    return row == null || row['selected_path'] == null;
  } catch (_) {
    return false;
  }
}
