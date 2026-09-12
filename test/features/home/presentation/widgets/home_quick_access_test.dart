import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_quick_access.dart';
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
    DateTime Function()? now,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, routerState) => Scaffold(
            body: HomeQuickAccess(
              state: state,
              skin: HomeSkin.forBrightness(Brightness.light),
              now: now,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.quranBookmarks,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.quranBookmarks);
            return const Scaffold(body: Text('bookmarks'));
          },
        ),
        GoRoute(
          path: '/azkar/morning',
          builder: (context, routerState) {
            pushedRoutes.add('/azkar/morning');
            return const Scaffold(body: Text('azkar-morning'));
          },
        ),
        GoRoute(
          path: '/azkar/evening',
          builder: (context, routerState) {
            pushedRoutes.add('/azkar/evening');
            return const Scaffold(body: Text('azkar-evening'));
          },
        ),
        GoRoute(
          path: '/quran/surah/18',
          builder: (context, routerState) {
            pushedRoutes.add('/quran/surah/18');
            return const Scaffold(body: Text('surah-18'));
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

  testWidgets('renders bookmarks and morning azkar on normal morning, no khatmah chip', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
    );
    // Tuesday 9 AM
    final tuesdayMorning = DateTime(2026, 9, 8, 9);

    await tester.pumpWidget(createHarness(
      state: state,
      pushedRoutes: pushedRoutes,
      now: () => tuesdayMorning,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(InkWell), findsNWidgets(2));
    expect(find.text('إشارة مرجعية'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('ابدأ ختمة'), findsNothing);

    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    expect(pushedRoutes, contains('/azkar/morning'));
  });

  testWidgets('renders evening azkar on evening', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'evening',
      activityStartDate: DateTime.utc(2026, 1, 1),
    );
    // Tuesday 7 PM (19:00)
    final tuesdayEvening = DateTime(2026, 9, 8, 19);

    await tester.pumpWidget(createHarness(
      state: state,
      pushedRoutes: pushedRoutes,
      now: () => tuesdayEvening,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الأذكار'));
    await tester.pumpAndSettle();
    expect(pushedRoutes, contains('/azkar/evening'));
  });

  testWidgets('renders Kahf chip in addition to azkar on Friday before 18:00', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
    );
    // Friday 10 AM
    final fridayMorning = DateTime(2026, 9, 11, 10);

    await tester.pumpWidget(createHarness(
      state: state,
      pushedRoutes: pushedRoutes,
      now: () => fridayMorning,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(InkWell), findsNWidgets(3));
    expect(find.text('إشارة مرجعية'), findsOneWidget);
    expect(find.text('الأذكار'), findsOneWidget);
    expect(find.text('سورة الكهف'), findsOneWidget);
    expect(find.text('ابدأ ختمة'), findsNothing);

    await tester.tap(find.text('سورة الكهف'));
    await tester.pumpAndSettle();
    expect(pushedRoutes, contains('/quran/surah/18'));
  });
}
