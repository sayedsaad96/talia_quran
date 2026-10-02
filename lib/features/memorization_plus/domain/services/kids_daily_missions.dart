import 'package:equatable/equatable.dart';

import '../entities/kids_session_log.dart';
import '../navigation/kids_next_mission_resolver.dart';

enum KidsDailyMissionKind { learning, reading, home }

enum KidsDailyMissionStatus { available, completed }

const int kKidsMaxDailyMissions = 3;

/// One card of «مهماتي اليوم» on the kids home screen.
final class KidsDailyMission extends Equatable {
  const KidsDailyMission({
    required this.id,
    required this.kind,
    required this.status,
    this.learning,
    this.homeMissionId,
  });

  /// `'$dayKey:${kind.name}'` (home: `'$dayKey:home:$homeMissionId'`).
  final String id;
  final KidsDailyMissionKind kind;
  final KidsDailyMissionStatus status;
  final KidsNextMission? learning;
  final String? homeMissionId;

  @override
  List<Object?> get props => [id, kind, status, learning, homeMissionId];
}

/// Local calendar day key, `yyyy-MM-dd`.
String kidsDayKey(DateTime localNow) {
  final y = localNow.year.toString().padLeft(4, '0');
  final m = localNow.month.toString().padLeft(2, '0');
  final d = localNow.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Resolves today's mission cards: learning, then reading, capped at
/// [maxMissions]. Completion needs an explicit outcome (a positive session
/// log / a confirmed page); opening or listening never completes a mission.
List<KidsDailyMission> resolveKidsDailyMissions({
  required DateTime now,
  required KidsNextMission? learning,
  required bool dayGoalReached,
  required List<KidsSessionLog> logs,
  required Set<int> pagesReadToday,
  int maxMissions = kKidsMaxDailyMissions,
}) {
  if (maxMissions <= 0) return const [];
  final dayKey = kidsDayKey(now);
  final learnedToday = logs.any(
    (log) =>
        log.pointsEarned > 0 && kidsDayKey(log.completedAt.toLocal()) == dayKey,
  );

  final cards = <KidsDailyMission>[
    if (learning != null || learnedToday)
      KidsDailyMission(
        id: '$dayKey:${KidsDailyMissionKind.learning.name}',
        kind: KidsDailyMissionKind.learning,
        status: learnedToday
            ? KidsDailyMissionStatus.completed
            : KidsDailyMissionStatus.available,
        learning: learning,
      ),
    KidsDailyMission(
      id: '$dayKey:${KidsDailyMissionKind.reading.name}',
      kind: KidsDailyMissionKind.reading,
      status: pagesReadToday.isNotEmpty
          ? KidsDailyMissionStatus.completed
          : KidsDailyMissionStatus.available,
    ),
  ];
  return cards.take(maxMissions).toList(growable: false);
}
