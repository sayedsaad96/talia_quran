import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';

void main() {
  const surahQ = WhichSurahQuestion(
    ListeningAyahRef(2, 5),
    optionSurahIds: [1, 2, 3, 4],
  );
  const nextQ = NextAyahQuestion(ListeningAyahRef(3, 7), nextAyahText: 'x');

  test('skipped answers do not count toward the score', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.correct),
      ListeningAnswer(nextQ, ListeningOutcome.skipped),
    ]);
    expect(result.scored, 1);
    expect(result.correct, 1);
  });

  test('weak links point at the heard ayah or the missed continuation', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.wrong),
      ListeningAnswer(nextQ, ListeningOutcome.hesitant),
      ListeningAnswer(surahQ, ListeningOutcome.wrong),
    ]);
    expect(result.weakLinks, const [
      ListeningAyahRef(2, 5),
      ListeningAyahRef(3, 8),
    ]);
  });

  test('correct and skipped answers are never weak', () {
    const result = ListeningRoundResult([
      ListeningAnswer(surahQ, ListeningOutcome.correct),
      ListeningAnswer(nextQ, ListeningOutcome.skipped),
    ]);
    expect(result.weakLinks, isEmpty);
  });
}
