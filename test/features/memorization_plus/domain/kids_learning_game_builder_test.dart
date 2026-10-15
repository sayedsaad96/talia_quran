import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_learning_game.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_learning_game_builder.dart';

KidsSessionLog _log(
  int surahId,
  int ayah, {
  KidsMissionType type = KidsMissionType.newMemorization,
  int points = 10,
}) => KidsSessionLog(
  id: '$surahId:$ayah:${type.name}',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 1,
  pointsEarned: points,
  completedAt: DateTime.utc(2026, 10, 1),
  missionType: type,
);

void main() {
  KidsLearningGame? build(List<KidsSessionLog> logs, {int seed = 1}) =>
      buildListenAndChooseSurahGame(logs, random: Random(seed));

  group('buildListenAndChooseSurahGame', () {
    test('nothing memorized means no game', () {
      expect(build(const []), isNull);
    });

    test('only rewarded new memorization counts as memorized', () {
      final game = build([
        _log(114, 1, type: KidsMissionType.dueReview),
        _log(113, 1, points: 0),
        _log(2, 1), // not on the kids journey path
      ]);

      expect(game, isNull);
    });

    test('three memorized surahs give three rounds with three answers', () {
      for (var seed = 0; seed < 20; seed++) {
        final game = build([
          _log(114, 1),
          _log(113, 2),
          _log(112, 3),
          _log(1, 4),
        ], seed: seed)!;

        expect(game.rounds, hasLength(KidsLearningGame.maxRounds));
        expect(game.rounds.map((r) => r.surahId).toSet(), hasLength(3));
      }
    });

    test('every round plays a memorized ayah and offers it once', () {
      final memorized = {(114, 1), (114, 2), (113, 1)};
      for (var seed = 0; seed < 20; seed++) {
        final game = build([
          for (final (s, a) in memorized) _log(s, a),
        ], seed: seed)!;
        for (final round in game.rounds) {
          expect(memorized, contains((round.surahId, round.ayahNumber)));
          expect(round.options, hasLength(KidsLearningGame.optionsPerRound));
          expect(round.options.toSet(), hasLength(round.options.length));
          expect(
            round.options.where((id) => id == round.surahId),
            hasLength(1),
          );
          for (final id in round.options) {
            expect(KidsJourneyPath.contains(id), isTrue);
          }
        }
      }
    });

    test('a single memorized surah gives one round with path neighbours', () {
      final game = build([_log(114, 1), _log(114, 2)])!;

      expect(game.rounds, hasLength(1));
      expect(game.rounds.single.options, hasLength(3));
      expect(game.rounds.single.options, contains(114));
    });
  });

  group('follows the selected journey path', () {
    KidsLearningGame? buildOn(
      KidsJourneyPathDefinition path,
      List<KidsSessionLog> logs,
    ) => buildListenAndChooseSurahGame(logs, random: Random(1), path: path);

    test('surah 67 counts on the Quran journey, not on the adventure', () {
      final logs = [_log(67, 1)];

      expect(buildOn(KidsJourneyPathDefinition.adventure, logs), isNull);
      final game = buildOn(
        KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromNas),
        logs,
      )!;
      expect(game.rounds.single.surahId, 67);
    });

    test('distractors come from the selected path', () {
      final path = KidsJourneyPathDefinition.of(
        KidsJourneyPathId.quranFromFatiha,
      );
      final game = buildOn(path, [_log(67, 1)])!;

      expect(game.rounds.single.options, hasLength(3));
      for (final id in game.rounds.single.options) {
        expect(path.contains(id), isTrue);
      }
      expect(game.rounds.single.options.toSet(), {66, 67, 68});
    });
  });

  group('evaluateKidsGameAnswer', () {
    const round = KidsGameRound(
      surahId: 114,
      ayahNumber: 1,
      options: [113, 114, 112],
    );

    test('scores right and wrong options', () {
      expect(
        evaluateKidsGameAnswer(round: round, optionSurahId: 114),
        KidsGameResult.correct,
      );
      expect(
        evaluateKidsGameAnswer(round: round, optionSurahId: 113),
        KidsGameResult.incorrect,
      );
    });

    test('an id that is not an option is reported, not scored', () {
      expect(
        evaluateKidsGameAnswer(round: round, optionSurahId: 2),
        KidsGameResult.unknownOption,
      );
    });
  });
}
