import 'package:equatable/equatable.dart';

import '../../features/memorization_plus/domain/entities/memorization_entities.dart';

/// Read-only aggregate of memorization state across existing stores.
///
/// Composes existing domain entities only — no duplicate progress models.
///
/// **Review records note (Sprint 8B):** [reviewRecords] is sourced from the
/// shared Memorization Plus Isar collection and may contain records from any
/// [ReviewRecordCreatedByMode] value: `adultMemPlus`, `kidsMode`, `migration`,
/// or `unknown`.  Consumers that surface adult-only data **must** apply
/// source-aware filtering via [ReviewRecordFilters] before using this list.
/// See `review_record_filters.dart` for available predicates.
class MemorizationSnapshot extends Equatable {
  const MemorizationSnapshot({
    required this.profile,
    this.lastRestorableLocation,
    this.reviewRecords = const [],
    this.cachedDailyPlan,
    this.customPlan,
    this.kidsProgress,
    this.kidsSessionLogs = const [],
  });

  /// Identity and path selection (SharedPrefs `mem_plus_profile`).
  final MemorizationProfile profile;

  /// Last restorable route from [AppSessionService], when valid.
  final String? lastRestorableLocation;

  /// Memorization Plus per-ayah SRS records (Isar `AyahReviewRecord`).
  final List<AyahReviewRecord> reviewRecords;

  /// Same-day cached daily plan, if any (SharedPrefs `mem_plus_daily_plan`).
  final DailyPlan? cachedDailyPlan;

  /// Active custom plan configuration, if any.
  final CustomMemorizationPlan? customPlan;

  /// Kids gamification progress (SharedPrefs). Null when read fails.
  final KidsProgress? kidsProgress;

  /// Kids session completion logs. No SRS history attached.
  final List<KidsSessionLog> kidsSessionLogs;

  @override
  List<Object?> get props => [
    profile,
    lastRestorableLocation,
    reviewRecords,
    cachedDailyPlan,
    customPlan,
    kidsProgress,
    kidsSessionLogs,
  ];
}
