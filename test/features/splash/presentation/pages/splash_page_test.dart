import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/app_initializer.dart';
import 'package:talia_quran/features/splash/presentation/pages/splash_page.dart';

Widget _buildSplashTestApp({
  ThemeMode themeMode = ThemeMode.system,
  Locale locale = const Locale('ar'),
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: SplashPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) =>
            const Scaffold(body: Text('onboarding route')),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('home route')),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    themeMode: themeMode,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Animate.defaultDuration = Duration.zero;
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(prefs);
    AppInitializer.resetForTesting(initialized: false);
  });

  tearDown(() async {
    await getIt.reset();
    AppInitializer.resetForTesting();
  });

  group('SplashPage Visual & Brand Quality Tests', () {
    testWidgets(
      'uses dedicated splash_hero.png asset and not native splash padded asset',
      (tester) async {
        await tester.pumpWidget(_buildSplashTestApp());
        await tester.pumpAndSettle();

        // Must find dedicated hero asset
        expect(
          find.image(const AssetImage('assets/images/splash_hero.png')),
          findsOneWidget,
        );

        // Must NOT find old padded native splash asset
        expect(
          find.image(const AssetImage('assets/images/logo_new_padded.png')),
          findsNothing,
        );
      },
    );

    testWidgets('displays poetic tagline and removes redundant "تالية" text', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSplashTestApp(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      // The tagline must be present
      expect(find.text('رفيقك في رحاب القرآن'), findsOneWidget);

      // The separate text 'تالية' must NOT be rendered (artwork already contains the calligraphy)
      expect(find.text('تالية'), findsNothing);
    });

    testWidgets('renders properly in dark theme without crash', (tester) async {
      await tester.pumpWidget(_buildSplashTestApp(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(
        find.image(const AssetImage('assets/images/splash_hero.png')),
        findsOneWidget,
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('renders properly in English with LTR tagline', (tester) async {
      await tester.pumpWidget(_buildSplashTestApp(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(
        find.text('Your Companion in the Journey of the Quran'),
        findsOneWidget,
      );
    });
  });
}
