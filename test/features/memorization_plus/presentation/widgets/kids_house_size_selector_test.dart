import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_house_size_selector.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  testWidgets('shows the saved preference and saves a new count', (
    tester,
  ) async {
    int? saved;
    await tester.pumpWidget(
      app(
        KidsHouseSizeSelector(
          current: 4,
          onSave: (value) async {
            saved = value;
            return true;
          },
        ),
      ),
    );
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byKey(const Key('kids_house_size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6').last);
    await tester.pumpAndSettle();
    expect(saved, 6);
  });

  testWidgets('failed save keeps the previous selection', (tester) async {
    await tester.pumpWidget(
      app(KidsHouseSizeSelector(current: 3, onSave: (_) async => false)),
    );
    await tester.tap(find.byKey(const Key('kids_house_size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('disables selection while save is pending', (tester) async {
    final pending = Completer<bool>();
    await tester.pumpWidget(
      app(KidsHouseSizeSelector(current: null, onSave: (_) => pending.future)),
    );
    await tester.tap(find.byKey(const Key('kids_house_size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final dropdown = tester.widget<DropdownButton<int>>(
      find.byKey(const Key('kids_house_size')),
    );
    expect(dropdown.onChanged, isNull);
    pending.complete(true);
    await tester.pumpAndSettle();
  });
}
