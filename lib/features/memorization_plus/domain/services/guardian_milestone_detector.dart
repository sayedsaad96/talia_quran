import 'package:equatable/equatable.dart';

import '../../../certificate/domain/entities/certificate_award.dart';
import '../entities/kids_session_log.dart';
import 'kids_adventure_regions.dart';

/// Something worth telling the guardian about a child. [id] is stable across
/// refreshes, so "already seen" can be remembered by id.
sealed class GuardianMilestone extends Equatable {
  const GuardianMilestone();

  String get id;
}

/// Every ayah of [surahId] is covered by the child's canonical reward logs.
final class SurahCompletedMilestone extends GuardianMilestone {
  const SurahCompletedMilestone(this.surahId);

  final int surahId;

  @override
  String get id => 'surah:$surahId';

  @override
  List<Object?> get props => [surahId];
}

/// The child earned a certificate. The title is the certificate's own title.
final class CertificateEarnedMilestone extends GuardianMilestone {
  const CertificateEarnedMilestone({
    required this.certificateId,
    required this.titleAr,
    this.titleEn,
  });

  final String certificateId;
  final String titleAr;
  final String? titleEn;

  @override
  String get id => 'cert:$certificateId';

  @override
  List<Object?> get props => [certificateId, titleAr, titleEn];
}

/// The child met the weekly goal in the last full week (Monday to Sunday,
/// UTC, the same week the dashboard counts). [weekStart] is that Monday.
final class WeekCompletedMilestone extends GuardianMilestone {
  const WeekCompletedMilestone(this.weekStart);

  final DateTime weekStart;

  @override
  String get id =>
      'week:${weekStart.year.toString().padLeft(4, '0')}-'
      '${weekStart.month.toString().padLeft(2, '0')}-'
      '${weekStart.day.toString().padLeft(2, '0')}';

  @override
  List<Object?> get props => [weekStart];
}

/// Pure: everything the guardian could be told about a child right now.
/// The caller subtracts what was already seen. Surahs ascending, then
/// certificates newest first, then the week.
List<GuardianMilestone> detectGuardianMilestones({
  required List<KidsSessionLog> logs,
  required Map<int, int> ayahCountBySurah,
  required List<CertificateAward> certificates,
  required int weeklyGoalSessions,
  required DateTime now,
}) {
  final result = <GuardianMilestone>[];

  final surahs = kidsMemorizedSurahIds(logs, ayahCountBySurah).toList()..sort();
  for (final surahId in surahs) {
    result.add(SurahCompletedMilestone(surahId));
  }

  final newestFirst = [...certificates]
    ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  final seenCertificates = <String>{};
  for (final certificate in newestFirst) {
    if (!seenCertificates.add(certificate.id)) continue;
    result.add(
      CertificateEarnedMilestone(
        certificateId: certificate.id,
        titleAr: certificate.titleAr,
        titleEn: certificate.titleEn,
      ),
    );
  }

  if (weeklyGoalSessions > 0) {
    final utc = now.toUtc();
    final thisWeek = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).subtract(Duration(days: utc.weekday - 1));
    final lastWeek = DateTime.utc(
      thisWeek.year,
      thisWeek.month,
      thisWeek.day - 7,
    );
    final sessions = logs.where((log) {
      final at = log.completedAt.toUtc();
      return !at.isBefore(lastWeek) && at.isBefore(thisWeek);
    }).length;
    if (sessions >= weeklyGoalSessions) {
      result.add(WeekCompletedMilestone(lastWeek));
    }
  }
  return result;
}
