import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/v2/recitation_word_diff.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_recitation_result_sheet.dart';

V2EvaluationFeedback _feedback({
  required String target,
  required String spoken,
}) {
  final differ = const RecitationWordDiffer().diff(
    targetText: target,
    spokenText: spoken,
  );
  final evaluator = const V2RecitationEvaluator().evaluate(
    targetText: target,
    spokenText: spoken,
  );
  return V2EvaluationFeedback(result: evaluator, wordDiff: differ);
}

Widget _host(void Function(BuildContext) onOpen) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ar'),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => onOpen(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'result sheet shows success header and continue action on pass',
    (tester) async {
      final feedback = _feedback(
        target: 'الحمد لله رب العالمين',
        spoken: 'الحمد لله رب العالمين',
      );

      V2RecitationResultAction? action;
      await tester.pumpWidget(
        _host((context) async {
          action = await showV2RecitationResultSheet(context, feedback);
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('v2-result-continue')), findsOneWidget);
      expect(find.byKey(const Key('v2-result-retry-now')), findsNothing);

      await tester.tap(find.byKey(const Key('v2-result-continue')));
      await tester.pumpAndSettle();

      expect(action, V2RecitationResultAction.dismiss);
    },
  );

  testWidgets(
    'result sheet shows word diff and retry actions on failure',
    (tester) async {
      final feedback = _feedback(
        target: 'الحمد لله رب العالمين',
        spoken: 'الحمد لله العالمين',
      );

      V2RecitationResultAction? action;
      await tester.pumpWidget(
        _host((context) async {
          action = await showV2RecitationResultSheet(context, feedback);
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Failure UI: retry + review actions, and the diff view with the
      // missing target word rendered.
      expect(find.byKey(const Key('v2-result-retry-now')), findsOneWidget);
      expect(find.byKey(const Key('v2-result-review-ayah')), findsOneWidget);
      expect(find.text('رب'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('v2-result-retry-now')),
      );
      await tester.tap(find.byKey(const Key('v2-result-retry-now')));
      await tester.pumpAndSettle();

      expect(action, V2RecitationResultAction.retryNow);
    },
  );
}
