import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/hands_free/hands_free_round_state.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/hands_free_review_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/hands_free_review_page.dart';

void main() {
  testWidgets('warning gates start until the user accepts it', (tester) async {
    final cubit = _FakeHandsFreeReviewCubit(
      const HandsFreeReviewState(firstUseWarningPending: true),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));

    expect(
      find.text('For your safety, do not use this while driving.'),
      findsOneWidget,
    );
    final start = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start'),
    );
    expect(start.onPressed, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'I understand'));
    await tester.pump();

    expect(cubit.acceptWarningCalls, 1);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('shows the localized no-due state', (tester) async {
    final cubit = _FakeHandsFreeReviewCubit(_finishedRound(const []));
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));

    expect(find.text('No review is due right now.'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });

  testWidgets('warning-save failure explains the problem and can be retried', (
    tester,
  ) async {
    final cubit = _FakeHandsFreeReviewCubit(
      const HandsFreeReviewState(firstUseWarningPending: true, hasError: true),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));

    expect(find.text('Could not continue. Try again.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'I understand'), findsOneWidget);
  });

  testWidgets('manual grade controls invoke the Cubit for a user turn', (
    tester,
  ) async {
    final cubit = _FakeHandsFreeReviewCubit(
      HandsFreeReviewState(
        micAvailable: false,
        firstUseWarningPending: false,
        round: HandsFreeRoundState(
          phase: HandsFreePhase.userTurn,
          items: const [ListeningAyahRef(1, 2)],
          currentIndex: 0,
          grades: const [null],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));

    expect(
      find.text('Speech recognition is unavailable. Use the buttons below.'),
      findsOneWidget,
    );
    expect(find.text('Surah Al-Fatihah, Ayah 2'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Correct'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Review'));

    expect(cubit.primaryCalls, 1);
    expect(cubit.secondaryCalls, 1);
  });

  testWidgets('summary lists review ayahs by reference without Quran text', (
    tester,
  ) async {
    final cubit = _FakeHandsFreeReviewCubit(
      HandsFreeReviewState(
        firstUseWarningPending: false,
        round: HandsFreeRoundState(
          phase: HandsFreePhase.finished,
          items: const [ListeningAyahRef(1, 1), ListeningAyahRef(1, 2)],
          currentIndex: 2,
          grades: const [HandsFreeGrade.correct, HandsFreeGrade.review],
        ),
      ),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(_app(cubit));

    expect(find.text('2 ayahs graded'), findsOneWidget);
    expect(find.text('Surah Al-Fatihah, Ayah 2'), findsOneWidget);
  });

  testWidgets('fits a large RTL text scale on a 320dp screen', (tester) async {
    final cubit = _FakeHandsFreeReviewCubit(
      const HandsFreeReviewState(firstUseWarningPending: true),
    );
    addTearDown(cubit.close);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _app(cubit, locale: const Locale('ar'), textScaleFactor: 2),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

HandsFreeReviewState _finishedRound(List<ListeningAyahRef> items) {
  return HandsFreeReviewState(
    firstUseWarningPending: false,
    round: HandsFreeRoundState(
      phase: HandsFreePhase.finished,
      items: items,
      currentIndex: items.length,
      grades: List<HandsFreeGrade?>.filled(items.length, null),
    ),
  );
}

Widget _app(
  HandsFreeReviewCubit cubit, {
  Locale locale = const Locale('en'),
  double textScaleFactor = 1,
}) {
  return BlocProvider<HandsFreeReviewCubit>.value(
    value: cubit,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScaleFactor)),
        child: child!,
      ),
      home: const HandsFreeReviewView(),
    ),
  );
}

class _FakeHandsFreeReviewCubit extends Cubit<HandsFreeReviewState>
    implements HandsFreeReviewCubit {
  _FakeHandsFreeReviewCubit(super.initialState);

  var acceptWarningCalls = 0;
  var primaryCalls = 0;
  var secondaryCalls = 0;

  @override
  Future<void> acceptWarning() async {
    acceptWarningCalls++;
    emit(state.copyWith(firstUseWarningPending: false));
  }

  @override
  void onPrimary() => primaryCalls++;

  @override
  void onSecondary() => secondaryCalls++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
