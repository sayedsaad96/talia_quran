import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/listening/listening_corpus.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_audio.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_quiz_source.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_recitation_capture.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/listening_review_state.dart';

class _MockSource extends Mock implements ListeningQuizSource {}

class _MockAudio extends Mock implements ListeningAudio {}

class _MockCapture extends Mock implements ListeningRecitationCapture {}

// Keys compare letters only, so spell numbers as letters (a=0 … j=9).
String _letters(int n) =>
    n.toString().split('').map((d) => 'abcdefghij'[int.parse(d)]).join();

ListeningQuizMaterial _material({int promptCount = 12}) {
  final corpus = ListeningCorpus.fromTexts({
    for (var s = 1; s <= 114; s++)
      s: [
        for (var a = 1; a <= 20; a++)
          'surah ${_letters(s)} ayah ${_letters(a)}',
      ],
  });
  return ListeningQuizMaterial(
    corpus: corpus,
    prompts: [for (var a = 1; a <= promptCount; a++) ListeningAyahRef(10, a)],
    surahs: const {},
  );
}

void main() {
  late _MockSource source;
  late _MockAudio audio;
  late _MockCapture capture;
  late ListeningReviewStatsStore stats;

  setUpAll(() {
    registerFallbackValue(const ListeningAyahRef(1, 1));
    registerFallbackValue((String _) {}); // for capture.start(any())
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    stats = ListeningReviewStatsStore(
      await SharedPreferences.getInstance(),
      const FixedRecordOwnerProvider('owner-a'),
    );
    source = _MockSource();
    audio = _MockAudio();
    capture = _MockCapture();
    when(() => audio.isCached(any())).thenAnswer((_) async => true);
    when(() => audio.play(any())).thenAnswer((_) async => true);
    when(() => audio.stop()).thenAnswer((_) async {});
    when(() => audio.dispose()).thenAnswer((_) async {});
    when(() => capture.cancel()).thenAnswer((_) async {});
  });

  ListeningReviewCubit build() => ListeningReviewCubit(
    source: source,
    audio: audio,
    capture: capture,
    stats: stats,
    random: Random(5),
  );

  test('load → idle with stats when the pool is large enough', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, const ListeningReviewIdle(ListeningReviewStats.empty));
  });

  test('load → not enough when fewer than 5 eligible prompts', () async {
    when(
      () => source.load(),
    ).thenAnswer((_) async => Right(_material(promptCount: 4)));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, isA<ListeningReviewNotEnough>());
  });

  test('load → error when the source fails', () async {
    when(
      () => source.load(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    final cubit = build();
    await cubit.load();
    expect(cubit.state, isA<ListeningReviewError>());
  });

  test(
    'which-surah round: answering records outcome once and plays audio',
    () async {
      when(() => source.load()).thenAnswer((_) async => Right(_material()));
      final cubit = build();
      await cubit.load();
      await cubit.startRound(ListeningQuizMode.whichSurah);

      final round = cubit.state as ListeningReviewInRound;
      expect(round.questions, hasLength(10));
      verify(() => audio.play(round.question.prompt)).called(1);

      final q = round.question as WhichSurahQuestion;
      final wrong = q.optionSurahIds.firstWhere((s) => s != q.prompt.surahId);
      cubit.answerSurah(wrong);
      cubit.answerSurah(q.prompt.surahId); // ignored: already answered
      final answered = cubit.state as ListeningReviewInRound;
      expect(answered.current!.outcome, ListeningOutcome.wrong);
      expect(answered.answers, hasLength(1));
    },
  );

  test('replay is capped at 3 plays per question', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    await cubit.replay();
    await cubit.replay();
    await cubit.replay(); // 4th play refused
    final round = cubit.state as ListeningReviewInRound;
    expect(round.playsUsed, 3);
    verify(() => audio.play(round.question.prompt)).called(3);
  });

  test('audio failure skips the question without scoring it', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    var calls = 0;
    when(() => audio.play(any())).thenAnswer((_) async => calls++ != 0);
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    final round = cubit.state as ListeningReviewInRound;
    expect(round.index, 1);
    expect(round.answers.single.outcome, ListeningOutcome.skipped);
  });

  test('finishing a round writes stats and emits the result', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.whichSurah);
    for (var i = 0; i < 10; i++) {
      final q =
          (cubit.state as ListeningReviewInRound).question
              as WhichSurahQuestion;
      cubit.answerSurah(q.prompt.surahId);
      await cubit.next();
    }
    final finished = cubit.state as ListeningReviewFinished;
    expect(finished.result.correct, 10);
    expect(stats.read().bestPercent, 100);
  });

  test(
    'next-ayah: recognized recitation is scored with the evaluator',
    () async {
      when(() => source.load()).thenAnswer((_) async => Right(_material()));
      when(
        () => capture.prepare(),
      ).thenAnswer((_) async => ListeningCaptureReadiness.ready);
      when(() => capture.start(any())).thenAnswer((_) async {});
      final cubit = build();
      await cubit.load();
      await cubit.startRound(ListeningQuizMode.nextAyah);
      final q =
          (cubit.state as ListeningReviewInRound).question as NextAyahQuestion;
      when(() => capture.stop()).thenAnswer((_) async => q.nextAyahText);

      await cubit.startRecording();
      await cubit.stopRecording();

      final round = cubit.state as ListeningReviewInRound;
      expect(round.current!.outcome, ListeningOutcome.correct);
    },
  );

  test('next-ayah: two empty recognitions switch to self-grade', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    when(
      () => capture.prepare(),
    ).thenAnswer((_) async => ListeningCaptureReadiness.ready);
    when(() => capture.start(any())).thenAnswer((_) async {});
    when(() => capture.stop()).thenAnswer((_) async => '');
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.nextAyah);

    await cubit.startRecording();
    await cubit.stopRecording();
    expect((cubit.state as ListeningReviewInRound).selfGradeMode, isFalse);
    await cubit.startRecording();
    await cubit.stopRecording();
    final round = cubit.state as ListeningReviewInRound;
    expect(round.selfGradeMode, isTrue);
    expect(round.isAnswered, isFalse);
  });

  test('next-ayah: denied microphone falls back to self-grade', () async {
    when(() => source.load()).thenAnswer((_) async => Right(_material()));
    when(
      () => capture.prepare(),
    ).thenAnswer((_) async => ListeningCaptureReadiness.permissionDenied);
    final cubit = build();
    await cubit.load();
    await cubit.startRound(ListeningQuizMode.nextAyah);
    await cubit.startRecording();
    expect((cubit.state as ListeningReviewInRound).selfGradeMode, isTrue);

    cubit.revealForSelfGrade();
    cubit.selfGrade(ListeningOutcome.hesitant);
    expect(
      (cubit.state as ListeningReviewInRound).current!.outcome,
      ListeningOutcome.hesitant,
    );
  });
}
