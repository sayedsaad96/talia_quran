import 'package:get_it/get_it.dart';

import '../../features/home/domain/repositories/activity_feed_repository.dart';
import '../../features/memorization_plus/data/datasources/kids_reading_receipt_store.dart';
import '../../features/memorization_plus/data/repositories/collaborators/family_activity_publisher.dart';
import '../../features/memorization_plus/domain/services/kids_daily_missions.dart';
import '../services/achievement_service.dart';
import '../services/streak_service.dart';
import '../services/xp_service.dart';

/// Resolves the child-activity sources at publish time, so the repository
/// that publishes never depends on services that themselves depend on it.
FamilyActivityInputsLoader familyActivityInputsLoader(GetIt getIt) => () async {
  final streakService = getIt<StreakService>();
  final streak = await streakService.getStreak();
  final receipts = getIt<KidsReadingReceiptStore>();
  return FamilyActivityInputs(
    currentStreak: streak.currentStreak,
    longestStreak: streak.longestStreak,
    totalXp: await getIt<XpService>().getTotalXp(),
    activityByDay: await streakService.getActivityMap(days: 30),
    readPages: await receipts.allPages(),
    todayReadPages: await receipts.pagesOn(kidsDayKey(DateTime.now())),
    events: await getIt<ActivityFeedRepository>().recent(
      limit: FamilyActivityPublisher.maxActivities,
    ),
    certificates: getIt<AchievementService>().getEarnedCertificates(
      isKids: true,
    ),
  );
};
