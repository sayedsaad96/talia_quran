import '../../../../core/memorization/v2/recitation_evaluator.dart';
import '../entities/custom_memorization_plan.dart';
import '../entities/daily_plan.dart';

/// Turns the learner's plan settings into concrete daily scheduling:
///
/// * Days per week — rest days are spread evenly over a Friday-first week;
///   a rest day serves due reviews only (no new ayahs), so the backlog never
///   piles up.
/// * Session minutes — new ayahs shrink to fit the time left after the
///   required reviews, but a study day always keeps at least one.
/// * Difficulty — sets the memorization block size and, when challenging,
///   a slightly stricter recitation pass threshold.
abstract final class PlanSchedulePolicy {
  /// Rough effort estimates used to fit the plan into the session length.
  static const double minutesPerNewAyah = 4;
  static const double minutesPerReviewAyah = 1.5;

  static const double challengingPassThreshold = 0.92;

  /// Whether [day] (local calendar) is a study day for [plan]. With N days
  /// per week, exactly N days of every week are study days, spread evenly;
  /// the first rest day is Friday (so a 6-day plan rests on Friday).
  static bool isStudyDay(CustomMemorizationPlan plan, DateTime day) {
    final days = plan.availableDaysPerWeek.clamp(1, 7);
    if (days == 7) return true;
    // Friday = 0 … Thursday = 6.
    final index = (day.weekday - DateTime.friday + 7) % 7;
    return (index + 1) * days ~/ 7 > index * days ~/ 7;
  }

  /// New ayahs that fit in [sessionMinutes] before any reviews (at least 1).
  static int newAyahsFittingMinutes(int sessionMinutes) {
    final fitting = (sessionMinutes / minutesPerNewAyah).floor();
    return fitting < 1 ? 1 : fitting;
  }

  /// New ayahs to serve today, after [reviewItemCount] required reviews.
  static int newAyahBudget(
    CustomMemorizationPlan plan, {
    required int reviewItemCount,
    required DateTime today,
  }) {
    if (!isStudyDay(plan, today)) return 0;
    final configured = plan.newAyahsPerDay;
    if (configured <= 0) return 0;
    final minutesLeft =
        plan.sessionMinutes - reviewItemCount * minutesPerReviewAyah;
    final fitting = (minutesLeft / minutesPerNewAyah).floor();
    return fitting.clamp(1, configured);
  }

  /// Ayahs per memorization block, never more than the daily new ayahs.
  static int blockSize(CustomMemorizationPlan plan) {
    final byDifficulty = switch (plan.difficulty) {
      MemorizationDifficulty.easy => 3,
      MemorizationDifficulty.moderate => 5,
      MemorizationDifficulty.challenging => 7,
    };
    final daily = plan.newAyahsPerDay < 1 ? 1 : plan.newAyahsPerDay;
    return byDifficulty < daily ? byDifficulty : daily;
  }

  /// Fits [blockSize] to today's plan for a session starting at
  /// [startAyah]: the block covers at most the unfinished new ayahs of
  /// [today] that run contiguously from [startAyah], so the session never
  /// memorizes more than the plan (and its time estimate) promised. A start
  /// outside today's new ayahs (surah practice, no plan) keeps [blockSize].
  static int fitToDailyPlan(
    int blockSize,
    DailyPlan? today, {
    required int surahId,
    required int startAyah,
  }) {
    if (today == null) return blockSize;
    final remaining = {
      for (final ayah in today.newAyahs)
        if (ayah.surahId == surahId &&
            !today.isAyahCompleted(ayah.surahId, ayah.ayahNumber))
          ayah.ayahNumber,
    };
    var run = 0;
    while (remaining.contains(startAyah + run)) {
      run++;
    }
    if (run == 0) return blockSize;
    return run < blockSize ? run : blockSize;
  }

  /// Recitation pass threshold for [difficulty].
  static double passThreshold(MemorizationDifficulty difficulty) =>
      difficulty == MemorizationDifficulty.challenging
      ? challengingPassThreshold
      : kV2PassThreshold;
}
