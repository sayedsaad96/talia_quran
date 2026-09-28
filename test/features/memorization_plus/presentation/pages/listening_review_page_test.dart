import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/listening_review_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

class _MockCubit extends Mock implements ListeningReviewCubit {}

Surah _surah(int id) => Surah(
  id: id,
  nameAr: 'سورة $id',
  nameEn: 'S$id',
  ayahCount: 3,
  juz: 1,
  type: 'meccan',
  page: 1,
);

final _material = ListeningQuizMaterial(
  corpus: ListeningCorpus.fromTexts({
    2: ['a', 'b', 'c'],
  }),
  prompts: const [],
  surahs: {for (var s = 1; s <= 5; s++) s: _surah(s)},
);

const _q = WhichSurahQuestion(
  ListeningAyahRef(2, 2),
  optionSurahIds: [1, 2, 3, 4],
);

Future<_MockCubit> _pump(
  WidgetTester tester,
  ListeningReviewState state,
) async {
  final cubit = _MockCubit();
  when(() => cubit.state).thenReturn(state);
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.material).thenReturn(_material);
  when(() => cubit.close()).thenAnswer((_) async {});
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
      home: BlocProvider<ListeningReviewCubit>.value(
        value: cubit,
        child: const ListeningReviewView(),
      ),
    ),
  );
  return cubit;
}

void main() {
  testWidgets('not-enough state explains the minimum', (tester) async {
    await _pump(tester, const ListeningReviewNotEnough());
    expect(find.text('Memorize a few ayahs first'), findsOneWidget);
  });

  testWidgets('idle shows the three modes and starts a round', (tester) async {
    final cubit = await _pump(
      tester,
      const ListeningReviewIdle(ListeningReviewStats.empty),
    );
    when(
      () => cubit.startRound(ListeningQuizMode.whichSurah),
    ).thenAnswer((_) async {});
    expect(find.text('Which surah?'), findsOneWidget);
    expect(find.text('Continue the next ayah'), findsOneWidget);
    expect(find.text('Mixed'), findsOneWidget);
    await tester.tap(find.text('Which surah?'));
    verify(() => cubit.startRound(ListeningQuizMode.whichSurah)).called(1);
  });

  testWidgets('tapping a surah option answers the question', (tester) async {
    final cubit = await _pump(
      tester,
      const ListeningReviewInRound(
        mode: ListeningQuizMode.whichSurah,
        questions: [_q],
        index: 0,
      ),
    );
    await tester.tap(find.text('S3'));
    verify(() => cubit.answerSurah(3)).called(1);
  });

  testWidgets('answered question reveals canonical text and Next', (
    tester,
  ) async {
    await _pump(
      tester,
      const ListeningReviewInRound(
        mode: ListeningQuizMode.whichSurah,
        questions: [_q],
        index: 0,
        current: ListeningAnswer(_q, ListeningOutcome.wrong),
      ),
    );
    expect(find.text('Not quite'), findsOneWidget);
    expect(find.textContaining('b'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('result lists weak links', (tester) async {
    await _pump(
      tester,
      const ListeningReviewFinished(
        ListeningRoundResult([ListeningAnswer(_q, ListeningOutcome.wrong)]),
      ),
    );
    expect(find.text('Round complete'), findsOneWidget);
    expect(find.text('Links to review'), findsOneWidget);
    expect(find.text('Surah S2 · Ayah 2'), findsOneWidget);
  });
}
