import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/daily_review_task.dart';
import 'package:talia_quran/features/adult_journey/domain/services/daily_review_task_policy.dart';

final now = DateTime(2026, 10, 31, 12);
const review = UnifiedJourneyAction(
  route: '/memorization/review',
  priority: UnifiedJourneyPriority.p3ReviewBacklog,
  source: 'test',
  actionType: UnifiedJourneyActionType.reviewBacklog,
  intent: JourneyIntent.review,
);
const resume = UnifiedJourneyAction(
  route: '/quran',
  priority: UnifiedJourneyPriority.p1ActiveSession,
  source: 'test',
  actionType: UnifiedJourneyActionType.resumeSession,
  intent: JourneyIntent.resume,
);
const critical = UnifiedJourneyAction(
  route: '/quran',
  priority: UnifiedJourneyPriority.p2CriticalAlert,
  source: 'test',
  actionType: UnifiedJourneyActionType.criticalAlert,
  intent: JourneyIntent.reading,
);
AdultJourneyContext context(
  List<UnifiedJourneyAction> actions, {
  bool adult = true,
  bool records = true,
  bool due = false,
}) => AdultJourneyContext(
  ownerId: 'a',
  isAdult: adult,
  now: now,
  actions: actions,
  hasActiveAdultPlan: true,
  hasAdultReviewRecords: records,
  hasDueAdultReview: due,
);
const prefs = AdultJourneyPreferences(
  todayLocalDate: '2026-10-31',
  todayMinutes: 5,
);
const policy = DailyReviewTaskPolicy();
void main() {
  test('respects identity and protected priorities', () {
    expect(
      policy
          .select(context: context([review], adult: false), preferences: prefs)
          .status,
      DailyReviewTaskStatus.unavailable,
    );
    expect(
      policy
          .select(context: context([review, resume]), preferences: prefs)
          .suggestion!
          .action,
      same(resume),
    );
    expect(
      policy
          .select(context: context([critical, review]), preferences: prefs)
          .status,
      DailyReviewTaskStatus.blockedByPriority,
    );
  });
  test('finds review beyond three actions without a selected time', () {
    final decision = policy.select(
      context: context([criticalCopy, criticalCopy, criticalCopy, review]),
      preferences: AdultJourneyPreferences.empty,
    );
    expect(decision.suggestion!.action, same(review));
    expect(decision.exceedsBudget, false);
    expect(
      policy
          .select(context: context([review]), preferences: prefs)
          .exceedsBudget,
      true,
    );
  });
  test('distinguishes missing, completed and inconsistent records', () {
    expect(
      policy
          .select(context: context([], records: false), preferences: prefs)
          .status,
      DailyReviewTaskStatus.noReviews,
    );
    expect(
      policy.select(context: context([]), preferences: prefs).status,
      DailyReviewTaskStatus.noDueReview,
    );
    expect(
      policy.select(context: context([], due: true), preferences: prefs).status,
      DailyReviewTaskStatus.unavailable,
    );
  });
  test('yesterday budget expires and decision key is stable', () {
    const yesterday = AdultJourneyPreferences(
      todayLocalDate: '2026-10-30',
      todayMinutes: 5,
    );
    final first = policy.select(
      context: context([review]),
      preferences: yesterday,
    );
    final second = policy.select(
      context: context([review]),
      preferences: yesterday,
    );
    expect(first.exceedsBudget, false);
    expect(first.decisionKey, second.decisionKey);
  });
}

const criticalCopy = UnifiedJourneyAction(
  route: '/quran',
  priority: UnifiedJourneyPriority.p5DailyGoal,
  source: 'test',
  actionType: UnifiedJourneyActionType.dailyReading,
  intent: JourneyIntent.reading,
);
