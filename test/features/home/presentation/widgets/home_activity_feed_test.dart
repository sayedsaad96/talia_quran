import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/home/domain/entities/activity_event.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_activity_feed.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

void main() {
  OverallProgress emptyProgress() => const OverallProgress(
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
        kidsPoints: 0,
        kidsStars: 0,
      );

  Widget createHarness({
    required HomeLoaded state,
    required List<String> pushedRoutes,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, routerState) => Scaffold(
            body: HomeActivityFeed(
              state: state,
              skin: HomeSkin.forBrightness(Brightness.light),
            ),
          ),
        ),
        GoRoute(
          path: '/quran',
          builder: (context, routerState) {
            pushedRoutes.add('/quran');
            return const Scaffold(body: Text('quran-page'));
          },
          routes: [
            GoRoute(
              path: 'page/:page',
              builder: (context, routerState) {
                final page = routerState.pathParameters['page'];
                final mode = routerState.uri.queryParameters['mode'];
                pushedRoutes.add('/quran/page/$page${mode != null ? '?mode=$mode' : ''}');
                return Scaffold(body: Text('page-$page'));
              },
            ),
            GoRoute(
              path: 'surah/:surahId',
              builder: (context, routerState) {
                final surahId = routerState.pathParameters['surahId'];
                pushedRoutes.add('/quran/surah/$surahId');
                return Scaffold(body: Text('surah-$surahId'));
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.memorizationV2Session,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.memorizationV2Session);
            return const Scaffold(body: Text('review-session'));
          },
        ),
        GoRoute(
          path: AppRoutes.hifzPracticeSurah,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.hifzPracticeSurah);
            return const Scaffold(body: Text('practice-surah'));
          },
        ),
        GoRoute(
          path: AppRoutes.memorizationHub,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.memorizationHub);
            return const Scaffold(body: Text('memorization-hub'));
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: const Locale('ar'),
    );
  }

  testWidgets('does not render view all text button pointing to progress', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      recentActivity: [
        ActivityEvent(
          occurredAt: DateTime.now(),
          kind: ActivityEventKind.reading,
          idempotencyKey: 'k1',
          pageNumber: 10,
        ),
      ],
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    // Verify "عرض الكل" or "View all" is not rendered
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('tapping reading activity navigates directly to quran page', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      recentActivity: [
        ActivityEvent(
          occurredAt: DateTime.now(),
          kind: ActivityEventKind.reading,
          idempotencyKey: 'k1',
          pageNumber: 42,
        ),
      ],
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('42'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains('/quran/page/42'));
  });

  testWidgets('tapping khatmah activity navigates to page in khatmah mode', (tester) async {
    final pushedRoutes = <String>[];
    final plan = KhatmahPlan(
      id: 'kp1',
      title: 'Khatmah',
      status: KhatmahStatus.active,
      targetPagesPerDay: 4,
      targetDays: 30,
      startDate: DateTime.now(),
      expectedEndDate: DateTime.now().add(const Duration(days: 30)),
      dailyTargetDate: DateTime.now(),
      dailyTargetStartPage: 1,
      dailyTargetEndPage: 4,
      completedPages: {1, 2},
    );
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      activeKhatmah: plan,
      recentActivity: [
        ActivityEvent(
          occurredAt: DateTime.now(),
          kind: ActivityEventKind.khatmah,
          idempotencyKey: 'k2',
          pageNumber: 3,
        ),
      ],
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('3'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains('/quran/page/3?mode=khatmah'));
  });

  testWidgets('tapping review activity navigates to memorization session', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      recentActivity: [
        ActivityEvent(
          occurredAt: DateTime.now(),
          kind: ActivityEventKind.review,
          idempotencyKey: 'k3',
          surahId: 1,
          startAyah: 1,
          endAyah: 7,
        ),
      ],
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains(AppRoutes.memorizationV2Session));
  });
}
