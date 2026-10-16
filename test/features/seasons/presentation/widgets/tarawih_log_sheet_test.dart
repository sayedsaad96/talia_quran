import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/seasons/data/tarawih_log_store.dart';
import 'package:talia_quran/features/seasons/presentation/widgets/tarawih_log_sheet.dart';

void main() {
  late TarawihLogStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = TarawihLogStore(
      await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('a'),
    );
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTarawihLogSheet(
              context,
              store,
              now: () => DateTime(2027, 2, 10, 22),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('saves tonight with Arabic digits, then deletes', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('tarawih_from')), '٣');
    await tester.enterText(find.byKey(const ValueKey('tarawih_to')), '٧');
    await tester.tap(find.byKey(const ValueKey('tarawih_save')));
    await tester.pumpAndSettle();
    expect(await store.entries(), const [
      TarawihEntry(nightKey: '2027-02-10', fromPage: 3, toPage: 7),
    ]);

    await open(tester);
    await tester.tap(find.byKey(const ValueKey('tarawih_delete')));
    await tester.pumpAndSettle();
    expect(await store.entries(), isEmpty);
  });

  testWidgets('invalid range shows an error and saves nothing', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('tarawih_from')), '9');
    await tester.enterText(find.byKey(const ValueKey('tarawih_to')), '2');
    await tester.tap(find.byKey(const ValueKey('tarawih_save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tarawih_invalid')), findsOneWidget);
    expect(await store.entries(), isEmpty);
  });
}
