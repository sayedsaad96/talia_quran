import 'package:get_it/get_it.dart';

import '../../features/memorization_plus/presentation/world/kids_policy_controller.dart';
import '../../features/memorization_plus/presentation/world/kids_world_growth_controller.dart';
import '../../features/settings/presentation/cubits/profile_cubit.dart';
import '../memorization/memorization_path_resolver.dart';
import '../utils/talia_logger.dart';

/// Refreshes the app-lifetime singletons that hold restored preferences in
/// memory. Call it after a restore succeeds, before leaving the page.
///
/// Audited singletons (`registerLazySingleton`/`registerSingleton` in
/// `injection.dart`) and why the others need nothing:
/// - [ProfileCubit] caches `user_profile`; a stale state would also be
///   written back by `updateProfile`. Reloaded.
/// - [KidsPolicyController] caches the policy from the parent settings and
///   loads only on demand. Reloaded.
/// - [KidsWorldGrowthController] caches the kids achievements and listens
///   only to kids-progress events, not the restore's `cloudPull`. Refreshed.
/// - [MemorizationPathResolver] holds no state, but the router re-reads the
///   memorization profile only when it fires. Notified.
/// - Every other store, datasource and repository on a restored key
///   (khatmah, hifz, azkar counters, daily reading, kids streak/receipts/
///   achievements, adult journey, tarawih) reads SharedPreferences or Isar on
///   each call; progress listeners are refreshed by the restore's `cloudPull`
///   event, and page cubits are recreated by the navigation to splash.
/// - Theme, locale, notifications, prayer, audio and bookmarks hold device
///   settings or data a backup does not carry.
Future<void> afterBackupRestore([GetIt? locator]) async {
  final getIt = locator ?? GetIt.instance;
  void step(String name, void Function() run) {
    try {
      run();
    } catch (e, st) {
      TaliaLogger.w('After-restore refresh of $name failed', e, st);
    }
  }

  if (getIt.isRegistered<ProfileCubit>()) {
    step('profile', () => getIt<ProfileCubit>().loadProfile());
  }
  if (getIt.isRegistered<KidsWorldGrowthController>()) {
    step('kids growth', () => getIt<KidsWorldGrowthController>().refresh());
  }
  if (getIt.isRegistered<MemorizationPathResolver>()) {
    step('path', () => getIt<MemorizationPathResolver>().notifyChanged());
  }
  if (getIt.isRegistered<KidsPolicyController>()) {
    try {
      await getIt<KidsPolicyController>().reload();
    } catch (e, st) {
      TaliaLogger.w('After-restore refresh of kids policy failed', e, st);
    }
  }
}
