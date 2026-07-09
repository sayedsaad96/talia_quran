import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_ayah_card.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('KidsGamifiedListenPage', () {
    testWidgets('renders ayah card, audio controls, and mic button', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var played = false;
      var recorded = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(currentLoop: 3),
            onBack: () {},
            onPlayPause: () => played = true,
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
          ),
        ),
      );

      expect(find.byType(KidsAyahCard), findsOneWidget);
      expect(find.text('Ayah 3'), findsOneWidget);
      expect(find.text('Listen and repeat'), findsWidgets);
      expect(find.text('Record your recitation'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('kids-gamified-play-audio')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
      );
      await tester.pump();

      expect(played, isTrue);
      expect(recorded, isTrue);
    });

    testWidgets('mic button stays disabled until all loops complete', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var recorded = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState,
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(recorded, isFalse);
    });

    testWidgets('isBuffering=true shows loading spinner on ayah card', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            // isBuffering=true but isPlaying can be false while URL is loading
            state: _baseState.copyWith(isPlaying: true, isBuffering: true),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
          ),
        ),
      );

      // The card should show "Preparing recitation..." (isAudioLoading = isBuffering)
      expect(find.text('Preparing recitation...'), findsOneWidget);
    });

    testWidgets(
      'isPlaying=true but isBuffering=false does NOT show loading spinner',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedListenContent(
              // Playing but not buffering — audio is actually playing
              state: _baseState.copyWith(
                isPlaying: true,
                isBuffering: false,
                currentLoop: 2,
              ),
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: () {},
            onStopRecording: () {},
            ),
          ),
        );

        // Should NOT show loading indicator when audio is playing (not buffering)
        expect(find.text('Preparing recitation...'), findsNothing);
      },
    );

    testWidgets('audioError shows unavailable message', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(audioError: 'network'),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
          ),
        ),
      );

      expect(
        find.text('Audio is unavailable right now. Please try again soon.'),
        findsOneWidget,
      );
    });

    testWidgets('isRecording=true shows recording indicator and disables play', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var played = false;
      var recorded = false;
      var stopped = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(isRecording: true),
            onBack: () {},
            onPlayPause: () => played = true,
            onRecordRecitation: () => recorded = true,
            onStopRecording: () => stopped = true,
          ),
        ),
      );

      // While recording, the panel appears with 'Recording...'
      expect(find.text('Recording...'), findsOneWidget);
      expect(find.byKey(const ValueKey('recording-panel')), findsOneWidget);

      // Tapping the disabled play button should NOT fire callback
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-play-audio')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(played, isFalse);

      // Tapping the stop button should fire onStopRecording
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-stop-recording')),
      );
      await tester.pump();
      expect(recorded, isFalse); // start recording was not called
      expect(stopped, isTrue); // stop recording was called
    });

    testWidgets('isCompleted=true disables mic button', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var recorded = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(isCompleted: true),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
          ),
        ),
      );

      // Mic button should be disabled — tapping should not fire
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(recorded, isFalse);
    });

    testWidgets('back button triggers onBack callback', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var backCalled = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState,
            onBack: () => backCalled = true,
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets('loop indicator shows correct count', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(currentLoop: 2),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
          ),
        ),
      );

      // Loop 2/3 displayed
      expect(find.text('2/3'), findsOneWidget);
    });

    test('tracks session stars separately from level stars', () {
      const leveledProgress = KidsProgress(
        totalPoints: 3500,
        currentLevel: 8,
        currentStreak: 3,
        starsEarned: 20,
        ayahsCompleted: 20,
        lastSessionAt: null,
      );
      final state = _baseState.copyWith(
        progress: leveledProgress,
        sessionStarsEarned: 1,
      );

      expect(state.progress.starsForLevel, 3);
      expect(state.sessionStarsEarned, 1);
    });
  });
}

final _baseState = KidsModeLoaded(
  surahId: 114,
  ayahNumber: 3,
  ayahText: 'Test ayah text',
  sessionState: _testSessionState(),
  progress: const KidsProgress(
    totalPoints: 150,
    currentLevel: 2,
    currentStreak: 3,
    starsEarned: 7,
    ayahsCompleted: 3,
    lastSessionAt: null,
  ),
  isPlaying: false,
  currentLoop: 1,
  maxLoops: 3,
  isCompleted: false,
);

V2SessionState _testSessionState() {
  return V2SessionState.initial(
    surahId: 114,
    blockAyahs: const [
      Ayah(
        number: 6234,
        surahId: 114,
        text: 'Test ayah text',
        numberInSurah: 3,
      ),
    ],
    blockReviewRequired: false,
  );
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
      home: Scaffold(body: child),
    );
  }
}
