import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/guardian_promise_dialog.dart';

void main() {
  GuardianPromiseDraft? result;

  Future<void> open(
    WidgetTester tester, {
    List<int> surahIds = const [114, 113, 112],
  }) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<GuardianPromiseDraft>(
                  context: context,
                  builder: (_) => GuardianPromiseDialog(surahIds: surahIds),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('guardian-promise-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('the title field takes at most 80 characters', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'ا' * 95);
    await save(tester);

    expect(result?.title.length, 80);
  });

  testWidgets('an empty title is refused', (tester) async {
    await open(tester);

    await save(tester);

    expect(result, isNull);
    expect(find.byType(GuardianPromiseDialog), findsOneWidget);
  });

  testWidgets('an example chip fills the title', (tester) async {
    await open(tester);

    await tester.tap(find.text('كتاب جديد'));
    await tester.pump();
    await save(tester);

    expect(result?.title, 'كتاب جديد');
    expect(result?.milestoneSurahId, isNull);
  });

  testWidgets('a chosen surah is returned with the title', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'نزهة');
    await tester.tap(find.byKey(const ValueKey('guardian-promise-surah')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإخلاص').last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(result?.title, 'نزهة');
    expect(result?.milestoneSurahId, 112);
  });

  testWidgets('without surah choices no condition picker is shown', (
    tester,
  ) async {
    await open(tester, surahIds: const []);

    expect(find.byKey(const ValueKey('guardian-promise-surah')), findsNothing);
  });
}
