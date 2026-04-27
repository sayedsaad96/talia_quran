import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../services/audio_cache_service.dart';
import '../services/notification_service.dart';
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
import '../../features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/track_selection_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import '../../features/memorization_plus/presentation/cubits/quiz_cubit.dart';
import '../../features/settings/presentation/cubits/profile_cubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ─── External ───────────────────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [IsarAyahProgressSchema],
    directory: dir.path,
  );
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
  getIt.registerSingleton<TaliaNotificationService>(
    TaliaNotificationService.instance,
  );

  // ─── Progress ───────────────────────────────────────────────────────────────
  
  getIt.registerLazySingleton<ProgressLocalDatasource>(
    () => ProgressLocalDatasourceImpl(getIt<SharedPreferences>()),
  );
  
  // Register hifz datasource here so we can satisfy progress repository dependencies early
  getIt.registerLazySingleton<HifzLocalDatasource>(
    () => HifzLocalDatasourceImpl(getIt<SharedPreferences>()),
  );

  // Register MemorizationPlus datasource early — required by ProgressRepository
  getIt.registerLazySingleton<MemorizationPlusLocalDatasource>(
    () => MemorizationPlusLocalDatasourceImpl(getIt<SharedPreferences>()),
  );

  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositoryImpl(
      getIt<ProgressLocalDatasource>(),
      getIt<HifzLocalDatasource>(),
      getIt<MemorizationPlusLocalDatasource>(),
    ),
  );
  getIt.registerLazySingleton<GetProgressUsecase>(
    () => GetProgressUsecase(getIt<ProgressRepository>()),
  );
  getIt.registerLazySingleton<SaveReadPageUsecase>(
    () => SaveReadPageUsecase(getIt<ProgressRepository>()),
  );
  getIt.registerFactory<ProgressCubit>(
    () => ProgressCubit(getIt<GetProgressUsecase>()),
  );

  // ─── Quran ──────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<QuranLocalDatasource>(
    () => QuranLocalDatasourceImpl(),
  );
  getIt.registerLazySingleton<BookmarkService>(
    () => BookmarkService(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<QuranRepository>(
    () => QuranRepositoryImpl(getIt<QuranLocalDatasource>()),
  );
  getIt.registerLazySingleton<GetSurahsUsecase>(
    () => GetSurahsUsecase(getIt<QuranRepository>()),
  );
  getIt.registerLazySingleton<GetSurahDetailUsecase>(
    () => GetSurahDetailUsecase(getIt<QuranRepository>()),
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
    ),
  );
  getIt.registerFactory<SearchQuranCubit>(
    () => SearchQuranCubit(getIt<QuranRepository>()),
  );

  // ─── Hifz ───────────────────────────────────────────────────────────────────
  // HifzLocalDatasource is now registered earlier above.
  getIt.registerLazySingleton<HifzRepository>(
    () => HifzRepositoryImpl(getIt<HifzLocalDatasource>(), getIt<QuranLocalDatasource>()),
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
      getIt<GetSurahDetailUsecase>(),
      getIt<SaveAyahProgressUsecase>(),
      getIt<GetProgressForSurahUsecase>(),
      getIt<SharedPreferences>(),
    ),
  );

  // ─── Azkar ──────────────────────────────────────────────────────────────────
  getIt.registerLazySingleton<AzkarLocalDatasource>(
    () => AzkarLocalDatasourceImpl(),
  );
  getIt.registerLazySingleton<AzkarRepository>(
    () => AzkarRepositoryImpl(getIt<AzkarLocalDatasource>()),
  );
  getIt.registerLazySingleton<GetAzkarUsecase>(
    () => GetAzkarUsecase(getIt<AzkarRepository>()),
  );
  getIt.registerFactory<AzkarCubit>(
    () => AzkarCubit(getIt<GetAzkarUsecase>(), getIt<SharedPreferences>()),
  );

  // ─── Home ───────────────────────────────────────────────────────────────────
  getIt.registerFactory<HomeCubit>(
    () => HomeCubit(
      getIt<GetProgressUsecase>(),
      getIt<GetHifzProgressUsecase>(),
      getIt<QuranRepository>(),
      getIt<MemorizationPlusRepository>(),
    ),
  );

  // ─── MemorizationPlus ────────────────────────────────────────────────────────
  // NOTE: MemorizationPlusLocalDatasource is already registered in the Progress section above.
  getIt.registerLazySingleton<MemorizationPlusRepository>(
    () => MemorizationPlusRepositoryImpl(
      getIt<MemorizationPlusLocalDatasource>(),
      getIt<QuranRepository>(),
    ),
  );
  getIt.registerLazySingleton<GenerateDailyPlanUsecase>(
    () => GenerateDailyPlanUsecase(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerLazySingleton<EvaluateMemorizationUsecase>(
    () => EvaluateMemorizationUsecase(getIt<MemorizationPlusRepository>()),
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
  getIt.registerFactory<TrackSelectionCubit>(
    () => TrackSelectionCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<DailyPlanCubit>(
    () => DailyPlanCubit(
      getIt<GenerateDailyPlanUsecase>(),
      getIt<GetCachedDailyPlanUsecase>(),
      getIt<EvaluateMemorizationUsecase>(),
      getIt<MemorizationPlusRepository>(),
    ),
  );
  getIt.registerFactory<KidsModeCubit>(
    () => KidsModeCubit(
      getIt<GetKidsProgressUsecase>(),
      getIt<AwardKidsPointsUsecase>(),
      getIt<QuranRepository>(),
    ),
  );
  getIt.registerFactory<CustomPlanCubit>(
    () => CustomPlanCubit(getIt<MemorizationPlusRepository>()),
  );
  getIt.registerFactory<QuizCubit>(
    () => QuizCubit(
      getIt<MemorizationPlusRepository>(),
      getIt<QuranRepository>(),
    ),
  );
}
