import 'package:equatable/equatable.dart';

import '../../domain/entities/adult_journey_preferences.dart';
import '../../domain/entities/adult_journey_suggestion.dart';
import '../../domain/services/adult_return_policy.dart';

/// Why the last save failed. The UI maps it to a localized message; raw
/// exceptions never reach the state.
enum AdultJourneyErrorCode { saveFailed, unavailable, unsupportedRecord }

/// Which action failed, so only that action's card shows the message.
enum AdultJourneyErrorSource { profile, snooze, today, returnAction }

/// [hidden] means "show the ordinary experience": flag off, not a confirmed
/// adult, identity unresolved, or nothing loaded yet.
enum AdultJourneyStatus { hidden, ready }

class AdultJourneyState extends Equatable {
  const AdultJourneyState({
    this.status = AdultJourneyStatus.hidden,
    this.preferences = AdultJourneyPreferences.empty,
    this.suggestions = const [],
    this.localDate,
    this.todayBudgetEnabled = false,
    this.setupInviteDue = false,
    this.returnOffer,
    this.returnTimeActionsEnabled = false,
    this.isSaving = false,
    this.error,
    this.errorSource,
  });

  static const hidden = AdultJourneyState();

  final AdultJourneyStatus status;
  final AdultJourneyPreferences preferences;
  final List<AdultJourneySuggestion> suggestions;

  /// The local day the state was computed for (`YYYY-MM-DD`).
  final String? localDate;
  final bool todayBudgetEnabled;

  /// Personalization is on, no profile yet, and not snoozed today. Home still
  /// hides the invite while its own first-run card is visible.
  final bool setupInviteDue;

  /// The gentle-return invitation to show today, or null (flag off, not due,
  /// or dismissed today).
  final AdultReturnDecision? returnOffer;

  /// «بداية خفيفة» and «اختر وقتي» need the today-budget flag as well.
  final bool returnTimeActionsEnabled;
  final bool isSaving;
  final AdultJourneyErrorCode? error;
  final AdultJourneyErrorSource? errorSource;

  /// The error to show for [source], or null.
  AdultJourneyErrorCode? errorFor(AdultJourneyErrorSource source) =>
      errorSource == source ? error : null;

  bool get isVisible => status == AdultJourneyStatus.ready;

  /// Today's chosen minutes, or null when none or from another day.
  int? get todayMinutes =>
      localDate == null ? null : preferences.minutesFor(localDate!);

  AdultJourneyState copyWith({
    AdultJourneyPreferences? preferences,
    List<AdultJourneySuggestion>? suggestions,
    bool? isSaving,
    Object? error = _keep,
    Object? errorSource = _keep,
  }) {
    return AdultJourneyState(
      status: status,
      preferences: preferences ?? this.preferences,
      suggestions: suggestions ?? this.suggestions,
      localDate: localDate,
      todayBudgetEnabled: todayBudgetEnabled,
      setupInviteDue: setupInviteDue,
      returnOffer: returnOffer,
      returnTimeActionsEnabled: returnTimeActionsEnabled,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _keep)
          ? this.error
          : error as AdultJourneyErrorCode?,
      errorSource: identical(errorSource, _keep)
          ? this.errorSource
          : errorSource as AdultJourneyErrorSource?,
    );
  }

  static const Object _keep = Object();

  @override
  List<Object?> get props => [
    status,
    preferences,
    suggestions,
    localDate,
    todayBudgetEnabled,
    setupInviteDue,
    returnOffer,
    returnTimeActionsEnabled,
    isSaving,
    error,
    errorSource,
  ];
}
