import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/router/app_router.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/features/memorization_plus/data/datasources/kids_reading_receipt_store.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_daily_missions.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_page_cubit.dart';
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
    expect(find.byIcon(TaliaKidsIcons.arrowBack), findsOneWidget);
    expect(find.byIcon(TaliaKidsIcons.arrowForward), findsNothing);
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

  group('confirm the page (Plan 2)', () {
    const confirmKey = ValueKey('kids-reader-confirm-page');
    final now = DateTime(2026, 10, 2, 9);
    late KidsReadingReceiptStore store;
    late List<int> confirmCalls;
    late KidsReaderConfirmation confirmation;

    Future<void> setUpConfirmation({
      Future<bool> Function(int)? confirmRead,
      KidsReadingReceiptStore? withStore,
    }) async {
      SharedPreferences.setMockInitialValues({});
      store =
          withStore ??
          KidsReadingReceiptStore(
            await SharedPreferences.getInstance(),
            const FixedRecordOwnerProvider('a'),
            clock: () => now,
          );
      confirmCalls = [];
      confirmation = KidsReaderConfirmation(
        confirmRead:
            confirmRead ??
            (page) async {
              confirmCalls.add(page);
              return true;
            },
        store: store,
        clock: () => now,
      );
      addTearDown(confirmation.dispose);
    }

    Widget host({
      int page = 12,
      bool audioPlaying = false,
      Locale locale = const Locale('en'),
      double textScale = 1.0,
    }) => _TestApp(
      locale: locale,
      textScale: textScale,
      child: _PageHost(
        confirmation: confirmation,
        initialPage: page,
        audioPlaying: audioPlaying,
      ),
    );

    testWidgets('confirm and listen share one row on a 320px Arabic screen', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await setUpConfirmation();

      await tester.pumpWidget(
        _TestApp(
          locale: const Locale('ar'),
          child: KidsQuranReaderContent(
            pageNumber: 12,
            onBack: () {},
            reader: const SizedBox(),
            confirmation: confirmation,
            onTogglePageAudio: () {},
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final confirm = tester.getRect(find.byKey(confirmKey));
      final listen = tester.getRect(
        find.byKey(const ValueKey('kids-quran-page-audio')),
      );
      // Side by side: same row, no overlap, so the Mushaf keeps the height.
      expect(confirm.center.dy, closeTo(listen.center.dy, 1));
      expect(confirm.overlaps(listen.deflate(1)), isFalse);
    });

    testWidgets('confirm button records the page once', (tester) async {
      await setUpConfirmation();
      await tester.pumpWidget(host());

      expect(find.byKey(confirmKey), findsOneWidget);
      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump();

      expect(confirmCalls, [12]);
      expect(await store.pagesOn(kidsDayKey(now)), {12});
      expect(find.byKey(confirmKey), findsNothing);
      expect(find.text('Well done! Your reading is saved'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      // After the toast the saved state stays visible as a chip.
      expect(find.byKey(confirmKey), findsNothing);
      expect(find.text('Well done! Your reading is saved'), findsOneWidget);
    });

    testWidgets('turning to another page shows the button again', (
      tester,
    ) async {
      await setUpConfirmation();
      await tester.pumpWidget(host());
      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byKey(confirmKey), findsNothing);

      await tester.tap(find.byKey(const ValueKey('test-next-page')));
      await tester.pump();

      expect(find.byKey(confirmKey), findsOneWidget);
    });

    testWidgets('a page already confirmed today starts as confirmed', (
      tester,
    ) async {
      await setUpConfirmation();
      await store.recordPage(12);
      await confirmation.loadToday();
      await tester.pumpWidget(host());

      expect(find.byKey(confirmKey), findsNothing);
      expect(find.text('Well done! Your reading is saved'), findsOneWidget);
    });

    testWidgets('confirmation failure keeps the button and shows no success', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await setUpConfirmation(
        withStore: _ThrowingStore(await SharedPreferences.getInstance()),
      );
      await tester.pumpWidget(host());

      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(confirmKey), findsOneWidget);
      expect(find.text('Well done! Your reading is saved'), findsNothing);
    });

    testWidgets('a refused confirmRead records nothing', (tester) async {
      await setUpConfirmation(confirmRead: (_) async => false);
      await tester.pumpWidget(host());

      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump();

      expect(await store.pagesOn(kidsDayKey(now)), isEmpty);
      expect(find.byKey(confirmKey), findsOneWidget);
    });

    testWidgets('a page that is not the loaded detail records nothing', (
      tester,
    ) async {
      const loaded = QuranPageLoaded(
        QuranPageDetail(pageNumber: 13, surahs: [], ayahs: []),
      );
      expect(kidsReaderPageIsLoaded(loaded, 13), isTrue);
      expect(kidsReaderPageIsLoaded(loaded, 12), isFalse);
      expect(kidsReaderPageIsLoaded(QuranPageLoading(), 13), isFalse);
      expect(
        kidsReaderCanConfirmPage(loaded, currentPageNumber: 12, pageNumber: 12),
        isFalse,
      );
      expect(
        kidsReaderCanConfirmPage(loaded, currentPageNumber: 13, pageNumber: 13),
        isTrue,
      );

      // The page asks to confirm 12 while the shared cubit holds page 13.
      await setUpConfirmation(
        confirmRead: (page) async => kidsReaderPageIsLoaded(loaded, page),
      );
      await tester.pumpWidget(host());

      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump();

      expect(await store.pagesOn(kidsDayKey(now)), isEmpty);
      expect(find.byKey(confirmKey), findsOneWidget);
    });

    testWidgets('the button never appears while audio plays', (tester) async {
      await setUpConfirmation();
      await tester.pumpWidget(host(audioPlaying: true));

      expect(find.byKey(confirmKey), findsNothing);
    });

    testWidgets('no confirmation wiring hides the button', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          child: KidsQuranReaderContent(
            pageNumber: 12,
            onBack: () {},
            reader: const SizedBox(),
          ),
        ),
      );

      expect(find.byKey(confirmKey), findsNothing);
    });

    testWidgets('fits 320px Arabic at text scale 1.3', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.reset);
      await setUpConfirmation();

      await tester.pumpWidget(host(locale: const Locale('ar'), textScale: 1.3));
      expect(find.text('قرأت هذه الصفحة'), findsOneWidget);
      await tester.tap(find.byKey(confirmKey));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });
}

