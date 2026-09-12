import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/prayer_times_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../settings/data/user_profile.dart';
import '../../../settings/presentation/cubits/profile_cubit.dart';
import '../../domain/services/home_occasion_service.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import 'home_background.dart';
import 'home_context_bar.dart';

class HomeNightHeader extends StatelessWidget {
  const HomeNightHeader({super.key, required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (state.occasion != HomeOccasion.none)
        _OccasionChip(occasion: state.occasion, skin: skin),
      if (state.prayerSnapshot != null)
        HomePrayerChip(snapshot: state.prayerSnapshot!, skin: skin),
      HomeAchievementChip(
        progress: state.progress,
        isKids: state.isKids,
        totalXp: state.totalXp,
        foreground: skin.textOnHero,
        background: skin.onHeroFill,
        border: skin.onHeroBorder,
      ),
    ];

    return HomeHeroBanner(
      skin: skin,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.4,
                child: _TopRow(state: state, skin: skin),
              ),
              const SizedBox(height: AppSpacing.sm),
              _BrandLockup(skin: skin),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: chips,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            final profile = profileState is ProfileLoaded
                ? profileState.profile
                : const UserProfile();
            final name = profile.displayName;
            final initial = name.trim().isEmpty
                ? '?'
                : String.fromCharCodes(name.trim().runes.take(1));
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skin.onHeroFill,
                      border: Border.all(color: skin.onHeroBorder),
                    ),
                    child: FittedBox(
                      child: Text(
                        initial,
                        style: AppTypography.titleMedium.copyWith(
                          color: skin.textOnHero,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.homeWelcomeUser(name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: skin.textOnHero,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (state.hijriLabel.isNotEmpty)
                          Text(
                            state.hijriLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: skin.textOnHeroMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        _HeaderIcon(
          skin: skin,
          tooltip: context.l10n.searchSurah,
          icon: Icons.search_rounded,
          onTap: () => context.push(AppRoutes.quranSearch),
        ),
        const SizedBox(width: AppSpacing.xs),
        _HeaderIcon(
          skin: skin,
          tooltip: context.l10n.settings,
          icon: Icons.settings_suggest_rounded,
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.skin,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final HomeSkin skin;
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skin.onHeroFill,
              border: Border.all(color: skin.onHeroBorder),
            ),
            child: Icon(icon, size: 20, color: skin.textOnHero),
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.skin});

  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          HomeSkin.logoAsset,
          width: 96,
          height: 96,
          cacheWidth: 200,
          cacheHeight: 200,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          errorBuilder: (_, _, _) =>
              Icon(Icons.menu_book_rounded, color: skin.gold, size: 48),
        ),
        // The emblem already contains the calligraphic wordmark, so the text
        // below it stays a quiet letter-spaced caption instead of a second
        // display-sized title.
        Text(
          context.l10n.homeBrandSubtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: skin.textOnHeroMuted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _OccasionChip extends StatelessWidget {
  const _OccasionChip({required this.occasion, required this.skin});

  final HomeOccasion occasion;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final label = switch (occasion) {
      HomeOccasion.friday => context.l10n.homeOccasionFriday,
      HomeOccasion.ramadan => context.l10n.homeOccasionRamadan,
      HomeOccasion.lastTenNights => context.l10n.homeOccasionLastTenNights,
      HomeOccasion.none => '',
    };
    return _HeroChip(
      skin: skin,
      icon: occasion == HomeOccasion.friday
          ? Icons.menu_book_rounded
          : Icons.nights_stay_rounded,
      label: label,
      onTap: occasion == HomeOccasion.friday
          ? () => context.push('/quran/surah/18')
          : null,
    );
  }
}

class HomePrayerChip extends StatelessWidget {
  const HomePrayerChip({super.key, required this.snapshot, required this.skin});

  final PrayerTimesSnapshot snapshot;
  final HomeSkin skin;

  String _localizedName(BuildContext context) => switch (snapshot.nextName) {
    'fajr' => context.l10n.prayerFajr,
    'sunrise' => context.l10n.prayerSunrise,
    'dhuhr' => context.l10n.prayerDhuhr,
    'asr' => context.l10n.prayerAsr,
    'maghrib' => context.l10n.prayerMaghrib,
    'isha' => context.l10n.prayerIsha,
    _ => snapshot.nextName,
  };

  String _formattedTime(BuildContext context) {
    final t = snapshot.nextTime;
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = context.isArabic
        ? (t.hour >= 12 ? 'م' : 'ص')
        : (t.hour >= 12 ? 'PM' : 'AM');
    return '$hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final name = _localizedName(context);
    return Semantics(
      label: context.l10n.homePrayerChip(name, snapshot.minutesUntil),
      child: _HeroChip(
        skin: skin,
        icon: Icons.mosque_rounded,
        label: '$name  ${_formattedTime(context)}',
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.skin,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final HomeSkin skin;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: skin.onHeroFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: skin.onHeroBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: skin.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(
                color: skin.textOnHero,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: chip,
      ),
    );
  }
}
