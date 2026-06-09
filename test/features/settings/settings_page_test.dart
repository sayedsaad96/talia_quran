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
import 'package:talia_quran/core/l10n/locale_cubit.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/app_version_service.dart';
import 'package:talia_quran/core/theme/app_colors.dart';
import 'package:talia_quran/core/theme/theme_cubit.dart';
import 'package:talia_quran/features/auth/domain/entities/app_user.dart';
import 'package:talia_quran/features/auth/domain/repositories/auth_repository.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:talia_quran/features/settings/presentation/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('guest account section shows guest status and sign-in action', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Using Talia as guest'), findsOneWidget);
    expect(
      find.text(
        'Your local progress remains on this device. Create an account for account management and family features.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign in / Create account'), findsOneWidget);
    expect(find.textContaining('cloud', findRichText: true), findsNothing);
    expect(find.textContaining('sync', findRichText: true), findsNothing);
    expect(find.textContaining('backup', findRichText: true), findsNothing);
  });

  testWidgets('signed-in account section shows status and sign-out action', (
    tester,
  ) async {
    await _pumpSettings(tester, user: _signedInUser);

    expect(find.text('Sarah'), findsOneWidget);
    expect(find.text('sarah@example.com'), findsOneWidget);
    expect(find.text('Signed in to your account'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
  });

  testWidgets('appearance section contains language and theme', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgets(
    'Quran & Memorization section contains accuracy and reset path when selected',
    (tester) async {
      await _pumpSettings(tester, path: MemorizationPath.adult);

      expect(find.text('Quran & Memorization'), findsOneWidget);
      expect(find.text('Accuracy Level'), findsOneWidget);
      expect(find.text('Memorization Path'), findsOneWidget);
      expect(find.text('Reset path'), findsOneWidget);
    },
  );

  testWidgets('Kids & Guardian section follows parent visibility rules', (
    tester,
  ) async {
    await _pumpSettings(tester, path: MemorizationPath.adult);

    expect(find.text('Kids & Guardian'), findsOneWidget);
    expect(find.text('I am a parent/guardian'), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsNothing);
  });

  testWidgets('parent dashboard is visible only for adult parent mode', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      path: MemorizationPath.adult,
      isParentGuardian: true,
    );

    expect(find.text('Parent Dashboard'), findsOneWidget);
    expect(
      find.text(
        'Sign in to manage your account and access guardian tools. Your local progress remains on this device.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('guest parent dashboard access routes to sign-in prompt', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      path: MemorizationPath.adult,
      isParentGuardian: true,
    );

    await _tapVisibleText(tester, 'Parent Dashboard');

    expect(find.text('login route'), findsOneWidget);
  });

  testWidgets('parent dashboard is not exposed to child profiles', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      path: MemorizationPath.child,
      isParentGuardian: true,
    );

    expect(find.text('Parent Dashboard'), findsNothing);
    expect(find.text('I am a parent/guardian'), findsNothing);
  });

  testWidgets(
    'privacy and security contains privacy policy and delete account',
    (tester) async {
      await _pumpSettings(tester, user: _signedInUser);

      await _scrollUntilVisible(tester, 'Privacy & Security');

      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Delete account'), findsOneWidget);
    },
  );

  testWidgets('help and tutorial contains tutorial guide', (tester) async {
    await _pumpSettings(tester);

    await _scrollUntilVisible(tester, 'Help & Tutorial');

    expect(find.text('Help & Tutorial'), findsOneWidget);
    expect(find.text('Talia user guide'), findsOneWidget);
  });

  testWidgets('about section renders app version and build metadata', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      versionInfo: const AppVersionInfo(version: '1.3.0', buildNumber: '45'),
    );

    await _scrollUntilVisible(tester, 'About Talia');

    expect(find.text('Version 1.3.0'), findsOneWidget);
    expect(find.text('Build 45'), findsOneWidget);
  });

  testWidgets('about section falls back when app version is unavailable', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      versionInfo: const AppVersionInfo.unavailable(),
    );

    await _scrollUntilVisible(tester, 'About Talia');

    expect(find.text('Version —'), findsOneWidget);
    expect(find.text('Build —'), findsOneWidget);
  });

  testWidgets('progress section keeps all reminder controls visible', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await _scrollUntilVisible(tester, 'Progress & Achievements');

    expect(find.text('Daily Review Reminder'), findsOneWidget);
    expect(find.text('Streak Protection'), findsOneWidget);
    expect(find.text('Morning Azkar Reminder'), findsOneWidget);
    expect(find.text('Evening Azkar Reminder'), findsOneWidget);
    expect(find.text('Daily Dua'), findsOneWidget);
    expect(find.byType(Switch), findsAtLeastNWidgets(5));
  });

  testWidgets('reset path dialog appears and preserves confirmation behavior', (
    tester,
  ) async {
    final repo = await _pumpSettings(tester, path: MemorizationPath.adult);

    await _tapVisibleText(tester, 'Reset path');
    expect(find.text('Reset memorization path?'), findsOneWidget);
    expect(find.text('Type "Reset path" to confirm.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Reset path');
    await tester.pump();
    await tester.tap(find.text('Confirm reset'));
    await tester.pumpAndSettle();

    expect(repo.resetCount, 1);
  });

  testWidgets('privacy navigation still uses the existing route', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await _tapVisibleText(tester, 'Privacy Policy');

    expect(find.text('privacy route'), findsOneWidget);
  });

  testWidgets('tutorial navigation still uses the existing route', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await _tapVisibleText(tester, 'Talia user guide');

    expect(find.text('tutorial route'), findsOneWidget);
  });

  testWidgets('English locale renders LTR', (tester) async {
    await _pumpSettings(tester, locale: const Locale('en'));

    final direction = Directionality.of(
      tester.element(find.byType(SettingsPage)),
    );
    expect(direction, TextDirection.ltr);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Arabic locale renders RTL', (tester) async {
    await _pumpSettings(tester, locale: const Locale('ar'));

    final direction = Directionality.of(
      tester.element(find.byType(SettingsPage)),
    );
    expect(direction, TextDirection.rtl);
    expect(find.text('الإعدادات'), findsOneWidget);
  });

  testWidgets('dark theme renders the correct settings background', (
    tester,
  ) async {
    await _pumpSettings(tester, themeMode: ThemeMode.dark);

    final darkScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(darkScaffold.backgroundColor, AppColors.darkBackground);
  });

  testWidgets('light theme renders the correct settings background', (
    tester,
  ) async {
    await _pumpSettings(tester, themeMode: ThemeMode.light);

    final lightScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(lightScaffold.backgroundColor, AppColors.lightBackground);
  });
}

