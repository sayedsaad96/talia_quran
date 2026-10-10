import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/progress_metrics_service.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/widgets/app_shell.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/progress/progress_changed_reason.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_custom_plan_service.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/memorization_daily_plan_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/get_plan_details_usecase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/plan_details_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_tab_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/plan_details_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/memorization_tab_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/memorization_hub_page.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _Repository extends Mock implements MemorizationPlusRepository {}

class _Quran extends Mock implements QuranRepository {}

class _Datasource extends Mock implements MemorizationPlusLocalDatasource {}

class _IdleAudioService extends Fake implements QuranContinuousPlayerService {
  @override
  final ValueNotifier<ContinuousPlaybackState> stateNotifier = ValueNotifier(
    const ContinuousPlaybackState(),
  );
  @override
  ContinuousPlaybackState get state => stateNotifier.value;
}

void main() {
  late _Repository repository;
  late MemorizationCustomPlanService custom;
  late MemorizationDailyPlanService daily;
  late ProgressEventsBus events;
  late GoRouter router;
  late MemorizationPathResolver paths;
  late QuranAudioPlayerCubit audio;
  late _IdleAudioService player;
  CustomMemorizationPlanModel? customCache;
  DailyPlanModel? dailyCache;
  late List<AyahReviewRecordModel> records;

  final metadata =
      (jsonDecode(File('assets/data/surahs.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final surahs = metadata
      .map(
        (row) => Surah(
          id: row['id'] as int,
          nameAr: row['nameAr'] as String,
          nameEn: row['nameEn'] as String,
          ayahCount: row['ayahCount'] as int,
          juz: row['juz'] as int,
          type: row['type'] as String,
          page: row['page'] as int,
        ),
      )
      .toList();
  final corpus =
      jsonDecode(File('assets/data/quran.json').readAsStringSync())
          as Map<String, dynamic>;
  final plan = CustomMemorizationPlan(
    name: 'My saved plan',
    startSurahId: 67,
    endSurahId: 67,
    startAyah: 1,
    newAyahsPerDay: 3,
    availableDaysPerWeek: 7,
    sessionMinutes: 30,
    difficulty: MemorizationDifficulty.moderate,
    enableNearRevision: true,
    enableFarRevision: true,
    nearRevisionCount: 5,
    farRevisionCount: 3,
    createdAt: DateTime.now().toUtc(),
  );

  setUp(() async {
    registerFallbackValue(ReviewRecordReadScope.adult);
    await getIt.reset();
    records = [];
    customCache = CustomMemorizationPlanModel.fromEntity(plan);
    dailyCache = null;
    events = ProgressEventsBus();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final datasource = _Datasource();
    final quran = _Quran();
    repository = _Repository();
    paths = MemorizationPathResolver(repository);
    player = _IdleAudioService();
    audio = QuranAudioPlayerCubit(player);
    registerFallbackValue(plan);
    registerFallbackValue(CustomMemorizationPlanModel.fromEntity(plan));
    registerFallbackValue(
      DailyPlanModel.fromEntity(
        DailyPlan(
          generatedAt: DateTime.now().toUtc(),
          surahId: 67,
          newAyahs: const [],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [],
        ),
      ),
    );
    when(() => datasource.getCustomPlan()).thenAnswer((_) async => customCache);
    when(() => datasource.saveCustomPlan(any())).thenAnswer((call) async {
      customCache =
          call.positionalArguments.single as CustomMemorizationPlanModel;
    });
    when(
      () => datasource.clearDailyPlanCache(),
    ).thenAnswer((_) async => dailyCache = null);
    when(
      () => datasource.getCachedDailyPlan(),
    ).thenAnswer((_) async => dailyCache);
    when(() => datasource.saveDailyPlan(any())).thenAnswer((call) async {
      dailyCache = call.positionalArguments.single as DailyPlanModel;
    });
    when(
      () => datasource.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer((_) async => records);
    when(() => quran.getSurahs()).thenAnswer((_) async => Right(surahs));
    when(() => quran.getSurahDetail(any())).thenAnswer((call) async {
      final id = call.positionalArguments.single as int;
      return Right(
        SurahDetail(
          surah: surahs.singleWhere((s) => s.id == id),
          ayahs: [
            for (final row in corpus['$id'] as List)
              Ayah(
                number: row['global'] as int,
                surahId: id,
                text: row['text'] as String,
                numberInSurah: row['verse'] as int,
                page: row['page'] as int,
                juz: row['juz'] as int,
              ),
          ],
        ),
      );
    });
    custom = MemorizationCustomPlanService(datasource, prefs);
    daily = MemorizationDailyPlanService(datasource, quran, prefs, events);
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) => custom.getCustomPlan());
    when(() => repository.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    when(() => repository.saveCustomPlan(any())).thenAnswer(
      (call) => custom.saveCustomPlan(
        call.positionalArguments.single as CustomMemorizationPlan,
      ),
    );
    when(
      () => repository.getCachedDailyPlan(),
    ).thenAnswer((_) => daily.getCachedDailyPlan());
    when(
      () => repository.getKidsSessionLogs(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getParentSettings(),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    when(
      () => repository.getAllReviewRecords(scope: any(named: 'scope')),
    ).thenAnswer((_) async => Right(records));
    getIt
      ..registerSingleton<MemorizationPlusRepository>(repository)
      ..registerSingleton<QuranRepository>(quran)
      ..registerSingleton<ProgressEventsBus>(events)
      ..registerFactory<CustomPlanCubit>(
        () => CustomPlanCubit(repository, events),
      )
      ..registerFactory<MemorizationTabCubit>(
        () => MemorizationTabCubit(repository, events, paths),
      )
      ..registerFactory<MemorizationIdentityCubit>(
        () => MemorizationIdentityCubit(
          repository: repository,
          pathResolver: paths,
        ),
      )
      ..registerFactory<PlanDetailsCubit>(
        () => PlanDetailsCubit(
          GetPlanDetailsUseCase(
            repository,
            quran,
            const ProgressMetricsService(),
          ),
          events,
        ),
      );
    router = GoRouter(
      initialLocation: AppRoutes.memorizationPlusCustomPlan,
      routes: [
        GoRoute(
          path: AppRoutes.memorizationPlusCustomPlan,
          builder: (_, _) => const CustomPlanSetupPage(),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusPlanDetails,
          builder: (_, _) => const PlanDetailsPage(),
        ),
        GoRoute(
          path: AppRoutes.memorizationOptions,
          builder: (_, _) => const MemorizationHubPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [_stubTab(AppRoutes.home, 'home fixture')],
            ),
            StatefulShellBranch(
              routes: [_stubTab(AppRoutes.quran, 'quran fixture')],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.memorizationHub,
                  builder: (_, _) => const MemorizationTabPage(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [_stubTab(AppRoutes.azkar, 'azkar fixture')],
            ),
            StatefulShellBranch(
              routes: [_stubTab(AppRoutes.progress, 'progress fixture')],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.memorizationV2Session,
          builder: (_, state) => Scaffold(
            body: Column(
              children: [
                Text(
                  'session ${state.uri.queryParameters['surahId']}:${state.uri.queryParameters['startAyah']}',
                ),
                Builder(
                  builder: (context) => FilledButton(
                    key: const Key('complete_fixture_session'),
                    onPressed: () async {
                      final now = DateTime.now().toUtc();
                      records.add(
                        AyahReviewRecordModel.fromEntity(
                          AyahReviewRecord(
                            surahId: 67,
                            ayahNumber: 1,
                            strengthLevel: 6,
                            intervalDays: 3,
                            lastReviewedAt: now,
                            nextReviewDate: now.add(const Duration(days: 3)),
                            totalReviews: 4,
                            lastRating: PerformanceRating.excellent,
                            createdByMode: ReviewRecordCreatedByMode.v2Session,
                          ),
                        ),
                      );
                      await daily.markDailyPlanAyahCompleted(
                        surahId: 67,
                        ayahNumber: 1,
                      );
                      events.notify(ProgressChangedReason.reviewRecord);
                      if (context.mounted) context.pop();
                    },
                    child: const Text('Complete fixture session'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await getIt.reset();
    events.dispose();
    await paths.dispose();
    await audio.close();
    player.stateNotifier.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1100);
    addTearDown(tester.view.reset);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      BlocProvider.value(
        value: audio,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final target = find.byKey(Key(key));
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'save shows details before starting, and returned session refreshes progress',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'custom_plan_save');
      expect(find.byType(PlanDetailsPage), findsOneWidget);
      expect(find.text('session 67:1'), findsNothing);
      expect(customCache!.newAyahsPerDay, 3);
      await tapKey(tester, 'plan_details_start_session');
      expect(find.text('session 67:1'), findsOneWidget);
      await tapKey(tester, 'complete_fixture_session');
      expect(find.byType(PlanDetailsPage), findsOneWidget);
      final memorized = tester.widget<Text>(
        find.byKey(const Key('plan_details_memorized')),
      );
      expect(memorized.data, contains('1'));
      final remaining = tester.widget<Text>(
        find.byKey(const Key('plan_details_remaining')),
      );
      expect(remaining.data, contains('29'));
    },
  );

  testWidgets(
    'edit retains existing settings and saving returns to refreshed details',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'custom_plan_save');
      await tapKey(tester, 'plan_details_edit');
      expect(find.byType(CustomPlanSetupPage), findsOneWidget);
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.controller?.text == 'My saved plan',
      );
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Edited plan');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tapKey(tester, 'custom_plan_save');
      expect(find.byType(PlanDetailsPage), findsOneWidget);
      expect(find.text('Edited plan'), findsOneWidget);
      expect(customCache!.sessionMinutes, 30);
      expect(customCache!.createdAt, plan.createdAt);
    },
  );

  testWidgets('a tab read error retries safely and restores the saved plan', (
    tester,
  ) async {
    await pump(tester);
    router.go(AppRoutes.home);
    await tester.pumpAndSettle();
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    await tester.tap(find.text('Memorization'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailsPage), findsNothing);
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) => custom.getCustomPlan());
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanDetailsPage), findsOneWidget);
  });

  testWidgets(
    'other memorization tools stay accessible and return to the selected plan',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'custom_plan_save');
      await tapKey(tester, 'plan_details_other_options');
      expect(find.byType(MemorizationHubPage), findsOneWidget);
      expect(find.text('Practice by Surah'), findsOneWidget);
      await tester.ensureVisible(find.text('Plan details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan details'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanDetailsPage), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
    },
  );

  testWidgets(
    'bottom nav opens selected plan and exiting setup can return without changing it',
    (tester) async {
      await pump(tester);
      await tapKey(tester, 'custom_plan_save');
      expect(find.byType(AppShell), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CustomPlanSetupPage), findsOneWidget);
      await tapKey(tester, 'custom_plan_return_selected');
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('home fixture'), findsOneWidget);
      await tester.tap(find.text('Memorization'));
      await tester.pumpAndSettle();
      expect(find.text('My saved plan'), findsOneWidget);
      await tapKey(tester, 'plan_details_exit');
      expect(find.byType(CustomPlanSetupPage), findsOneWidget);
      expect(
        find.byKey(const Key('custom_plan_return_selected')),
        findsOneWidget,
      );
      final name = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.controller?.text == 'My saved plan',
      );
      await tester.ensureVisible(name);
      await tester.pumpAndSettle();
      await tester.enterText(name, 'Unsaved draft');
      await tapKey(tester, 'custom_plan_return_selected');
      expect(find.byType(PlanDetailsPage), findsOneWidget);
      expect(find.text('My saved plan'), findsOneWidget);
      expect(customCache!.name, 'My saved plan');
      expect(find.byType(AppShell), findsOneWidget);
    },
  );
}

GoRoute _stubTab(String path, String label) => GoRoute(
  path: path,
  builder: (_, _) => Scaffold(body: Text(label)),
);
