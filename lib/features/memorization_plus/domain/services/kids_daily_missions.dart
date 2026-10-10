import 'package:equatable/equatable.dart';

import '../entities/kids_home_mission.dart';
import '../entities/kids_session_log.dart';
import '../entities/kids_session_policy.dart';
import '../navigation/kids_next_mission_resolver.dart';

enum KidsDailyMissionKind { learning, reading, home, practice }

enum KidsDailySuggestion {
  readPage,
  readTwoPages,
  reciteAyah,
  listenAndRecite,
  reviewAyah,
}

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
    this.homeMissionTitle,
    this.suggestion,
    this.targetCount = 1,
  });

  /// Calendar-scoped assignment or suggestion identity.
  final String id;
  final KidsDailyMissionKind kind;
  final KidsDailyMissionStatus status;
  final KidsNextMission? learning;
  final String? homeMissionId;

  /// The guardian's text for a `home` card.
  final String? homeMissionTitle;
  final KidsDailySuggestion? suggestion;
  final int targetCount;

  @override
  List<Object?> get props => [
    id,
    kind,
    status,
    learning,
    homeMissionId,
    homeMissionTitle,
    suggestion,
    targetCount,
  ];
}

/// Local calendar day key, `yyyy-MM-dd`.
String kidsDayKey(DateTime localNow) {
  final y = localNow.year.toString().padLeft(4, '0');
  final m = localNow.month.toString().padLeft(2, '0');
  final d = localNow.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Guardian assignments take priority over generated suggestions, including
/// their reported-today state. Only suggestions use [maxMissions]. Daily
/// variety uses a local calendar seed, with prior activity setting the pace.
List<KidsDailyMission> resolveKidsDailyMissions({
  required DateTime now,
  required KidsNextMission? learning,
  required bool dayGoalReached,
  required List<KidsSessionLog> logs,
  required Set<int> pagesReadToday,
  KidsHomeMission? homeMission,
  List<KidsHomeMission> homeMissions = const [],
  int recentReadingDays = 0,
  bool readingAvailable = true,
  int maxMissions = kKidsMaxDailyMissions,
}) {
  final local = now.toLocal();
  final dayKey = kidsDayKey(local);
  final assigned = _guardianCards(dayKey, [...homeMissions, ?homeMission]);
  if (assigned.isNotEmpty) return assigned;
  if (maxMissions <= 0) return const [];
  final rotation =
      DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
  final today = logs
      .where(
        (log) =>
            log.pointsEarned > 0 &&
            kidsDayKey(log.completedAt.toLocal()) == dayKey,
      )
      .toList();
  final practice = _practiceCard(
    dayKey,
    rotation,
    learning,
    logs,
    today,
    local,
  );
  final reading = readingAvailable
      ? _readingCard(dayKey, rotation, recentReadingDays, pagesReadToday)
      : null;
  final cards = <KidsDailyMission>[
    if (rotation.isEven && reading != null) reading,
    ?practice,
    if (rotation.isOdd && reading != null) reading,
  ];
  return cards
      .take(maxMissions.clamp(0, kKidsMaxDailyMissions))
      .toList(growable: false);
}

List<KidsDailyMission> _guardianCards(
  String day,
  List<KidsHomeMission> missions,
) {
  final unique = <String, KidsHomeMission>{};
  for (final mission in missions) {
    if (mission.status == KidsHomeMissionStatus.assigned ||
        (mission.reportedAt != null &&
            kidsDayKey(mission.reportedAt!.toLocal()) == day)) {
      unique.putIfAbsent(mission.id, () => mission);
    }
  }
  final eligible = unique.values.toList()
    ..sort((a, b) {
      final aAssigned = a.status == KidsHomeMissionStatus.assigned;
      final bAssigned = b.status == KidsHomeMissionStatus.assigned;
      if (aAssigned != bAssigned) return aAssigned ? -1 : 1;
      final order = aAssigned
          ? a.createdAt.compareTo(b.createdAt)
          : b.reportedAt!.compareTo(a.reportedAt!);
      return order != 0 ? order : a.id.compareTo(b.id);
    });
  return eligible
      .map(
        (mission) => KidsDailyMission(
          id: '$day:home:${mission.id}',
          kind: KidsDailyMissionKind.home,
          status: mission.status == KidsHomeMissionStatus.assigned
              ? KidsDailyMissionStatus.available
              : KidsDailyMissionStatus.completed,
          homeMissionId: mission.id,
          homeMissionTitle: mission.title,
        ),
      )
      .toList(growable: false);
}

KidsDailyMission _readingCard(
  String day,
  int rotation,
  int history,
  Set<int> pages,
) {
  final target = history >= 2 && rotation.isEven ? 2 : 1;
  final suggestion = target == 2
      ? KidsDailySuggestion.readTwoPages
      : KidsDailySuggestion.readPage;
  return KidsDailyMission(
    id: '$day:suggestion:${suggestion.name}',
    kind: KidsDailyMissionKind.reading,
    suggestion: suggestion,
    targetCount: target,
    status: pages.where((page) => page >= 1 && page <= 604).length >= target
        ? KidsDailyMissionStatus.completed
        : KidsDailyMissionStatus.available,
  );
}

KidsDailyMission? _practiceCard(
  String day,
  int rotation,
  KidsNextMission? learning,
  List<KidsSessionLog> logs,
  List<KidsSessionLog> today,
  DateTime now,
) {
  if (learning == null && today.isEmpty) return null;
  bool isReview(KidsSessionLog log) =>
      log.missionType == KidsMissionType.dueReview ||
      log.missionType == KidsMissionType.linkedReview;
  final newToday = today.any(
    (log) => log.missionType == KidsMissionType.newMemorization,
  );
  final review =
      !newToday &&
      (today.any(isReview) ||
          learning?.type == KidsMissionType.dueReview ||
          learning?.type == KidsMissionType.linkedReview);
  final listen =
      !review &&
      (_recentlyNeededSupport(logs, now)
          ? rotation % 3 != 0
          : rotation.isEven) &&
      (learning?.type == KidsMissionType.newMemorization ||
          today.any((log) => log.repeatsCompleted >= 2));
  final suggestion = review
      ? KidsDailySuggestion.reviewAyah
      : listen
      ? KidsDailySuggestion.listenAndRecite
      : KidsDailySuggestion.reciteAyah;
  final completed = review
      ? today.any(isReview)
      : listen
      ? today.any((log) => log.repeatsCompleted >= 2)
      : today.isNotEmpty;
  return KidsDailyMission(
    id: '$day:suggestion:${suggestion.name}',
    kind: KidsDailyMissionKind.practice,
    learning: learning,
    suggestion: suggestion,
    status: completed
        ? KidsDailyMissionStatus.completed
        : KidsDailyMissionStatus.available,
  );
}

bool _recentlyNeededSupport(List<KidsSessionLog> logs, DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  final since = DateTime(now.year, now.month, now.day - 7);
  return logs.any(
    (log) =>
        log.pointsEarned > 0 &&
        log.completedAt.toLocal().isBefore(start) &&
        !log.completedAt.toLocal().isBefore(since) &&
        (log.hintCount > 0 || log.attemptCount > 1),
  );
}
