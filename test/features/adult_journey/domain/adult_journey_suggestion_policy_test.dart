import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/core/journey/unified_journey_engine.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_suggestion.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_journey_suggestion_policy.dart';

const _today = '2026-10-11';
final _now = DateTime.utc(2026, 10, 11, 9);
const _policy = AdultJourneySuggestionPolicy(toLocal: _utc);

UnifiedJourneyAction _action(
  String route,
  UnifiedJourneyPriority priority,
  UnifiedJourneyActionType type,
  JourneyIntent intent,
) => UnifiedJourneyAction(
  route: route,
  priority: priority,
  source: 'test',
  actionType: type,
  intent: intent,
);

final _resume = _action(
  '/memorization-plus/v2/session?surahId=2',
  UnifiedJourneyPriority.p1ActiveSession,
  UnifiedJourneyActionType.resumeSession,
  JourneyIntent.resume,
);
final _backlog = _action(
  '/memorization/review',
  UnifiedJourneyPriority.p3ReviewBacklog,
  UnifiedJourneyActionType.reviewBacklog,
  JourneyIntent.review,
);
final _plan = _action(
  '/memorization/plan',
  UnifiedJourneyPriority.p4SmartPlan,
  UnifiedJourneyActionType.smartPlan,
  JourneyIntent.memorize,
);
final _khatmah = _action(
  '/khatmah',
  UnifiedJourneyPriority.p5DailyGoal,
  UnifiedJourneyActionType.khatmah,
  JourneyIntent.reading,
);
final _wird = _action(
  '/quran/page/5',
  UnifiedJourneyPriority.p5DailyGoal,
  UnifiedJourneyActionType.dailyReading,
  JourneyIntent.reading,
);
final _explore = _action(
  '/quran',
  UnifiedJourneyPriority.p6FreeExploration,
  UnifiedJourneyActionType.explore,
  JourneyIntent.explore,
);

AdultJourneyContext _context(
  List<UnifiedJourneyAction> actions, {
  bool isAdult = true,
  bool hasPlan = true,
  bool hasReviews = true,
}) => AdultJourneyContext(
  ownerId: 'owner-a',
  isAdult: isAdult,
  now: _now,
  actions: actions,
  hasActiveAdultPlan: hasPlan,
  hasAdultReviewRecords: hasReviews,
  hasDueAdultReview: false,
);

AdultJourneyPreferences _prefs({
  AdultJourneyGoal? goal,
  int? minutes,
  bool light = false,
}) => AdultJourneyPreferences(
  goal: goal,
  profileCompleted: goal != null,
  todayLocalDate: minutes == null ? null : _today,
  todayMinutes: minutes,
  lightReturnToday: light,
);

List<String?> _routes(List<AdultJourneySuggestion> list) =>
    list.map((s) => s.action?.route).toList();

