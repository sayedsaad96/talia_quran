import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_context.dart';
import 'package:talia_quran/features/adult_journey/presentation/adult_journey_context_adapter.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

OverallProgress _progress({int memorized = 0, int overdue = 0}) =>
    OverallProgress(
      memorizedAyahs: memorized,
      totalAyahs: 6236,
      memorizedSurahs: 0,
      totalSurahs: 114,
      memorizedJuz: 0,
      totalJuz: 30,
      readAyahs: 0,
      readSurahs: 0,
      readJuz: 0,
      streakDays: 0,
      lastActiveDate: null,
      achievements: const [],
      readPagesCount: 0,
      totalQuranPages: 604,
      learningAyahs: 0,
      reviewAyahs: 0,
      overdueReviews: overdue,
    );

CustomMemorizationPlan _plan({
  bool active = true,
  PlanTargetUser target = PlanTargetUser.adult,
}) => CustomMemorizationPlan(
  name: 'plan',
  startSurahId: 78,
  endSurahId: 114,
  newAyahsPerDay: 3,
  availableDaysPerWeek: 5,
  sessionMinutes: 20,
  difficulty: MemorizationDifficulty.moderate,
  enableNearRevision: true,
  enableFarRevision: true,
  nearRevisionCount: 3,
  farRevisionCount: 3,
  startAyah: 1,
  createdAt: DateTime(2026, 1, 1),
  isActive: active,
  targetUser: target,
);

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

HomeLoaded _home({
  MemorizationTrack? track = MemorizationTrack.adults,
  bool isKids = false,
  OverallProgress? progress,
  CustomMemorizationPlan? plan,
  List<UnifiedJourneyAction> actions = const [],
  AyahReviewRecord? micro,
}) => HomeLoaded(
  progress: progress ?? _progress(),
  greeting: 'x',
  activityStartDate: DateTime(2026, 1, 1),
  selectedTrack: track,
  isKids: isKids,
  customPlan: plan,
  alternativeActions: actions,
  microReview: micro,
);

AdultJourneyContext _build(HomeLoaded s) => buildAdultJourneyContext(
  state: s,
  ownerId: 'owner-1',
  now: DateTime(2026, 10, 13),
);

void main() {
  test('a chosen adult track is a confirmed adult', () {
    final ctx = _build(_home());
    expect(ctx.isAdult, isTrue);
    expect(ctx.ownerId, 'owner-1');
  });

  test('a missing track (profile absent or failed) is not an adult', () {
    expect(_build(_home(track: null)).isAdult, isFalse);
  });

  test('kids are never adults, even with an adult track value', () {
    expect(_build(_home(track: MemorizationTrack.kids)).isAdult, isFalse);
    expect(_build(_home(isKids: true)).isAdult, isFalse);
  });

  test('actions keep their evaluateAll order', () {
    final a = _action(
      '/azkar',
      UnifiedJourneyPriority.p6FreeExploration,
      UnifiedJourneyActionType.explore,
      JourneyIntent.azkar,
    );
    final b = _action(
      '/quran',
      UnifiedJourneyPriority.p5DailyGoal,
      UnifiedJourneyActionType.dailyReading,
      JourneyIntent.reading,
    );
    final ctx = _build(_home(actions: [a, b]));
    expect(ctx.actions.map((x) => x.route), ['/azkar', '/quran']);
  });

  test('only an active adult plan counts as a plan', () {
    expect(_build(_home()).hasActiveAdultPlan, isFalse);
    expect(_build(_home(plan: _plan())).hasActiveAdultPlan, isTrue);
    expect(
      _build(_home(plan: _plan(active: false))).hasActiveAdultPlan,
      isFalse,
    );
    expect(
      _build(
        _home(plan: _plan(target: PlanTargetUser.child)),
      ).hasActiveAdultPlan,
      isFalse,
    );
  });

  test('review records need a memorized count or an adult micro review', () {
    expect(_build(_home()).hasAdultReviewRecords, isFalse);
    expect(
      _build(_home(progress: _progress(memorized: 3))).hasAdultReviewRecords,
      isTrue,
    );
  });

  test('due review comes from overdue count or a backlog action', () {
    expect(_build(_home()).hasDueAdultReview, isFalse);
    expect(
      _build(_home(progress: _progress(overdue: 2))).hasDueAdultReview,
      isTrue,
    );
    final backlog = _action(
      '/memorization',
      UnifiedJourneyPriority.p3ReviewBacklog,
      UnifiedJourneyActionType.reviewBacklog,
      JourneyIntent.review,
    );
    expect(_build(_home(actions: [backlog])).hasDueAdultReview, isTrue);
  });
}
