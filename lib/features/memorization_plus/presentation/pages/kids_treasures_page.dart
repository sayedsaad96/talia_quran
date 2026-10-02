import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../certificate/domain/entities/certificate_award.dart';
import '../../domain/services/kids_adventure_regions.dart';
import '../cubits/kids_treasures_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_region_name.dart';
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
      body: BlocBuilder<KidsTreasuresCubit, KidsTreasuresState>(
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
          KidsTreasuresLoaded(:final regions, :final certificates) =>
            KidsTreasuresContent(
              regions: regions,
              certificates: certificates,
              onBack: () => _back(context),
            ),
        },
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
  });

  final List<KidsRegionProgress> regions;
  final List<CertificateAward> certificates;
  final VoidCallback onBack;

  bool get _isEmpty =>
      certificates.isEmpty && regions.every((r) => r.memorized == 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = KidsWorldPalette.of(context);
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
                    if (_isEmpty) ...[
                      KidsTaliaCompanion(
                        pose: KidsTaliaPose.encourage,
                        message: l10n.kidsTreasuresEmpty,
                        animate: false,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    for (final region in regions) ...[
                      _RegionCard(progress: region),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (certificates.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.myCertificates,
                        style: AppTypography.titleMedium.copyWith(
                          color: palette.onScene,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0,
                        ),
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
  KidsRegionId.beginning => Icons.flag_rounded,
  KidsRegionId.palmOasis => Icons.park_rounded,
  KidsRegionId.flowerValley => Icons.local_florist_rounded,
  KidsRegionId.starMountain => Icons.landscape_rounded,
  KidsRegionId.pearlSea => Icons.water_rounded,
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
          Icon(_regionIcon(id), color: KidsTheme.houseBrown, size: 32),
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
            const Icon(
              Icons.workspace_premium_rounded,
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
          const Icon(
            Icons.workspace_premium_rounded,
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
