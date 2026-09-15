/// Stable identity for a single ayah at learning-flow boundaries.
final class AyahReference {
  const AyahReference({required this.surahId, required this.ayahNumber});

  final int surahId;
  final int ayahNumber;
}

enum LearningIntent { memorize, review, repeat }

enum LearningOrigin {
  unknown,
  dailyPlan,
  review,
  smartCoach,
  surahPractice,
  quranReader,
}

/// Typed context carried from an entry point into a resumable learning session.
final class LearningLaunchContext {
  const LearningLaunchContext({
    required this.ayah,
    required this.intent,
    required this.origin,
  });

  factory LearningLaunchContext.fromRouteValues({
    required int surahId,
    required int startAyah,
    String? intent,
    String? origin,
  }) {
    return LearningLaunchContext(
      ayah: AyahReference(surahId: surahId, ayahNumber: startAyah),
      intent: _enumValueOr(
        LearningIntent.values,
        intent,
        LearningIntent.memorize,
      ),
      origin: _enumValueOr(
        LearningOrigin.values,
        origin,
        LearningOrigin.unknown,
      ),
    );
  }

  final AyahReference ayah;
  final LearningIntent intent;
  final LearningOrigin origin;

  Map<String, String> toRouteQuery() => {
    'surahId': '${ayah.surahId}',
    'startAyah': '${ayah.ayahNumber}',
    'intent': intent.name,
    'origin': origin.name,
  };
}

T _enumValueOr<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
