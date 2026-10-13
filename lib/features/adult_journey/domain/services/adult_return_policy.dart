import 'package:equatable/equatable.dart';

import 'adult_local_date.dart';

enum AdultReturnReason {
  /// Seven or more local calendar days since the previous eligible visit.
  absence,

  /// The user described themself as returning; no absence date is claimed.
  selfDescribed,
}

class AdultReturnDecision extends Equatable {
  const AdultReturnDecision.none()
    : showOffer = false,
      eligibleLocalDate = null,
      reason = null;

  const AdultReturnDecision.offer({
    required String this.eligibleLocalDate,
    required AdultReturnReason this.reason,
  }) : showOffer = true;

  final bool showOffer;
  final String? eligibleLocalDate;
  final AdultReturnReason? reason;

  @override
  List<Object?> get props => [showOffer, eligibleLocalDate, reason];
}

/// Pure calendar-day rules for the gentle-return invitation (spec §4.3).
///
/// Instants are converted with [toLocal] (the device's current zone by
/// default) and compared by calendar day, never by `difference.inDays`.
class AdultReturnPolicy {
  const AdultReturnPolicy({DateTime Function(DateTime instant)? toLocal})
    : _toLocal = toLocal;

  static const minimumGapDays = 7;

  final DateTime Function(DateTime instant)? _toLocal;

  DateTime _local(DateTime instant) =>
      _toLocal == null ? instant.toLocal() : _toLocal(instant);

  String localDateOf(DateTime instant) =>
      AdultLocalDate.format(_local(instant));

  /// Whole local calendar days from [from] to [to]; negative when [from] is
  /// later (a future or skewed stored instant).
  int calendarDayGap(DateTime from, DateTime to) {
    final a = _local(from);
    final b = _local(to);
    final dayA = DateTime.utc(a.year, a.month, a.day);
    final dayB = DateTime.utc(b.year, b.month, b.day);
    return dayB.difference(dayA).inDays;
  }

  AdultReturnDecision evaluate({
    required DateTime now,
    required DateTime? lastHomeSeenAtUtc,
    required String? returnOfferLocalDate,
    required String? returnDismissedLocalDate,
    required bool explicitlyReturning,
  }) {
    final today = localDateOf(now);
    if (returnDismissedLocalDate == today) {
      return const AdultReturnDecision.none();
    }
    if (returnOfferLocalDate == today) {
      return AdultReturnDecision.offer(
        eligibleLocalDate: today,
        reason: AdultReturnReason.absence,
      );
    }
    if (explicitlyReturning) {
      return AdultReturnDecision.offer(
        eligibleLocalDate: today,
        reason: AdultReturnReason.selfDescribed,
      );
    }
    if (_isAbsence(now, lastHomeSeenAtUtc)) {
      return AdultReturnDecision.offer(
        eligibleLocalDate: today,
        reason: AdultReturnReason.absence,
      );
    }
    return const AdultReturnDecision.none();
  }

  /// Whether a visit at [now] after [previousVisit] counts as a return. A
  /// missing (upgrade/first run) or future previous visit never does.
  bool isAbsence(DateTime now, DateTime? previousVisit) =>
      _isAbsence(now, previousVisit);

  bool _isAbsence(DateTime now, DateTime? previous) {
    if (previous == null) return false;
    return calendarDayGap(previous, now) >= minimumGapDays;
  }
}
