import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../domain/entities/kids_home_mission.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/services/kids_adventure_regions.dart';
import '../cubits/kids_treasures_cubit.dart';
import '../widgets/kids_gift_card.dart';
import '../widgets/kids_home_mission_card.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_region_name.dart';
import '../widgets/kids_section_heading.dart';
import '../widgets/kids_talia_companion.dart';
import '../widgets/kids_ui.dart';
import '../world/kids_world_palette.dart';

/// «كنوزي» — region progress and the child's kids certificates.
class KidsTreasuresPage extends StatelessWidget {
  const KidsTreasuresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsTreasuresCubit>()..load(),
      child: const _KidsTreasuresView(),
    );
  }
}

class _KidsTreasuresView extends StatelessWidget {
  const _KidsTreasuresView();

  void _back(BuildContext context) => context.canPop()
      ? context.pop()
      : context.go(AppRoutes.memorizationPlusKidsHome);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocConsumer<KidsTreasuresCubit, KidsTreasuresState>(
        listenWhen: (previous, current) =>
            current is KidsTreasuresLoaded &&
            current.rewardMessage != null &&
            (previous is! KidsTreasuresLoaded ||
                previous.rewardMessageId != current.rewardMessageId),
        listener: (context, state) {
          final message = (state as KidsTreasuresLoaded).rewardMessage!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.localizedCubitMessage(message))),
          );
        },
        builder: (context, state) => switch (state) {
          KidsTreasuresLoading() => const Center(child: KidsLoadingWidget()),
          KidsTreasuresError(:final message) => KidsBackground(
            child: SafeArea(
              child: KidsErrorWidget(
                message: context.localizedCubitMessage(message),
                onRetry: () => context.read<KidsTreasuresCubit>().load(),
              ),
            ),
          ),
          KidsTreasuresLoaded(
            :final regions,
            :final certificates,
            :final rewards,
            :final homeMissions,
            :final homeMissionsPaused,
            :final guardianLinked,
          ) =>
            KidsTreasuresContent(
              regions: regions,
              certificates: certificates,
              rewards: rewards,
              homeMissions: homeMissions,
              homeMissionsPaused: homeMissionsPaused,
              guardianLinked: guardianLinked,
              onRequestReward: context.read<KidsTreasuresCubit>().requestReward,
              onReportHomeMission: context
                  .read<KidsTreasuresCubit>()
                  .reportHomeMission,
              onBack: () => _back(context),
            ),
        },
      ),
    );
  }
}

/// Tells a linked child that their guardian follows the journey, so the
/// gifts and missions below have a clear source.
class _GuardianLinkedBadge extends StatelessWidget {
  const _GuardianLinkedBadge();

