import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_policy_controls.dart';

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
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  final goal = find.byKey(const ValueKey('kids-policy-session-goal'));

  testWidgets('a null session goal shows "Age default", not 6 (P3-R17)', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        KidsPolicyControls(policy: const KidsChildPolicy(), onChanged: (_) {}),
      ),
    );

    final dropdown = tester.widget<DropdownButton<int>>(goal);
    expect(
      find.descendant(of: goal, matching: find.text('Age default')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: goal, matching: find.text('6 minutes')),
      findsNothing,
    );
    expect(dropdown.items!.map((i) => i.value), [0, 6, 8, 10]);
  });

  testWidgets('choosing "Age default" saves a null goal', (tester) async {
    KidsChildPolicy? saved;
    await tester.pumpWidget(
      app(
        KidsPolicyControls(
          policy: const KidsChildPolicy(sessionGoalMinutes: 8, version: 2),
          onChanged: (p) => saved = p,
        ),
      ),
    );

    await tester.tap(goal);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Age default').last);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.sessionGoalMinutes, isNull);
    expect(saved!.version, 2);
  });

  testWidgets('choosing 6 from the age default saves 6', (tester) async {
    KidsChildPolicy? saved;
    await tester.pumpWidget(
      app(
        KidsPolicyControls(
          policy: const KidsChildPolicy(),
          onChanged: (p) => saved = p,
        ),
      ),
    );

    await tester.tap(goal);
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 minutes').last);
    await tester.pumpAndSettle();

    expect(saved?.sessionGoalMinutes, 6);
  });
}
