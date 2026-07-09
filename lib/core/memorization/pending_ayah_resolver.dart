import '../../features/memorization_plus/domain/entities/memorization_entities.dart';
import 'review_record_filters.dart';

/// Why a new V2 session is being opened — drives [PendingAyahResolver].
enum PendingAyahIntent {
  /// Hub "Continue Today's Plan" and coach continue-plan card.
  continueDailyPlan,

  /// Hub "Review Session" — retention / due review in the plan surah.
  reviewSession,

  /// Hifz surah tile or practice-by-surah entry.
  practiceSurah,
}

/// Resolved entry context for a **new** V2 session start (not mid-session resume).
final class PendingAyahTarget {
  const PendingAyahTarget({
    required this.surahId,
    required this.startAyah,
    required this.blockSize,
    required this.intent,
  });

  final int surahId;
  final int startAyah;
  final int blockSize;
  final PendingAyahIntent intent;
}

/// Inputs for [PendingAyahResolver.resolve] — pure data, no I/O.
final class PendingAyahResolverInput {
  const PendingAyahResolverInput({
    required this.surahId,
    required this.intent,
    required this.reviewRecords,
    this.cachedDailyPlan,
    this.surahAyahCount,
    this.defaultBlockSize = 5,
  });

  final int surahId;
  final PendingAyahIntent intent;
  final List<AyahReviewRecord> reviewRecords;
  final DailyPlan? cachedDailyPlan;
  final int? surahAyahCount;
  final int defaultBlockSize;
}

/// Single SSOT for `surahId + startAyah + blockSize` on **new** session starts.
///
/// Mid-session resume still uses Isar via [MemorizationSessionCubit.startSession].
final class PendingAyahResolver {
  const PendingAyahResolver();

  PendingAyahTarget resolve(PendingAyahResolverInput input) {
    final blockSize = input.defaultBlockSize;

    return switch (input.intent) {
      PendingAyahIntent.continueDailyPlan => _continueDailyPlan(
        input,
        blockSize,
      ),
      PendingAyahIntent.reviewSession => _reviewSession(input, blockSize),
      PendingAyahIntent.practiceSurah => _practiceSurah(input, blockSize),
    };
  }

  PendingAyahTarget _continueDailyPlan(
    PendingAyahResolverInput input,
    int blockSize,
  ) {
    final plan = input.cachedDailyPlan;
    if (plan != null && plan.surahId == input.surahId) {
      final pending = firstPendingPlanAyah(plan);
      if (pending != null) {
        return PendingAyahTarget(
          surahId: input.surahId,
          startAyah: pending,
          blockSize: blockSize,
          intent: PendingAyahIntent.continueDailyPlan,
        );
      }
    }

    return PendingAyahTarget(
      surahId: input.surahId,
      startAyah: _firstLearningAyahInSurah(input) ?? 1,
      blockSize: blockSize,
      intent: PendingAyahIntent.continueDailyPlan,
    );
  }

  PendingAyahTarget _reviewSession(
    PendingAyahResolverInput input,
    int blockSize,
  ) {
    final dueAyah = _firstDueAyahInSurah(input);
    if (dueAyah != null) {
      return PendingAyahTarget(
        surahId: input.surahId,
        startAyah: dueAyah,
        blockSize: blockSize,
        intent: PendingAyahIntent.reviewSession,
      );
    }

    final startedAyah = _lowestStartedAyahInSurah(input);
    return PendingAyahTarget(
      surahId: input.surahId,
      startAyah: startedAyah ?? 1,
      blockSize: blockSize,
      intent: PendingAyahIntent.reviewSession,
    );
  }

  PendingAyahTarget _practiceSurah(
    PendingAyahResolverInput input,
    int blockSize,
  ) {
    return PendingAyahTarget(
      surahId: input.surahId,
      startAyah: _firstLearningAyahInSurah(input) ?? 1,
      blockSize: blockSize,
      intent: PendingAyahIntent.practiceSurah,
    );
  }

  /// First incomplete required ayah in plan order (new → near → far).
  static int? firstPendingPlanAyah(DailyPlan plan) {
    for (final ayah in plan.requiredAyahs) {
      if (!plan.isCompleted(ayah.ayahNumber)) {
        return ayah.ayahNumber;
      }
    }
    return null;
  }

  int? _firstLearningAyahInSurah(PendingAyahResolverInput input) {
    final ayahCount = input.surahAyahCount;
    if (ayahCount == null || ayahCount < 1) return null;

    final recordsByAyah = {
      for (final record in _surahAdultRecords(input)) record.ayahNumber: record,
    };

    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      final record = recordsByAyah[ayah];
      if (record == null) return ayah;
      if (ReviewRecordFilters.isLearning(record)) return ayah;
    }
    return null;
  }

  int? _firstDueAyahInSurah(PendingAyahResolverInput input) {
    final due =
        _surahAdultRecords(
            input,
          ).where((record) => record.reviewClassification.isDue).toList()
          ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    return due.isEmpty ? null : due.first.ayahNumber;
  }

  int? _lowestStartedAyahInSurah(PendingAyahResolverInput input) {
    final started =
        _surahAdultRecords(input).where(ReviewRecordFilters.isStarted).toList()
          ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    return started.isEmpty ? null : started.first.ayahNumber;
  }

  Iterable<AyahReviewRecord> _surahAdultRecords(
    PendingAyahResolverInput input,
  ) {
    return input.reviewRecords
        .where((record) => record.surahId == input.surahId)
        .where(ReviewRecordFilters.isAdultCompatible);
  }
}
