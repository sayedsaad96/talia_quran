import 'package:equatable/equatable.dart';

/// What the adult wants the optional journey card to favour. It only orders
/// optional suggestions; it never writes `user_primary_goal` or feeds the
/// unified journey engine (spec §4.1).
enum AdultJourneyGoal { reading, memorization, review, azkar }

/// Self-description. Affects wording and suggestions only: it never marks an
/// ayah as memorized or changes grades, difficulty or the stored plan.
enum AdultJourneyExperience { beginner, continuing, returning }

/// The only "time for today" choices offered (spec §4.2).
const Set<int> adultJourneyMinuteChoices = {5, 10, 20};

/// One owner's adult-journey preferences. The owner is part of the storage
/// key, never a field. Local dates are `YYYY-MM-DD` in the device's current
/// zone; [lastHomeSeenAtUtc] is an absolute instant.
class AdultJourneyPreferences extends Equatable {
  const AdultJourneyPreferences({
    this.goal,
    this.experience,
    this.profileCompleted = false,
    this.setupSnoozedLocalDate,
    this.todayLocalDate,
    this.todayMinutes,
    this.lightReturnToday = false,
    this.lastHomeSeenAtUtc,
    this.returnOfferLocalDate,
    this.returnDismissedLocalDate,
  });

  static const schemaVersion = 1;

  /// No stored record: the ordinary, unpersonalized experience.
  static const empty = AdultJourneyPreferences();

  final AdultJourneyGoal? goal;
  final AdultJourneyExperience? experience;
  final bool profileCompleted;
  final String? setupSnoozedLocalDate;
  final String? todayLocalDate;
  final int? todayMinutes;
  final bool lightReturnToday;
  final DateTime? lastHomeSeenAtUtc;
  final String? returnOfferLocalDate;
  final String? returnDismissedLocalDate;

  /// Today's time choice, or null once the local day it was made for passed.
  int? minutesFor(String localDate) =>
      todayLocalDate == localDate ? todayMinutes : null;

  bool lightReturnFor(String localDate) =>
      todayLocalDate == localDate && lightReturnToday;

  bool isSetupSnoozedOn(String localDate) => setupSnoozedLocalDate == localDate;

  AdultJourneyPreferences copyWith({
    Object? goal = _keep,
    Object? experience = _keep,
    bool? profileCompleted,
    Object? setupSnoozedLocalDate = _keep,
    Object? todayLocalDate = _keep,
    Object? todayMinutes = _keep,
    bool? lightReturnToday,
    Object? lastHomeSeenAtUtc = _keep,
    Object? returnOfferLocalDate = _keep,
    Object? returnDismissedLocalDate = _keep,
  }) {
    return AdultJourneyPreferences(
      goal: _pick(goal, this.goal),
      experience: _pick(experience, this.experience),
      profileCompleted: profileCompleted ?? this.profileCompleted,
      setupSnoozedLocalDate: _pick(
        setupSnoozedLocalDate,
        this.setupSnoozedLocalDate,
      ),
      todayLocalDate: _pick(todayLocalDate, this.todayLocalDate),
      todayMinutes: _pick(todayMinutes, this.todayMinutes),
      lightReturnToday: lightReturnToday ?? this.lightReturnToday,
      lastHomeSeenAtUtc: _pick(lastHomeSeenAtUtc, this.lastHomeSeenAtUtc),
      returnOfferLocalDate: _pick(
        returnOfferLocalDate,
        this.returnOfferLocalDate,
      ),
      returnDismissedLocalDate: _pick(
        returnDismissedLocalDate,
        this.returnDismissedLocalDate,
      ),
    );
  }

  static const Object _keep = Object();

  static T? _pick<T>(Object? value, T? current) =>
      identical(value, _keep) ? current : value as T?;

  @override
  List<Object?> get props => [
    goal,
    experience,
    profileCompleted,
    setupSnoozedLocalDate,
    todayLocalDate,
    todayMinutes,
    lightReturnToday,
    lastHomeSeenAtUtc,
    returnOfferLocalDate,
    returnDismissedLocalDate,
  ];
}

enum AdultJourneyLoadStatus {
  /// A valid v1 record.
  ready,

  /// Nothing stored for this owner.
  missing,

  /// A record from a newer schema. Never overwritten (downgrade safety).
  unsupported,

  /// Unreadable JSON or invalid fields. Never overwritten automatically.
  corrupt,

  /// Identity not ready, owner changed, or storage could not be trusted.
  unavailable,
}

/// The outcome of reading the record. Anything other than [ready] shows the
/// ordinary experience through [preferences] == [AdultJourneyPreferences.empty].
class AdultJourneyLoadResult extends Equatable {
  const AdultJourneyLoadResult._(this.status, this.preferences);

  const AdultJourneyLoadResult.ready(AdultJourneyPreferences preferences)
    : this._(AdultJourneyLoadStatus.ready, preferences);

  static const missing = AdultJourneyLoadResult._(
    AdultJourneyLoadStatus.missing,
    AdultJourneyPreferences.empty,
  );
  static const unsupported = AdultJourneyLoadResult._(
    AdultJourneyLoadStatus.unsupported,
    AdultJourneyPreferences.empty,
  );
  static const corrupt = AdultJourneyLoadResult._(
    AdultJourneyLoadStatus.corrupt,
    AdultJourneyPreferences.empty,
  );
  static const unavailable = AdultJourneyLoadResult._(
    AdultJourneyLoadStatus.unavailable,
    AdultJourneyPreferences.empty,
  );

  final AdultJourneyLoadStatus status;
  final AdultJourneyPreferences preferences;

  @override
  List<Object?> get props => [status, preferences];
}

enum AdultJourneySaveFailure {
  /// Identity not ready, or the owner changed during the save.
  unavailable,

  /// The platform write reported failure or threw.
  storage,

  /// The stored record is from a newer schema and is kept untouched.
  unsupportedRecord,

  /// Corrupt record and an automatic command: left for the user to replace.
  corruptRecord,
}

/// The outcome of one update. A failed save never reports success.
class AdultJourneySaveResult extends Equatable {
  const AdultJourneySaveResult.saved(AdultJourneyPreferences this.preferences)
    : failure = null,
      changed = true;

  const AdultJourneySaveResult.unchanged(
    AdultJourneyPreferences this.preferences,
  ) : failure = null,
      changed = false;

  const AdultJourneySaveResult.failed(AdultJourneySaveFailure this.failure)
    : preferences = null,
      changed = false;

  final AdultJourneyPreferences? preferences;
  final AdultJourneySaveFailure? failure;
  final bool changed;

  bool get isSuccess => failure == null;

  @override
  List<Object?> get props => [preferences, failure, changed];
}
