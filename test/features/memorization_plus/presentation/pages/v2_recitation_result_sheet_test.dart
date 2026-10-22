import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/core/memorization/similar_ayah/similar_ayah_confusion_detector.dart';
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
  testWidgets('expired feedback is hidden when expiry precedes first route build',
      (tester) async {
    final expiry = StreamController<void>.broadcast(sync: true);
    var valid = true;
    final feedback = _feedback(target: 'private target one two',
      spoken: 'different result one two');
    await tester.pumpWidget(_host((context) {
      unawaited(showV2RecitationResultSheet(
        context, feedback, expiry: expiry.stream, isCurrent: () => valid,
      ));
      valid = false;
      expiry.add(null);
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(V2RecitationResultSheet), findsNothing);
    expect(find.byKey(const Key('v2-result-retry-now')), findsNothing);
    expect(tester.takeException(), isNull);
    await expiry.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('closed feedback source cannot open a late sheet', (tester) async {
    final feedback = _feedback(target: 'private target one two',
      spoken: 'different result one two');
    await tester.pumpWidget(_host((context) {
      unawaited(showV2RecitationResultSheet(
        context, feedback, isCurrent: () => false,
      ));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(V2RecitationResultSheet), findsNothing);
  });

  testWidgets('attribution note preserves the original failure result', (tester) async {
    final original = _feedback(target: 'alpha beta gamma delta', spoken: 'one two three four');
    final feedback = V2EvaluationFeedback(
      result: original.result, wordDiff: original.wordDiff,
      confusionMatch: const SimilarAyahConfusionMatch(
        targetKey: '2:1', otherKey: '2:2', originalScore: 0, candidateScore: 1,
      ),
    );
    await tester.pumpWidget(_host((context) {
      unawaited(showV2RecitationResultSheet(context, feedback));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // The other ayah is named by surah, never by its raw "2:2" key.
    expect(find.textContaining('2:2'), findsNothing);
    expect(find.textContaining('البقرة'), findsOneWidget);
    expect(find.byKey(const Key('v2-result-retry-now')), findsOneWidget);
    expect(find.byKey(const Key('v2-result-continue')), findsNothing);
    expect(feedback.result, same(original.result));
  });

  testWidgets('expiry removes exact feedback route beneath another dialog', (tester) async {
    final expiry = StreamController<void>.broadcast(sync: true);
    late BuildContext hostContext;
    final feedback = _feedback(target: 'private target one two', spoken: 'different result one two');
    await tester.pumpWidget(_host((context) {
      hostContext = context;
      unawaited(showV2RecitationResultSheet(context, feedback, expiry: expiry.stream));
    }));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    unawaited(showDialog<void>(context: hostContext, builder: (_) =>
      const AlertDialog(content: Text('independent dialog'))));
    await tester.pumpAndSettle();
    expiry.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(V2RecitationResultSheet), findsNothing);
    expect(find.text('independent dialog'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expiry.close();
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
      // Two of four words: a clear failure, below the near-miss band.
      final feedback = _feedback(
        target: 'الحمد لله رب العالمين',
        spoken: 'الحمد العالمين',
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
      final word = tester.widget<Text>(find.text('رب'));
      expect(word.style?.fontFamily, 'Amiri');
      expect(word.style?.fontSize, 24);

      await tester.ensureVisible(
        find.byKey(const Key('v2-result-retry-now')),
      );
      await tester.tap(find.byKey(const Key('v2-result-retry-now')));
      await tester.pumpAndSettle();

      expect(action, V2RecitationResultAction.retryNow);
    },
  );

  testWidgets('a near miss offers only an immediate retry (A5)', (
    tester,
  ) async {
    // Three of four words: inside the retry band.
    final feedback = _feedback(
      target: 'الحمد لله رب العالمين',
      spoken: 'الحمد لله العالمين',
    );

    await tester.pumpWidget(
      _host((context) async {
        await showV2RecitationResultSheet(context, feedback);
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('v2-result-retry-now')), findsOneWidget);
    expect(find.byKey(const Key('v2-result-review-ayah')), findsNothing);
  });
}
