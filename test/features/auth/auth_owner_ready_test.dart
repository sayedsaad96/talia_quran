import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/presentation/pages/login_page.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/services/xp_service.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/auth/application/cloud_sync_coordinator.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatmah_local_datasource.dart';
import 'package:talia_quran/features/khatmah/data/repositories/khatmah_repository_impl.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_reading_result.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/create_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/delete_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_active_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatmah_history_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/pause_resume_khatmah_usecase.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_history_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart';
import 'package:talia_quran/features/khatmah/presentation/pages/khatmah_completion_page.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/domain/usecases/get_activity_heatmap_usecase.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

import '../home/presentation/cubits/home_cubit_test.mocks.dart';

class _Auth extends Mock implements AuthRepository {}

class _Reset extends Mock implements AccountDataReset {}

class _MarkerStore extends InMemorySharedPreferencesStore {
  _MarkerStore(super.data) : super.withData();
  bool reject = true;
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (reject && key.endsWith(AuthCubit.lastSignedInUserIdKey)) return false;
    return super.setValue(valueType, key, value);
  }
}

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);
  @override
  String currentOwnerId;
  @override
  bool get isSignedIn => currentOwnerId != 'local';
}

class _ForcedPreserveCoordinator extends CloudSyncCoordinator {
  _ForcedPreserveCoordinator(AuthRepository authRepository)
    : super(authRepository: authRepository);

  bool flushResult = false;

  @override
  Future<bool> flushBeforeSignOut() async => flushResult;

  @override
  Future<void> preservePendingSignOutWork() async {}

  @override
  Future<void> run() async {}
}

class _TestXpService extends Fake implements XpService {
  @override
  Future<int> getTotalXp() async => 0;
}

class _PendingGetRepository implements KhatmahRepository {
  _PendingGetRepository(this.delegate);

  final KhatmahRepository delegate;
  bool blockNext = false;
  Completer<void> started = Completer<void>();
  Completer<void> release = Completer<void>();

  @override
  Stream<void>? get changes => delegate.changes;

  @override
  Object? get authority => delegate.authority;

  @override
  Future<KhatmahPlan?> getActivePlan() async {
    if (blockNext) {
      blockNext = false;
      final captured = await delegate.getActivePlan();
      if (!started.isCompleted) started.complete();
      await release.future;
      return captured;
    }
    return delegate.getActivePlan();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'forced-preserve signout invalidates runtime authority before repository signout',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_owner': 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = _Owner('a');
      final retainedLease = barrier.capture();
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      final signOutStarted = Completer<void>();
      final releaseSignOut = Completer<void>();
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(() => auth.signOut(preserveAccountData: true)).thenAnswer((_) async {
        signOutStarted.complete();
        await releaseSignOut.future;
        return const Right(unit);
      });
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        _ForcedPreserveCoordinator(auth),
      );
      addTearDown(() async {
        if (!releaseSignOut.isCompleted) releaseSignOut.complete();
        await cubit.close();
      });

      final signOut = cubit.signOut(force: true);
      await signOutStarted.future;

