import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_progress_header.dart';

void main() {
  // Same pattern as the other kids page suites: disable the looping avatar
  // float animation so no Timer stays pending after tree disposal.
  setUpAll(() {
    Animate.defaultDuration = Duration.zero;
    Animate.restartOnHotReload = false;
  });

  group('KidsProgressHeader', () {
    testWidgets('shows the daily streak badge when a streak exists', (tester) async {
      // K12: the daily-consistency engine (currentStreak) was invisible to
      // kids; the header must surface it with the shared home streak label.
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      const progress = KidsProgress(
        totalPoints: 150,
        currentLevel: 2,
        currentStreak: 5,
        starsEarned: 7,
        ayahsCompleted: 3,
        lastSessionAt: null,
      );

      await tester.pumpWidget(
        const _TestApp(
          child: KidsProgressHeader(progress: progress),
        ),
      );

      expect(find.byKey(const ValueKey('kids-streak-badge')), findsOneWidget);
      expect(find.text('5-day streak'), findsOneWidget);
    });

    testWidgets('hides the streak badge when the streak is zero', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      const progress = KidsProgress.initial();

      await tester.pumpWidget(
        const _TestApp(
          child: KidsProgressHeader(progress: progress),
        ),
      );

      expect(find.byKey(const ValueKey('kids-streak-badge')), findsNothing);
      expect(find.textContaining('-day streak'), findsNothing);
    });

    testWidgets('renders at 320px without layout exceptions', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });

      const progress = KidsProgress(
        totalPoints: 150,
        currentLevel: 2,
        currentStreak: 5,
        starsEarned: 7,
        ayahsCompleted: 3,
        lastSessionAt: null,
      );

      await tester.pumpWidget(
        const _TestApp(
          child: SingleChildScrollView(
            child: KidsProgressHeader(progress: progress),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('kids-streak-badge')), findsOneWidget);
    });
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
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
