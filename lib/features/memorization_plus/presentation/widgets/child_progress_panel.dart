import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../../home/domain/entities/activity_event.dart';
import '../../../home/presentation/widgets/home_activity_feed.dart'
    show activityTimeLabel;
import '../../domain/services/kids_achievements.dart';
import '../../domain/services/kids_progress_snapshot.dart';
import 'kids_achievement_labels.dart';

/// The guardian's view of one child's kids progress: the same numbers,
/// milestones and certificates the child sees on «تقدّمي». Each certificate
/// opens the certificate page in the child's name, to print or share.
class ChildProgressPanel extends StatelessWidget {
  const ChildProgressPanel({
    super.key,
    required this.snapshot,
    required this.childName,
  });

  final KidsProgressSnapshot snapshot;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.tokens.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _Stat(
              icon: TaliaIcons.medal,
              value: snapshot.level,
              label: l10n.kidsProgressLevelLabel,
            ),
            _Stat(
              icon: TaliaIcons.starFilled,
              value: snapshot.stars,
              label: l10n.kidsProgressStars,
            ),
            _Stat(
              icon: TaliaIcons.flame,
              value: snapshot.currentStreak,
              label: l10n.kidsProgressStreak,
            ),
            _Stat(
              icon: TaliaIcons.hifz,
              value: snapshot.memorizedAyahs,
              label: l10n.kidsProgressAyahs,
            ),
            _Stat(
              icon: TaliaIcons.mushaf,
              value: snapshot.weekPages,
              label: l10n.kidsProgressWeekPages,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.kidsAchievementsTitle,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              l10n.kidsAchievementsCount(
                context.numText(snapshot.unlockedCount),
                context.numText(snapshot.achievements.length),
              ),
              style: AppTypography.labelMedium.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final achievement in snapshot.achievements)
              _AchievementChip(achievement: achievement),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.myCertificates,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (snapshot.certificates.isEmpty)
          Text(
            l10n.childDetailCertificatesEmpty,
            style: AppTypography.bodySmall.copyWith(color: muted),
          )
        else ...[
          Text(
            l10n.childDetailCertificateOpenHint,
            style: AppTypography.bodySmall.copyWith(color: muted),
          ),
          for (final award in snapshot.certificates)
            _CertificateTile(award: award, childName: childName),
        ],
        if (snapshot.recentActivity.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.kidsProgressRecentTitle,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final event in snapshot.recentActivity) _ActivityLine(event),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});

  final IconData icon;

  /// Null when the child device has not published it yet.
  final int? value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: context.tokens.accent),
          const SizedBox(height: 2),
          Text(
            value == null ? '—' : context.numText(value!),
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.labelSmall.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({required this.achievement});

  final KidsAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.isUnlocked;
    final title = kidsAchievementTitle(context.l10n, achievement.id);
    final label = unlocked
        ? title
        : '$title — ${context.l10n.kidsAchievementProgress(context.numText(achievement.current), context.numText(achievement.target))}';
    final color = unlocked ? AppColors.gold : context.tokens.textSecondary;
    return Container(
      key: ValueKey('child-achievement-${achievement.id.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.gold.withValues(alpha: 0.14) : null,
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked
                ? kidsAchievementIcon(achievement.metric, kids: false)
                : TaliaIcons.lock,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: unlocked ? null : context.tokens.textSecondary,
              fontWeight: unlocked ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateTile extends StatelessWidget {
  const _CertificateTile({required this.award, required this.childName});

  final CertificateAward award;
  final String childName;

  @override
  Widget build(BuildContext context) {
    final title = context.isArabic
        ? award.titleAr
        : (award.titleEn ?? award.titleAr);
    final date = context.digitText(
      MaterialLocalizations.of(
        context,
      ).formatShortDate(award.earnedAt.toLocal()),
    );
    return ListTile(
      key: ValueKey('child-certificate-${award.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(TaliaIcons.certificate, color: AppColors.gold),
      title: Text(title, style: AppTypography.titleSmall),
      subtitle: Text(date, style: AppTypography.bodySmall),
      trailing: Icon(
        context.isArabic ? TaliaIcons.chevronBack : TaliaIcons.chevronForward,
        size: 18,
      ),
      onTap: () => context.push(
        AppRoutes.certificate,
        extra: <String, dynamic>{'award': award, 'userName': childName},
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine(this.event);

  final ActivityEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kind = switch (event.kind) {
      ActivityEventKind.reading => l10n.homeActivityReading,
      ActivityEventKind.memorize => l10n.homeActivityMemorize,
      ActivityEventKind.review => l10n.homeActivityReview,
      ActivityEventKind.khatmah => l10n.homeActivityKhatmah,
    };
    final what = event.surahId != null
        ? (context.isArabic
              ? SurahNames.nameAr(event.surahId)
              : SurahNames.nameEn(event.surahId))
        : event.pageNumber != null
        ? l10n.homeDailyWirdPage(context.numText(event.pageNumber!))
        : kind;
    final range = event.startAyah != null && event.endAyah != null
        ? '${context.listSeparator}${l10n.homeAyahRange(context.numText(event.startAyah!), context.numText(event.endAyah!))}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        '$kind: $what$range${context.listSeparator}'
        '${activityTimeLabel(l10n, event.occurredAt)}',
        style: AppTypography.bodySmall,
      ),
    );
  }
}
