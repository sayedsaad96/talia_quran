import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/content/content_manifest_summary.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/settings/presentation/pages/subpages/about_settings_page.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_cubit.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_state.dart';
import 'package:talia_quran/features/settings/presentation/pages/trust_center_page.dart';

class _MockSettingsCubit extends Mock implements SettingsCubit {}

Widget _app(Widget home, {List<GoRoute> extra = const []}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: AppRoutes.sourcesLicenses,
        builder: (_, _) => const Scaffold(body: Text('sources-page')),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (_, _) => const Scaffold(body: Text('privacy-page')),
      ),
      GoRoute(
        path: AppRoutes.trustCenter,
        builder: (_, _) => const Scaffold(body: Text('trust-page')),
      ),
      ...extra,
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
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
  redirectTests();
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => getIt.reset());

  testWidgets(
    'page shows three cards; meta line hidden when summary null; buttons push routes',
    (tester) async {
      await tester.pumpWidget(
        _app(
          TrustCenterPage(
            summaryFuture: Future.value(
              const ContentManifestSummary(
                datasetVersion: 'v9',
                sourceCount: 4,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Verified sources'), findsOneWidget);
      expect(find.text('Your voice'), findsOneWidget);
      expect(find.text('Your data'), findsOneWidget);
      expect(find.text('Data version v9 • 4 sources'), findsOneWidget);

      await tester.tap(find.text('View sources and licenses'));
      await tester.pumpAndSettle();
      expect(find.text('sources-page'), findsOneWidget);
    },
  );

  testWidgets('privacy button pushes the privacy policy route', (tester) async {
    await tester.pumpWidget(
      _app(TrustCenterPage(summaryFuture: Future.value(null))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();
    expect(find.text('privacy-page'), findsOneWidget);
  });

  testWidgets('meta line uses the singular form for one source', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        TrustCenterPage(
          summaryFuture: Future.value(
            const ContentManifestSummary(datasetVersion: 'v9', sourceCount: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Data version v9 • 1 source'), findsOneWidget);
  });

  testWidgets('meta line hidden when summary is null', (tester) async {
    await tester.pumpWidget(
      _app(TrustCenterPage(summaryFuture: Future.value(null))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Data version'), findsNothing);
    expect(find.text('Verified sources'), findsOneWidget);
  });

  Future<void> pumpAbout(WidgetTester tester) async {
    final cubit = _MockSettingsCubit();
    when(() => cubit.state).thenReturn(const SettingsState());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.close()).thenAnswer((_) async {});
    await tester.pumpWidget(
      _app(
        BlocProvider<SettingsCubit>.value(
          value: cubit,
          child: const AboutSettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('settings tile hidden when flag off or not registered', (
    tester,
  ) async {
    await pumpAbout(tester);
    expect(find.text('How we protect content and your privacy'), findsNothing);

    getIt.registerSingleton<ExperienceFlags>(const ExperienceFlags(_off));
    await pumpAbout(tester);
    expect(find.text('How we protect content and your privacy'), findsNothing);
  });

  testWidgets('settings tile shown when flag on and opens the page', (
    tester,
  ) async {
    getIt.registerSingleton<ExperienceFlags>(const ExperienceFlags(_on));
    await pumpAbout(tester);
    final tile = find.text('How we protect content and your privacy');
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.text('trust-page'), findsOneWidget);
  });
}

bool _off(String key) => false;
bool _on(String key) => key == ExperienceFeature.trustCenter.storageKey;

void redirectTests() {
  group('trustCenterRedirect', () {
    test('flag off leads to settings', () {
      expect(
        trustCenterRedirect(const ExperienceFlags(_off)),
        AppRoutes.settings,
      );
    });
    test('flags unregistered leads to settings', () {
      expect(trustCenterRedirect(null), AppRoutes.settings);
    });
    test('flag on allows the route', () {
      expect(trustCenterRedirect(const ExperienceFlags(_on)), isNull);
    });
  });
}
