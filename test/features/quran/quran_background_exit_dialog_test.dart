import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_background_exit_dialog.dart';

void main() {
  Widget buildTestApp({
    required void Function(BuildContext) onOpenDialog,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onOpenDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders dialog and returns continueInBackground on tap', (tester) async {
    QuranBackgroundExitAction? result;

    await tester.pumpWidget(
      buildTestApp(
        onOpenDialog: (context) async {
          result = await showQuranBackgroundExitDialog(
            context: context,
            surahName: 'الفاتحة',
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('التلاوة قيد التشغيل'), findsOneWidget);
    expect(find.textContaining('سورة الفاتحة'), findsOneWidget);
    expect(find.text('متابعة في الخلفية'), findsOneWidget);
    expect(find.text('إيقاف التلاوة والخروج'), findsOneWidget);
    expect(find.text('البقاء في التطبيق'), findsOneWidget);

    await tester.tap(find.text('متابعة في الخلفية'));
    await tester.pumpAndSettle();

    expect(result, QuranBackgroundExitAction.continueInBackground);
  });

  testWidgets('returns stopAndExit when stop button is tapped', (tester) async {
    QuranBackgroundExitAction? result;

    await tester.pumpWidget(
      buildTestApp(
        onOpenDialog: (context) async {
          result = await showQuranBackgroundExitDialog(
            context: context,
            surahName: 'البقرة',
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('إيقاف التلاوة والخروج'));
    await tester.pumpAndSettle();

    expect(result, QuranBackgroundExitAction.stopAndExit);
  });

  testWidgets('returns null when cancel/stay button is tapped', (tester) async {
    QuranBackgroundExitAction? result = QuranBackgroundExitAction.stopAndExit;

    await tester.pumpWidget(
      buildTestApp(
        onOpenDialog: (context) async {
          result = await showQuranBackgroundExitDialog(
            context: context,
            surahName: 'يس',
          );
        },
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('البقاء في التطبيق'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });
}
