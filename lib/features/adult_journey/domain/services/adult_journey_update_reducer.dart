import '../entities/adult_journey_preferences.dart';
import '../entities/adult_journey_update.dart';
import 'adult_return_policy.dart';

/// Applies one [AdultJourneyUpdate] to the latest stored record. Pure: the
/// repository runs it inside the account barrier. Returns null when the
/// command changes nothing, so no write happens.
class AdultJourneyUpdateReducer {
  const AdultJourneyUpdateReducer({
    AdultReturnPolicy returnPolicy = const AdultReturnPolicy(),
  }) : _returnPolicy = returnPolicy;

  final AdultReturnPolicy _returnPolicy;

  AdultJourneyPreferences? reduce(
    AdultJourneyPreferences current,
    AdultJourneyUpdate command,
  ) {
    final next = switch (command) {
      SaveAdultProfile(:final goal, :final experience) => current.copyWith(
        goal: goal,
        experience: experience,
        profileCompleted: true,
      ),
      SnoozeAdultSetup(:final localDate) => current.copyWith(
        setupSnoozedLocalDate: localDate,
      ),
      SetAdultToday(:final localDate, :final minutes, :final lightReturn) =>
        current.copyWith(
          todayLocalDate: localDate,
          todayMinutes: minutes,
          lightReturnToday: lightReturn,
        ),
      ClearAdultToday() => current.copyWith(
        todayLocalDate: null,
        todayMinutes: null,
        lightReturnToday: false,
      ),
      RecordAdultHomeVisit(:final nowUtc) => _recordVisit(current, nowUtc),
      DismissAdultReturn(:final localDate) => current.copyWith(
        returnDismissedLocalDate: localDate,
      ),
    };
    if (next == null || next == current) return null;
    return next;
  }

  /// At most one write per local day: a later visit on the same day keeps the
  /// stored instant. The offer is decided from the previous visit before it is
  /// replaced, and stored with the new visit in the same record.
  AdultJourneyPreferences? _recordVisit(
    AdultJourneyPreferences current,
    DateTime nowUtc,
  ) {
    final now = nowUtc.toUtc();
    final previous = current.lastHomeSeenAtUtc;
    final today = _returnPolicy.localDateOf(now);
    if (previous != null && _returnPolicy.localDateOf(previous) == today) {
      return null;
    }
    final offerToday = _returnPolicy.isAbsence(now, previous);
    return current.copyWith(
      lastHomeSeenAtUtc: now,
      returnOfferLocalDate: offerToday ? today : current.returnOfferLocalDate,
    );
  }
}
