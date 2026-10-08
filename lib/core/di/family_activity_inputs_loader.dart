import 'package:get_it/get_it.dart';

import '../../features/home/domain/repositories/activity_feed_repository.dart';
import '../../features/memorization_plus/data/datasources/kids_achievement_store.dart';
import '../../features/memorization_plus/data/datasources/kids_reading_receipt_store.dart';
import '../../features/memorization_plus/data/datasources/kids_streak_store.dart';
import '../../features/memorization_plus/data/repositories/collaborators/family_activity_publisher.dart';
import '../../features/memorization_plus/domain/services/kids_daily_missions.dart';
import '../../features/memorization_plus/domain/services/kids_progress_snapshot.dart';
import '../services/achievement_service.dart';
import '../services/xp_service.dart';

/// Resolves the child-activity sources at publish time, so the repository
/// that publishes never depends on services that themselves depend on it.
FamilyActivityInputsLoader familyActivityInputsLoader(GetIt getIt) => () async {
  // The child's own streak, never the primary learner's shared one.
  final kidsStreak = getIt<KidsStreakStore>();
  final streak = await kidsStreak.getStreak();
  final receipts = getIt<KidsReadingReceiptStore>();
  return FamilyActivityInputs(
    currentStreak: streak.currentStreak,
    longestStreak: streak.longestStreak,
    totalXp: await getIt<XpService>().getTotalXp(),
    activityByDay: await kidsStreak.getActivityMap(days: 30),
    readPages: await receipts.allPages(),
    todayReadPages: await receipts.pagesOn(kidsDayKey(DateTime.now())),
    events: await getIt<ActivityFeedRepository>().recent(
      limit: FamilyActivityPublisher.maxActivities,
      kids: true,
    ),
    certificates: getIt<AchievementService>().getEarnedCertificates(
      isKids: true,
    ),
    weekReadPages: {
      for (var i = 0; i < 7; i++)
        ...await receipts.pagesOn(
          kidsDayKey(DateTime.now().subtract(Duration(days: i))),
        ),
    },
    achievements: await _kidsAchievements(getIt),
  );
};

/// The child's milestones, brought up to date first so a milestone reached
/// since the kids page was last opened is published too.
Future<Map<String, DateTime>> _kidsAchievements(GetIt getIt) async {
  try {
    await getIt<KidsProgressSnapshotLoader>().load();
  } catch (_) {
    // Publish what is already stored.
  }
  return getIt<KidsAchievementStore>().unlocked();
}
