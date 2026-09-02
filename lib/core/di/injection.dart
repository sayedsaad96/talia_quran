import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../services/audio_cache_service.dart';
import '../services/app_session_service.dart';
import '../services/app_version_service.dart';
import '../services/hifz_migration_service.dart';
import '../services/notification_service.dart';
import '../services/notification_scheduler.dart';
import '../services/quran_continuous_player_service.dart';
import '../services/quran_reciter_service.dart';
import '../../features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import '../services/streak_reader.dart';
import '../services/streak_service.dart';
import '../services/xp_service.dart';
import '../services/achievement_service.dart';
import '../theme/theme_cubit.dart';
import '../l10n/locale_cubit.dart';
import '../memorization/review_record_audience_scope.dart';
import '../memorization/kids_hifz_feature_flags.dart';
import '../memorization/memorization_path_resolver.dart';
import '../memorization/pending_ayah_resolver.dart';
import '../memorization/smart_coach_engine.dart';
import '../memorization/usecases/get_smart_coach_recommendation_usecase.dart';
import '../memorization/memorization_progress_reader.dart';
import '../memorization/progress_metrics_service.dart';
import '../memorization/usecases/get_memorization_snapshot_usecase.dart';
import '../memorization/v2/session_adapters.dart';
import '../memorization/v2/session_engine.dart';
import '../memorization/v2/session_phase.dart';
import '../progress/progress_events_bus.dart';
import '../identity/record_owner_provider.dart';
import '../sync/cloud_sync_queue.dart';
import '../sync/cloud_sync_queue_item.dart';
import '../sync/background_sync_scheduler.dart';
import '../security/parent_pin_secure_store.dart';
import '../security/encrypted_account_preferences_store.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/data/services/quran_warmup_service.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/usecases/get_surahs_usecase.dart';
// GetSurahDetailUsecase is defined in get_surahs_usecase.dart
import '../../features/quran/presentation/cubits/surah_list_cubit.dart';
import '../../features/quran/presentation/cubits/surah_detail_cubit.dart';
import '../../features/quran/presentation/cubits/quran_page_cubit.dart';
import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
import '../../features/hifz/data/datasources/isar_hifz_local_datasource_impl.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/hifz/data/repositories/hifz_repository_impl.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/memorization_plus/presentation/cubits/practice_surah_cubit.dart';
import '../../features/azkar/data/datasources/azkar_local_datasource.dart';
import '../../features/azkar/data/repositories/azkar_repository_impl.dart';
import '../../features/azkar/domain/repositories/azkar_repository.dart';
import '../../features/azkar/domain/usecases/get_azkar_usecase.dart';
import '../../features/azkar/presentation/cubits/azkar_cubit.dart';
import '../journey/unified_journey_engine.dart';
import '../../features/progress/data/datasources/progress_local_datasource.dart';
import '../../features/progress/data/repositories/progress_repository_impl.dart';
import '../../features/progress/domain/repositories/progress_repository.dart';
import '../../features/progress/domain/usecases/get_progress_usecase.dart';
import '../../features/progress/domain/usecases/save_read_page_usecase.dart';
import '../../features/progress/presentation/cubits/progress_cubit.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';
import '../../features/home/data/repositories/heatmap_repository_impl.dart';
import '../../features/home/domain/repositories/heatmap_repository.dart';
import '../../features/home/domain/usecases/get_activity_heatmap_usecase.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../features/memorization_plus/data/models/isar_ayah_review_record.dart';
import '../../features/memorization_plus/data/models/isar_v2_session.dart';
import '../../features/memorization_plus/data/datasources/v2_session_local_datasource.dart';
import '../../features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import '../../features/memorization_plus/domain/entities/kids_session_policy.dart';
import '../../features/memorization_plus/domain/navigation/kids_next_mission_resolver.dart';
import '../../features/memorization_plus/domain/repositories/memorization_cloud_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_identity_repository.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/memorization_plus/presentation/cubits/guardian_linking_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import '../../features/onboarding/presentation/cubits/onboarding_cubit.dart';
import '../../features/settings/presentation/cubits/profile_cubit.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/presentation/cubits/streak_cubit.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/application/cloud_sync_coordinator.dart';
import '../identity/account_data_reset.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/khatmah/data/datasources/khatmah_local_datasource.dart';
import '../../features/khatmah/data/repositories/khatmah_repository_impl.dart';
import '../../features/khatmah/domain/repositories/khatmah_repository.dart';
import '../../features/khatmah/domain/usecases/complete_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import '../../features/khatmah/domain/usecases/update_khatmah_progress_usecase.dart';
import '../../features/khatmah/presentation/cubits/khatmah_cubit.dart';
import '../../features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({bool background = false}) async {
  // ─── External ───────────────────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  final dir = await getApplicationDocumentsDirectory();
  final schemas = [
    IsarAyahProgressSchema,
    IsarAyahReviewRecordSchema,
    IsarV2SessionSchema, // V2 session persistence
    StreakIsarSchema,
    XpIsarSchema,
    DailyActivityIsarSchema, // For yearly activity heatmap
    CloudSyncQueueItemSchema,
  ];
  final isar =
      Isar.getInstance() ?? await Isar.open(schemas, directory: dir.path);
  getIt.registerSingleton<Isar>(isar);
  getIt.registerLazySingleton<V2SessionLocalDatasource>(
    () => V2SessionLocalDatasource(getIt<Isar>()),
  );

  // Migrate old SharedPreferences Hifz data to Isar if needed
  final hifzDatasource = IsarHifzLocalDatasourceImpl(isar, sharedPrefs);
  await hifzDatasource.migrateFromSharedPreferencesIfNeeded();
  getIt.registerLazySingleton<HifzLocalDatasource>(() => hifzDatasource);

  getIt.registerLazySingleton<RecordOwnerProvider>(
    () => const SupabaseRecordOwnerProvider(),
  );
  getIt.registerLazySingleton<ParentPinSecureStore>(
    () => FlutterParentPinSecureStore(),
  );
  getIt.registerLazySingleton<EncryptedAccountPreferencesStore>(
    () => FlutterEncryptedAccountPreferencesStore(),
  );
  getIt.registerLazySingleton<BackgroundSyncScheduler>(
    BackgroundSyncScheduler.new,
  );
  getIt.registerLazySingleton<CloudSyncQueue>(
    () => CloudSyncQueue(
      getIt<Isar>(),
      getIt<RecordOwnerProvider>(),
      scheduleBackgroundDelivery:
          getIt<BackgroundSyncScheduler>().scheduleAccountSync,
      requestForegroundSync: () => getIt<CloudSyncCoordinator>().run(),
    ),
  );
  getIt.registerLazySingleton<AccountDataReset>(
    () => AccountDataReset(
      getIt<Isar>(),
      getIt<SharedPreferences>(),
      parentPinStore: getIt<ParentPinSecureStore>(),
      encryptedAccountPreferences: getIt<EncryptedAccountPreferencesStore>(),
      owner: getIt<RecordOwnerProvider>(),
      backgroundSyncScheduler: getIt<BackgroundSyncScheduler>(),
    ),
  );

  final memorizationPlusDatasource = MemorizationPlusLocalDatasourceImpl(
    sharedPrefs,
    isar: isar,
    owner: getIt<RecordOwnerProvider>(),
  );
  await memorizationPlusDatasource.migrateReviewRecordsToIsarIfNeeded();
  await memorizationPlusDatasource.migrateReviewRecordIdentityIfNeeded();

  // ─── Core ───────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<LocaleCubit>(
    () => LocaleCubit(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<ProfileCubit>(
    () => ProfileCubit(getIt<SharedPreferences>()),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getIt<MemorizationPlusRepository>(),
      getIt<SharedPreferences>(),
      getIt<MemorizationPathResolver>(),
      getIt<AppVersionInfoProvider>(),
    ),
  );
  getIt.registerSingleton<AudioCacheService>(AudioCacheService.instance);
  getIt.registerSingleton<QuranReciterService>(
    QuranReciterService(getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<AppSessionService>(
    AppSessionService(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<AppVersionInfoProvider>(
    () => const PackageInfoAppVersionInfoProvider(),
  );
  getIt.registerLazySingleton<TaliaNotificationService>(
    TaliaNotificationService.new,
  );
  getIt.registerLazySingleton<NotificationScheduler>(
    () => NotificationScheduler(
      getIt<TaliaNotificationService>(),
      kidsSessionDatesLoader: () async {
        if (!getIt.isRegistered<MemorizationPlusRepository>()) return [];
        final result = await getIt<MemorizationPlusRepository>()
            .getKidsSessionLogs();
        return result.fold(
          (_) => <DateTime>[],
          (logs) => logs.map((log) => log.completedAt).toList(),
        );
      },
    ),
  );
  getIt.registerSingleton<ProgressEventsBus>(ProgressEventsBus());

  // ─── New Core Services ──────────────────────────────────────────────────────
  // ─── Datasources ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ProgressLocalDatasource>(
    () => ProgressLocalDatasourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<MemorizationPlusLocalDatasource>(
    () => memorizationPlusDatasource,
  );
  getIt.registerLazySingleton<QuranLocalDatasource>(
    () => QuranLocalDatasourceImpl(),
  );
  getIt.registerLazySingleton<QuranWarmupService>(
    () => QuranWarmupService(
      datasource: getIt<QuranLocalDatasource>(),
      sessionService: getIt<AppSessionService>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<BookmarkService>(
    () => BookmarkService(
      getIt<SharedPreferences>(),
      owner: getIt<RecordOwnerProvider>(),
      cloudSyncQueue: getIt<CloudSyncQueue>(),
      encryptedAccountPreferences: getIt<EncryptedAccountPreferencesStore>(),
    ),
  );
  getIt.registerLazySingleton<AzkarLocalDatasource>(
    () => AzkarLocalDatasourceImpl(),
  );
  getIt.registerLazySingleton<KhatmahLocalDatasource>(
    () => KhatmahLocalDatasource(getIt<SharedPreferences>()),
  );

  // ─── Core Services ──────────────────────────────────────────────────────────
  getIt.registerSingleton<StreakService>(
    StreakService(getIt<Isar>(), getIt<ProgressEventsBus>()),
  );
  getIt.registerSingleton<StreakReader>(getIt<StreakService>());
  getIt.registerSingleton<XpService>(
    XpService(getIt<Isar>(), getIt<ProgressEventsBus>()),
  );
  getIt.registerLazySingleton<ProgressMetricsService>(
    () => const ProgressMetricsService(),
  );
  // Lazy (not eager) because it optionally depends on
  // MemorizationPlusRepository, which is registered further below — a lazy
  // singleton resolves its factory only on first use, once all
  // registrations in this function have completed.
  getIt.registerLazySingleton<AchievementService>(
    () => AchievementService(
      getIt<SharedPreferences>(),
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
      getIt<ProgressEventsBus>(),
      getIt<MemorizationPlusRepository>(),
      getIt<ProgressMetricsService>(),
      getIt<CloudSyncQueue>(),
    ),
  );

  // ─── Repositories ───────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      getIt<ProgressLocalDatasource>(),
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
      getIt<StreakReader>(),
      getIt<ProgressEventsBus>(),
      getIt<ProgressMetricsService>(),
    ),
  );
  getIt.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(getIt<QuranLocalDatasource>()),
  );
  getIt.registerLazySingleton<QuranContinuousPlayerService>(
    () => QuranContinuousPlayerService(
      quranRepository: getIt<QuranRepository>(),
      reciterService: getIt<QuranReciterService>(),
    ),
    dispose: (service) => service.dispose(),
  );
  getIt.registerLazySingleton<QuranAudioPlayerCubit>(
    () => QuranAudioPlayerCubit(getIt<QuranContinuousPlayerService>()),
  );
  getIt.registerLazySingleton<HifzRepository>(
    () => HifzRepositoryImpl(
      getIt<HifzLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
    ),
  );
  // One-time Hifz → V2 migration service (registered after both repos are ready).
  getIt.registerLazySingleton<HifzMigrationService>(
    () => HifzMigrationService(
      hifzRepository: getIt<HifzRepository>(),
      memPlusRepository: getIt<MemorizationPlusRepository>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<AzkarRepository>(
    () => AzkarRepositoryImpl(getIt<AzkarLocalDatasource>()),
  );
  getIt.registerLazySingleton<KhatmahRepository>(
    () => KhatmahRepositoryImpl(getIt<KhatmahLocalDatasource>()),
  );
  getIt.registerLazySingleton<MemorizationPlusRepository>(
    () => MemorizationPlusRepositoryImpl(
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranRepository>(),
      getIt<StreakReader>(),
      getIt<ProgressEventsBus>(),
      getIt<SharedPreferences>(),
      metrics: const ProgressMetricsService(),
      cloudSyncQueue: getIt<CloudSyncQueue>(),
      parentPinStore: getIt<ParentPinSecureStore>(),
    ),
  );
  getIt.registerLazySingleton<MemorizationIdentityRepository>(
    () => getIt<MemorizationPlusRepository>() as MemorizationIdentityRepository,
  );
  getIt.registerLazySingleton<MemorizationCloudRepository>(
    () => getIt<MemorizationPlusRepository>() as MemorizationCloudRepository,
  );
  getIt.registerLazySingleton<MemorizationPathResolver>(
    () => MemorizationPathResolver(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<MemorizationProgressReader>(
    () => MemorizationProgressReaderImpl(
      getIt<MemorizationPlusRepository>(),
      getIt<AppSessionService>(),
    ),
  );
  getIt.registerLazySingleton<GetMemorizationSnapshotUsecase>(
    () => GetMemorizationSnapshotUsecase(getIt<MemorizationProgressReader>()),
  );
  getIt.registerLazySingleton<SmartCoachEngine>(() => const SmartCoachEngine());
  getIt.registerLazySingleton<V2SessionEngine>(() => V2SessionEngine());
  // P0-01 FIX: ScheduleNextReviewUsecase is required by V2SessionReviewAdapter
  // but was never registered — caused a GetIt crash on first V2 session use.
  // The class is const with no dependencies, so a lazy singleton is sufficient.
  getIt.registerLazySingleton<ScheduleNextReviewUsecase>(
    () => const ScheduleNextReviewUsecase(),
  );
  getIt.registerLazySingleton<V2SessionReviewAdapter>(
    () => V2SessionReviewAdapter(
      repository: getIt<MemorizationPlusRepository>(),
      scheduler: getIt<ScheduleNextReviewUsecase>(),
      markDailyPlanCompleted: MarkDailyPlanAyahCompletedUsecase(
        getIt<MemorizationPlusRepository>(),
      ),
    ),
  );
  getIt.registerLazySingleton<PendingAyahResolver>(
    () => const PendingAyahResolver(),
  );
  getIt.registerLazySingleton<V2SessionProgressAdapter>(
    () =>
        V2SessionProgressAdapter(datasource: getIt<V2SessionLocalDatasource>()),
  );
  getIt.registerLazySingleton<V2SessionGamificationAdapter>(
    () => V2SessionGamificationAdapter(
      streakService: getIt<StreakService>(),
      xpService: getIt<XpService>(),
      achievementService: getIt<AchievementService>(),
    ),
  );
  getIt.registerLazySingleton<GetSmartCoachRecommendationUsecase>(
    () => GetSmartCoachRecommendationUsecase(
      getIt<GetMemorizationSnapshotUsecase>(),
      getIt<SmartCoachEngine>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<Isar>(),
      getIt<AccountDataReset>(),
      getIt<SharedPreferences>(),
    ),
  );
  getIt.registerLazySingleton<CloudSyncCoordinator>(
    () => CloudSyncCoordinator(
      authRepository: getIt<AuthRepository>(),
      memorizationCloudRepository: getIt<MemorizationCloudRepository>(),
      progressEvents: getIt<ProgressEventsBus>(),
      achievementService: getIt<AchievementService>(),
      cloudSyncQueue: getIt<CloudSyncQueue>(),
      bookmarkService: getIt<BookmarkService>(),
      syncBookmarks: !background,
    ),
    dispose: (coordinator) => coordinator.dispose(),
  );

  // ─── Usecases ───────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<GetProgressUsecase>(
    () => GetProgressUsecase(getIt<ProgressRepository>()),
  );
  getIt.registerLazySingleton<SaveReadPageUsecase>(
    () => SaveReadPageUsecase(getIt<ProgressRepository>()),
  );
  getIt.registerLazySingleton<GetSurahsUsecase>(
    () => GetSurahsUsecase(getIt<QuranRepository>()),
  );
  getIt.registerLazySingleton<GetSurahDetailUsecase>(
    () => GetSurahDetailUsecase(getIt<QuranRepository>()),
  );
  getIt.registerLazySingleton<HeatmapRepository>(
    () => HeatmapRepositoryImpl(getIt<Isar>()),
  );
  getIt.registerLazySingleton<GetActivityHeatmapUsecase>(
    () => GetActivityHeatmapUsecase(getIt<HeatmapRepository>()),
  );
  getIt.registerLazySingleton<GetAzkarUsecase>(
    () => GetAzkarUsecase(getIt<AzkarRepository>()),
  );
  getIt.registerLazySingleton<GetKidsProgressUsecase>(
    () => GetKidsProgressUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<AwardKidsPointsUsecase>(
    () => AwardKidsPointsUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetQuranPageUsecase>(
    () => GetQuranPageUsecase(getIt<QuranRepository>()),
  );
  getIt.registerLazySingleton<GetCustomPlanUsecase>(
    () => GetCustomPlanUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetKidsJourneyUsecase>(
    () => GetKidsJourneyUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<SaveKidsSessionLogUsecase>(
    () => SaveKidsSessionLogUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<ParentAccessUsecase>(
    () => ParentAccessUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<ParentRemoteLinkUsecase>(
    () => ParentRemoteLinkUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetFamilyDashboardUsecase>(
    () => GetFamilyDashboardUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetActiveKhatmahUsecase>(
    () => GetActiveKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<CreateKhatmahUsecase>(
    () => CreateKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<UpdateKhatmahProgressUsecase>(
    () => UpdateKhatmahProgressUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<CompleteKhatmahUsecase>(
    () => CompleteKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<PauseResumeKhatmahUsecase>(
    () => PauseResumeKhatmahUsecase(getIt<KhatmahRepository>()),
  );
  getIt.registerLazySingleton<DeleteKhatmahUsecase>(
    () => DeleteKhatmahUsecase(getIt<KhatmahRepository>()),
  );

  // ─── Cubits ─────────────────────────────────────────────────────────────────
  getIt.registerFactory<ProgressCubit>(
    () => ProgressCubit(
      getIt<GetProgressUsecase>(),
      getIt<MemorizationPathResolver>(),
      getIt<ProgressEventsBus>(),
    ),
  );
  getIt.registerFactory<SurahListCubit>(
    () => SurahListCubit(getIt<GetSurahsUsecase>()),
  );
  getIt.registerFactory<SurahDetailCubit>(
    () => SurahDetailCubit(getIt<GetSurahDetailUsecase>()),
  );
  getIt.registerFactory<QuranPageCubit>(
    () => QuranPageCubit(
      getIt<QuranRepository>(),
      getIt<SaveReadPageUsecase>(),
      getIt<StreakService>(),
      getIt<UpdateKhatmahProgressUsecase>(),
      getIt<GetActiveKhatmahUsecase>(),
    ),
  );
  getIt.registerFactory<PracticeSurahCubit>(
    () => PracticeSurahCubit(
      getIt<GetSurahsUsecase>(),
      getIt<MemorizationPlusRepository>(),
    ),
  );
  getIt.registerFactory<AzkarCubit>(
    () => AzkarCubit(getIt<GetAzkarUsecase>(), getIt<SharedPreferences>()),
  );
  getIt.registerFactory<GuardianLinkingCubit>(
    () => GuardianLinkingCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<MemorizationIdentityCubit>(
    () => MemorizationIdentityCubit(
      repository: getIt<MemorizationPlusRepository>(),
      pathResolver: getIt<MemorizationPathResolver>(),
    ),
  );
  getIt.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(
      prefs: getIt<SharedPreferences>(),
      memorizationRepository: getIt<MemorizationPlusRepository>(),
      pathResolver: getIt<MemorizationPathResolver>(),
    ),
  );
  getIt.registerFactory<KidsModeCubit>(
    () => KidsModeCubit(
      getIt<GetKidsProgressUsecase>(),
      getIt<GetKidsJourneyUsecase>(),
      getIt<AwardKidsPointsUsecase>(),
      getIt<AchievementService>(),
      getIt<QuranRepository>(),
      getIt<V2SessionEngine>(),
      getIt<V2SessionReviewAdapter>(),
      getIt<StreakService>(),
      null,
      getIt<AppSessionService>(),
      (pin) async => (await getIt<ParentAccessUsecase>().verifyPin(
        pin,
      )).getOrElse(() => false),
      () async {
        final result = await getIt<MemorizationPlusRepository>()
            .getMemorizationProfile();
        final age = result.fold((_) => 8, (profile) => profile.childAge ?? 8);
        return KidsSessionPolicy.forAge(age >= 5 && age <= 12 ? age : 8);
      },
      V2SessionProgressAdapter(
        datasource: getIt<V2SessionLocalDatasource>(),
        audience: MemorizationAudience.kids,
      ),
    ),
  );
  getIt.registerFactory<CustomPlanCubit>(
    () => CustomPlanCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<KidsJourneyCubit>(
    () => KidsJourneyCubit(
      getIt<GetKidsJourneyUsecase>(),
      getIt<GetKidsProgressUsecase>(),
      getIt<QuranRepository>(),
      reviewRecordsLoader: () async {
        final result = await getIt<MemorizationPlusRepository>()
            .getAllReviewRecords(scope: ReviewRecordReadScope.kids);
        return result.getOrElse(() => const []);
      },
      resumeMissionLoader: () async {
        final datasource = getIt<V2SessionLocalDatasource>();
        final saved = await datasource.getLatestSession(
          audience: MemorizationAudience.kids,
        );
        if (saved == null) return null;
        final phaseIndex = saved.phaseIndex;
        final phaseIsValid =
            phaseIndex >= 0 && phaseIndex < V2SessionPhase.values.length;
        final hasBlock = saved.blockAyahNumbers.isNotEmpty;
        if (!phaseIsValid || !hasBlock) return null;
        final phase = V2SessionPhase.values[phaseIndex];
        if (phase == V2SessionPhase.created || phase.isTerminal) {
          await datasource.clearSession(
            saved.surahId,
            audience: MemorizationAudience.kids,
          );
          return null;
        }
        final currentIndex = saved.currentAyahIndex.clamp(
          0,
          saved.blockAyahNumbers.length - 1,
        );
        return KidsNextMission(
          type: KidsMissionType.resume,
          surahId: saved.surahId,
          ayahNumbers: [saved.blockAyahNumbers[currentIndex]],
        );
      },
      v2Enabled: KidsHifzFeatureFlags.isEnabled(getIt<SharedPreferences>()),
    ),
  );

  getIt.registerFactory<FamilyDashboardCubit>(
    () => FamilyDashboardCubit(
      getIt<ParentAccessUsecase>(),
      getIt<ParentRemoteLinkUsecase>(),
      getIt<GetFamilyDashboardUsecase>(),
    ),
  );
  getIt.registerFactory<MemorizationSessionCubit>(
    () => MemorizationSessionCubit(
      quranRepository: getIt<QuranRepository>(),
      memorizationRepository: getIt<MemorizationPlusRepository>(),
      sessionEngine: getIt<V2SessionEngine>(),
      reviewAdapter: getIt<V2SessionReviewAdapter>(),
      progressAdapter: getIt<V2SessionProgressAdapter>(),
      gamificationAdapter: getIt<V2SessionGamificationAdapter>(),
      appSessionService: getIt<AppSessionService>(),
    ),
  );

  getIt.registerSingleton<UnifiedJourneyEngine>(const UnifiedJourneyEngine());

  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      getIt<GetProgressUsecase>(),
      getIt<GetQuranPageUsecase>(),
      getIt<GetCustomPlanUsecase>(),
      getIt<MemorizationPlusRepository>(),
      getIt<AppSessionService>(),
      getIt<GetActivityHeatmapUsecase>(),
      getIt<MemorizationPathResolver>(),
      getIt<GetSmartCoachRecommendationUsecase>(),
      getIt<UnifiedJourneyEngine>(),
      getIt<SharedPreferences>(),
      getIt<ProgressEventsBus>(),
      getIt<XpService>(),
      getIt<GetActiveKhatmahUsecase>(),
    ),
  );
  getIt.registerFactory<StreakCubit>(
    () => StreakCubit(getIt<StreakService>(), getIt<ProgressEventsBus>()),
  );
  getIt.registerFactory<KhatmahCubit>(
    () => KhatmahCubit(
      getIt<GetActiveKhatmahUsecase>(),
      getIt<UpdateKhatmahProgressUsecase>(),
      getIt<CompleteKhatmahUsecase>(),
      getIt<PauseResumeKhatmahUsecase>(),
      getIt<DeleteKhatmahUsecase>(),
    ),
  );
  getIt.registerFactory<KhatmahSetupCubit>(
    () => KhatmahSetupCubit(getIt<CreateKhatmahUsecase>()),
  );
  getIt.registerSingleton<AuthCubit>(
    AuthCubit(
      getIt<AuthRepository>(),
      getIt<MemorizationPlusRepository>(),
      getIt<ProgressEventsBus>(),
      getIt<AchievementService>(),
      getIt<CloudSyncQueue>(),
      getIt<SharedPreferences>(),
      getIt<AccountDataReset>(),
      getIt<CloudSyncCoordinator>(),
    ),
  );
}
