import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/activity_event.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeActivityFeed extends StatelessWidget {
  const HomeActivityFeed({super.key, required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final events = state.recentActivity.take(5).toList();
    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: skin.gold),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: Text(
                  context.l10n.homeRecentActivity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: skin.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.progress),
                    style: TextButton.styleFrom(
                      foregroundColor: skin.accent,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.homeActivityViewAll,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                context.l10n.homeActivityEmpty,
                style: AppTypography.bodySmall.copyWith(
                  color: skin.textSecondary,
                ),
              ),
            )
          else
            for (var i = 0; i < events.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: skin.glassBorder),
              _ActivityRow(event: events[i], skin: skin),
            ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event, required this.skin});

  final ActivityEvent event;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final (icon, color, kindLabel) = switch (event.kind) {
      ActivityEventKind.reading => (
        Icons.menu_book_rounded,
        AppColors.accentBlue,
        context.l10n.homeActivityReading,
      ),
      ActivityEventKind.memorize => (
        Icons.bookmark_rounded,
        AppColors.primaryLight,
        context.l10n.homeActivityMemorize,
      ),
      ActivityEventKind.review => (
        Icons.replay_rounded,
        AppColors.gold,
        context.l10n.homeActivityReview,
      ),
      ActivityEventKind.khatmah => (
        Icons.auto_stories_rounded,
        AppColors.success,
        context.l10n.homeActivityKhatmah,
      ),
    };
    final title = event.surahId != null
        ? (context.isArabic
              ? SurahNames.nameAr(event.surahId)
              : SurahNames.nameEn(event.surahId))
        : event.pageNumber != null
        ? context.l10n.homeDailyWirdPage(event.pageNumber.toString())
        : kindLabel;
    final detail = event.startAyah != null && event.endAyah != null
        ? context.l10n.homeAyahRange(event.startAyah!, event.endAyah!)
        : kindLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleSmall.copyWith(
                    color: skin.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$detail · ${activityTimeLabel(context.l10n, event.occurredAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: skin.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String activityTimeLabel(AppLocalizations l10n, DateTime at, [DateTime? now]) {
  final moment = now ?? DateTime.now();
  final local = at.toLocal();
  final diff = moment.difference(local);
  if (diff.inMinutes < 1) return l10n.homeActivityJustNow;
  if (diff.inMinutes < 60) return l10n.homeActivityMinutesAgo(diff.inMinutes);
  final startOfToday = DateTime(moment.year, moment.month, moment.day);
  final startOfLocal = DateTime(local.year, local.month, local.day);
  if (startOfLocal == startOfToday) {
    return l10n.homeActivityHoursAgo(diff.inHours.clamp(1, 23));
  }
  if (startOfLocal == startOfToday.subtract(const Duration(days: 1))) {
    return l10n.homeActivityYesterday;
  }
  return l10n.homeActivityDaysAgo(diff.inDays.clamp(1, 9999));
}
