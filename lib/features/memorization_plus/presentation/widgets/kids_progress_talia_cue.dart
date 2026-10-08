import '../../domain/services/kids_achievements.dart';
import 'kids_talia_companion.dart';

enum KidsProgressCueKind { start, newAchievement, next, allDone }

/// What Talia says on the kids «تقدّمي» page: always encouragement, never a
/// shortfall.
class KidsProgressTaliaCue {
  const KidsProgressTaliaCue(this.kind, this.pose, [this.achievement]);

  final KidsProgressCueKind kind;
  final KidsTaliaPose pose;

  /// The milestone the message names, when it names one.
  final KidsAchievement? achievement;
}

/// A milestone reached within [freshFor] is celebrated; otherwise Talia
/// points at the closest one still ahead.
KidsProgressTaliaCue kidsProgressTaliaCue(
  List<KidsAchievement> achievements, {
  required DateTime now,
  Duration freshFor = const Duration(hours: 24),
}) {
  final unlocked = achievements.where((a) => a.isUnlocked).toList();
  if (unlocked.isEmpty) {
    return const KidsProgressTaliaCue(
      KidsProgressCueKind.start,
      KidsTaliaPose.encourage,
    );
  }
  // Newest first; among milestones reached together, the one with the
  // largest goal is the one worth naming.
  unlocked.sort((a, b) {
    final byDate = b.unlockedAt!.compareTo(a.unlockedAt!);
    return byDate != 0 ? byDate : b.target.compareTo(a.target);
  });
  final newest = unlocked.first;
  if (now.difference(newest.unlockedAt!) <= freshFor) {
    return KidsProgressTaliaCue(
      KidsProgressCueKind.newAchievement,
      KidsTaliaPose.celebrate,
      newest,
    );
  }
  final ahead = achievements.where((a) => !a.isUnlocked).toList();
  if (ahead.isEmpty) {
    return const KidsProgressTaliaCue(
      KidsProgressCueKind.allDone,
      KidsTaliaPose.celebrate,
    );
  }
  // Closest by share done; ties keep catalog order (smaller goals first).
  var closest = ahead.first;
  for (final achievement in ahead.skip(1)) {
    if (achievement.progress > closest.progress) closest = achievement;
  }
  return KidsProgressTaliaCue(
    KidsProgressCueKind.next,
    KidsTaliaPose.pointRight,
    closest,
  );
}
