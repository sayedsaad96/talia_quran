import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/onboarding/presentation/pages/child_onboarding_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('explains Kids flow before entering memorization area', (
    tester,
  ) async {
    getIt.registerSingleton<MemorizationPlusRepository>(
      const _ChildOnboardingRepository(),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.childOnboarding,
      routes: [
        GoRoute(
          path: AppRoutes.childOnboarding,
          builder: (_, _) => const ChildOnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, _) => const Scaffold(body: Text('onboarding')),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlus,
          builder: (_, _) => const Scaffold(body: Text('kids setup')),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusKidsHome,
          builder: (_, _) => const Scaffold(body: Text('kids home')),
        ),
        GoRoute(
          path: AppRoutes.tutorialGuide,
          builder: (_, _) => const Scaffold(body: Text('guide')),
        ),
      ],
    );

    await tester.pumpWidget(_LocalizedRouter(router));
    await tester.pumpAndSettle();

    expect(find.text('Kids Mode'), findsOneWidget);
    expect(find.text('Missions'), findsOneWidget);
    expect(find.text('Rewards'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(find.text('Parent Follow-up'), findsOneWidget);

    await tester.tap(find.text('Start Kids Mode'));
    await tester.pumpAndSettle();

    expect(find.text('kids setup'), findsOneWidget);
  });

  testWidgets('routes existing Kids profile to Kids Home', (tester) async {
    getIt.registerSingleton<MemorizationPlusRepository>(
      _ChildOnboardingRepository(profile: _profile(MemorizationPath.child)),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.childOnboarding,
      routes: [
        GoRoute(
          path: AppRoutes.childOnboarding,
          builder: (_, _) => const ChildOnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusKidsHome,
          builder: (_, _) => const Scaffold(body: Text('kids home')),
        ),
      ],
    );

    await tester.pumpWidget(_LocalizedRouter(router));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Kids Mode'));
    await tester.pumpAndSettle();

    expect(find.text('kids home'), findsOneWidget);
    expect(find.text('kids setup'), findsNothing);
  });

  testWidgets('skips orientation when it was already seen', (tester) async {
    SharedPreferences.setMockInitialValues({'child_onboarding_seen': true});
    getIt.registerSingleton<MemorizationPlusRepository>(
      _ChildOnboardingRepository(profile: _profile(MemorizationPath.child)),
    );
    final router = GoRouter(
      initialLocation: AppRoutes.childOnboarding,
      routes: [
        GoRoute(
          path: AppRoutes.childOnboarding,
          builder: (_, _) => const ChildOnboardingPage(),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusKidsHome,
          builder: (_, _) => const Scaffold(body: Text('kids home')),
        ),
      ],
    );

    await tester.pumpWidget(_LocalizedRouter(router));
    await tester.pumpAndSettle();

    expect(find.text('kids home'), findsOneWidget);
    expect(find.text('Kids Mode'), findsNothing);
  });
}

class _LocalizedRouter extends StatelessWidget {
  const _LocalizedRouter(this.router);

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

MemorizationProfile _profile(MemorizationPath path) {
  final now = DateTime.utc(2026, 1, 1);
  return MemorizationProfile(
    schemaVersion: 1,
    selectedPath: path,
    guardianLinkStatus: GuardianLinkStatus.none,
    guardianOnboardingStatus: GuardianOnboardingStatus.skipped,
    isParentGuardian: false,
    createdAt: now,
    updatedAt: now,
  );
}

class _ChildOnboardingRepository implements MemorizationPlusRepository {
  const _ChildOnboardingRepository({this.profile});

  final MemorizationProfile? profile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      profile == null
      ? const Left(CacheFailure('No profile'))
      : Right(profile!);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords() async =>
      const Right([]);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
