import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../services/audio_cache_service.dart';
import '../services/app_session_service.dart';
import '../services/notification_service.dart';
import '../services/streak_service.dart';
import '../services/xp_service.dart';
import '../services/subscription_service.dart';
import '../services/achievement_service.dart';
import '../theme/theme_cubit.dart';
import '../l10n/locale_cubit.dart';
import '../../features/quran/data/datasources/quran_local_datasource.dart';
import '../../features/quran/data/datasources/bookmark_service.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/domain/usecases/get_surahs_usecase.dart';
// GetSurahDetailUsecase is defined in get_surahs_usecase.dart
import '../../features/quran/presentation/cubits/surah_list_cubit.dart';
import '../../features/quran/presentation/cubits/surah_detail_cubit.dart';
import '../../features/quran/presentation/cubits/quran_page_cubit.dart';
import '../../features/quran/presentation/cubits/search_quran_cubit.dart';
import '../../features/hifz/data/datasources/hifz_local_datasource.dart';
import '../../features/hifz/data/datasources/isar_hifz_local_datasource_impl.dart';
import '../../features/hifz/data/models/isar_ayah_progress.dart';
import '../../features/hifz/data/repositories/hifz_repository_impl.dart';
import '../../features/hifz/domain/repositories/hifz_repository.dart';
import '../../features/hifz/domain/usecases/get_hifz_progress_usecase.dart';
import '../../features/hifz/domain/usecases/save_ayah_progress_usecase.dart';
import '../../features/hifz/presentation/cubits/hifz_cubit.dart';
import '../../features/hifz/presentation/cubits/hifz_session_cubit.dart';
import '../../features/azkar/data/datasources/azkar_local_datasource.dart';
import '../../features/azkar/data/repositories/azkar_repository_impl.dart';
import '../../features/azkar/domain/repositories/azkar_repository.dart';
import '../../features/azkar/domain/usecases/get_azkar_usecase.dart';
import '../../features/azkar/presentation/cubits/azkar_cubit.dart';
import '../../features/progress/data/datasources/progress_local_datasource.dart';
import '../../features/progress/data/repositories/progress_repository_impl.dart';
import '../../features/progress/domain/repositories/progress_repository.dart';
import '../../features/progress/domain/usecases/get_progress_usecase.dart';
import '../../features/progress/domain/usecases/save_read_page_usecase.dart';
import '../../features/progress/presentation/cubits/progress_cubit.dart';
import '../../features/home/presentation/cubits/home_cubit.dart';
import '../../features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import '../../features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import '../../features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import '../../features/memorization_plus/presentation/cubits/daily_plan_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/kids_journey_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/parent_dashboard_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/track_selection_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/quiz_cubit.dart';
import '../../features/settings/presentation/cubits/profile_cubit.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/streak/data/models/streak_isar.dart';
import '../../features/streak/data/models/daily_activity_isar.dart';
import '../../features/streak/presentation/cubits/streak_cubit.dart';
import '../../features/xp/data/models/xp_isar.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ─── External ───────────────────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    IsarAyahProgressSchema,
    StreakIsarSchema,
    XpIsarSchema,
    DailyActivityIsarSchema, // For yearly activity heatmap
  ], directory: dir.path);
  getIt.registerSingleton<Isar>(isar);

  // Migrate old SharedPreferences Hifz data to Isar if needed
  final hifzDatasource = IsarHifzLocalDatasourceImpl(isar, sharedPrefs);
  await hifzDatasource.migrateFromSharedPreferencesIfNeeded();
  getIt.registerLazySingleton<HifzLocalDatasource>(() => hifzDatasource);

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
  getIt.registerSingleton<AudioCacheService>(AudioCacheService.instance);
  getIt.registerSingleton<AppSessionService>(
    AppSessionService(getIt<SharedPreferences>()),
  );
  getIt.registerSingleton<TaliaNotificationService>(
    TaliaNotificationService.instance,
  );

  // ─── New Core Services ──────────────────────────────────────────────────────
  // ─── Datasources ────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ProgressLocalDatasource>(
    () => ProgressLocalDatasourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<MemorizationPlusLocalDatasource>(
    () => MemorizationPlusLocalDatasourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<QuranLocalDatasource>(
    () => QuranLocalDatasourceImpl(),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<BookmarkService>(
    () => BookmarkService(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<AzkarLocalDatasource>(
    () => AzkarLocalDatasourceImpl(),
  );

  // ─── Core Services ──────────────────────────────────────────────────────────
  getIt.registerSingleton<StreakService>(StreakService(getIt<Isar>()));
  getIt.registerSingleton<XpService>(XpService(getIt<Isar>()));
  getIt.registerSingleton<SubscriptionService>(SubscriptionService());
  getIt.registerSingleton<AchievementService>(
    AchievementService(
      getIt<SharedPreferences>(),
      hifzDatasource,
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
    ),
  );

  // ─── Repositories ───────────────────────────────────────────────────────────
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      getIt<ProgressLocalDatasource>(),
      getIt<HifzLocalDatasource>(),
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
    ),
  );
  getIt.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(getIt<QuranLocalDatasource>()),
  );
  getIt.registerLazySingleton<HifzRepository>(
    () => HifzRepositoryImpl(
      getIt<HifzLocalDatasource>(),
      getIt<QuranLocalDatasource>(),
    ),
  );
  getIt.registerLazySingleton<AzkarRepository>(
    () => AzkarRepositoryImpl(getIt<AzkarLocalDatasource>()),
  );
  getIt.registerLazySingleton<MemorizationPlusRepository>(
    () => MemorizationPlusRepositoryImpl(
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranRepository>(),
    ),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<Isar>()),
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
  getIt.registerLazySingleton<GetHifzProgressUsecase>(
    () => GetHifzProgressUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<GetProgressForSurahUsecase>(
    () => GetProgressForSurahUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<SaveAyahProgressUsecase>(
    () => SaveAyahProgressUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<GetHifzPathUsecase>(
    () => GetHifzPathUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<SaveHifzPathUsecase>(
    () => SaveHifzPathUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<GenerateHifzSegmentsUsecase>(
    () => const GenerateHifzSegmentsUsecase(),
  );
  getIt.registerLazySingleton<CheckNextAyahUnlockUsecase>(
    () => const CheckNextAyahUnlockUsecase(),
  );
  getIt.registerLazySingleton<GetNextRequiredReviewCheckpointUsecase>(
    () => const GetNextRequiredReviewCheckpointUsecase(),
  );
  getIt.registerLazySingleton<GetPassedCheckpointKeysUsecase>(
    () => GetPassedCheckpointKeysUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<MarkCheckpointReviewPassedUsecase>(
    () => MarkCheckpointReviewPassedUsecase(getIt<HifzRepository>()),
  );
  getIt.registerLazySingleton<GetAzkarUsecase>(
    () => GetAzkarUsecase(getIt<AzkarRepository>()),
  );
  getIt.registerLazySingleton<GenerateDailyPlanUsecase>(
    () => GenerateDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<EvaluateMemorizationUsecase>(
    () => EvaluateMemorizationUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<MarkAyahMemorizedUsecase>(
    () => MarkAyahMemorizedUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetCachedDailyPlanUsecase>(
    () => GetCachedDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
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
  getIt.registerLazySingleton<SaveDailyPlanUsecase>(
    () => SaveDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetKidsJourneyUsecase>(
    () => GetKidsJourneyUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<SaveKidsSessionLogUsecase>(
    () => SaveKidsSessionLogUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<GetParentDashboardUsecase>(
    () => GetParentDashboardUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<ParentAccessUsecase>(
    () => ParentAccessUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<ParentRemoteLinkUsecase>(
    () => ParentRemoteLinkUsecase(getIt<MemorizationPlusRepository>()),
  );

  // ─── Cubits ─────────────────────────────────────────────────────────────────
  getIt.registerFactory<ProgressCubit>(
    () => ProgressCubit(getIt<GetProgressUsecase>()),
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
    ),
  );
  getIt.registerFactory<SearchQuranCubit>(
    () => SearchQuranCubit(getIt<QuranRepository>()),
  );
  getIt.registerFactory<HifzCubit>(
    () => HifzCubit(
      getIt<GetSurahsUsecase>(),
      getIt<GetHifzProgressUsecase>(),
      getIt<GetHifzPathUsecase>(),
      getIt<SaveHifzPathUsecase>(),
    ),
  );
  getIt.registerFactory<HifzSessionCubit>(
    () => HifzSessionCubit(
      getIt<GetSurahsUsecase>(),
      getIt<GetSurahDetailUsecase>(),
      getIt<SaveAyahProgressUsecase>(),
      getIt<GetProgressForSurahUsecase>(),
      getIt<GetHifzProgressUsecase>(),
      getIt<GetHifzPathUsecase>(),
      getIt<GenerateHifzSegmentsUsecase>(),
      getIt<CheckNextAyahUnlockUsecase>(),
      getIt<GetNextRequiredReviewCheckpointUsecase>(),
      getIt<GetPassedCheckpointKeysUsecase>(),
      getIt<MarkCheckpointReviewPassedUsecase>(),
      getIt<SettingsRepository>(),
      getIt<StreakService>(),
      getIt<XpService>(),
      getIt<AchievementService>(),
    ),
  );
  getIt.registerFactory<AzkarCubit>(
    () => AzkarCubit(getIt<GetAzkarUsecase>(), getIt<SharedPreferences>()),
  );
  getIt.registerFactory<TrackSelectionCubit>(
    () => TrackSelectionCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<DailyPlanCubit>(
    () => DailyPlanCubit(
      getIt<GenerateDailyPlanUsecase>(),
      getIt<GetCachedDailyPlanUsecase>(),
      getIt<EvaluateMemorizationUsecase>(),
      getIt<SaveDailyPlanUsecase>(),
      getIt<AchievementService>(),
      getIt<StreakService>(), // RISK-5 FIX
      getIt<XpService>(), // RISK-5 FIX
    ),
  );
  getIt.registerFactory<KidsModeCubit>(
    () => KidsModeCubit(
      getIt<GetKidsProgressUsecase>(),
      getIt<AwardKidsPointsUsecase>(),
      getIt<MarkAyahMemorizedUsecase>(),
      getIt<SaveKidsSessionLogUsecase>(),
      getIt<AchievementService>(),
      getIt<QuranRepository>(),
      getIt<StreakService>(), // RISK-5 FIX
      getIt<XpService>(), // RISK-5 FIX
    ),
  );
  getIt.registerFactory<CustomPlanCubit>(
    () => CustomPlanCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<KidsJourneyCubit>(
    () => KidsJourneyCubit(
      getIt<GetKidsJourneyUsecase>(),
      getIt<GetKidsProgressUsecase>(),
      getIt<ParentRemoteLinkUsecase>(),
    ),
  );
  getIt.registerFactory<ParentDashboardCubit>(
    () => ParentDashboardCubit(
      getIt<GetParentDashboardUsecase>(),
      getIt<ParentAccessUsecase>(),
      getIt<ParentRemoteLinkUsecase>(),
    ),
  );
  getIt.registerFactory<QuizCubit>(
    () => QuizCubit(
      getIt<MemorizationPlusRepository>(),
      getIt<QuranRepository>(),
      getIt<AchievementService>(),
    ),
  );
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      getIt<GetProgressUsecase>(),
      getIt<GetHifzProgressUsecase>(),
      getIt<GetQuranPageUsecase>(),
      getIt<GetCustomPlanUsecase>(),
    ),
  );
  getIt.registerFactory<StreakCubit>(() => StreakCubit(getIt<StreakService>()));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt<AuthRepository>()));
}
