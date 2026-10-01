import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/custom_plan_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/custom_plan_setup_page.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';

class _MockRepository extends Mock implements MemorizationPlusRepository {}

class _MockQuranRepository extends Mock implements QuranRepository {}

class _MockPathResolver extends Mock implements MemorizationPathResolver {}

void main() {
  late _MockRepository repository;
  late _MockPathResolver pathResolver;

  setUp(() async {
    await getIt.reset();
    repository = _MockRepository();
    pathResolver = _MockPathResolver();
    final quran = _MockQuranRepository();
    when(() => quran.getSurahs()).thenAnswer((_) async => const Right([]));
    when(
      () => repository.getCustomPlan(),
    ).thenAnswer((_) async => const Right(null));
    when(() => pathResolver.notifyChanged()).thenReturn(null);
    getIt
      ..registerSingleton<MemorizationPlusRepository>(repository)
      ..registerSingleton<QuranRepository>(quran)
      ..registerSingleton<MemorizationPathResolver>(pathResolver)
      ..registerFactory<CustomPlanCubit>(() => CustomPlanCubit(repository));
  });

  tearDown(() => getIt.reset());

  void profileIs(MemorizationProfile profile) => when(
    () => repository.getMemorizationProfile(),
  ).thenAnswer((_) async => Right(profile));

  Future<GoRouter> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.memorizationPlusCustomPlan,
      routes: [
        GoRoute(
          path: AppRoutes.memorizationPlusCustomPlan,
          builder: (_, _) => const CustomPlanSetupPage(),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlus,
          builder: (_, state) => Text(
            'kids path ${state.uri.queryParameters['preferred']} '
            '${state.uri.queryParameters['setup']}',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
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
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapChild(WidgetTester tester) async {
    final child = find.text('Child');
    await tester.ensureVisible(child);
    await tester.tap(child);
    await tester.pumpAndSettle();
  }

  MemorizationProfile adult() => MemorizationProfile.empty().copyWith(
    selectedPath: MemorizationPath.adult,
  );

  testWidgets('choosing Child confirms, resets the adult path, opens kids', (
    tester,
  ) async {
    profileIs(adult());
    when(
      () => repository.resetMemorizationIdentity(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
    await pump(tester);

    await tapChild(tester);
    expect(find.text('Switch to the kids path?'), findsOneWidget);
    verifyNever(() => repository.resetMemorizationIdentity());

    await tester.tap(find.byKey(const Key('custom_plan_child_switch_confirm')));
    await tester.pumpAndSettle();

    verify(() => repository.resetMemorizationIdentity()).called(1);
    verify(() => pathResolver.notifyChanged()).called(1);
    expect(find.text('kids path kids kids'), findsOneWidget);
  });

  testWidgets('cancelling keeps the adult path and the plan screen', (
    tester,
  ) async {
    profileIs(adult());
    await pump(tester);

    await tapChild(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.resetMemorizationIdentity());
    expect(find.text('kids path kids kids'), findsNothing);
    expect(find.byType(CustomPlanSetupPage), findsOneWidget);
  });

  testWidgets('with no path chosen yet it goes to kids without a reset', (
    tester,
  ) async {
    profileIs(MemorizationProfile.empty());
    await pump(tester);

    await tapChild(tester);

    verifyNever(() => repository.resetMemorizationIdentity());
    expect(find.text('kids path kids kids'), findsOneWidget);
  });
}
