import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/tutorial_guide/presentation/pages/tutorial_guide_page.dart';

void main() {
  testWidgets('uses LTR direction in English locale', (tester) async {
    await tester.pumpWidget(
      const _LocalizedApp(locale: Locale('en'), child: TutorialGuidePage()),
    );

    expect(_pageDirection(tester), TextDirection.ltr);
    await _drainGuideAnimations(tester);
  });

  testWidgets('keeps RTL direction in Arabic locale', (tester) async {
    await tester.pumpWidget(
      const _LocalizedApp(locale: Locale('ar'), child: TutorialGuidePage()),
    );

    expect(_pageDirection(tester), TextDirection.rtl);
    await _drainGuideAnimations(tester);
  });
}

Future<void> _drainGuideAnimations(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 2));
}

TextDirection _pageDirection(WidgetTester tester) {
  final directionality = tester.widget<Directionality>(
    find.byWidgetPredicate(
      (widget) => widget is Directionality && widget.child is Scaffold,
    ),
  );
  return directionality.textDirection;
}

class _LocalizedApp extends StatelessWidget {
  const _LocalizedApp({required this.locale, required this.child});

  final Locale locale;
  final Widget child;

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