class _ThrowingStore extends KidsReadingReceiptStore {
  _ThrowingStore(SharedPreferences prefs)
    : super(prefs, const FixedRecordOwnerProvider('a'));

  @override
  Future<Set<int>> recordPage(int pageNumber) async =>
      throw StateError('disk full');
}

/// Mimics the page state: owns the current page and feeds the content.
class _PageHost extends StatefulWidget {
  const _PageHost({
    required this.confirmation,
    required this.initialPage,
    required this.audioPlaying,
  });

  final KidsReaderConfirmation confirmation;
  final int initialPage;
  final bool audioPlaying;

  @override
  State<_PageHost> createState() => _PageHostState();
}

class _PageHostState extends State<_PageHost> {
  late int _page = widget.initialPage;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      KidsQuranReaderContent(
        pageNumber: _page,
        onBack: () {},
        reader: const SizedBox(),
        confirmation: widget.confirmation,
        isAudioPlaying: widget.audioPlaying,
      ),
      Positioned(
        top: 0,
        left: 0,
        child: SizedBox(
          width: 1,
          height: 1,
          child: GestureDetector(
            key: const ValueKey('test-next-page'),
            onTap: () => setState(() => _page += 1),
          ),
        ),
      ),
    ],
  );
}

class _MockAudio extends Mock implements QuranAudioPlayerCubit {}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.child,
    this.locale = const Locale('en'),
    this.textScale = 1.0,
  });

  final Widget child;
  final Locale locale;
  final double textScale;

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
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
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