const _signedInUser = AppUser(
  id: 'user-1',
  email: 'sarah@example.com',
  displayName: 'Sarah',
);

Future<_FakeMemorizationRepository> _pumpSettings(
  WidgetTester tester, {
  MemorizationPath? path,
  bool isParentGuardian = false,
  AppUser? user,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  AppVersionInfo versionInfo = const AppVersionInfo(
    version: '1.0.0',
    buildNumber: '1',
  ),
}) async {
  tester.view.physicalSize = const Size(1080, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = await _registerSettingsDependencies(
    path: path,
    isParentGuardian: isParentGuardian,
    user: user,
    locale: locale,
    themeMode: themeMode,
    versionInfo: versionInfo,
  );

  await tester.pumpWidget(
    _SettingsTestApp(
      router: _settingsRouter(),
      locale: locale,
      themeMode: themeMode,
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

Future<_FakeMemorizationRepository> _registerSettingsDependencies({
  MemorizationPath? path,
  bool isParentGuardian = false,
  AppUser? user,
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  AppVersionInfo versionInfo = const AppVersionInfo(
    version: '1.0.0',
    buildNumber: '1',
  ),
}) async {
  SharedPreferences.setMockInitialValues({
    'app_locale': locale.languageCode,
    'theme_mode': switch (themeMode) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    },
  });
  final prefs = await SharedPreferences.getInstance();
  final repo = _FakeMemorizationRepository(
    profile: _profile(path, isParentGuardian: isParentGuardian),
  );
  final resolver = MemorizationPathResolver(repo);
  final authRepository = _FakeAuthRepository(user);
  final authCubit = AuthCubit(authRepository);
  final profileCubit = ProfileCubit(prefs)..loadProfile();
  final themeCubit = ThemeCubit(prefs)..loadTheme();
  final localeCubit = LocaleCubit(prefs)..loadLocale();

  addTearDown(authRepository.dispose);
  addTearDown(authCubit.close);
  addTearDown(profileCubit.close);
  addTearDown(themeCubit.close);
  addTearDown(localeCubit.close);

  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<MemorizationPlusRepository>(repo);
  getIt.registerSingleton<MemorizationPathResolver>(resolver);
  getIt.registerSingleton<AuthCubit>(authCubit);
  getIt.registerSingleton<ProfileCubit>(profileCubit);
  getIt.registerSingleton<ThemeCubit>(themeCubit);
  getIt.registerSingleton<LocaleCubit>(localeCubit);
  getIt.registerSingleton<AppVersionInfoProvider>(
    _FakeAppVersionInfoProvider(versionInfo),
  );
  getIt.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getIt<MemorizationPlusRepository>(),
      getIt<SharedPreferences>(),
      getIt<MemorizationPathResolver>(),
    ),
  );

  return repo;
}

GoRouter _settingsRouter() {
  return GoRouter(
    initialLocation: AppRoutes.settings,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: Text('home route')),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('login route')),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (_, _) => const Scaffold(body: Text('privacy route')),
      ),
      GoRoute(
        path: AppRoutes.tutorialGuide,
        builder: (_, _) => const Scaffold(body: Text('tutorial route')),
      ),
      GoRoute(
        path: AppRoutes.memorizationHub,
        builder: (_, _) => const Scaffold(body: Text('memorization route')),
      ),
    ],
  );
}

