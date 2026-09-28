import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_loading_widget.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
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

  testWidgets('error action defaults to Try again', (tester) async {
    await tester.pumpWidget(app(KidsErrorWidget(onRetry: () {})));

    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('a daily-limit error leads back instead of retrying (N3)', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      app(
        KidsErrorWidget(
          message: 'done for today',
          actionLabel: 'Go Back',
          onRetry: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Try Again'), findsNothing);
    await tester.tap(find.text('Go Back'));
    expect(tapped, isTrue);
  });
}
