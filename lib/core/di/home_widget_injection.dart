import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../experience/experience_feature_flags.dart';
import '../home_widget/home_widget_publisher.dart';
import '../home_widget/platform_home_widget_bridge.dart';
import '../home_widget/widget_section_preferences.dart';
import '../home_widget/widget_snapshot_source.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../l10n/locale_cubit.dart';
import '../memorization/memorization_path_resolver.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../services/prayer_times_service.dart';

Future<void> registerHomeWidget(GetIt getIt) async {
  final owner = getIt<RecordOwnerProvider>();
  final path = getIt<MemorizationPathResolver>();
  final barrier = AccountDataBarrier.forPreferences(getIt<SharedPreferences>());
  final khatmah = getIt<KhatmahRepository>();
  // The widget is adult-only: a child or guardian-less kids device must not
  // be offered it in the launcher, so the receiver also needs an adult.
  var adult = (await path.currentProfile())?.isAdult == true;
  // Audience changes reach the publisher only after [adult] is updated.
  final audienceChanges = path.changes.asyncMap((_) async {
    try {
      adult = (await path.currentProfile())?.isAdult == true;
    } catch (_) {
      adult = false;
    }
  }).asBroadcastStream();
  bool flagOn() =>
      adult &&
      getIt<ExperienceFlags>().isEnabled(ExperienceFeature.homeWidget);
  final source = WidgetSnapshotSource(
    owner: owner,
    records: getIt<MemorizationPlusRepository>(),
    path: path,
    prayers: getIt<PrayerTimesService>(),
    khatmah: khatmah,
    isEnabled: flagOn,
    sections: WidgetSectionPreferences(getIt<SharedPreferences>()),
    languageCode: () => getIt<LocaleCubit>().state.languageCode,
  );
  final publisher = HomeWidgetPublisher(
    bridge: PlatformHomeWidgetBridge(),
    load: source.load,
    owner: owner,
    barrier: barrier,
    authorityChanges: [audienceChanges],
    isEnabled: flagOn,
    // ExperienceFlags has no change signal; the publisher re-reads the flag on
    // every refresh (start, resume, progress) and applies off -> clear and
    // disable receiver, on -> enable receiver. A future signal plugs into
    // `flagChanges` without further wiring.
    audience: () async => (await path.currentProfile())?.isAdult == true,
    refreshTriggers: [
      getIt<ProgressEventsBus>().changes
          .where(
            (reason) =>
                reason == ProgressChangedReason.reviewRecord ||
                reason == ProgressChangedReason.cloudPull,
          )
          .map<void>((_) {}),
      ?khatmah.changes,
      // The widget follows the app language, not the device language.
      getIt<LocaleCubit>().stream.map<void>((_) {}),
    ],
  );
  getIt.registerSingleton<HomeWidgetPublisher>(
    publisher,
    dispose: (value) => value.dispose(),
  );
  await publisher.start();
}
