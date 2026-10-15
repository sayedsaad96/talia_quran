import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_surah_split_sheet.dart';

Future<void> _open(
  WidgetTester tester, {
  required int ayahCount,
  int defaultStageSize = 3,
  bool initialWhole = false,
  int? initialStageSize,
  required void Function(KidsSurahSplitChoice?) onResult,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showKidsSurahSplitSheet(
                context,
                ayahCount: ayahCount,
                defaultStageSize: defaultStageSize,
                initialWhole: initialWhole,
                initialStageSize: initialStageSize,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('whole option hidden for 30 ayahs, shown for 3', (tester) async {
    await _open(tester, ayahCount: 30, onResult: (_) {});
    expect(find.text('How would you like to memorize it?'), findsOneWidget);
    expect(find.text('All at once'), findsNothing);
    expect(find.text('Ayahs per stage'), findsOneWidget);
  });

  testWidgets('whole option shown for 3 ayahs and at the 20 limit', (
    tester,
  ) async {
    await _open(tester, ayahCount: 3, onResult: (_) {});
    expect(find.text('All at once'), findsOneWidget);
    expect(find.text('In stages'), findsOneWidget);
  });

  testWidgets('whole option shown at exactly 20, hidden at 21', (tester) async {
    await _open(tester, ayahCount: 20, onResult: (_) {});
    expect(find.text('All at once'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await _open(tester, ayahCount: 21, onResult: (_) {});
    expect(find.text('All at once'), findsNothing);
  });

  testWidgets('stage count text updates: 30 ayahs, size 4 -> 8 stages', (
    tester,
  ) async {
    await _open(tester, ayahCount: 30, onResult: (_) {});
    expect(find.text('10 stages'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('kids-split-size-4')));
    await tester.pumpAndSettle();
    expect(find.text('8 stages'), findsOneWidget);
  });

  testWidgets('confirm returns KidsSurahSplitChoice(whole: false, size 4)', (
    tester,
  ) async {
    KidsSurahSplitChoice? result;
    await _open(tester, ayahCount: 30, onResult: (r) => result = r);
    await tester.tap(find.byKey(const ValueKey('kids-split-size-4')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(result?.whole, isFalse);
    expect(result?.stageSize, 4);
  });

  testWidgets('choosing whole returns whole: true without a size', (
    tester,
  ) async {
    KidsSurahSplitChoice? result;
    await _open(tester, ayahCount: 3, onResult: (r) => result = r);
    await tester.tap(find.text('All at once'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(result?.whole, isTrue);
    expect(result?.stageSize, isNull);
  });

  _currentChoiceTests();

  testWidgets('dismissing without choosing returns null', (tester) async {
    KidsSurahSplitChoice? result = const KidsSurahSplitChoice(whole: true);
    await _open(tester, ayahCount: 30, onResult: (r) => result = r);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}

void _currentChoiceTests() {
  testWidgets('initialWhole pre-selects all-at-once', (tester) async {
    KidsSurahSplitChoice? result;
    await _open(
      tester,
      ayahCount: 3,
      initialWhole: true,
      onResult: (r) => result = r,
    );
    expect(find.byKey(const ValueKey('kids-split-size-3')), findsNothing);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(result, const KidsSurahSplitChoice(whole: true));
  });

  testWidgets('initialStageSize 5 shows 5 selected', (tester) async {
    KidsSurahSplitChoice? result;
    await _open(
      tester,
      ayahCount: 30,
      initialStageSize: 5,
      onResult: (r) => result = r,
    );
    expect(find.text('6 stages'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const ValueKey('kids-split-size-5')),
    );
    expect(chip.selected, isTrue);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(result, const KidsSurahSplitChoice(whole: false, stageSize: 5));
  });
}
