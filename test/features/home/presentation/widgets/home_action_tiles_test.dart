import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/features/home/domain/entities/ayah_of_day.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_action_tiles.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

class FakeQuranContinuousPlayerService implements QuranContinuousPlayerService {
  int? playedSurahId;
  int? playedAyahNumber;

  @override
  Future<void> playAyah(
    int surahId,
    int ayahNumber, {
    QuranReciter? reciter,
    PlayScope scope = PlayScope.surah,
  }) async {
    playedSurahId = surahId;
    playedAyahNumber = ayahNumber;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeQuranContinuousPlayerService player;

  setUp(() async {
    await getIt.reset();
    player = FakeQuranContinuousPlayerService();
    getIt.registerSingleton<QuranContinuousPlayerService>(player);
  });

  tearDown(() async {
    await getIt.reset();
  });

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
            body: HomeActionTiles(
              state: state,
              skin: HomeSkin.forBrightness(Brightness.light),
            ),
          ),
        ),
        GoRoute(
          path: '/quran',
          builder: (context, routerState) {
            pushedRoutes.add('/quran');
            return const Scaffold(body: Text('quran'));
          },
          routes: [
            GoRoute(
              path: 'page/:page',
              builder: (context, routerState) {
                final page = routerState.pathParameters['page'];
                pushedRoutes.add('/quran/page/$page');
                return Scaffold(body: Text('page-$page'));
              },
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.memorizationV2Session,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.memorizationV2Session);
            return const Scaffold(body: Text('review'));
          },
        ),
        GoRoute(
          path: AppRoutes.hifzPracticeSurah,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.hifzPracticeSurah);
            return const Scaffold(body: Text('memorize'));
          },
        ),
        GoRoute(
          path: AppRoutes.memorizationHub,
          builder: (context, routerState) {
            pushedRoutes.add(AppRoutes.memorizationHub);
            return const Scaffold(body: Text('hub'));
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

  testWidgets('Review tile navigates directly to memorizationV2Session', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('مراجعة'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains(AppRoutes.memorizationV2Session));
  });

  testWidgets('Memorize tile navigates directly to hifzPracticeSurah', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains(AppRoutes.hifzPracticeSurah));
  });

  testWidgets('Read tile navigates to last restorable location if available', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      lastRestorableLocation: '/quran/page/45',
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('قراءة'));
    await tester.pumpAndSettle();

    expect(pushedRoutes, contains('/quran/page/45'));
  });

  testWidgets('Listen tile plays ayah when ayahOfDay is present', (tester) async {
    final pushedRoutes = <String>[];
    final state = HomeLoaded(
      progress: emptyProgress(),
      greeting: 'morning',
      activityStartDate: DateTime.utc(2026, 1, 1),
      ayahOfDay: const AyahOfDay(
        surahId: 2,
        ayahNumber: 255,
        text: 'الله لا إله إلا هو',
        surahNameAr: 'البقرة',
        surahNameEn: 'Al-Baqarah',
        pageNumber: 42,
      ),
    );

    await tester.pumpWidget(createHarness(state: state, pushedRoutes: pushedRoutes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تسميع'));
    await tester.pumpAndSettle();

    expect(player.playedSurahId, 2);
    expect(player.playedAyahNumber, 255);
    expect(pushedRoutes, isEmpty);
  });
}
