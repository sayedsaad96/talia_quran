import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
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
            gemsEarned: 3,
            onNext: () => nextTapped = true,
            onReturnToMap: () => mapTapped = true,
          ),
        ),
      );

      expect(find.text('Well done!'), findsOneWidget);
      expect(find.text('+2 stars'), findsOneWidget);
      expect(find.text('+3 gems'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Return to map'), findsOneWidget);

      await tester.tap(find.text('Next'));
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
            gemsEarned: 3,
            showNextButton: false,
            onNext: () {},
            onReturnToMap: () {},
          ),
        ),
      );

      expect(find.text('Next'), findsNothing);
      expect(find.text('Return to map'), findsOneWidget);
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
