import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/pages/kids_quran_reader_page.dart';

void main() {
  testWidgets('Kids Quran mode can return to Kids Home', (tester) async {
    var returned = false;

    await tester.pumpWidget(
      _TestApp(
        child: KidsQuranReaderContent(
          pageNumber: 604,
          surahName: 'An-Nas',
          onBack: () => returned = true,
          reader: const Center(child: Text('kids quran page content')),
        ),
      ),
    );

    expect(find.text('Kids Quran'), findsOneWidget);
    expect(find.text('kids quran page content'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to Kids Home'));
    await tester.pump();

    expect(returned, isTrue);
  });

  testWidgets('Kids Quran mode does not show adult-only reader controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        child: KidsQuranReaderContent(
          pageNumber: 604,
          onBack: () {},
          reader: const Center(child: Text('kids quran page content')),
        ),
      ),
    );

    expect(find.text('Copy'), findsNothing);
    expect(find.text('Bookmark'), findsNothing);
    expect(find.text('Tafsir'), findsNothing);
    expect(find.text('Kids Quran'), findsOneWidget);
  });

  testWidgets('Adult Quran route remains separate from Kids Quran route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.quran,
      routes: [
        GoRoute(
          path: AppRoutes.quran,
          builder: (_, _) => const Scaffold(body: Text('adult quran route')),
        ),
        GoRoute(
          path: AppRoutes.memorizationPlusKidsQuran,
          builder: (_, _) => const Scaffold(body: Text('kids quran route')),
        ),
      ],
    );

    await tester.pumpWidget(_RouterTestApp(router: router));
    await tester.pumpAndSettle();

    expect(find.text('adult quran route'), findsOneWidget);
    expect(find.text('kids quran route'), findsNothing);

    router.go(AppRoutes.memorizationPlusKidsQuran);
    await tester.pumpAndSettle();

    expect(find.text('kids quran route'), findsOneWidget);
    expect(find.text('adult quran route'), findsNothing);
  });

  testWidgets('Kids Quran mode supports Arabic RTL layout', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        locale: const Locale('ar'),
        child: KidsQuranReaderContent(
          pageNumber: 604,
          surahName: 'الناس',
          onBack: () {},
          reader: const Center(child: Text('محتوى القرآن')),
        ),
      ),
    );

    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(find.text('قرآن الأطفال'), findsOneWidget);
  });

  testWidgets('the back arrow points back in English (K22)', (tester) async {
    await tester.pumpWidget(
      _TestApp(
        child: KidsQuranReaderContent(
          pageNumber: 604,
          onBack: () {},
          reader: const SizedBox(),
        ),
      ),
    );

    // arrow_back mirrors itself under RTL; a hand-picked "forward" arrow
    // pointed English readers the wrong way.
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  group('read and listen (K26)', () {
    const color = Colors.green;

    test('marks the mission ayah while nothing plays', () {
      final highlights = kidsReaderHighlights(
        audio: const QuranAudioPlayerState(),
        missionSurahId: 114,
        missionAyah: 3,
        color: color,
      );

      expect(highlights, hasLength(1));
      expect(highlights.single.surah, 114);
      expect(highlights.single.verseNumber, 3);
      expect(highlights.single.page, 604);
    });

    test('follows the ayah being recited instead', () {
      final highlights = kidsReaderHighlights(
        audio: const QuranAudioPlayerState(
          status: PlaybackStatus.playing,
          currentSurahId: 114,
          currentAyahNumber: 5,
          currentPageNumber: 604,
          scope: PlayScope.page,
        ),
        missionSurahId: 114,
        missionAyah: 3,
        color: color,
      );

      expect(highlights, hasLength(1));
      expect(highlights.single.verseNumber, 5);
    });

    test('has nothing to mark without a mission or audio', () {
      expect(
        kidsReaderHighlights(
          audio: const QuranAudioPlayerState(),
          color: color,
        ),
        isEmpty,
      );
    });

    group('audio controller', () {
      late _MockAudio audio;
      late KidsReaderAudioController controller;

      setUp(() {
        audio = _MockAudio();
        controller = KidsReaderAudioController(audio);
        when(() => audio.playAyah(any(), any())).thenAnswer((_) async {});
        when(() => audio.playPage(any())).thenAnswer((_) async {});
        when(() => audio.stop()).thenAnswer((_) async {});
      });

      test('a long press recites that ayah once', () async {
        await controller.playAyah(114, 3);

        verify(() => audio.playAyah(114, 3)).called(1);
      });

      test('the page button plays (or toggles) this page', () async {
        await controller.togglePage(604);

        verify(() => audio.playPage(604)).called(1);
      });

      test('leaving stops the recitation the reader started', () async {
        when(() => audio.state).thenReturn(
          const QuranAudioPlayerState(status: PlaybackStatus.playing),
        );
        await controller.playAyah(114, 3);

        await controller.stopIfStarted();

        verify(() => audio.stop()).called(1);
      });

      test('leaving never stops audio it did not start', () async {
        when(() => audio.state).thenReturn(
          const QuranAudioPlayerState(status: PlaybackStatus.playing),
        );

        await controller.stopIfStarted();

        verifyNever(() => audio.stop());
      });
    });

    testWidgets('the footer teaches the long press and plays the page', (
      tester,
    ) async {
      var toggled = false;
      await tester.pumpWidget(
        _TestApp(
          child: KidsQuranReaderContent(
            pageNumber: 604,
            onBack: () {},
            reader: const SizedBox(),
            onTogglePageAudio: () => toggled = true,
          ),
        ),
      );

      expect(find.text('Long-press any ayah to hear it'), findsOneWidget);
      await tester.tap(find.text('Listen to the page'));
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('the page button pauses while the page plays', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: KidsQuranReaderContent(
            pageNumber: 604,
            onBack: () {},
            reader: const SizedBox(),
            isPagePlaying: true,
            onTogglePageAudio: () {},
          ),
        ),
      );

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Listen to the page'), findsNothing);
    });

    testWidgets('the footer fits a 320px Arabic screen', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          locale: const Locale('ar'),
          child: KidsQuranReaderContent(
            pageNumber: 604,
            surahName: 'الناس',
            onBack: () {},
            reader: const SizedBox(),
            onTogglePageAudio: () {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

class _MockAudio extends Mock implements QuranAudioPlayerCubit {}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child, this.locale = const Locale('en')});

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
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

class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
