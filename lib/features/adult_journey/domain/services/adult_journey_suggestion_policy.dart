import '../../../../core/journey/unified_journey_action.dart';
import '../../../../core/journey/unified_journey_engine.dart';
import '../entities/adult_journey_context.dart';
import '../entities/adult_journey_preferences.dart';
import '../entities/adult_journey_suggestion.dart';
import 'adult_local_date.dart';

/// Chooses up to [maxSuggestions] optional suggestions on top of the unified
/// journey's existing actions (spec §4.2). It never creates sessions, tasks
/// or plan changes, and never reorders the protected p1–p3 actions.
class AdultJourneySuggestionPolicy {
  const AdultJourneySuggestionPolicy({
    DateTime Function(DateTime instant)? toLocal,
  }) : _toLocal = toLocal;

  static const maxSuggestions = 3;

  final DateTime Function(DateTime instant)? _toLocal;

  List<AdultJourneySuggestion> select({
    required AdultJourneyContext context,
    required AdultJourneyPreferences preferences,
  }) {
    if (!context.isAdult) return const [];
    final now = context.now;
    final today = AdultLocalDate.format(
      _toLocal == null ? now.toLocal() : _toLocal(now),
    );
    final budget = preferences.minutesFor(today);
    final goal = preferences.profileCompleted ? preferences.goal : null;
    if (goal == null && budget == null) return const [];
    final light = preferences.lightReturnFor(today);

    final protected = <AdultJourneySuggestion>[];
    final optional = <_Ranked>[];
    for (final (index, action) in context.actions.indexed) {
      final kind = launchKindOf(action);
      final minutes = journeyActionMinutes(action);
      final exceeds = budget != null && minutes > budget;
      if (action.priority.index <=
          UnifiedJourneyPriority.p3ReviewBacklog.index) {
        protected.add(
          AdultJourneySuggestion(
            action: action,
            launchKind: kind,
            estimatedMinutes: minutes,
            exceedsBudget: exceeds,
            reason: kind == AdultJourneyLaunchKind.resume
                ? AdultJourneySuggestionReason.resume
                : AdultJourneySuggestionReason.urgent,
            resumeDestination: kind == AdultJourneyLaunchKind.resume
                ? resumeDestinationOf(action.route)
                : null,
          ),
        );
        continue;
      }
      final matches = goal != null && _matchesGoal(kind, goal);
      final fits = budget != null && !exceeds;
      optional.add(
        _Ranked(
          index: index,
          demoted: light && kind == AdultJourneyLaunchKind.memorize,
          matchesGoal: matches,
          fits: budget == null || !exceeds,
          suggestion: AdultJourneySuggestion(
            action: action,
            launchKind: kind,
            estimatedMinutes: minutes,
            exceedsBudget: exceeds,
            reason: matches
                ? AdultJourneySuggestionReason.goalMatch
                : fits
                ? AdultJourneySuggestionReason.timeFit
                : AdultJourneySuggestionReason.ordinary,
          ),
        ),
      );
    }
    optional.sort(_Ranked.compare);

    final hasKind = {
      for (final s in [...protected, ...optional.map((r) => r.suggestion)])
        s.launchKind,
    };
    final goalStart = goal == null
        ? null
        : _goalStart(goal, context, hasKind, light);

    return [
      ...protected,
      ?goalStart,
      ...optional.map((r) => r.suggestion),
    ].take(maxSuggestions).toList(growable: false);
  }

