import 'kids_session_policy.dart';

/// A surah of at most this many ayahs may be memorized as one whole house.
const kKidsWholeSurahMaxAyahsLimit = 20;

enum KidsJourneyPathId {
  juzAmmaAdventure('fatiha_then_juz_amma'),
  quranFromNas('quran_from_nas'),
  quranFromFatiha('quran_from_fatiha');

  const KidsJourneyPathId(this.storageValue);

  final String storageValue;

  /// Unknown or missing values fall back to the Juz Amma adventure.
  static KidsJourneyPathId parse(String? raw) {
    for (final id in values) {
      if (id.storageValue == raw) return id;
    }
    return juzAmmaAdventure;
  }
}

final class KidsJourneyPathDefinition {
  const KidsJourneyPathDefinition._(this.id);

  static const adventure = KidsJourneyPathDefinition._(
    KidsJourneyPathId.juzAmmaAdventure,
  );
  static const _quranFromNas = KidsJourneyPathDefinition._(
    KidsJourneyPathId.quranFromNas,
  );
  static const _quranFromFatiha = KidsJourneyPathDefinition._(
    KidsJourneyPathId.quranFromFatiha,
  );

  static final List<int> _nasOrder = List.unmodifiable([
    1,
    for (var s = 114; s >= 2; s--) s,
  ]);
  static final List<int> _fatihaOrder = List.unmodifiable([
    for (var s = 1; s <= 114; s++) s,
  ]);

  static KidsJourneyPathDefinition of(KidsJourneyPathId id) => switch (id) {
    KidsJourneyPathId.juzAmmaAdventure => adventure,
    KidsJourneyPathId.quranFromNas => _quranFromNas,
    KidsJourneyPathId.quranFromFatiha => _quranFromFatiha,
  };

  final KidsJourneyPathId id;

  List<int> get surahIds => switch (id) {
    KidsJourneyPathId.juzAmmaAdventure => KidsJourneyPath.surahIds,
    KidsJourneyPathId.quranFromNas => _nasOrder,
    KidsJourneyPathId.quranFromFatiha => _fatihaOrder,
  };

  bool contains(int surahId) => id == KidsJourneyPathId.juzAmmaAdventure
      ? KidsJourneyPath.contains(surahId)
      : surahIds.contains(surahId);

  int? nextAfter(int surahId) {
    if (id == KidsJourneyPathId.juzAmmaAdventure) {
      return KidsJourneyPath.nextAfter(surahId);
    }
    final index = surahIds.indexOf(surahId);
    if (index < 0 || index + 1 >= surahIds.length) return null;
    return surahIds[index + 1];
  }

  bool get locksAhead => id == KidsJourneyPathId.juzAmmaAdventure;

  bool get isQuranJourney => !locksAhead;
}

/// Flag off → adventure, whatever is stored.
KidsJourneyPathDefinition resolveKidsJourneyPath({
  required String? storedPathId,
  required bool quranJourneyEnabled,
}) {
  if (!quranJourneyEnabled) return KidsJourneyPathDefinition.adventure;
  return KidsJourneyPathDefinition.of(KidsJourneyPathId.parse(storedPathId));
}
