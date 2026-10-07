import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/progress/progress_events_bus.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/streak_reader.dart';
import 'package:talia_quran/core/theme/app_theme.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart';
import 'package:talia_quran/features/memorization_plus/data/models/memorization_models.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/daily_plan_page.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/streak/domain/entities/streak_entity.dart';

void main() {
  // N6: the theme's colored AppBar title style overrode the page's white
  // foreground, drawing a near-black title on the dark teal bar (~2:1).
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('header title is readable on its bar ($name)', (tester) async {
      final repository = await _repositoryForPlan(
        DailyPlan(
          generatedAt: DateTime.now().toUtc(),
          surahId: 1,
          newAyahs: const [],
          nearRevision: const [],
          farRevision: const [],
          completedAyahNums: const [],
        ),
        withActivePlan: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: DailyPlanPage(repositoryOverride: repository),
        ),
      );
      await tester.pumpAndSettle();

      expect(headerTitleContrast(tester, "Today's Plan"), greaterThan(4.5));
    });
  }

  testWidgets('DailyPlanPage shows buckets and completion checkmarks', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final datasource = MemorizationPlusLocalDatasourceImpl(prefs);
    final plan = DailyPlan(
      generatedAt: DateTime.now().toUtc(),
      surahId: 67,
      newAyahs: const [
        DailyPlanAyah(
          surahId: 67,
          ayahNumber: 1,
          ayahText: 'text',
          record: null,
        ),
        DailyPlanAyah(
          surahId: 67,
          ayahNumber: 2,
          ayahText: 'text',
          record: null,
        ),
      ],
      nearRevision: const [],
      farRevision: const [],
      completedAyahNums: const [1],
    );
    await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
    await datasource.saveCustomPlan(
      CustomMemorizationPlanModel.fromEntity(_activeAdultPlan),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DailyPlanPage(
          repositoryOverride: MemorizationPlusRepositoryImpl(
            datasource,
            _UnusedQuranRepository(),
            _FakeStreakReader(),
            ProgressEventsBus(),
            prefs,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Plan"), findsOneWidget);
    expect(find.textContaining('1 completed'), findsOneWidget);
    expect(find.byIcon(TaliaIcons.checkCircleFilled), findsOneWidget);
    expect(find.byIcon(TaliaIcons.circle), findsOneWidget);
  });

  testWidgets('without an active plan it invites creating one (M-U2)', (
    tester,
  ) async {
    final repository = await _repositoryForPlan(
      DailyPlan(
        generatedAt: DateTime.now().toUtc(),
        surahId: 1,
        newAyahs: const [],
        nearRevision: const [],
        farRevision: const [],
        completedAyahNums: const [],
      ),
      withActivePlan: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: DailyPlanPage(repositoryOverride: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("You haven't created a memorization plan yet"),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('daily_plan_create_plan_button')),
      findsOneWidget,
    );
    expect(find.text('Well done! No reviews are due today'), findsNothing);
  });

  testWidgets('tapping a plan ayah opens its exact surah and ayah', (
    tester,
  ) async {
    final plan = DailyPlan(
      generatedAt: DateTime.now().toUtc(),
      surahId: 67,
      newAyahs: const [],
      weakRecovery: const [
        DailyPlanAyah(
          surahId: 36,
          ayahNumber: 3,
          ayahText: 'text',
          record: null,
        ),
      ],
      nearRevision: const [],
      farRevision: const [],
      completedAyahNums: const [],
    );
    final repository = await _repositoryForPlan(plan);
    final router = GoRouter(
      initialLocation: '/plan',
      routes: [
        GoRoute(
          path: '/plan',
          builder: (_, _) => DailyPlanPage(repositoryOverride: repository),
        ),
        GoRoute(
          path: AppRoutes.memorizationV2Session,
          builder: (_, state) => Scaffold(
            body: Text(
              '${state.uri.queryParameters['surahId']}:'
              '${state.uri.queryParameters['startAyah']}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
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

    await tester.tap(find.text('Ya-Sin · Ayah 3'));
    await tester.pumpAndSettle();

    expect(find.text('36:3'), findsOneWidget);
  });
}

Future<MemorizationPlusRepositoryImpl> _repositoryForPlan(
  DailyPlan plan, {
  bool withActivePlan = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final datasource = MemorizationPlusLocalDatasourceImpl(prefs);
  await datasource.saveDailyPlan(DailyPlanModel.fromEntity(plan));
  if (withActivePlan) {
    await datasource.saveCustomPlan(
      CustomMemorizationPlanModel.fromEntity(_activeAdultPlan),
    );
  }
  return MemorizationPlusRepositoryImpl(
    datasource,
    _UnusedQuranRepository(),
    _FakeStreakReader(),
    ProgressEventsBus(),
    prefs,
  );
}

class _FakeStreakReader implements StreakReader {
  @override
  Future<StreakEntity> getStreak() async =>
      const StreakEntity(currentStreak: 0, longestStreak: 0);
}

class _UnusedQuranRepository implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _activeAdultPlan = CustomMemorizationPlan(
  name: 'plan',
  startSurahId: 67,
  endSurahId: 114,
  newAyahsPerDay: 3,
  availableDaysPerWeek: 7,
  sessionMinutes: 30,
  difficulty: MemorizationDifficulty.moderate,
  enableNearRevision: true,
  enableFarRevision: true,
  nearRevisionCount: 5,
  farRevisionCount: 3,
  startAyah: 1,
  createdAt: DateTime.utc(2026, 9, 1),
);

/// Contrast ratio between an AppBar title and the color behind it (the bar,
/// or the scaffold when the bar is transparent).
double headerTitleContrast(WidgetTester tester, String title) {
  final appBar = find.byType(AppBar);
  final paragraph = tester.widget<RichText>(
    find.descendant(
      of: appBar,
      matching: find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == title,
      ),
    ),
  );
  final fg = paragraph.text.style!.color!;
  var bg = tester
      .widget<Material>(
        find.descendant(of: appBar, matching: find.byType(Material)).first,
      )
      .color!;
  if (bg.a < 1) {
    bg =
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor ??
        Theme.of(tester.element(appBar)).scaffoldBackgroundColor;
  }
  final l1 = fg.computeLuminance();
  final l2 = bg.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}
