import 'package:equatable/equatable.dart';

/// One «أي سورة هذه؟» round: the child hears an ayah they memorized and
/// picks its surah. Options are surah ids only; no Quran text is shown, so
/// nothing can be mistaken for an ayah.
class KidsGameRound extends Equatable {
  const KidsGameRound({
    required this.surahId,
    required this.ayahNumber,
    required this.options,
  });

  /// The surah of the ayah that plays (the right answer).
  final int surahId;
  final int ayahNumber;

  /// Distinct surah ids, the right one included, in display order.
  final List<int> options;

  @override
  List<Object?> get props => [surahId, ayahNumber, options];
}

/// A short round set (at most [maxRounds]). Finishing it is learning only:
/// it grants no memorization, certificate or engine points.
class KidsLearningGame extends Equatable {
  const KidsLearningGame(this.rounds);

  static const maxRounds = 3;
  static const optionsPerRound = 3;

  final List<KidsGameRound> rounds;

  @override
  List<Object?> get props => [rounds];
}

enum KidsGameResult { correct, incorrect, unknownOption }