  /// An explained destination for the goal when no existing action covers
  /// it. It carries no ayah range or session target.
  AdultJourneySuggestion? _goalStart(
    AdultJourneyGoal goal,
    AdultJourneyContext context,
    Set<AdultJourneyLaunchKind> present,
    bool light,
  ) {
    if (light) return null;
    final (kind, reason) = switch (goal) {
      AdultJourneyGoal.memorization when !context.hasActiveAdultPlan => (
        AdultJourneyLaunchKind.setupPlan,
        AdultJourneySuggestionReason.needsPlan,
      ),
      AdultJourneyGoal.memorization => (
        AdultJourneyLaunchKind.memorize,
        AdultJourneySuggestionReason.goalMatch,
      ),
      AdultJourneyGoal.review when !context.hasAdultReviewRecords => (
        AdultJourneyLaunchKind.setupPlan,
        AdultJourneySuggestionReason.noReview,
      ),
      AdultJourneyGoal.review => (
        AdultJourneyLaunchKind.review,
        AdultJourneySuggestionReason.goalMatch,
      ),
      AdultJourneyGoal.reading => (
        AdultJourneyLaunchKind.reading,
        AdultJourneySuggestionReason.goalMatch,
      ),
      AdultJourneyGoal.azkar => (
        AdultJourneyLaunchKind.azkar,
        AdultJourneySuggestionReason.goalMatch,
      ),
    };
    if (present.any((k) => _matchesGoal(k, goal))) return null;
    return AdultJourneySuggestion(launchKind: kind, reason: reason);
  }

  static bool _matchesGoal(AdultJourneyLaunchKind kind, AdultJourneyGoal goal) {
    return switch (goal) {
      AdultJourneyGoal.reading =>
        kind == AdultJourneyLaunchKind.reading ||
            kind == AdultJourneyLaunchKind.khatmah,
      AdultJourneyGoal.memorization => kind == AdultJourneyLaunchKind.memorize,
      AdultJourneyGoal.review => kind == AdultJourneyLaunchKind.review,
      AdultJourneyGoal.azkar => kind == AdultJourneyLaunchKind.azkar,
    };
  }

  static AdultJourneyLaunchKind launchKindOf(UnifiedJourneyAction action) {
    switch (action.actionType) {
      case UnifiedJourneyActionType.resumeSession:
        return AdultJourneyLaunchKind.resume;
      case UnifiedJourneyActionType.khatmah:
        return AdultJourneyLaunchKind.khatmah;
      case UnifiedJourneyActionType.dailyReading:
        return AdultJourneyLaunchKind.reading;
      case UnifiedJourneyActionType.explore:
        return AdultJourneyLaunchKind.explore;
      case UnifiedJourneyActionType.criticalAlert:
      case UnifiedJourneyActionType.reviewBacklog:
      case UnifiedJourneyActionType.smartPlan:
        return switch (action.intent) {
          JourneyIntent.memorize => AdultJourneyLaunchKind.memorize,
          JourneyIntent.reading => AdultJourneyLaunchKind.reading,
          JourneyIntent.azkar => AdultJourneyLaunchKind.azkar,
          JourneyIntent.explore => AdultJourneyLaunchKind.explore,
          JourneyIntent.resume => AdultJourneyLaunchKind.resume,
          JourneyIntent.review => AdultJourneyLaunchKind.review,
        };
    }
  }

  /// The section a stored resume location belongs to. Kids paths and
  /// anything unrecognised map to [AdultResumeDestination.unknown].
  static AdultResumeDestination resumeDestinationOf(String route) {
    final path = Uri.tryParse(route)?.path ?? '';
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty || segments.any((s) => s.contains('kids'))) {
      return AdultResumeDestination.unknown;
    }
    return switch (segments.first) {
      'memorization' ||
      'memorization-plus' => AdultResumeDestination.memorization,
      'quran' => AdultResumeDestination.quran,
      'azkar' => AdultResumeDestination.azkar,
      _ => AdultResumeDestination.unknown,
    };
  }
}

class _Ranked {
  const _Ranked({
    required this.index,
    required this.demoted,
    required this.matchesGoal,
    required this.fits,
    required this.suggestion,
  });

  final int index;
  final bool demoted;
  final bool matchesGoal;
  final bool fits;
  final AdultJourneySuggestion suggestion;

  /// Light return first avoids new memorization, then goal, then time, then
  /// the journey's original order.
  static int compare(_Ranked a, _Ranked b) {
    if (a.demoted != b.demoted) return a.demoted ? 1 : -1;
    if (a.matchesGoal != b.matchesGoal) return a.matchesGoal ? -1 : 1;
    if (a.fits != b.fits) return a.fits ? -1 : 1;
    return a.index.compareTo(b.index);
  }
}