  @override
  Widget build(BuildContext context) {
    final palette = KidsWorldPalette.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        key: const ValueKey('kids-guardian-linked-badge'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: palette.onScene.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TaliaIcon(TaliaKidsIcons.family, size: 18, color: palette.onScene),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                context.l10n.kidsGuardianLinkedBadge,
                style: AppTypography.bodyMedium.copyWith(
                  color: palette.onScene,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class KidsTreasuresContent extends StatelessWidget {
  const KidsTreasuresContent({
    super.key,
    required this.regions,
    required this.certificates,
    required this.onBack,
    this.rewards = const [],
    this.homeMissions = const [],
    this.homeMissionsPaused = false,
    this.guardianLinked = false,
    this.onRequestReward,
    this.onReportHomeMission,
  });

  final List<KidsRegionProgress> regions;
  final List<CertificateAward> certificates;
  final VoidCallback onBack;
  final List<ParentReward> rewards;
  final List<KidsHomeMission> homeMissions;
  final bool homeMissionsPaused;
  final bool guardianLinked;
  final void Function(String rewardId)? onRequestReward;
  final void Function(String missionId)? onReportHomeMission;

  bool get _isEmpty =>
      certificates.isEmpty &&
      rewards.isEmpty &&
      homeMissions.isEmpty &&
      !homeMissionsPaused &&
      regions.every((r) => r.memorized == 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KidsBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              KidsTopBar(title: l10n.kidsTreasuresTitle, onBack: onBack),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    if (guardianLinked) ...[
                      const _GuardianLinkedBadge(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_isEmpty) ...[
                      KidsTaliaCompanion(
                        pose: KidsTaliaPose.encourage,
                        message: l10n.kidsTreasuresEmpty,
                        animate: false,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (homeMissions.isNotEmpty || homeMissionsPaused) ...[
                      KidsSectionHeading(
                        text: l10n.kidsHomeMissionsTitle,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (homeMissionsPaused)
                        Text(
                          l10n.kidsHomeMissionsPaused,
                          key: const ValueKey('kids-home-missions-paused'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: KidsWorldPalette.of(context).onScene,
                            letterSpacing: 0,
                          ),
                        ),
                      for (final mission in homeMissions) ...[
                        KidsHomeMissionCard(
                          mission: mission,
                          onReport: onReportHomeMission == null
                              ? null
                              : () => onReportHomeMission!(mission.id),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (rewards.isNotEmpty) ...[
                      KidsSectionHeading(
                        text: l10n.kidsGiftsTitle,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final reward in rewards) ...[
                        KidsGiftCard(
                          reward: reward,
                          onRequest: onRequestReward == null
                              ? null
                              : () => onRequestReward!(reward.id),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    for (final region in regions) ...[
                      _RegionCard(progress: region),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (certificates.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      KidsSectionHeading(
                        text: l10n.myCertificates,
                        fontWeight: FontWeight.bold,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final cert in certificates) ...[
                        _CertificateCard(award: cert),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _regionIcon(KidsRegionId id) => switch (id) {
  KidsRegionId.beginning => TaliaKidsIcons.flag,
  KidsRegionId.palmOasis => TaliaKidsIcons.tree,
  KidsRegionId.flowerValley => TaliaKidsIcons.flower,
  KidsRegionId.starMountain => TaliaKidsIcons.mountain,
  KidsRegionId.pearlSea => TaliaKidsIcons.water,
};

Color _regionDoorColor(KidsRegionId id) => switch (id) {
  KidsRegionId.beginning => AppColors.kidsDoorCoral,
  KidsRegionId.palmOasis => AppColors.kidsDoorLeaf,
  KidsRegionId.flowerValley => AppColors.kidsDoorViolet,
  KidsRegionId.starMountain => AppColors.kidsDoorSun,
  KidsRegionId.pearlSea => AppColors.kidsDoorSky,
};

BoxDecoration _creamCard() => BoxDecoration(
  gradient: KidsTheme.parchmentGradient,
  borderRadius: KidsTheme.cardRadius,
  border: Border.all(color: KidsTheme.parchmentEdge, width: 1.5),
  boxShadow: KidsTheme.card25DShadow,
);

class _RegionCard extends StatelessWidget {
  const _RegionCard({required this.progress});

  final KidsRegionProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = progress.region.id;
    final fraction = progress.total == 0
        ? 0.0
        : (progress.memorized / progress.total).clamp(0.0, 1.0);
    return Container(
      key: ValueKey('kids-region-${id.name}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _creamCard(),
      child: Row(
        children: [
          TaliaFeatureDoor(
            icon: _regionIcon(id),
            color: _regionDoorColor(id),
            size: 40,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kidsRegionName(l10n, id),
                  style: AppTypography.titleMedium.copyWith(
                    color: KidsTheme.inkOnParchment,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.kidsRegionProgress(
                    progress.memorized,
                    progress.total,
                    context.numText(progress.memorized),
                    context.numText(progress.total),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: KidsTheme.inkOnParchment,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: fraction,
                    backgroundColor: KidsTheme.parchmentEdge,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      KidsTheme.goldStar,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (progress.isComplete) ...[
            const SizedBox(width: AppSpacing.sm),
            const TaliaIcon(
              TaliaKidsIcons.certificate,
              color: KidsTheme.goldStar,
              size: 36,
            ),
          ],
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.award});

  final CertificateAward award;

  @override
  Widget build(BuildContext context) {
    final title = context.isArabic
        ? award.titleAr
        : (award.titleEn ?? award.titleAr);
    return Container(
      key: ValueKey('kids-certificate-${award.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _creamCard(),
      child: Row(
        children: [
          const TaliaIcon(
            TaliaKidsIcons.certificate,
            color: KidsTheme.goldStar,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleSmall.copyWith(
                color: KidsTheme.inkOnParchment,
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
