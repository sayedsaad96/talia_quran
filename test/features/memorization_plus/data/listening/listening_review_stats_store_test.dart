import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/listening/listening_question.dart';
import 'package:talia_quran/core/memorization/listening/listening_round_result.dart';
import 'package:talia_quran/features/memorization_plus/data/listening/listening_review_stats_store.dart';

const _q = WhichSurahQuestion(
  ListeningAyahRef(1, 1),
  optionSurahIds: [1, 2, 3, 4],
);

ListeningRoundResult _result(int correct, int wrong) => ListeningRoundResult([
  for (var i = 0; i < correct; i++)
    const ListeningAnswer(_q, ListeningOutcome.correct),
  for (var i = 0; i < wrong; i++)
    const ListeningAnswer(_q, ListeningOutcome.wrong),
]);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ListeningReviewStatsStore store(String owner) =>
      ListeningReviewStatsStore(prefs, FixedRecordOwnerProvider(owner));

  test('starts empty', () {
    expect(store('a').read(), ListeningReviewStats.empty);
    expect(store('a').read().hasPlayed, isFalse);
  });

  test('records last round and keeps the best percent', () async {
    await store('a').record(_result(8, 2));
    await store('a').record(_result(5, 5));
    expect(
      store('a').read(),
      const ListeningReviewStats(
        lastCorrect: 5,
        lastScored: 10,
        bestPercent: 80,
      ),
    );
  });

  test('a round with nothing scored is not recorded', () async {
    await store('a').record(const ListeningRoundResult([]));
    expect(store('a').read().hasPlayed, isFalse);
  });

  test('stats are isolated per account', () async {
    await store('a').record(_result(9, 1));
    expect(store('b').read().hasPlayed, isFalse);
  });

  test('corrupt stored JSON reads as empty', () async {
    await prefs.setString('listening_review_stats_v1_a', '{not json');
    expect(store('a').read(), ListeningReviewStats.empty);
  });
}
