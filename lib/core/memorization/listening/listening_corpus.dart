import '../../utils/arabic_normalizer.dart';
import 'listening_question.dart';

/// Frozen Quran texts plus the ambiguity indexes the listening quiz needs.
///
/// Normalized keys are comparison-only; [textOf] always returns the
/// canonical text exactly as loaded.
final class ListeningCorpus {
  ListeningCorpus._(this._texts, this._crossSurahDuplicates, this._repeats);

  /// [ayahTextsBySurah] maps surah id → canonical ayah texts in order
  /// (index 0 is ayah 1).
  factory ListeningCorpus.fromTexts(Map<int, List<String>> ayahTextsBySurah) {
    final surahsByKey = <String, Set<int>>{};
    final repeats = <int, Set<String>>{};
    ayahTextsBySurah.forEach((surahId, texts) {
      final seen = <String>{};
      for (final text in texts) {
        final key = normalizedKey(text);
        surahsByKey.putIfAbsent(key, () => <int>{}).add(surahId);
        if (!seen.add(key)) {
          repeats.putIfAbsent(surahId, () => <String>{}).add(key);
        }
      }
    });
    return ListeningCorpus._(
      {
        for (final entry in ayahTextsBySurah.entries)
          entry.key: List<String>.unmodifiable(entry.value),
      },
      {
        for (final entry in surahsByKey.entries)
          if (entry.value.length > 1) entry.key,
      },
      repeats,
    );
  }

  static String normalizedKey(String text) => ArabicNormalizer.normalize(
    text.replaceAll('﻿', ''),
  ).replaceAll(RegExp(r'\s+'), ' ').trim();

  final Map<int, List<String>> _texts;
  final Set<String> _crossSurahDuplicates;
  final Map<int, Set<String>> _repeats;

  int ayahCount(int surahId) => _texts[surahId]?.length ?? 0;

  String? textOf(ListeningAyahRef ref) {
    final texts = _texts[ref.surahId];
    if (texts == null || ref.ayahNumber < 1 || ref.ayahNumber > texts.length) {
      return null;
    }
    return texts[ref.ayahNumber - 1];
  }

  bool _isCrossSurahDuplicate(String text) =>
      _crossSurahDuplicates.contains(normalizedKey(text));

  /// True when the heard ayah identifies exactly one surah.
  bool canAskWhichSurah(ListeningAyahRef ref) {
    final text = textOf(ref);
    return text != null && !_isCrossSurahDuplicate(text);
  }

  /// True when "the next ayah" is unique: not the last ayah, not repeated
  /// inside its surah, and not shared with another surah.
  bool canAskNextAyah(ListeningAyahRef ref) {
    final text = textOf(ref);
    if (text == null || ref.ayahNumber >= ayahCount(ref.surahId)) return false;
    if (_isCrossSurahDuplicate(text)) return false;
    return !(_repeats[ref.surahId]?.contains(normalizedKey(text)) ?? false);
  }
}