void main() {
  test('a child or unconfirmed adult gets nothing', () {
    expect(
      _policy.select(
        context: _context([_explore], isAdult: false),
        preferences: _prefs(goal: AdultJourneyGoal.reading, minutes: 10),
      ),
      isEmpty,
    );
  });

  test('without a goal or a time choice there is no overlay', () {
    expect(
      _policy.select(context: _context([_explore]), preferences: _prefs()),
      isEmpty,
    );
  });

  test('protected p1..p3 stay first and in order regardless of goal', () {
    final result = _policy.select(
      context: _context([_resume, _backlog, _plan, _wird, _explore]),
      preferences: _prefs(goal: AdultJourneyGoal.reading, minutes: 20),
    );
    expect(_routes(result), [_resume.route, _backlog.route, _wird.route]);
    expect(result[0].reason, AdultJourneySuggestionReason.resume);
    expect(result[0].resumeDestination, AdultResumeDestination.memorization);
    expect(result[1].reason, AdultJourneySuggestionReason.urgent);
  });

  test('a review longer than 5 minutes stays first and is flagged', () {
    final result = _policy.select(
      context: _context([_backlog, _plan, _explore]),
      preferences: _prefs(minutes: 5),
    );
    expect(result.first.action, same(_backlog));
    expect(result.first.estimatedMinutes, 6);
    expect(result.first.exceedsBudget, isTrue);
  });

  test('at most three suggestions without duplicate routes', () {
    final result = _policy.select(
      context: _context([_resume, _backlog, _plan, _khatmah, _wird, _explore]),
      preferences: _prefs(minutes: 10),
    );
    expect(result, hasLength(3));
    expect(_routes(result).toSet(), hasLength(3));
  });

  test('optional items: goal, then time fit, then original order', () {
    final result = _policy.select(
      context: _context([_plan, _wird, _explore]),
      preferences: _prefs(goal: AdultJourneyGoal.reading, minutes: 5),
    );
    // wird matches the goal; explore (2) fits 5 minutes; plan (8) does not.
    expect(_routes(result), [_wird.route, _explore.route, _plan.route]);
    expect(result[0].reason, AdultJourneySuggestionReason.goalMatch);
    expect(result[1].reason, AdultJourneySuggestionReason.timeFit);
    expect(result[2].exceedsBudget, isTrue);
  });

  test('reading goal matches the khatmah as well as the wird', () {
    final result = _policy.select(
      context: _context([_plan, _khatmah, _explore]),
      preferences: _prefs(goal: AdultJourneyGoal.reading),
    );
    expect(result.first.launchKind, AdultJourneyLaunchKind.khatmah);
  });

  test('light return never puts new memorization before other options', () {
    final result = _policy.select(
      context: _context([_plan, _wird, _explore]),
      preferences: _prefs(
        goal: AdultJourneyGoal.memorization,
        minutes: 5,
        light: true,
      ),
    );
    expect(result.last.launchKind, AdultJourneyLaunchKind.memorize);
    expect(
      result.where((s) => s.action == null),
      isEmpty,
      reason: 'light return adds no synthetic start',
    );
  });

  test('memorization goal without a plan offers the existing plan setup', () {
    final result = _policy.select(
      context: _context([_wird, _explore], hasPlan: false),
      preferences: _prefs(goal: AdultJourneyGoal.memorization),
    );
    expect(result.first.launchKind, AdultJourneyLaunchKind.setupPlan);
    expect(result.first.reason, AdultJourneySuggestionReason.needsPlan);
    expect(result.first.action, isNull);
    expect(result.first.estimatedMinutes, isNull);
  });

  test('review goal with nothing memorized explains instead of inventing', () {
    final result = _policy.select(
      context: _context([_wird, _explore], hasReviews: false),
      preferences: _prefs(goal: AdultJourneyGoal.review),
    );
    expect(result.first.reason, AdultJourneySuggestionReason.noReview);
    expect(result.first.action, isNull);
  });

  test(
    'no synthetic start when an existing action already covers the goal',
    () {
      final result = _policy.select(
        context: _context([_plan, _explore], hasPlan: false),
        preferences: _prefs(goal: AdultJourneyGoal.memorization),
      );
      expect(result.first.action, same(_plan));
      expect(result.where((s) => s.action == null), isEmpty);
    },
  );

  test('a time choice from yesterday has expired', () {
    final result = _policy.select(
      context: _context([_backlog, _explore]),
      preferences: const AdultJourneyPreferences(
        todayLocalDate: '2026-10-10',
        todayMinutes: 5,
      ),
    );
    expect(result, isEmpty);
  });

  test('estimates come from the existing journeyActionMinutes', () {
    final result = _policy.select(
      context: _context([_resume, _plan, _wird]),
      preferences: _prefs(minutes: 20),
    );
    for (final s in result) {
      expect(s.estimatedMinutes, journeyActionMinutes(s.action!));
    }
    expect(result.map((s) => s.estimatedMinutes), [3, 8, 4]);
  });

  group('resume destination', () {
    test('maps known sections and rejects kids or unknown paths', () {
      String d(String route) =>
          AdultJourneySuggestionPolicy.resumeDestinationOf(route).name;
      expect(d('/memorization-plus/v2/session?x=1'), 'memorization');
      expect(d('/memorization/review'), 'memorization');
      expect(d('/quran/page/3'), 'quran');
      expect(d('/azkar/morning'), 'azkar');
      expect(d('/memorization-plus/kids-quran?surah=1'), 'unknown');
      expect(d('/settings'), 'unknown');
      expect(d(''), 'unknown');
    });
  });
}

DateTime _utc(DateTime value) => value.toUtc();
