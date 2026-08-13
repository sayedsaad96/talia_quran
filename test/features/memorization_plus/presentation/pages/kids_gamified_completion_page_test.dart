import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart';

void main() {
  group('KidsGamifiedCompletionPage', () {
    testWidgets('renders rewards and navigation actions', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      var nextTapped = false;
      var mapTapped = false;

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            onNext: () => nextTapped = true,
            onReturnToMap: () => mapTapped = true,
          ),
        ),
      );

      expect(find.text('Well done!'), findsOneWidget);
      expect(find.text('+2 stars'), findsOneWidget);
      expect(find.text('+3 gems'), findsNothing);
      expect(find.text('Start mission'), findsOneWidget);
      expect(find.text('Return to map'), findsOneWidget);

      await tester.tap(find.text('Start mission'));
      await tester.pump();
      await tester.tap(find.text('Return to map'));
      await tester.pump();

      expect(nextTapped, isTrue);
      expect(mapTapped, isTrue);
    });

    testWidgets('hides next button when showNextButton is false', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1200);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: KidsGamifiedCompletionContent(
            starsEarned: 2,
            showNextButton: false,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.text('Start mission'), findsNothing);
      expect(find.text('Return to map'), findsOneWidget);
    });

    test(
      'selects the current journey mission instead of incrementing ayah',
      () {
        const stages = [
          KidsJourneyStage(
            stageNumber: 1,
            surahId: 114,
            startAyah: 1,
            endAyah: 5,
            completedAyahs: [1, 2, 3, 4, 5],
            status: KidsJourneyStageStatus.completed,
          ),
          KidsJourneyStage(
            stageNumber: 2,
            surahId: 114,
            startAyah: 6,
            endAyah: 6,
            completedAyahs: [],
            status: KidsJourneyStageStatus.current,
          ),
        ];

        final mission = KidsJourneyMissionResolver.nextMission(stages);

        expect(mission?.surahId, 114);
        expect(mission?.ayahNumber, 6);
      },
    );
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
      home: child,
    );
  }
}
