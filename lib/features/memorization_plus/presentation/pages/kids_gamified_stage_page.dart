import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_stage_details.dart';

class KidsGamifiedStagePage extends StatelessWidget {
  const KidsGamifiedStagePage({
    super.key,
    required this.stage,
    this.surahName,
    this.onStartMission,
  });

  final KidsJourneyStage stage;
  final String? surahName;
  final VoidCallback? onStartMission;

  @override
  Widget build(BuildContext context) {
    final resolvedSurahName =
        surahName ?? '${context.l10n.surah} ${stage.surahId}';
    return KidsGamifiedStageContent(
      stage: stage,
      surahName: resolvedSurahName,
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      onStartMission: onStartMission ?? () => _startMission(context, stage),
    );
  }

  void _startMission(BuildContext context, KidsJourneyStage stage) {
    final startAyah = stage.nextAyahToStart;
    context.push(
      '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}&ayahNumber=$startAyah',
    );
  }
}

@visibleForTesting
class KidsGamifiedStageContent extends StatelessWidget {
  const KidsGamifiedStageContent({
    super.key,
    required this.stage,
    required this.surahName,
    required this.onBack,
    required this.onStartMission,
  });

  final KidsJourneyStage stage;
  final String surahName;
  final VoidCallback onBack;
  final VoidCallback onStartMission;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _KidsGamifiedStageAppBar(onBack: onBack),
              Expanded(
                child: CustomScrollView(
                  key: const PageStorageKey<String>('kids-gamified-stage'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      sliver: SliverList.list(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: KidsTheme.creamParchment,
                              borderRadius: KidsTheme.cardRadius,
                              border: Border.all(
                                color: KidsTheme.parchmentEdge,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: KidsStageDetails(
                                stage: stage,
                                surahName: surahName,
                                onStartMission: onStartMission,
                              ),
                            ),
                          ),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
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

class _KidsGamifiedStageAppBar extends StatelessWidget {
  const _KidsGamifiedStageAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.kidsGamifiedMissions,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontFamily: 'Amiri',
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