class _SettingsTestApp extends StatelessWidget {
  const _SettingsTestApp({
    required this.router,
    required this.locale,
    required this.themeMode,
  });

  final GoRouter router;
  final Locale locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<AuthCubit>()),
        BlocProvider.value(value: getIt<ProfileCubit>()),
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<LocaleCubit>()),
      ],
      child: MaterialApp.router(
        locale: locale,
        themeMode: themeMode,
        theme: ThemeData.light(useMaterial3: true),
        darkTheme: ThemeData.dark(useMaterial3: true),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  await _scrollUntilVisible(tester, text);
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    return;
  }

  await tester.scrollUntilVisible(
    finder,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

MemorizationProfile _profile(
  MemorizationPath? path, {
  required bool isParentGuardian,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return MemorizationProfile(
    schemaVersion: 1,
    selectedPath: path,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: path == MemorizationPath.child
        ? GuardianOnboardingStatus.required
        : GuardianOnboardingStatus.completed,
    isParentGuardian: isParentGuardian,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeAppVersionInfoProvider implements AppVersionInfoProvider {
  const _FakeAppVersionInfoProvider(this.info);

  final AppVersionInfo info;

  @override
  Future<AppVersionInfo> getVersionInfo() async => info;
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final _authController = StreamController<AppUser?>.broadcast();
  final _passwordRecoveryController = StreamController<void>.broadcast();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  Stream<void> get passwordRecoveryChanges =>
      _passwordRecoveryController.stream;

  @override
  Future<Either<Failure, Unit>> signOut() async {
    _user = null;
    _authController.add(null);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    _user = null;
    return const Right(unit);
  }

  Future<void> dispose() async {
    await _authController.close();
    await _passwordRecoveryController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMemorizationRepository implements MemorizationPlusRepository {
  _FakeMemorizationRepository({required this.profile});

  MemorizationProfile profile;
  int resetCount = 0;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async {
    return Right(profile);
  }

  @override
  Future<Either<Failure, MemorizationProfile>>
  resetMemorizationIdentity() async {
    resetCount += 1;
    profile = profile.copyWith(clearSelectedPath: true);
    return Right(profile);
  }

  @override
  Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(
    bool value,
  ) async {
    profile = profile.copyWith(isParentGuardian: value);
    return Right(profile);
  }

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async {
    return const Right(null);
  }

  @override
  Either<Failure, MemorizationTrack?> getSelectedTrack() {
    return Right(profile.legacyTrack);
  }

  @override
  Either<Failure, bool> getIsParentMode() {
    return Right(profile.isParentGuardian);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