      expect(
        retainedLease.check,
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(prefs.getString('khatmah_active_plan'), 'private-a');

      releaseSignOut.complete();
      await signOut;
    },
  );

  test(
    'failed forced-preserve signout restores fresh authority for the same session',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_owner': 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = _Owner('a');
      final staleLease = barrier.capture();
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.signOut(preserveAccountData: true),
      ).thenAnswer((_) async => const Left(UnknownFailure('still signed in')));
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        _ForcedPreserveCoordinator(auth),
      );
      addTearDown(cubit.close);

      await cubit.signOut(force: true);

      expect(cubit.state, isA<AuthError>());
      expect(staleLease.check, throwsA(isA<AccountDataUnavailableException>()));
      expect(barrier.isReady, isTrue);
      expect(barrier.capture().check, returnsNormally);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');
    },
  );

  test(
    'forced-preserve auth null is published only after runtime invalidation',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_owner': 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = _Owner('a');
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      AppUser? current = user;
      final events = StreamController<AppUser?>.broadcast(sync: true);
      when(() => auth.currentUser).thenAnswer((_) => current);
      when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(() => auth.signOut(preserveAccountData: true)).thenAnswer((_) async {
        current = null;
        events.add(null);
        return const Right(unit);
      });
      final cubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        _ForcedPreserveCoordinator(auth),
      );
      addTearDown(() async {
        await cubit.close();
        await events.close();
      });
      bool? readyWhenUnauthenticated;
      final sub = cubit.stream.listen((state) {
        if (state is AuthUnauthenticated) {
          readyWhenUnauthenticated = barrier.isReady;
        }
      });
      addTearDown(sub.cancel);

      await cubit.signOut(force: true);
      await Future<void>.delayed(Duration.zero);

      expect(readyWhenUnauthenticated, isFalse);
      expect(barrier.isReady, isFalse);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');
    },
  );

  testWidgets(
    'actual forced-preserve signout neutralizes retained production consumers and recovers safely',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'theme_mode': 'dark',
      });
      final prefs = await SharedPreferences.getInstance();
      final owner = _Owner('a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final repository = KhatmahRepositoryImpl(KhatmahLocalDatasource(prefs));
      final completedPlan = KhatmahPlan(
        id: 'completed-private-plan',
        title: 'Completed private Khatmah',
        completedPages: {for (var page = 1; page <= 604; page++) page},
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2026, 6, 1),
        status: KhatmahStatus.completed,
        lastReadDate: DateTime(2026, 5, 31),
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Completed Mother',
          relationship: 'Mother',
          condition: DedicationCondition.alive,
        ),
      );
      await repository.createPlan(completedPlan);
      final completedHistory = await repository.completePlan(completedPlan);
      final plan = KhatmahPlan(
        id: 'private-plan',
        title: 'Private for Mother',
        targetPagesPerDay: 4,
        targetDays: 151,
        startDate: DateTime(2026, 9, 1),
        expectedEndDate: DateTime(2027, 1, 29),
        dedication: const KhatmahDedication(
          isDedicated: true,
          recipientName: 'Mother',
          relationship: 'Mother',
          condition: DedicationCondition.alive,
        ),
      );
      await repository.createPlan(plan);

      final dashboard = KhatmahCubit(
        GetActiveKhatmahUsecase(repository),
        RecordKhatmahReadingUsecase(repository),
        PauseResumeKhatmahUsecase(repository),
        DeleteKhatmahUsecase(repository),
      );
      final setup = KhatmahSetupCubit(CreateKhatmahUsecase(repository));
      final history = KhatmahHistoryCubit(GetKhatmahHistoryUsecase(repository));
      await dashboard.load();
      await setup.createPlan(pagesPerDay: 4);
      await history.load();
      expect(dashboard.state, isA<KhatmahActive>());
      expect(setup.state, isA<KhatmahSetupConflict>());
      expect(history.state, isA<KhatmahHistoryLoaded>());

      final pendingRepository = _PendingGetRepository(repository);
      final mockGetProgress = MockGetProgressUsecase();
      final mockGetQuranPage = MockGetQuranPageUsecase();
      final mockGetCustomPlan = MockGetCustomPlanUsecase();
      final mockMemRepository = MockMemorizationPlusRepository();
      final mockSessionService = MockAppSessionService();
      final mockGetHeatmap = MockGetActivityHeatmapUsecase();
      final mockPathResolver = MockMemorizationPathResolver();
      final mockGetCoachRecommendation =
          MockGetSmartCoachRecommendationUsecase();
      final progressEvents = ProgressEventsBus();
      mockito
          .when(mockPathResolver.changes)
          .thenAnswer((_) => const Stream.empty());
      mockito
          .when(mockGetProgress.call())
          .thenAnswer(
            (_) async => const Right(
              OverallProgress(
                memorizedAyahs: 0,
                totalAyahs: 6236,
                memorizedSurahs: 0,
                totalSurahs: 114,
                memorizedJuz: 0,
                totalJuz: 30,
                readAyahs: 0,
                readSurahs: 0,
                readJuz: 0,
                streakDays: 0,
                lastActiveDate: null,
                achievements: [],
                readPagesCount: 0,
                totalQuranPages: 604,
                learningAyahs: 0,
                reviewAyahs: 0,
              ),
            ),
          );
      mockito
          .when(mockGetQuranPage.call(mockito.any))
          .thenAnswer((_) async => const Left(CacheFailure('no cache')));
      mockito
          .when(mockGetCustomPlan.call())
          .thenAnswer((_) async => const Right(null));
      mockito
          .when(mockGetHeatmap.call())
          .thenAnswer(
            (_) async => ActivityHeatmapData(
              countsByDay: const {},
              startDate: DateTime(2026, 1, 1),
            ),
          );
      mockito
          .when(mockGetCoachRecommendation.call())
          .thenAnswer((_) async => const Right(null));
      mockito
          .when(mockSessionService.getLastRestorableLocation())
          .thenReturn(null);
      mockito
          .when(mockMemRepository.getMemorizationProfile())
          .thenAnswer((_) async => Right(MemorizationProfile.empty()));
      mockito
          .when(mockMemRepository.getAllReviewRecords())
          .thenAnswer((_) async => const Right([]));
      final home = HomeCubit(
        mockGetProgress,
        mockGetQuranPage,
        mockGetCustomPlan,
        mockMemRepository,
        mockSessionService,
        mockGetHeatmap,
        mockPathResolver,
        mockGetCoachRecommendation,
        const UnifiedJourneyEngine(),
        prefs,
        progressEvents,
        _TestXpService(),
        GetActiveKhatmahUsecase(pendingRepository),
      );
      await home.load();
      expect((home.state as HomeLoaded).activeKhatmah?.id, plan.id);

      final completion = KhatmahReadingResult(
        plan: completedPlan.copyWith(authority: barrier.capture()),
        newlyCompletedPages: const {604},
        historyEntry: completedHistory,
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KhatmahCompletionPage(
            completion: completion,
            enableConfetti: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('khatmah_completion_certificate_button')),
        findsOneWidget,
      );
      expect(find.textContaining('Completed Mother'), findsWidgets);

      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      AppUser? current = user;
      final events = StreamController<AppUser?>.broadcast(sync: true);
      when(() => auth.currentUser).thenAnswer((_) => current);
      when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(() => auth.signOut(preserveAccountData: true)).thenAnswer((_) async {
        current = null;
        owner.currentOwnerId = 'local';
        events.add(null);
        return const Right(unit);
      });
      when(() => auth.signOut(preserveAccountData: false)).thenAnswer((
        _,
      ) async {
        owner.currentOwnerId = 'local';
        current = null;
        await barrier.clear(() async {
          await prefs.remove('khatmah_active_plan');
          await prefs.remove('khatmah_history');
          await prefs.remove('khatmah_owner');
        });
        events.add(null);
        return const Right(unit);
      });
      final coordinator = _ForcedPreserveCoordinator(auth);
      KhatmahCubit? recoveredDashboard;
      final authCubit = AuthCubit(
        auth,
        null,
        null,
        null,
        null,
        prefs,
        reset,
        coordinator,
      );
      addTearDown(() async {
        if (!pendingRepository.release.isCompleted) {
          pendingRepository.release.complete();
        }
        await authCubit.close();
        await recoveredDashboard?.close();
        await home.close();
        await dashboard.close();
        await setup.close();
        await history.close();
        await events.close();
        progressEvents.dispose();
      });

      pendingRepository.blockNext = true;
      final pendingHomeLoad = home.load();
      await pendingRepository.started.future;
      await authCubit.signOut(force: true);
      await tester.pump();
      pendingRepository.release.complete();
      await pendingHomeLoad;
      await tester.pump();

      expect(authCubit.state, isA<AuthUnauthenticated>());
      expect(dashboard.state, isA<KhatmahProgressFailure>());
      expect((dashboard.state as KhatmahProgressFailure).plan, isNull);
      expect(setup.state, isA<KhatmahSetupIdle>());
      expect(history.state, isA<KhatmahHistoryFailure>());
      expect((home.state as HomeLoaded).activeKhatmah, isNull);
      expect((home.state as HomeLoaded).khatmahError, isNotNull);
      expect(
        find.byKey(const Key('khatmah_completion_certificate_button')),
        findsNothing,
      );
      expect(find.textContaining('Completed Mother'), findsNothing);
      expect(barrier.isReady, isFalse);
      expect(prefs.getString('khatmah_active_plan'), contains('Mother'));
      expect(prefs.getString('khatmah_history'), contains('Completed Mother'));
      expect(prefs.getString('theme_mode'), 'dark');
      await expectLater(
        repository.createPlan(plan.copyWith(id: 'guest-write')),
        throwsA(isA<KhatmahProgressException>()),
      );
      await expectLater(
        repository.getActivePlan(),
        throwsA(isA<KhatmahProgressException>()),
      );

      current = user;
      owner.currentOwnerId = 'a';
      events.add(user);
      await tester.pump();
      await authCubit.ensureCloudSyncComplete();
      await history.load();
      await home.load();
      recoveredDashboard = KhatmahCubit(
        GetActiveKhatmahUsecase(repository),
        RecordKhatmahReadingUsecase(repository),
        PauseResumeKhatmahUsecase(repository),
        DeleteKhatmahUsecase(repository),
      );
      await recoveredDashboard.load();
      await tester.pump();

      expect(authCubit.state, isA<AuthAuthenticated>());
      expect(barrier.isReady, isTrue);
      expect(dashboard.state, isA<KhatmahProgressFailure>());
      expect(recoveredDashboard.state, isA<KhatmahActive>());
      expect(history.state, isA<KhatmahHistoryLoaded>());
      expect((home.state as HomeLoaded).activeKhatmah?.id, plan.id);
      expect(
        find.byKey(const Key('khatmah_completion_certificate_button')),
        findsNothing,
      );

      coordinator.flushResult = true;
      await authCubit.signOut();
      await tester.pump();

      expect(authCubit.state, isA<AuthUnauthenticated>());
      expect(barrier.isReady, isTrue);
      expect(prefs.getString('khatmah_active_plan'), isNull);
      expect(prefs.getString('khatmah_history'), isNull);
      expect(prefs.getString('theme_mode'), 'dark');
      expect(await repository.getActivePlan(), isNull);
      expect(await repository.getHistory(), isEmpty);
    },
  );

  testWidgets(
    'cached Home owner failure redirects to late-mounted recovery and retries until ready',
    (tester) async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_owner': 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(prefs);
      final owner = _Owner('b');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final auth = _Auth();
      final reset = _Reset();
      const b = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
      var resetAttempts = 0;
      when(() => auth.currentUser).thenReturn(b);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(() => reset.clearAccountOwnedData(departingOwnerId: 'a')).thenAnswer(
        (_) => barrier.clear(() async {
          resetAttempts++;
          if (resetAttempts < 3) {
            throw const AccountDataResetException('denied');
          }
          await prefs.remove('khatmah_active_plan');
        }),
      );
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      final profile = ProfileCubit(prefs)..loadProfile();

      await expectLater(
        cubit.ensureCloudSyncComplete(),
        throwsA(isA<AccountDataResetException>()),
      );
      expect(cubit.state, isA<AuthOwnerDataFailure>());
      expect(barrier.isReady, isFalse);

      final refresh = ChangeNotifier();
      final refreshSub = cubit.stream.listen((_) => refresh.notifyListeners());
      final router = GoRouter(
        initialLocation: AppRoutes.home,
        refreshListenable: refresh,
        redirect: (_, state) =>
            AppRouter.redirectForAuth(cubit.state, state.matchedLocation),
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
          GoRoute(
            path: AppRoutes.home,
            builder: (_, _) => const Scaffold(body: Text('ready home')),
          ),
        ],
      );
      addTearDown(() async {
        router.dispose();
        await refreshSub.cancel();
        refresh.dispose();
        await cubit.close();
        await profile.close();
        await getIt.reset();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: cubit),
            BlocProvider<ProfileCubit>.value(value: profile),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ready home'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));
      expect(find.text(l10n.retrySyncAfterError), findsOneWidget);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');

      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(resetAttempts, 2);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('ready home'), findsNothing);
      expect(barrier.isReady, isFalse);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');

      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(resetAttempts, 3);
      expect(find.text('ready home'), findsOneWidget);
      expect(barrier.isReady, isTrue);
      expect(prefs.getString('khatmah_active_plan'), isNull);
    },
  );

  testWidgets(
    'actual login cleanup failure stays on login and retry routes only after ready',
    (tester) async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_active_plan': 'private-a',
      });
      final prefs = await SharedPreferences.getInstance();
      getIt.registerSingleton<SharedPreferences>(prefs);
      final auth = _Auth();
      final reset = _Reset();
      final owner = _Owner('local');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      const b = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
      AppUser? current;
      var fail = true;
      when(() => auth.currentUser).thenAnswer((_) => current);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        current = b;
        owner.currentOwnerId = 'b';
        return const Right(b);
      });
      when(() => reset.clearAccountOwnedData(departingOwnerId: 'a')).thenAnswer(
        (_) => barrier.clear(() async {
          if (fail) throw const AccountDataResetException('denied');
          await prefs.remove('khatmah_active_plan');
        }),
      );
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      final profile = ProfileCubit(prefs)..loadProfile();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('ready home')),
          ),
        ],
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: cubit),
            BlocProvider<ProfileCubit>.value(value: profile),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'b@test.invalid',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      final submit = find.byType(FilledButton).last;
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ready home'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(barrier.isReady, isFalse);
      final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));
      expect(find.text(l10n.authGenericError), findsOneWidget);
      fail = false;
      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(find.text('ready home'), findsOneWidget);
      expect(prefs.getString('khatmah_active_plan'), isNull);
      expect(barrier.isReady, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await cubit.close();
      await profile.close();
      await getIt.reset();
    },
  );
  test(
    'marker rejection after successful clear stays gated and retry opens owner',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = _MarkerStore({
        'flutter.auth_last_signed_in_user_id': 'a',
        'flutter.khatmah_active_plan': 'private-a',
        'flutter.khatmah_owner': 'a',
      });
      SharedPreferencesStorePlatform.instance = store;
      final prefs = await SharedPreferences.getInstance();
      final owner = _Owner('b');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(() => reset.clearAccountOwnedData(departingOwnerId: 'a')).thenAnswer(
        (_) => barrier.clear(() async {
          await prefs.remove('khatmah_active_plan');
          await prefs.remove('khatmah_owner');
        }),
      );
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      await expectLater(
        cubit.ensureCloudSyncComplete(),
        throwsA(isA<AccountDataResetException>()),
      );
      expect(prefs.getString('khatmah_active_plan'), isNull);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'a');
      expect(cubit.state, isA<AuthOwnerDataFailure>());
      expect(barrier.isReady, isFalse);
      store.reject = false;
      await cubit.ensureCloudSyncComplete();
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(barrier.isReady, isTrue);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'b');
      await cubit.close();
    },
  );
  test(
    'same-owner cached startup preserves existing local authority offline',
    () async {
      SharedPreferences.setMockInitialValues({
        AuthCubit.lastSignedInUserIdKey: 'a',
        'khatmah_active_plan': 'private-a',
        'khatmah_owner': 'a',
      });
      final prefs = await SharedPreferences.getInstance();
      final barrier = AccountDataBarrier.forPreferences(prefs)
        ..owner = _Owner('a');
      final lease = barrier.capture();
      final auth = _Auth();
      final reset = _Reset();
      const user = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.authStateChanges).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.passwordRecoveryChanges,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => auth.pullProgressFromCloud(),
      ).thenAnswer((_) async => const Right(unit));
      when(
        () => auth.syncProgressToCloud(),
      ).thenAnswer((_) async => const Right(unit));
      final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
      await cubit.ensureCloudSyncComplete();
      expect(lease.check, returnsNormally);
      expect(prefs.getString('khatmah_active_plan'), 'private-a');
      expect(cubit.state, isA<AuthAuthenticated>());
      await cubit.close();
    },
  );
  for (final rejectC in [false, true]) {
    test(
      'rapid A B C preserves current failure=$rejectC and retry remains usable',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: 'a',
          'khatmah_active_plan': 'private-a',
          'khatmah_owner': 'a',
        });
        final prefs = await SharedPreferences.getInstance();
        final owner = _Owner('a');
        final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
        final auth = _Auth();
        final reset = _Reset();
        const a = AppUser(id: 'a', email: 'a@test.invalid', displayName: 'A');
        const b = AppUser(id: 'b', email: 'b@test.invalid', displayName: 'B');
        const c = AppUser(id: 'c', email: 'c@test.invalid', displayName: 'C');
        AppUser current = a;
        final events = StreamController<AppUser?>.broadcast();
        final started = Completer<void>();
        final release = Completer<void>();
        var clearCalls = 0;
        var failCurrent = rejectC;
        when(() => auth.currentUser).thenAnswer((_) => current);
        when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => reset.clearAccountOwnedData(
            departingOwnerId: any(named: 'departingOwnerId'),
          ),
        ).thenAnswer((_) async {
          clearCalls++;
          if (!started.isCompleted) started.complete();
          await release.future;
          await barrier.clear(() async {
            if (clearCalls > 1 && failCurrent) {
              throw const AccountDataResetException('current C denied');
            }
            await prefs.remove('khatmah_active_plan');
          });
        });
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        await cubit.ensureCloudSyncComplete();
        final states = <AuthState>[];
        final sub = cubit.stream.listen(states.add);
        current = b;
        owner.currentOwnerId = 'b';
        events.add(b);
        await started.future;
        current = c;
        owner.currentOwnerId = 'c';
        events.add(c);
        await Future<void>.delayed(Duration.zero);
        release.complete();
        if (rejectC) {
          await expectLater(
            cubit.ensureCloudSyncComplete(),
            throwsA(isA<AccountDataResetException>()),
          );
          expect(cubit.state, isA<AuthOwnerDataFailure>());
          expect(barrier.isReady, isFalse);
          expect(
            states.whereType<AuthAuthenticated>().any((s) => s.user.id == 'c'),
            isFalse,
          );
          failCurrent = false;
        }
        await cubit.ensureCloudSyncComplete();
        expect(
          states.whereType<AuthAuthenticated>().any((s) => s.user.id == 'b'),
          isFalse,
        );
        expect((cubit.state as AuthAuthenticated).user.id, 'c');
        expect(barrier.isReady, isTrue);
        expect(prefs.getString('khatmah_active_plan'), isNull);
        await sub.cancel();
        await cubit.close();
        await events.close();
      },
    );
  }
  for (final marker in [null, 'a']) {
    test(
      'guest to owner with previous marker=$marker opens local data after readiness',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: ?marker,
        });
        final prefs = await SharedPreferences.getInstance();
        final owner = _Owner('local');
        final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
        // A normal logout has already cleared all Khatmah data.
        await barrier.clear(() async {});
        final auth = _Auth();
        final reset = _Reset();
        const user = AppUser(
          id: 'a',
          email: 'a@test.invalid',
          displayName: 'A',
        );
        when(() => auth.currentUser).thenReturn(user);
        when(
          () => auth.authStateChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        owner.currentOwnerId = 'a';
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        addTearDown(cubit.close);
        await cubit.ensureCloudSyncComplete();
        expect(cubit.state, isA<AuthAuthenticated>());
        await expectLater(barrier.run((_) async => true), completion(isTrue));
      },
    );
  }
  for (final cached in [true, false]) {
    test(
      'owner readiness cached=$cached waits for cleanup and propagates failure',
      () async {
        SharedPreferences.setMockInitialValues({
          AuthCubit.lastSignedInUserIdKey: 'a',
          'khatmah_active_plan': 'private-a',
        });
        final prefs = await SharedPreferences.getInstance();
        final auth = _Auth();
        final reset = _Reset();
        const user = AppUser(
          id: 'b',
          email: 'b@test.invalid',
          displayName: 'B',
        );
        AppUser? current = cached ? user : null;
        final events = StreamController<AppUser?>.broadcast();
        final cleanup = Completer<void>();
        unawaited(
          cleanup.future.then<void>(
            (_) {},
            onError: (Object _, StackTrace _) {},
          ),
        );
        when(() => auth.currentUser).thenAnswer((_) => current);
        when(() => auth.authStateChanges).thenAnswer((_) => events.stream);
        when(
          () => auth.passwordRecoveryChanges,
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => auth.pullProgressFromCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => auth.syncProgressToCloud(),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => reset.clearAccountOwnedData(departingOwnerId: 'a'),
        ).thenAnswer((_) => cleanup.future);
        final cubit = AuthCubit(auth, null, null, null, null, prefs, reset);
        addTearDown(() async {
          await cubit.close();
          await events.close();
        });
        if (!cached) {
          current = user;
          events.add(user);
          await Future<void>.delayed(Duration.zero);
        }
        final prematurelyReady = cubit.state is AuthAuthenticated;
        final completion = cubit.ensureCloudSyncComplete().then<Object?>(
          (_) => null,
          onError: (Object e) => e,
        );
        cleanup.completeError(const AccountDataResetException('denied'));
        final error = await completion;
        expect(prematurelyReady, isFalse);
        expect(error, isA<AccountDataResetException>());
        expect(cubit.state, isNot(isA<AuthAuthenticated>()));
        expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'a');
      },
    );
  }
}
