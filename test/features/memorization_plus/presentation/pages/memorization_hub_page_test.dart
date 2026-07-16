import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/memorization_hub_page.dart';

void main() {
  setUp(() async {
    await getIt.reset();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'adult hub shows unified Today Practice Quiz Settings hierarchy',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1800);
      addTearDown(tester.view.reset);

      getIt.registerSingleton<MemorizationPlusRepository>(
        _ProfileRepository(_profile(MemorizationPath.adult)),
      );

      await tester.pumpWidget(const _TestApp(child: MemorizationHubPage()));
      await tester.pumpAndSettle();

      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text("Continue Today's Plan"), findsOneWidget);
      expect(find.text("View Today's Plan"), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Practice by Surah'), findsOneWidget);
      expect(find.textContaining('Recite Practice'), findsOneWidget);
      expect(find.text('Review Session'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Plan Settings'), findsOneWidget);
      expect(find.text('Parent Dashboard'), findsNothing);
    },
  );

  testWidgets('kids hub shows mission journey rewards only', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);

    getIt.registerSingleton<MemorizationPlusRepository>(
      _ProfileRepository(_profile(MemorizationPath.child)),
    );

    await tester.pumpWidget(const _TestApp(child: MemorizationHubPage()));
    await tester.pumpAndSettle();

    expect(find.text('Current Mission'), findsWidgets);
    expect(find.text('Journey'), findsWidgets);
    expect(find.text('Rewards / Progress'), findsWidgets);
    expect(find.text("Continue Today's Plan"), findsNothing);
    expect(find.text('Practice by Surah'), findsNothing);
    expect(find.text('Parent Dashboard'), findsNothing);
  });

  testWidgets('no path selected shows adult and kids setup choices', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1400);
    addTearDown(tester.view.reset);

    getIt.registerSingleton<MemorizationPlusRepository>(
      const _ProfileRepository(null),
    );

    await tester.pumpWidget(const _TestApp(child: MemorizationHubPage()));
    await tester.pumpAndSettle();

    expect(find.text('Adult Memorization'), findsOneWidget);
    expect(find.text('Kids Memorization'), findsOneWidget);
    expect(find.textContaining("Today's plan"), findsOneWidget);
    expect(find.textContaining('Current mission'), findsOneWidget);
    expect(find.text('Parent Dashboard'), findsNothing);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
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

class _ProfileRepository implements MemorizationPlusRepository {
  const _ProfileRepository(this.profile);

  final MemorizationProfile? profile;

  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      profile == null
      ? const Left(CacheFailure('No memorization profile'))
      : Right(profile!);

  @override
  Future<Either<Failure, DailyPlan?>> getCachedDailyPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, CustomMemorizationPlan?>> getCustomPlan() async =>
      const Right(null);

  @override
  Future<Either<Failure, List<AyahReviewRecord>>> getAllReviewRecords({
    ReviewRecordReadScope scope = ReviewRecordReadScope.adult,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<KidsSessionLog>>> getKidsSessionLogs() async =>
      const Right([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<bool> hasPendingCloudWork() async => false;
}
