import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../experience/experience_feature_flags.dart';
import '../home_widget/home_widget_publisher.dart';
import '../home_widget/platform_home_widget_bridge.dart';
import '../home_widget/widget_snapshot_source.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/memorization_path_resolver.dart';
import '../progress/progress_changed_reason.dart';
import '../progress/progress_events_bus.dart';
import '../services/prayer_times_service.dart';

Future<void> registerHomeWidget(GetIt getIt) async {
  final owner = getIt<RecordOwnerProvider>();
  final path = getIt<MemorizationPathResolver>();
  final barrier = AccountDataBarrier.forPreferences(getIt<SharedPreferences>());
  final khatmah = getIt<KhatmahRepository>();
  final source = WidgetSnapshotSource(
    owner: owner,
    records: getIt<MemorizationPlusRepository>(),
    path: path,
    prayers: getIt<PrayerTimesService>(),
    khatmah: khatmah,
    isEnabled: () =>
        getIt<ExperienceFlags>().isEnabled(ExperienceFeature.homeWidget),
  );
  final publisher = HomeWidgetPublisher(
    bridge: PlatformHomeWidgetBridge(),
    load: source.load,
    owner: owner,
    barrier: barrier,
    authorityChanges: [path.changes],
    refreshTriggers: [
      getIt<ProgressEventsBus>().changes
          .where(
            (reason) =>
                reason == ProgressChangedReason.reviewRecord ||
                reason == ProgressChangedReason.cloudPull,
          )
          .map<void>((_) {}),
      ?khatmah.changes,
    ],
  );
  getIt.registerSingleton<HomeWidgetPublisher>(
    publisher,
    dispose: (value) => value.dispose(),
  );
  await publisher.start();
}
