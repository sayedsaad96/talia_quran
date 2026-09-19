import 'package:equatable/equatable.dart';

/// The five obligatory prayers the Companion can track.
enum PrayerKey { fajr, dhuhr, asr, maghrib, isha }

/// Self-reported state of a single prayer occurrence.
///
/// Nothing is ever inferred from elapsed time: [unconfirmed] is the derived
/// default for an occurrence without a stored record, and [notYet] is an
/// explicit user statement, never an automatic state.
enum PrayerCompanionStatus {
  unconfirmed,
  prayNow,
  remindLater,
  confirmed,
  notYet,
}

/// Explicit user commands handled by the Companion policy.
enum PrayerCompanionCommand { confirm, prayNow, remindLater, notYet, clear }

/// Kinds of local notifications the Companion may schedule.
enum PrayerCompanionNotificationKind { preparation, checkIn, followUp }

/// Builds the stable, owner-scoped identity of a prayer occurrence.
///
/// The key uses the local civil date (time portion ignored) plus the prayer
/// key, so timezone, DST, or calculation changes never reassign a record.
String makeOccurrenceKey(
  String ownerId,
  DateTime localDate,
  PrayerKey prayerKey,
) {
  final y = localDate.year.toString().padLeft(4, '0');
  final m = localDate.month.toString().padLeft(2, '0');
  final d = localDate.day.toString().padLeft(2, '0');
  return '$ownerId|$y-$m-$d|${prayerKey.name}';
}

/// One prayer on one local civil day for one owner.
class PrayerOccurrence extends Equatable {
  const PrayerOccurrence({
    required this.ownerId,
    required this.localDate,
    required this.prayerKey,
    required this.scheduledAt,
  });

  final String ownerId;
  final DateTime localDate;
  final PrayerKey prayerKey;
  final DateTime scheduledAt;

  String get occurrenceKey => makeOccurrenceKey(ownerId, localDate, prayerKey);

  @override
  List<Object?> get props => [ownerId, localDate, prayerKey, scheduledAt];
}

/// Opt-in Companion preferences. The Companion defaults to off.
class PrayerCompanionSettings extends Equatable {
  const PrayerCompanionSettings({
    this.enabled = false,
    this.preparationMinutes = 0,
    this.checkInEnabled = true,
    this.followUpEnabled = true,
  }) : assert(
         preparationMinutes == 0 ||
             preparationMinutes == 5 ||
             preparationMinutes == 10 ||
             preparationMinutes == 15,
         'preparationMinutes must be 0, 5, 10, or 15',
       );

  final bool enabled;

  /// Minutes before the prayer for a preparation reminder (0/5/10/15).
  /// 0 disables the preparation reminder and is the default.
  final int preparationMinutes;

  /// Whether a check-in is scheduled 20 minutes after the prayer.
  final bool checkInEnabled;

  /// Whether the single follow-up reminder is allowed.
  final bool followUpEnabled;

  PrayerCompanionSettings copyWith({
    bool? enabled,
    int? preparationMinutes,
    bool? checkInEnabled,
    bool? followUpEnabled,
  }) {
    return PrayerCompanionSettings(
      enabled: enabled ?? this.enabled,
      preparationMinutes: preparationMinutes ?? this.preparationMinutes,
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      followUpEnabled: followUpEnabled ?? this.followUpEnabled,
    );
  }

  @override
  List<Object?> get props => [
    enabled,
    preparationMinutes,
    checkInEnabled,
    followUpEnabled,
  ];
}

/// Persisted self-reported state for one [PrayerOccurrence].
class PrayerCompanionRecord extends Equatable {
  const PrayerCompanionRecord({
    required this.occurrence,
    required this.status,
    required this.statusUpdatedAt,
    required this.followUpCount,
    required this.createdAt,
    required this.updatedAt,
    this.followUpAt,
  });

  final PrayerOccurrence occurrence;
  final PrayerCompanionStatus status;
  final DateTime statusUpdatedAt;
  final DateTime? followUpAt;

  /// Number of follow-ups scheduled in the CURRENT follow-up cycle for this
  /// occurrence. The policy allows at most one PENDING follow-up at a time,
  /// so this is only ever 0 or 1 while a follow-up is active.
  ///
  /// V1 semantics: a follow-up whose time passes without a new explicit
  /// command is simply no longer surfaced (the planner skips elapsed
  /// follow-ups); the stored `followUpAt` lingers until the next explicit
  /// status change clears it. A fresh follow-up for the same occurrence can
  /// only be scheduled after that clearing (for example notYet → remindLater).
  /// This is the documented interpretation of the plan's "never more than
  /// once per occurrence": never more than one PENDING follow-up, never an
  /// escalating sequence.
  final int followUpCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrayerCompanionRecord copyWith({
    PrayerCompanionStatus? status,
    DateTime? statusUpdatedAt,
    DateTime? followUpAt,
    bool clearFollowUp = false,
    int? followUpCount,
    DateTime? updatedAt,
  }) {
    assert(
      !clearFollowUp || followUpAt == null,
      'clearFollowUp cannot be combined with a new followUpAt',
    );
    return PrayerCompanionRecord(
      occurrence: occurrence,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      followUpAt: clearFollowUp ? null : (followUpAt ?? this.followUpAt),
      followUpCount: followUpCount ?? this.followUpCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    occurrence,
    status,
    statusUpdatedAt,
    followUpAt,
    followUpCount,
    createdAt,
    updatedAt,
  ];
}

/// Compact per-day projection for the prayer-times sheet.
class PrayerCompanionDaySummary extends Equatable {
  const PrayerCompanionDaySummary({
    required this.statusByPrayer,
    required this.confirmedCount,
    this.actionableOccurrence,
  });

  final Map<PrayerKey, PrayerCompanionStatus> statusByPrayer;

  /// Only [PrayerCompanionStatus.confirmed] records count.
  final int confirmedCount;

  /// The occurrence the user can act on right now, if any.
  final PrayerOccurrence? actionableOccurrence;

  /// The five obligatory prayers the summary always covers.
  static const totalObligatoryPrayers = 5;

  @override
  List<Object?> get props => [
    statusByPrayer,
    confirmedCount,
    actionableOccurrence,
  ];
}
