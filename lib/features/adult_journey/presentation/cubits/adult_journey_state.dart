import 'package:equatable/equatable.dart';

import '../../domain/entities/adult_journey_preferences.dart';
import '../../domain/entities/adult_journey_suggestion.dart';

/// Why the last save failed. The UI maps it to a localized message; raw
/// exceptions never reach the state.
enum AdultJourneyErrorCode { saveFailed, unavailable, unsupportedRecord }

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
    this.isSaving = false,
    this.error,
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
  final bool isSaving;
  final AdultJourneyErrorCode? error;

  bool get isVisible => status == AdultJourneyStatus.ready;

  /// Today's chosen minutes, or null when none or from another day.
  int? get todayMinutes =>
      localDate == null ? null : preferences.minutesFor(localDate!);

  AdultJourneyState copyWith({
    AdultJourneyPreferences? preferences,
    List<AdultJourneySuggestion>? suggestions,
    bool? isSaving,
    Object? error = _keep,
  }) {
    return AdultJourneyState(
      status: status,
      preferences: preferences ?? this.preferences,
      suggestions: suggestions ?? this.suggestions,
      localDate: localDate,
      todayBudgetEnabled: todayBudgetEnabled,
      setupInviteDue: setupInviteDue,
      isSaving: isSaving ?? this.isSaving,
      error: identical(error, _keep)
          ? this.error
          : error as AdultJourneyErrorCode?,
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
    isSaving,
    error,
  ];
}
