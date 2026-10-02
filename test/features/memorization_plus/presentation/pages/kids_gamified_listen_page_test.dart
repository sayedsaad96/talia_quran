import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/l10n/cubit_message_codes.dart';
import 'package:talia_quran/core/widgets/memorization_ayah_display.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_engine.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_ayah_card.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_chunky_button.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_policy_controller.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_scene.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('KidsGamifiedListenPage', () {
    testWidgets('after the listens the child tries from memory (K25)', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var played = false;
      var recorded = false;
      var tried = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(currentLoop: 3),
            onBack: () {},
            onPlayPause: () => played = true,
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
            onTryFromMemory: () => tried = true,
          ),
        ),
      );

      expect(find.byType(KidsAyahCard), findsOneWidget);
      expect(find.byType(MemorizationAyahDisplay), findsOneWidget);
      expect(find.text('Ayah 3'), findsOneWidget);
      expect(find.text('Listen and repeat'), findsWidgets);
      expect(find.text('3/3'), findsOneWidget);
      // Recall comes before the microphone (Product Rules 14.8).
      expect(find.text('Try from memory'), findsOneWidget);
      expect(find.text('Record your recitation'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('kids-gamified-play-audio')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-try-from-memory')),
      );
      await tester.pump();

      expect(played, isTrue);
      expect(tried, isTrue);
      expect(recorded, isFalse);
    });

    group('reviews start with recall (K28)', () {
      KidsModeLoaded reviewState() => KidsModeLoaded(
        surahId: 114,
        ayahNumber: 3,
        ayahText: 'Test ayah text',
        sessionState: V2SessionEngine().startReview(_testSessionState()),
        progress: _baseState.progress,
        isPlaying: false,
        currentLoop: 0,
        maxLoops: 0,
        isCompleted: false,
        isReview: true,
      );

      Future<void> pumpReview(
        WidgetTester tester, {
        required KidsModeLoaded state,
        VoidCallback? onRemind,
        VoidCallback? onRecord,
        Locale locale = const Locale('en'),
        Size size = const Size(900, 1200),
      }) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _TestApp(
            locale: locale,
            child: KidsGamifiedListenContent(
              state: state,
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: onRecord ?? () {},
              onStopRecording: () {},
              onTryFromMemory: () {},
              onRevealFirstWord: () {},
              onRemindMe: onRemind ?? () {},
            ),
          ),
        );
      }

      testWidgets('opens as a hidden review challenge with the mic ready', (
        tester,
      ) async {
        var reminded = false;
        var recorded = false;
        await pumpReview(
          tester,
          state: reviewState(),
          onRemind: () => reminded = true,
          onRecord: () => recorded = true,
        );

        expect(find.textContaining('Review challenge'), findsOneWidget);
        expect(find.byType(KidsAyahCard), findsNothing);
        expect(find.text('Test ayah text'), findsNothing);
        // No listening gate on a review.
        expect(find.text('0/0'), findsNothing);
        final play = tester.widget<KidsRoundActionButton>(
          find.byKey(const ValueKey('kids-gamified-play-audio')),
        );
        expect(play.onPressed, isNull);

        await tester.tap(
          find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
        );
        await tester.tap(find.byKey(const ValueKey('kids-gamified-remind-me')));
        await tester.pump();

        expect(recorded, isTrue);
        expect(reminded, isTrue);
      });

      testWidgets('a near miss in new memorization keeps the mic (fix)', (
        tester,
      ) async {
        final engine = V2SessionEngine();
        final reciting = engine.startReciting(
          engine.startMemorizing(engine.startLearning(_testSessionState())),
        );
        await pumpReview(
          tester,
          state: _baseState.copyWith(sessionState: reciting, currentLoop: 3),
        );

        expect(find.text('Try reciting without help'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
          findsOneWidget,
        );
        expect(find.text('Try from memory'), findsNothing);
        expect(
          find.byKey(const ValueKey('kids-gamified-remind-me')),
          findsOneWidget,
        );
      });

      testWidgets('fits a 320px Arabic screen', (tester) async {
        await pumpReview(
          tester,
          state: reviewState(),
          locale: const Locale('ar'),
          size: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('recalling from memory (K25)', () {
      Future<void> pumpRecall(
        WidgetTester tester, {
        required KidsModeLoaded state,
        VoidCallback? onRecord,
        VoidCallback? onReveal,
        Locale locale = const Locale('en'),
        Size size = const Size(900, 1200),
      }) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _TestApp(
            locale: locale,
            child: KidsGamifiedListenContent(
              state: state,
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: onRecord ?? () {},
              onStopRecording: () {},
              onTryFromMemory: () {},
              onRevealFirstWord: onReveal ?? () {},
            ),
          ),
        );
      }

      testWidgets('hides the ayah and offers the start and the mic', (
        tester,
      ) async {
        var recorded = false;
        var revealed = false;
        await pumpRecall(
          tester,
          state: _recallState(),
          onRecord: () => recorded = true,
          onReveal: () => revealed = true,
        );

        expect(find.byType(KidsAyahCard), findsNothing);
        expect(find.text('Test ayah text'), findsNothing);
        expect(find.text('Try to remember the ayah'), findsOneWidget);
        expect(find.text('Record your recitation'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('kids-gamified-first-word-hint')),
        );
        await tester.tap(
          find.byKey(const ValueKey('kids-gamified-record-recitation-idle')),
        );
        await tester.pump();

        expect(revealed, isTrue);
        expect(recorded, isTrue);
      });

      testWidgets('a revealed start shows only the first word', (tester) async {
        await pumpRecall(tester, state: _recallState(firstWordRevealed: true));

        expect(find.text('Test'), findsOneWidget);
        expect(
          find.text('Here is the first word — you finish it'),
          findsOneWidget,
        );
        expect(find.text('Test ayah text'), findsNothing);
        expect(
          find.byKey(const ValueKey('kids-gamified-first-word-hint')),
          findsNothing,
        );
      });

      testWidgets('recording hides the first word too', (tester) async {
        await pumpRecall(
          tester,
          state: _recallState(
            firstWordRevealed: true,
          ).copyWith(isRecording: true),
        );

        expect(find.text('Test'), findsNothing);
        expect(find.text('Test ayah text'), findsNothing);
      });

      testWidgets('fits a 320px Arabic screen', (tester) async {
        await pumpRecall(
          tester,
          state: _recallState(firstWordRevealed: true),
          locale: const Locale('ar'),
          size: const Size(320, 640),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('حاول تتذكّر الآية'), findsOneWidget);
      });
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

    testWidgets('listen-gated mic area shows a persistent hint that plays', (
      tester,
    ) async {
      // K8: with 1 of 3 required listens done, the mic slot must never be a
      // silent disabled button — it shows the remaining-listens hint instead.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var recorded = false;
      var played = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState,
            onBack: () {},
            onPlayPause: () => played = true,
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
          ),
        ),
      );

      expect(
        find.text('Listen to the ayah 2 times before recording your voice.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('kids-gamified-listen-first-hint')),
        findsOneWidget,
      );

      // Tapping the hint plays the audio (never records).
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-listen-first-hint')),
      );
      await tester.pump();

      expect(played, isTrue);
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

    testWidgets('audioError exposes the labelled manual completion action', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var manuallyCompleted = false;
      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(audioError: 'network'),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
            onManualComplete: () => manuallyCompleted = true,
          ),
        ),
      );

      expect(find.text('I finished memorizing'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('kids-gamified-manual-complete')),
      );
      expect(manuallyCompleted, isTrue);
    });

    testWidgets('recitation mismatch never exposes guardian completion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(
              recordingError: CubitMessageCodes.kidsRecitationMismatch,
            ),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
            onManualComplete: () {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('kids-gamified-manual-complete')),
        findsNothing,
      );
    });

    testWidgets(
      'a near-miss recitation shows the friendly word-progress banner',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1400);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedListenContent(
              state: _baseState.copyWith(
                recordingError: CubitMessageCodes.kidsRecitationMismatch,
                lastMatchedWords: 8,
                lastTargetWords: 10,
              ),
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: () {},
              onStopRecording: () {},
            ),
          ),
        );

        expect(
          find.byKey(const ValueKey('kids-close-match-feedback')),
          findsOneWidget,
        );
        expect(
          find.text(
            'So close! You got 8 of 10 words right. '
            'Listen again and try once more.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a total mismatch without matched words shows no misleading banner',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1400);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _TestApp(
            child: KidsGamifiedListenContent(
              state: _baseState.copyWith(
                recordingError: CubitMessageCodes.kidsRecitationMismatch,
                lastMatchedWords: 0,
                lastTargetWords: 2,
              ),
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: () {},
              onStopRecording: () {},
            ),
          ),
        );

        // "You got 0 of 2 words" is not encouraging feedback — hide the
        // banner and let the generic message speak instead.
        expect(
          find.byKey(const ValueKey('kids-close-match-feedback')),
          findsNothing,
        );
      },
    );
    testWidgets(
      'isRecording=true shows recording indicator and disables play',
      (tester) async {
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
        expect(find.text('Test ayah text'), findsNothing);
        expect(find.byType(KidsAyahCard), findsNothing);

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
      },
    );

    group('recording wave motion (K24)', () {
      Future<void> pumpRecording(
        WidgetTester tester, {
        required bool disableAnimations,
      }) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1200);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: _TestApp(
              child: KidsGamifiedListenContent(
                state: _baseState.copyWith(isRecording: true),
                onBack: () {},
                onPlayPause: () {},
                onRecordRecitation: () {},
                onStopRecording: () {},
              ),
            ),
          ),
        );
        // Let the panel's entrance transition finish.
        await tester.pump(const Duration(milliseconds: 400));
      }

      testWidgets('the wave moves while the child records', (tester) async {
        await pumpRecording(tester, disableAnimations: false);

        expect(tester.hasRunningAnimations, isTrue);
        // Remove the looping wave so the test can end cleanly.
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('the wave stays still with reduced motion', (tester) async {
        await pumpRecording(tester, disableAnimations: true);

        expect(tester.hasRunningAnimations, isFalse);
      });

      group('guardian reduce-motion policy (P3 Task 7)', () {
        tearDown(() {
          if (getIt.isRegistered<KidsPolicyController>()) {
            getIt.unregister<KidsPolicyController>();
          }
        });

        Future<KidsPolicyController> registerPolicy(
          KidsChildPolicy policy,
        ) async {
          final controller = KidsPolicyController(load: () async => policy);
          getIt.registerSingleton<KidsPolicyController>(controller);
          await controller.reload();
          return controller;
        }

        testWidgets('the wave stays still when the guardian reduces motion', (
          tester,
        ) async {
          await registerPolicy(const KidsChildPolicy(reduceMotion: true));
          await pumpRecording(tester, disableAnimations: false);

          expect(tester.hasRunningAnimations, isFalse);
        });

        testWidgets('turning the policy off re-enables motion live', (
          tester,
        ) async {
          final controller = await registerPolicy(
            const KidsChildPolicy(reduceMotion: true),
          );
          await pumpRecording(tester, disableAnimations: false);
          expect(tester.hasRunningAnimations, isFalse);

          controller.value = const KidsChildPolicy();
          await tester.pump();

          expect(tester.hasRunningAnimations, isTrue);
          await tester.pumpWidget(const SizedBox());
        });

        testWidgets('a motion-on policy keeps the recording wave', (
          tester,
        ) async {
          await registerPolicy(const KidsChildPolicy());
          await pumpRecording(tester, disableAnimations: false);

          expect(tester.hasRunningAnimations, isTrue);
          await tester.pumpWidget(const SizedBox());
        });
      });
    });

    testWidgets('isCompleted=true disables mic button', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var recorded = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenContent(
            state: _baseState.copyWith(isCompleted: true, currentLoop: 3),
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () => recorded = true,
            onStopRecording: () {},
            onTryFromMemory: () => recorded = true,
          ),
        ),
      );

      // Nothing is left to try once the ayah is done: no greyed-out ghost
      // button stays on screen.
      expect(
        find.byKey(const ValueKey('kids-gamified-try-from-memory')),
        findsNothing,
      );
      expect(recorded, isFalse);
    });

    testWidgets('visible labelled back control triggers onBack callback', (
      tester,
    ) async {
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

      expect(find.text('Go Back'), findsOneWidget);
      await tester.tap(find.text('Go Back'));
      await tester.pump();
      expect(backCalled, isTrue);
    });

    testWidgets('back control is localized in Arabic', (tester) async {
      await tester.pumpWidget(
        _TestApp(
          locale: const Locale('ar'),
          child: KidsGamifiedListenContent(
            state: _baseState,
            onBack: () {},
            onPlayPause: () {},
            onRecordRecitation: () {},
            onStopRecording: () {},
          ),
        ),
      );

      expect(find.text('العودة'), findsOneWidget);
    });

    testWidgets('loading shell keeps the labelled back control available', (
      tester,
    ) async {
      var backCalled = false;
      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedListenStatusShell(
            onBack: () => backCalled = true,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.text('Go Back'));
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

    test('completion state carries session points and level-up (K11)', () {
      // The completion route reads these from the cubit state, so points must
      // survive into the state that navigation serializes to the URL.
      final state = _baseState.copyWith(
        sessionPointsEarned: 14,
        leveledUpTo: 3,
      );

      expect(state.sessionPointsEarned, 14);
      expect(state.leveledUpTo, 3);
    });
  });

  group('Talia companion', () {
    test('takes a pose for each session moment', () {
      final engine = V2SessionEngine();
      final reciting = engine.startReciting(
        engine.startMemorizing(engine.startLearning(_testSessionState())),
      );

      expect(kidsTaliaPoseFor(_baseState), KidsTaliaPose.listening);
      expect(kidsTaliaPoseFor(_recallState()), KidsTaliaPose.thinking);
      expect(
        kidsTaliaPoseFor(_baseState.copyWith(sessionState: reciting)),
        KidsTaliaPose.thinking,
      );
      expect(
        kidsTaliaPoseFor(_baseState.copyWith(isRecording: true)),
        KidsTaliaPose.speaking,
      );
      expect(
        kidsTaliaPoseFor(_baseState.copyWith(isCompleted: true)),
        KidsTaliaPose.celebrate,
      );
      expect(
        kidsTaliaPoseFor(
          _baseState.copyWith(
            recordingError: CubitMessageCodes.kidsRecitationMismatch,
            lastMatchedWords: 3,
            lastTargetWords: 5,
          ),
        ),
        KidsTaliaPose.encourage,
      );
      expect(
        kidsTaliaPoseFor(
          KidsModeLoaded(
            surahId: 114,
            ayahNumber: 3,
            ayahText: 'Test ayah text',
            sessionState: engine.startReview(_testSessionState()),
            progress: _baseState.progress,
            isPlaying: false,
            currentLoop: 0,
            maxLoops: 0,
            isCompleted: false,
            isReview: true,
          ),
        ),
        KidsTaliaPose.pointRight,
      );
    });

    Future<void> pumpContent(
      WidgetTester tester,
      KidsModeLoaded state, {
      bool disableAnimations = false,
    }) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: _TestApp(
            child: KidsGamifiedListenContent(
              state: state,
              onBack: () {},
              onPlayPause: () {},
              onRecordRecitation: () {},
              onStopRecording: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('greets the child with a speech bubble', (tester) async {
      await pumpContent(tester, _baseState);

      expect(
        find.byKey(const ValueKey('kids-talia-companion')),
        findsOneWidget,
      );
      expect(find.text('Listen with me, then repeat it!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Talia and the scene keep still while the ayah plays', (
      tester,
    ) async {
      await pumpContent(tester, _baseState.copyWith(isPlaying: true));

      final talia = tester.widget<KidsTaliaCompanion>(
        find.byType(KidsTaliaCompanion),
      );
      final scene = tester.widget<KidsWorldScene>(
        find.byType(KidsWorldScene),
      );
      expect(talia.animate, isFalse);
      expect(scene.animate, isFalse);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('nothing loops with reduced motion', (tester) async {
      await pumpContent(
        tester,
        _baseState.copyWith(isPlaying: true),
        disableAnimations: true,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.hasRunningAnimations, isFalse);
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

/// The session after the listens, recalling the hidden ayah.
KidsModeLoaded _recallState({bool firstWordRevealed = false}) {
  final engine = V2SessionEngine();
  var session = engine.startMemorizing(
    engine.startLearning(_testSessionState()),
  );
  if (firstWordRevealed) {
    session = engine.useHint(session, V2HintLevel.firstWord);
  }
  return _baseState.copyWith(sessionState: session, currentLoop: 3);
}

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
  const _TestApp({required this.child, this.locale = const Locale('en')});

  final Widget child;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
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
