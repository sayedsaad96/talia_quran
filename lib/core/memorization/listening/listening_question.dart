import 'package:equatable/equatable.dart';

/// Which kind of question a listening round asks.
enum ListeningQuizMode { whichSurah, nextAyah, mixed }

/// A (surah, ayah) pair inside the listening quiz.
final class ListeningAyahRef extends Equatable {
  const ListeningAyahRef(this.surahId, this.ayahNumber);

  final int surahId;
  final int ayahNumber;

  @override
  List<Object?> get props => [surahId, ayahNumber];
}

/// One question of a listening round. The [prompt] ayah's audio is played.
sealed class ListeningQuestion extends Equatable {
  const ListeningQuestion(this.prompt);

  final ListeningAyahRef prompt;
}

/// "Which surah is this ayah from?" — exactly one option equals
/// `prompt.surahId`; the list is already shuffled.
final class WhichSurahQuestion extends ListeningQuestion {
  const WhichSurahQuestion(super.prompt, {required this.optionSurahIds});

  final List<int> optionSurahIds;

  @override
  List<Object?> get props => [prompt, optionSurahIds];
}

/// "Recite the ayah after this one." [nextAyahText] is the canonical,
/// unmodified text of `prompt.ayahNumber + 1` in the same surah.
final class NextAyahQuestion extends ListeningQuestion {
  const NextAyahQuestion(super.prompt, {required this.nextAyahText});

  final String nextAyahText;

  ListeningAyahRef get answer =>
      ListeningAyahRef(prompt.surahId, prompt.ayahNumber + 1);

  @override
  List<Object?> get props => [prompt, nextAyahText];
}
