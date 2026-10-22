import 'package:get_it/get_it.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/prayer_review/application/prayer_review_quran_reader.dart';
import '../../features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import '../../features/prayer_review/presentation/cubits/prayer_review_cubit.dart';
import '../../features/prayer_review/presentation/cubits/prayer_review_settings_cubit.dart';
import '../../features/prayer_companion/data/datasources/prayer_companion_preferences.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../experience/experience_feature_flags.dart';
import '../identity/account_data_barrier.dart';
import '../identity/record_owner_provider.dart';
import '../memorization/v2/review_effect_outbox_processor.dart';
import '../memorization/v2/self_grade.dart';
import '../prayer_review/manual_prayer_review_committer.dart';
import '../prayer_review/prayer_review_lengths.dart';
import '../prayer_review/prayer_review_offer_service.dart';
import '../prayer_review/prayer_review_notification_text.dart';
import '../prayer_review/prayer_review_prompt_coordinator.dart';
import '../prayer_review/prayer_review_home_loader.dart';
import '../services/activity_event_recorder.dart';
import '../services/prayer_times_service.dart';
import '../progress/progress_events_bus.dart';

/// Lazy registration leaves the disabled feature's database and readers idle.
void registerPrayerReviewDependencies(GetIt services) {
  services.registerLazySingleton<IsarPrayerReviewRepository>(
    () => IsarPrayerReviewRepository(
      services<Isar>(),
      services<RecordOwnerProvider>(),
      _barrier(services),
    ),
  );
  services.registerLazySingleton<PrayerReviewLengths>(
    () =>
        PrayerReviewLengths(services<SharedPreferences>(), _barrier(services)),
  );
  services.registerLazySingleton<PrayerReviewQuranReader>(
    () => PrayerReviewQuranReader(services<QuranRepository>()),
  );
  _registerOffer(services);
  services.registerLazySingleton<PrayerReviewNotificationText>(
    () => PrayerReviewNotificationText(services<PrayerReviewOfferService>()),
  );
  _registerCommitter(services);
  _registerPrompt(services);
  _registerSurfaces(services);
  services.registerFactory<PrayerReviewCubit>(
    () => PrayerReviewCubit(
      captureAuthority: services<IsarPrayerReviewRepository>().captureAuthority,
      accountChanges: _barrier(services).changes,
      loadOffer: services<PrayerReviewOfferService>().forOccurrence,
      readPassage: services<PrayerReviewQuranReader>().readPassage,
      saveGrade: (offer, grade) => _save(services, offer, grade),
    ),
  );
}

void _registerSurfaces(GetIt services) {
  services.registerLazySingleton<PrayerReviewHomeLoader>(
    () => PrayerReviewHomeLoader(
      offers: services<PrayerReviewOfferService>(),
      isEnabled: () => _enabled(services),
      readAdultEligibility: () => _adult(services),
      readSettings: () async => services<PrayerCompanionPreferences>().read(),
      readPrayerTimes: () =>
          services<PrayerTimesService>().current(isArabic: true),
      accountChanges: _barrier(services).changes,
    ),
  );
  services.registerFactory<PrayerReviewSettingsCubit>(
    () => PrayerReviewSettingsCubit(
      isEnabled: () => _enabled(services),
      captureAuthority: services<PrayerReviewOfferService>().captureAuthority,
      readAdultEligibility: () => _adult(services),
      readLength: services<PrayerReviewLengths>().read,
      writeLength: (owner, prayer, length, authority) =>
          services<PrayerReviewLengths>().write(
            owner,
            prayer,
            length,
            authority.lease,
          ),
      accountChanges: _barrier(services).changes,
    ),
  );
}

void _registerPrompt(GetIt services) {
  services.registerLazySingleton<PrayerReviewPromptCoordinator>(
    () => PrayerReviewPromptCoordinator(
      captureAuthority: services<PrayerReviewOfferService>().captureAuthority,
      isEnabled: () => _enabled(services),
      readAdultEligibility: () => _adult(services),
      loadExisting: (occurrence) => services<PrayerReviewOfferService>()
          .forOccurrence(occurrence, allowSelection: false),
      claimPrompt: services<IsarPrayerReviewRepository>().consumePrompt,
    ),
  );
}

void _registerOffer(GetIt services) {
  services.registerLazySingleton<PrayerReviewOfferService>(
    () => PrayerReviewOfferService(
      repository: services<IsarPrayerReviewRepository>(),
      lengths: services<PrayerReviewLengths>(),
      isEnabled: () => _enabled(services),
      captureAuthority: services<IsarPrayerReviewRepository>().captureAuthority,
      readAdultEligibility: () => _adult(services),
      readRecords: () async =>
          (await services<MemorizationPlusRepository>().getAllReviewRecords())
              .fold((failure) => throw failure, (rows) => rows),
      readCanonicalAyahs: services<PrayerReviewQuranReader>().readCanonical,
    ),
  );
}

void _registerCommitter(GetIt services) {
  services.registerLazySingleton<ManualPrayerReviewCommitter>(
    () => ManualPrayerReviewCommitter(
      isar: services<Isar>(),
      barrier: _barrier(services),
      scheduler: services<ScheduleNextReviewUsecase>(),
      isEnabled: () => _enabled(services),
      readAdultEligibility: () => _adult(services),
      progressEvents: services<ProgressEventsBus>(),
      activityRecorder: services.isRegistered<ActivityEventRecorder>()
          ? services<ActivityEventRecorder>()
          : null,
    ),
  );
}

Future<ManualPrayerReviewResult> _save(
  GetIt services,
  PrayerReviewOffer offer,
  V2SelfGrade grade,
) async {
  final result = await services<ManualPrayerReviewCommitter>().commit(
    selection: offer.selection,
    grade: grade,
    authority: offer.authority,
  );
  try {
    offer.authority.check();
    await services<V2ReviewEffectOutboxProcessor>().processPending();
  } catch (_) {
    // The durable review stays successful; pending effects retain their retry
    // receipts and must never cause a second scheduling of this passage.
  }
  return result;
}

AccountDataBarrier _barrier(GetIt services) =>
    AccountDataBarrier.forPreferences(services<SharedPreferences>());

bool _enabled(GetIt services) =>
    services<ExperienceFlags>().isEnabled(ExperienceFeature.prayerReview);

Future<bool> _adult(GetIt services) async =>
    (await services<MemorizationPlusRepository>().getMemorizationProfile())
        .fold((_) => false, (profile) => profile.isAdult);
