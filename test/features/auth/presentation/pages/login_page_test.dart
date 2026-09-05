import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/auth/presentation/pages/login_page.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => getIt.reset());

  testWidgets(
    'account-switch auth states resolve and route once after cloud sync',
    (tester) async {
      final syncRelease = Completer<void>();
      final authCubit = _LoginPageAuthCubit(syncRelease.future);
      final prefs = await SharedPreferences.getInstance();
      final profileCubit = ProfileCubit(prefs)..loadProfile();
      final repository = _TrackingMemorizationRepository();
      var homeRouteResolutions = 0;
      final router = _loginRouter(
        onHomeRouteResolved: () => homeRouteResolutions += 1,
      );
      addTearDown(() {
        if (!syncRelease.isCompleted) syncRelease.complete();
      });
      addTearDown(router.dispose);
      addTearDown(authCubit.close);
      addTearDown(profileCubit.close);
      getIt.registerSingleton<SharedPreferences>(prefs);
      getIt.registerSingleton<MemorizationPlusRepository>(repository);

      await _pumpLoginPage(
        tester,
        router: router,
        authCubit: authCubit,
        profileCubit: profileCubit,
      );

      authCubit.emitAccountSwitchStates(_accountB);
      await tester.pump();

      expect(repository.profileResolutionCalls, 0);
      expect(homeRouteResolutions, 0);
      expect(find.byType(LoginPage), findsOneWidget);

      syncRelease.complete();
      await tester.pumpAndSettle();

      expect(authCubit.ensureCloudSyncCalls, 1);
      expect(repository.profileResolutionCalls, 1);
      expect(homeRouteResolutions, 1);
      expect(find.text('home route'), findsOneWidget);
    },
  );

  testWidgets(
    'disposing login while profile resolution is pending does not navigate',
    (tester) async {
      final syncRelease = Completer<void>();
      final profileRelease = Completer<void>();
      final authCubit = _LoginPageAuthCubit(syncRelease.future);
      final prefs = await SharedPreferences.getInstance();
      final profileCubit = ProfileCubit(prefs)..loadProfile();
      final repository = _TrackingMemorizationRepository(
        profileRelease: profileRelease.future,
      );
      var homeRouteResolutions = 0;
      final router = _loginRouter(
        onHomeRouteResolved: () => homeRouteResolutions += 1,
      );
      addTearDown(() {
        if (!syncRelease.isCompleted) syncRelease.complete();
        if (!profileRelease.isCompleted) profileRelease.complete();
      });
      addTearDown(router.dispose);
      addTearDown(authCubit.close);
      addTearDown(profileCubit.close);
      getIt.registerSingleton<SharedPreferences>(prefs);
      getIt.registerSingleton<MemorizationPlusRepository>(repository);

      await _pumpLoginPage(
        tester,
        router: router,
        authCubit: authCubit,
        profileCubit: profileCubit,
      );

      authCubit.emitAuthenticated(_accountB);
      await tester.pump();
      expect(repository.profileResolutionCalls, 0);

      syncRelease.complete();
      await tester.pump();
      await repository.profileResolutionStarted.future;

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      profileRelease.complete();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(homeRouteResolutions, 0);
    },
  );

  testWidgets(
    'late-mounted login shows cached owner failure and retries until ready',
    (tester) async {
      final authCubit = _RecoveringLoginPageAuthCubit()..emitOwnerFailure();
      final prefs = await SharedPreferences.getInstance();
      final profileCubit = ProfileCubit(prefs)..loadProfile();
      final repository = _TrackingMemorizationRepository();
      var homeRouteResolutions = 0;
      final router = _loginRouter(
        onHomeRouteResolved: () => homeRouteResolutions += 1,
      );
      addTearDown(router.dispose);
      addTearDown(authCubit.close);
      addTearDown(profileCubit.close);
      getIt.registerSingleton<SharedPreferences>(prefs);
      getIt.registerSingleton<MemorizationPlusRepository>(repository);

      await _pumpLoginPage(
        tester,
        router: router,
        authCubit: authCubit,
        profileCubit: profileCubit,
      );

      final l10n = AppLocalizations.of(tester.element(find.byType(LoginPage)));
      expect(find.text(l10n.retrySyncAfterError), findsOneWidget);
      expect(homeRouteResolutions, 0);

      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(find.text(l10n.retrySyncAfterError), findsOneWidget);
      expect(authCubit.ensureCloudSyncCalls, 1);
      expect(homeRouteResolutions, 0);

      await tester.tap(find.text(l10n.retrySyncAfterError));
      await tester.pumpAndSettle();
      expect(authCubit.ensureCloudSyncCalls, 2);
      expect(homeRouteResolutions, 1);
      expect(find.text('home route'), findsOneWidget);
    },
  );
}

const _accountB = AppUser(
  id: 'owner-b',
  email: 'b@example.com',
  displayName: 'Owner B',
);

Future<void> _pumpLoginPage(
  WidgetTester tester, {
  required GoRouter router,
  required AuthCubit authCubit,
  required ProfileCubit profileCubit,
}) async {
  tester.view.physicalSize = const Size(1080, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<ProfileCubit>.value(value: profileCubit),
      ],
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

GoRouter _loginRouter({required VoidCallback onHomeRouteResolved}) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (_, state) {
      if (state.uri.path == AppRoutes.home) onHomeRouteResolved();
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home route')),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    ],
  );
}

class _LoginPageAuthCubit extends AuthCubit {
  _LoginPageAuthCubit(this._syncGate) : super(const _PageAuthRepository());

  final Future<void> _syncGate;
  int ensureCloudSyncCalls = 0;

  @override
  Future<void> ensureCloudSyncComplete() {
    ensureCloudSyncCalls += 1;
    return _syncGate;
  }

  void emitAccountSwitchStates(AppUser user) {
    emit(AuthAuthenticated(user: user));
    emit(AuthAccountDataDiscarded(user: user));
  }

  void emitAuthenticated(AppUser user) {
    emit(AuthAuthenticated(user: user));
  }
}

class _RecoveringLoginPageAuthCubit extends AuthCubit {
  _RecoveringLoginPageAuthCubit() : super(const _PageAuthRepository());

  int ensureCloudSyncCalls = 0;

  void emitOwnerFailure() => emit(const AuthOwnerDataFailure());

  @override
  Future<void> ensureCloudSyncComplete() async {
    ensureCloudSyncCalls += 1;
    if (ensureCloudSyncCalls == 1) throw StateError('owner reset failed');
  }
}

class _PageAuthRepository implements AuthRepository {
  const _PageAuthRepository();

  @override
  AppUser? get currentUser => null;

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Stream<void> get passwordRecoveryChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingMemorizationRepository implements MemorizationPlusRepository {
  _TrackingMemorizationRepository({this.profileRelease});

  final Future<void>? profileRelease;
  final profileResolutionStarted = Completer<void>();
  int profileResolutionCalls = 0;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    profileResolutionCalls += 1;
    if (!profileResolutionStarted.isCompleted) {
      profileResolutionStarted.complete();
    }
    await profileRelease;
    return Right(
      MemorizationProfile.empty().copyWith(
        selectedPath: MemorizationPath.adult,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
