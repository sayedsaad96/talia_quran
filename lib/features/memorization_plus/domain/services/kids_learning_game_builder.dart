import 'dart:math';

import '../entities/kids_journey_path_definition.dart';
import '../entities/kids_learning_game.dart';
import '../entities/kids_session_log.dart';
import '../entities/kids_session_policy.dart';

/// Builds a «أي سورة هذه؟» round set from ayahs the child has memorized
/// (canonical new-memorization logs only). Null when nothing is memorized:
/// the game never plays an ayah the child has not learned.
KidsLearningGame? buildListenAndChooseSurahGame(
  Iterable<KidsSessionLog> logs, {
  required Random random,
  KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure,
}) {
  final bySurah = <int, Set<int>>{};
  for (final log in logs) {
    if (log.missionType != KidsMissionType.newMemorization ||
        log.pointsEarned <= 0 ||
        !path.contains(log.surahId)) {
      continue;
    }
    bySurah.putIfAbsent(log.surahId, () => {}).add(log.ayahNumber);
  }
  if (bySurah.isEmpty) return null;

  // Distinct surahs first, so three rounds are three different answers.
  final surahs = bySurah.keys.toList()..shuffle(random);
  final rounds = <KidsGameRound>[];
  for (var i = 0; i < KidsLearningGame.maxRounds; i++) {
    final surahId = surahs[i % surahs.length];
    if (i >= surahs.length && surahs.length < 2) break;
    final ayahs = bySurah[surahId]!.toList()..sort();
    final ayahNumber = ayahs[random.nextInt(ayahs.length)];
    rounds.add(
      KidsGameRound(
        surahId: surahId,
        ayahNumber: ayahNumber,
        options: _options(
          surahId,
          bySurah.keys.toSet(),
          random,
          path.surahIds,
        ),
      ),
    );
  }
  return KidsLearningGame(rounds);
}

/// The right surah plus distractors: other memorized surahs first, then the
/// nearest surahs on the journey path, shuffled.
List<int> _options(
  int answer,
  Set<int> memorized,
  Random random,
  List<int> path,
) {
  final pool = memorized.where((id) => id != answer).toList()..shuffle(random);
  final at = path.indexOf(answer);
  for (var d = 1; pool.length < KidsLearningGame.optionsPerRound - 1; d++) {
    if (d > path.length) break;
    for (final i in [at - d, at + d]) {
      if (i >= 0 && i < path.length && !pool.contains(path[i])) {
        pool.add(path[i]);
      }
    }
  }
  final options = [
    answer,
    ...pool
        .where((id) => id != answer)
        .take(KidsLearningGame.optionsPerRound - 1),
  ]..shuffle(random);
  return options;
}

/// Pure check of one answer; an id that is not an option is reported as
/// such instead of being scored.
KidsGameResult evaluateKidsGameAnswer({
  required KidsGameRound round,
  required int optionSurahId,
}) {
  if (!round.options.contains(optionSurahId)) {
    return KidsGameResult.unknownOption;
  }
  return optionSurahId == round.surahId
      ? KidsGameResult.correct
      : KidsGameResult.incorrect;
}
