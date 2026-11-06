import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/share_good/application/active_invite_sessions.dart';
import '../../features/share_good/data/datasources/share_good_local_store.dart';
import '../../features/share_good/data/datasources/share_good_remote_datasource.dart';
import '../../features/share_good/data/repositories/share_good_repository_impl.dart';
import '../../features/share_good/domain/repositories/share_good_repository.dart';
import '../../features/share_good/domain/services/invite_target_labeler.dart';
import '../../features/share_good/domain/services/inviter_identity_resolver.dart';
import '../../features/share_good/presentation/cubits/invite_preview_cubit.dart';
import '../../features/share_good/share_good_config.dart';
import '../config/supabase_config.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../memorization/memorization_path_resolver.dart';
import '../security/secure_storage_configuration.dart';
import '../services/device_timezone.dart';

void registerShareGood(GetIt getIt) {
  getIt.registerLazySingleton(
    () => ShareGoodAvailability(
      getIt<ExperienceFlags>(),
      SupabaseConfig.fromDartDefine,
    ),
  );
  getIt.registerLazySingleton(
    () => ShareGoodLocalStore(taliaSecureStorage, getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton(
    () => ShareGoodRemoteDatasource(_configuredClient()),
  );
  getIt.registerLazySingleton<ShareGoodRepository>(
    () => ShareGoodRepositoryImpl(
      remote: getIt<ShareGoodRemoteDatasource>(),
      local: getIt<ShareGoodLocalStore>(),
      links: getIt<ShareGoodAvailability>().links,
      timezone: _inviteTimezone,
      accountBarrier: AccountDataBarrier.forPreferences(getIt()),
      isAvailable: () => getIt<ShareGoodAvailability>().isAvailable,
      isChild: () => _isShareGoodChild(getIt),
    ),
  );
  getIt.registerLazySingleton(() => InviteTargetLabeler(getIt()));
  getIt.registerLazySingleton(() => const InviterIdentityResolver());
  getIt.registerLazySingleton(
    () => ActiveInviteSessions(getIt<ShareGoodLocalStore>()),
    dispose: (sessions) => sessions.dispose(),
  );
  getIt.registerFactoryParam<InvitePreviewCubit, bool, void>(
    (arabic, _) => InvitePreviewCubit(
      repository: getIt(),
      labeler: getIt(),
      activeSessions: getIt(),
      isChild: () => _isShareGoodChild(getIt),
      cachedSession: getIt<ShareGoodLocalStore>().session,
      acknowledgeIncoming:
          getIt<ShareGoodLocalStore>().acknowledgePendingIncomingToken,
      arabic: arabic,
    ),
  );
}

Future<bool> _isShareGoodChild(GetIt getIt) async =>
    (await getIt<MemorizationPathResolver>().currentProfile())?.isChild == true;

Future<void> restoreShareGoodSessions(GetIt getIt) async {
  if (!getIt<ShareGoodAvailability>().isAvailable ||
      await _isShareGoodChild(getIt)) {
    return;
  }
  await getIt<ActiveInviteSessions>().restore();
}

SupabaseClient? _configuredClient() {
  if (!SupabaseConfig.fromDartDefine.isConfigured) return null;
  try {
    final supabase = Supabase.instance;
    return supabase.isInitialized ? supabase.client : null;
  } on AssertionError {
    return null;
  }
}

Future<String> _inviteTimezone() async {
  final device = await lookupDeviceTimezone();
  final location = device.location;
  if (location == null) throw StateError('Device timezone unavailable');
  return location.name;
}
