import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/share_good/application/active_invite_sessions.dart';
import '../../features/share_good/application/share_good_notification_controller.dart';
import '../../features/share_good/application/good_impact_indicator_controller.dart';
import '../../features/share_good/presentation/cubits/good_impact_cubit.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
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
import '../services/notification_service.dart';
import '../services/notification_scheduler.dart';
import '../l10n/locale_cubit.dart';
import '../l10n/app_localizations.dart';

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
    () => GoodImpactCubit(
      repository: getIt(),
      store: getIt(),
      auth: getIt<AuthCubit>(),
      barrier: AccountDataBarrier.forPreferences(getIt()),
      isAvailable: () => getIt<ShareGoodAvailability>().isAvailable,
      isChild: () async =>
          (await getIt<MemorizationPathResolver>().currentProfile())?.isAdult !=
          true,
      audienceChanges: getIt<MemorizationPathResolver>().changes,
    ),
    dispose: (cubit) => cubit.close(),
  );
  getIt.registerLazySingleton(
    () => GoodImpactIndicatorController(getIt<GoodImpactCubit>()),
  );
  getIt.registerLazySingleton(
    () => ActiveInviteSessions(getIt<ShareGoodLocalStore>()),
    dispose: (sessions) => sessions.dispose(),
  );
  getIt.registerLazySingleton(
    () => ShareGoodNotificationController(
      store: getIt(),
      isAvailable: () => getIt<ShareGoodAvailability>().isAvailable,
      isAdult: () async =>
          (await getIt<MemorizationPathResolver>().currentProfile())?.isAdult ==
          true,
      reminderEnabled: () =>
          getIt<SharedPreferences>().getBool(
            TaliaNotificationService.inviteReminderPreferenceKey,
          ) ??
          true,
    ),
    dispose: (controller) => controller.dispose(),
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
  if (getIt<ShareGoodAvailability>().isAvailable) {
    await getIt<ActiveInviteSessions>().restore();
  }
  await getIt<ShareGoodNotificationController>().start(
    sessions: getIt(),
    audienceChanges: getIt<MemorizationPathResolver>().changes,
    cancel: getIt<NotificationScheduler>().cancelInviteReminder,
    schedule: (session) async {
      final locale = getIt<LocaleCubit>().state;
      final label = await getIt<InviteTargetLabeler>().label(
        session.snapshot.target,
        arabic: locale.languageCode == 'ar',
      );
      await label.fold(
        (_) => getIt<NotificationScheduler>().cancelInviteReminder(),
        (label) async => getIt<NotificationScheduler>().scheduleInviteReminder(
          session,
          l10n: lookupAppLocalizations(locale),
          activityLabel: label.title,
          available: getIt<ShareGoodAvailability>().isAvailable,
          adult:
              (await getIt<MemorizationPathResolver>().currentProfile())
                  ?.isAdult ==
              true,
        ),
      );
    },
  );
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
