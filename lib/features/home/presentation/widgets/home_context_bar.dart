import 'home_achievement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/achievement_service.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../progress/domain/entities/progress_entities.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../domain/services/home_occasion_service.dart';
import '../cubits/home_cubit.dart';

class HomeContextBar extends StatelessWidget {
  const HomeContextBar({super.key, required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  Color _overlay() {
    return switch (state.greeting) {
      'morning' => const Color(0xFF1A3D32),
      'afternoon' => const Color(0xFF0D3F34),
      'evening' => const Color(0xFF0A2A24),
      _ => const Color(0xFF071614),
    };
  }

  IconData _greetingIcon() => switch (state.greeting) {
    'morning' => Icons.wb_sunny_rounded,
    'afternoon' => Icons.wb_cloudy_rounded,
    'evening' => Icons.wb_twilight_rounded,
    _ => Icons.nightlight_round,
  };

  String _greetingText(BuildContext context) => switch (state.greeting) {
    'morning' => context.l10n.greetingMorning,
    'afternoon' => context.l10n.greetingAfternoon,
    'evening' => context.l10n.greetingEvening,
    _ => context.l10n.greetingNight,
  };

  @override
  Widget build(BuildContext context) {
    final overlay = _overlay();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppSpacing.radiusHero),
      ),
      child: ColoredBox(
        color: overlay,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _greetingIcon(),
                      color: Colors.white.withValues(alpha: 0.82),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: BlocBuilder<ProfileCubit, ProfileState>(
                        builder: (context, profileState) {
                          final hasName =
                              profileState is ProfileLoaded &&
                              profileState.profile.hasName;
                          final name = hasName
                              ? ', ${profileState.profile.displayName}'
                              : '';
                          return Text(
                            '${context.l10n.brandName} · ${_greetingText(context)}$name',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.searchSurah,
                      onPressed: () => context.push(AppRoutes.quranSearch),
                      icon: const Icon(Icons.search_rounded),
                      color: Colors.white.withValues(alpha: 0.82),
                      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                    ),
                    IconButton(
                      tooltip: context.l10n.settings,
                      onPressed: () => context.push(AppRoutes.settings),
                      icon: const Icon(Icons.settings_suggest_rounded),
                      color: Colors.white.withValues(alpha: 0.82),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (state.hijriLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${state.hijriLabel}  ·  ${state.gregorianLabel}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
                if (state.occasion != HomeOccasion.none) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _OccasionChip(occasion: state.occasion),
                ],
                if (state.prayerSnapshot != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _PrayerCapsule(
                    snapshot: state.prayerSnapshot!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.occasion});
  final HomeOccasion occasion;

  @override
  Widget build(BuildContext context) {
    final label = switch (occasion) {
      HomeOccasion.friday => context.l10n.homeOccasionFriday,
      HomeOccasion.ramadan => context.l10n.homeOccasionRamadan,
      HomeOccasion.lastTenNights => context.l10n.homeOccasionLastTenNights,
      HomeOccasion.none => '',
    };
    return Semantics(
      button: true,
      label: label,
      child: ActionChip(
        onPressed: occasion == HomeOccasion.friday
            ? () => context.push('/quran/surah/18')
            : null,
        label: Text(label),
        avatar: Icon(
          occasion == HomeOccasion.friday
              ? Icons.menu_book_rounded
              : Icons.nights_stay_rounded,
          size: 18,
        ),
      ),
    );
  }
}

class HomeAchievementChip extends StatelessWidget {
  const HomeAchievementChip({
    super.key,
    required this.progress,
    required this.isKids,
    this.totalXp = 0,
    this.foreground = Colors.white,
    this.background,
    this.border,
  });

  final OverallProgress progress;
  final bool isKids;
  final int totalXp;
  final Color foreground;
  final Color? background;
  final Color? border;

  Achievement? _highest(Iterable<Achievement> items) {
    Achievement? best;
    for (final item in items) {
      if (best == null || item.targetValue > best.targetValue) {
        best = item;
      } else if (item.targetValue == best.targetValue &&
          item.currentValue > best.currentValue) {
        best = item;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final reading = _highest(
      progress.achievements.where(
        (a) => a.isUnlocked && a.category == AchievementCategory.reading,
      ),
    );
    final mem = _highest(
      progress.achievements.where(
        (a) => a.isUnlocked && a.category == AchievementCategory.memorization,
      ),
    );
    final shown = mem ?? reading;
    final title = shown == null
        ? context.l10n.levelBeginner
        : context.localizedAchievementTitle(shown);
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        onTap: () {
          final certs = getIt<AchievementService>().getEarnedCertificates(
            isKids: isKids,
          );
          CertificateAward? award;
          if (shown?.category == AchievementCategory.memorization) {
            for (final cert in certs) {
              if (cert.type != CertificateType.khatmahReading) {
                award = cert;
                break;
              }
            }
          } else if (shown?.category == AchievementCategory.reading) {
            for (final cert in certs) {
              if (cert.type == CertificateType.khatmahReading) {
                award = cert;
                break;
              }
            }
          }
          if (award == null) {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) => HomeAchievementSheet(
                progress: progress,
                totalXp: totalXp,
                isKids: isKids,
              ),
            );
            return;
          }
          context.push(
            AppRoutes.certificate,
            extra: {
              'award': award,
              'userName': context.read<ProfileCubit>().state is ProfileLoaded
                  ? (context.read<ProfileCubit>().state as ProfileLoaded)
                        .profile
                        .displayName
                  : context.l10n.taliaUser,
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: background ?? foreground.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 15,
                color: foreground,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerCapsule extends StatelessWidget {
  const _PrayerCapsule({required this.snapshot});
  final PrayerTimesSnapshot snapshot;

  String _localizedName(BuildContext context) => switch (snapshot.nextName) {
        'fajr' => context.l10n.prayerFajr,
        'sunrise' => context.l10n.prayerSunrise,
        'dhuhr' => context.l10n.prayerDhuhr,
        'asr' => context.l10n.prayerAsr,
        'maghrib' => context.l10n.prayerMaghrib,
        'isha' => context.l10n.prayerIsha,
        _ => snapshot.nextName,
      };

  String _formattedTime() {
    final t = snapshot.nextTime;
    final h = t.hour > 12 ? t.hour - 12 : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'م' : 'ص';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final name = _localizedName(context);
    final remaining = context.l10n.homePrayerChip(name, snapshot.minutesUntil);

    return Semantics(
      label: remaining,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mosque_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              '$name  ${_formattedTime()}',
              style: AppTypography.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${snapshot.minutesUntil} د',
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
