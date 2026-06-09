import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/kids_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../navigation/memorization_navigation_resolver.dart';
import '../widgets/kids_journey_map.dart';
import '../widgets/memorization_path_settings_sheet.dart';
import '../widgets/kids_progress_header.dart';

class KidsGamifiedJourneyPage extends StatelessWidget {
  const KidsGamifiedJourneyPage({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsJourneyCubit>()..load(surahId: surahId),
      child: _KidsGamifiedJourneyView(surahId: surahId),
    );
  }
}

class _KidsGamifiedJourneyView extends StatelessWidget {
  const _KidsGamifiedJourneyView({required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocConsumer<KidsJourneyCubit, KidsJourneyState>(
        listener: (context, state) {
          if (state is KidsJourneyLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is KidsJourneyInitial || state is KidsJourneyLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state is KidsJourneyError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<KidsJourneyCubit>().load(surahId: surahId),
            );
          }

          if (state is! KidsJourneyLoaded) return const SizedBox.shrink();

          return KidsGamifiedJourneyContent(
            state: state,
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(
                    MemorizationNavigationResolver.kidsHomeFallbackLocation(
                      surahId,
                    ),
                  ),
            onRefresh: () =>
                context.read<KidsJourneyCubit>().load(surahId: surahId),
            onPathSettingsTap: () =>
                showMemorizationPathSettingsSheet(context, isDark: true),
            onStageSelected: (stage) async {
              await context.push(_stageDetailsLocation(stage), extra: stage);
              if (context.mounted) {
                await context.read<KidsJourneyCubit>().load(
                  surahId: stage.surahId,
                );
              }
            },
          );
        },
      ),
    );
  }
}

@visibleForTesting
class KidsGamifiedJourneyContent extends StatelessWidget {
  const KidsGamifiedJourneyContent({
    super.key,
    required this.state,
    required this.onBack,
    required this.onStageSelected,
    this.onRefresh,
    this.onPathSettingsTap,
  });

  final KidsJourneyLoaded state;
  final VoidCallback onBack;
  final ValueChanged<KidsJourneyStage> onStageSelected;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onPathSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            _KidsGamifiedJourneyAppBar(onBack: onBack),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh ?? () async {},
                child: CustomScrollView(
                  key: const PageStorageKey<String>('kids-gamified-journey'),
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
                          KidsProgressHeader(
                            progress: state.progress,
                            onSettingsTap: onPathSettingsTap,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            context.l10n.kidsJourneyMapTitle,
                            style: AppTypography.headlineSmall.copyWith(
                              color: Colors.white,
                              fontFamily: 'Amiri',
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            context.l10n.kidsJourneySubtitle,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (state.stages.isEmpty)
                            EmptyStateWidget(
                              message: context.l10n.kidsGamifiedJourneyComplete,
                              icon: Icons.emoji_events_rounded,
                            )
                          else
                            KidsJourneyMap(
                              stages: state.stages,
                              surahNameBuilder: (_) =>
                                  state.surahName ??
                                  '${context.l10n.surah} ${state.surahId}',
                              onStageTap: onStageSelected,
                              onLockedStageTap: (stage) =>
                                  _showLockedStageMessage(context),
                            ),
                          const SizedBox(height: 96),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLockedStageMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.kidsGamifiedLockedStage)),
    );
  }
}

class _KidsGamifiedJourneyAppBar extends StatelessWidget {
  const _KidsGamifiedJourneyAppBar({required this.onBack});

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
              context.l10n.kidsJourneyTitle,
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

String _stageDetailsLocation(KidsJourneyStage stage) {
  final query = Uri(
    queryParameters: {
      'surahId': '${stage.surahId}',
      'stageNumber': '${stage.stageNumber}',
      'startAyah': '${stage.startAyah}',
      'endAyah': '${stage.endAyah}',
      'completedAyahs': stage.completedAyahs.join(','),
      'status': stage.status.name,
    },
  ).query;
  return '${AppRoutes.memorizationPlusKidsStage}?$query';
}
