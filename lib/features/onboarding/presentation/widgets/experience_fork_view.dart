import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/onboarding_cubit.dart';
import 'onboarding_cta.dart';

/// Step 2 — the fork. The journey splits into two living destinations, each
/// proven by a real window into its world: a parchment mushaf ayah for the
/// adult sanctuary, a starlit night with the Talia mascot for the child
/// journey. Choosing a path lights it and unfolds its details.
class ExperienceForkView extends StatelessWidget {
  const ExperienceForkView({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdult = state.selectedUserType == OnboardingUserType.adult;
    final isChild = state.selectedUserType == OnboardingUserType.child;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.xs,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          JourneyEntrance(
            child: Text(
              l10n.onboardingChooseExpTitle,
              textAlign: TextAlign.center,
              style: AppTypography.headlineMedium.copyWith(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w800,
                fontSize: context.isArabic ? 25 : 23,
                color: AppColors.darkTextPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          JourneyEntrance(
            delayMs: 60,
            child: Text(
              l10n.onboardingChooseExpSubtitle,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.darkTextSecondary,
                height: 1.6,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // The adult sanctuary — a quiet mushaf window on parchment.
          JourneyEntrance(
            delayMs: 120,
            child: _DestinationShrine(
              selected: isAdult,
              accentColor: AppColors.primaryLight,
              textAccentColor: _nightTealText,
              onAccentColor: Colors.white,
              preview: const _MushafWindow(),
              title: l10n.onboardingAdultPathTitle,
              subtitle: l10n.onboardingAdultPathSubtitle,
              detailChips: [
                l10n.onboardingPillarReadTitle,
                l10n.onboardingPillarMemorizeTitle,
                l10n.onboardingPillarHabitTitle,
              ],
              onTap: () => context.read<OnboardingCubit>().selectUserType(
                OnboardingUserType.adult,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // The child journey — a starlit night with Talia herself.
          JourneyEntrance(
            delayMs: 190,
            child: _DestinationShrine(
              selected: isChild,
              accentColor: AppColors.goldLight,
              textAccentColor: AppColors.goldLight,
              onAccentColor: AppColors.darkBackground,
              preview: const _KidsNightWindow(),
              title: l10n.onboardingKidsPathTitle,
              subtitle: l10n.onboardingKidsPathSubtitle,
              detailChips: [
                l10n.onboardingKidsFeatureMissions,
                l10n.onboardingKidsFeatureAudio,
                l10n.onboardingKidsFeatureStars,
              ],
              onTap: () => context.read<OnboardingCubit>().selectUserType(
                OnboardingUserType.child,
              ),
            ),
          ),

          if (state.status == OnboardingStatus.error &&
              state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                l10n.onboardingErrorGeneric,
                style: AppTypography.bodySmall.copyWith(color: _nightErrorText),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),
          JourneyEntrance(
            delayMs: 260,
            child: OnboardingPrimaryCta(
              label: l10n.onboardingEnterAsGuest,
              onTap: state.isLoading
                  ? null
                  : () => context.read<OnboardingCubit>().continueAsGuest(),
              isLoading: state.isLoading,
              trailingArrow: false,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Trust line — offline-first is a promise, not a footnote.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 14,
                color: AppColors.darkTextSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.onboardingOfflineTrustLine,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Secondary: sign in — tonal teal, never competing with the climb.
          JourneyEntrance(
            delayMs: 320,
            child: _TonalSignInButton(
              onTap: state.isLoading
                  ? null
                  : () =>
                        context.read<OnboardingCubit>().signInOrCreateAccount(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Night-ground interactive text accents: #148275 teal and #C0392B error
/// lack 4.5:1 headroom as small-text colors on #021210, so their labels
/// lift to these lighter siblings while borders and tints stay on-token.
const _nightTealText = Color(0xFF3BD6BC);
const _nightErrorText = Color(0xFFE57368);

/// A destination at the fork: a living preview window, its name, and — once
/// chosen — the unfolded details of that path. Radius 24 marks it as a
/// spiritual place, per the system's shape vocabulary.
class _DestinationShrine extends StatelessWidget {
  const _DestinationShrine({
    required this.selected,
    required this.accentColor,
    required this.textAccentColor,
    required this.onAccentColor,
    required this.preview,
    required this.title,
    required this.subtitle,
    required this.detailChips,
    required this.onTap,
  });

  final bool selected;
  final Color accentColor;
  final Color textAccentColor;
  final Color onAccentColor;
  final Widget preview;
  final String title;
  final String subtitle;
  final List<String> detailChips;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: selected ? accentColor : AppColors.darkDivider,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  child: preview,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.darkTextSecondary,
                              height: 1.45,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? accentColor : Colors.transparent,
                        border: Border.all(
                          color: selected ? accentColor : AppColors.darkDivider,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check, size: 15, color: onAccentColor)
                          : null,
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.sm),
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: detailChips
                                .map(
                                  (chip) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull,
                                      ),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      chip,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: textAccentColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The adult window — a real ayah on warm parchment in the Uthmani reading
/// rhythm; the mushaf itself, not a claim about it.
class _MushafWindow extends StatelessWidget {
  const _MushafWindow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.parchmentLight, AppColors.parchmentWarm],
        ),
        border: Border.all(color: AppColors.desertSand.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'وَرَتِّلِ ٱلْقُرْآنَ تَرْتِيلًا',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 21,
              height: 1.9,
              color: AppColors.inkDeep,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 0.8,
                  color: AppColors.desertSand.withValues(alpha: 0.5),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                ),
              ),
              const Icon(
                Icons.auto_awesome_rounded,
                size: 11,
                color: AppColors.desertSand,
              ),
              Expanded(
                child: Container(
                  height: 0.8,
                  color: AppColors.desertSand.withValues(alpha: 0.5),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.onboardingAyahReference,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.inkDeep.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// The child window — Talia beneath a small constellation, the warm gold
/// expression of the same night the adult sanctuary lives in.
class _KidsNightWindow extends StatelessWidget {
  const _KidsNightWindow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkSurfaceVariant, AppColors.darkSurface],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Constellation over the child's sky.
          PositionedDirectional(
            top: 14,
            start: 22,
            child: Icon(
              Icons.star_rounded,
              size: 11,
              color: AppColors.goldLight.withValues(alpha: 0.9),
            ),
          ),
          PositionedDirectional(
            top: 30,
            start: 64,
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: AppColors.darkTextPrimary.withValues(alpha: 0.7),
            ),
          ),
          const PositionedDirectional(
            top: 18,
            start: 104,
            child: Icon(
              Icons.star_rounded,
              size: 13,
              color: AppColors.goldLight,
            ),
          ),
          PositionedDirectional(
            top: 40,
            end: 86,
            child: Icon(
              Icons.star_rounded,
              size: 8,
              color: AppColors.darkTextPrimary.withValues(alpha: 0.55),
            ),
          ),
          // Warm glow where Talia stands.
          Align(
            alignment: const AlignmentDirectional(0.75, 1.1),
            child: Container(
              width: 150,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.20),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const AlignmentDirectional(0.7, 1.05),
            child: Image.asset(
              'assets/images/character/Talia_Master_Character.png',
              height: 112,
              excludeFromSemantics: true,
            ),
          ),
          const Align(
            alignment: AlignmentDirectional(-0.72, 0.15),
            child: Icon(
              Icons.star_rounded,
              size: 15,
              color: AppColors.goldLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _TonalSignInButton extends StatelessWidget {
  const _TonalSignInButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            height: AppSpacing.buttonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.login_rounded,
                  size: 18,
                  color: _nightTealText,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    context.l10n.onboardingSignInAccount,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleSmall.copyWith(
                      color: _nightTealText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
