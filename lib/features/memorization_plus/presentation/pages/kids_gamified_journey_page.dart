import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/kids_map_celebration_store.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../cubits/kids_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_journey_complete_card.dart';
import '../widgets/kids_journey_painters.dart';
import '../widgets/kids_journey_segment.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/kids_progress_header.dart';
import '../widgets/kids_ui.dart';
import '../widgets/memorization_path_settings_sheet.dart';

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
            return const Center(child: KidsLoadingWidget());
          }

          if (state is KidsJourneyError) {
            return KidsErrorWidget(
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
            loadCelebrations: getIt.isRegistered<KidsMapCelebrationStore>()
                ? getIt<KidsMapCelebrationStore>().takeNewlyCompleted
                : null,
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

/// K37 — the houses finished since the child's last visit to this map.
typedef KidsCelebrationLoader =
    Future<Set<int>> Function(int surahId, List<KidsJourneyStage> stages);

@visibleForTesting
class KidsGamifiedJourneyContent extends StatefulWidget {
  const KidsGamifiedJourneyContent({
    super.key,
    required this.state,
    required this.onBack,
    required this.onStageSelected,
    this.onRefresh,
    this.onPathSettingsTap,
    this.loadCelebrations,
  });

  final KidsJourneyLoaded state;
  final VoidCallback onBack;
  final ValueChanged<KidsJourneyStage> onStageSelected;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onPathSettingsTap;

  /// K37 — null means no glow (e.g. tests, or no store registered).
  final KidsCelebrationLoader? loadCelebrations;

  @override
  State<KidsGamifiedJourneyContent> createState() =>
      _KidsGamifiedJourneyContentState();
}

class _KidsGamifiedJourneyContentState
    extends State<KidsGamifiedJourneyContent> {
  final GlobalKey _activeStageKey = GlobalKey();
  bool _didAutoScroll = false;

  /// Cached once per state change — the active index used to be recomputed
  /// inside every segment's build, an O(n²) scan on each rebuild.
  late int _activeStageIndex;

  /// K37 — stage numbers to light up once on this visit.
  Set<int> _celebrate = const {};

  @override
  void initState() {
    super.initState();
    _activeStageIndex = _resolveActiveIndex(widget.state.stages);
    _scheduleAutoScroll();
    _loadCelebrations();
  }

  Future<void> _loadCelebrations() async {
    final loader = widget.loadCelebrations;
    if (loader == null) return;
    final celebrate = await loader(widget.state.surahId, widget.state.stages);
    if (mounted) setState(() => _celebrate = celebrate);
  }

  @override
  void didUpdateWidget(covariant KidsGamifiedJourneyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Back from a house: anything finished meanwhile glows now.
    if (oldWidget.state.stages != widget.state.stages) _loadCelebrations();
    if (oldWidget.state.surahId != widget.state.surahId) {
      _didAutoScroll = false;
      _activeStageIndex = _resolveActiveIndex(widget.state.stages);
      _scheduleAutoScroll();
    }
  }

  static int _resolveActiveIndex(List<KidsJourneyStage> stages) =>
      stages.indexWhere(
        (stage) =>
            stage.status == KidsJourneyStageStatus.current ||
            stage.status == KidsJourneyStageStatus.needsReview,
      );

  void _scheduleAutoScroll() {
    // The stages live in a lazy SliverList: the active segment's context may
    // not exist in the first frame (a long journey scrolls far below), so
    // retry on the next frames instead of silently dropping the child's
    // place on the map.
    var attempts = 0;
    void tryScroll() {
      if (!mounted || _didAutoScroll || attempts > 8) return;
      attempts++;
      final activeContext = _activeStageKey.currentContext;
      if (activeContext == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => tryScroll());
        return;
      }
      _didAutoScroll = true;
      Scrollable.ensureVisible(
        activeContext,
        alignment: 0.28,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryScroll());
  }

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
      child: Stack(
        children: [
          // Lightweight vector horizon scenery (0 raster overhead)
          const Positioned.fill(
            child: Opacity(
              opacity: 0.24,
              child: RepaintBoundary(
                child: CustomPaint(painter: LandscapeBackdropPainter()),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                KidsTopBar(
                  title: context.l10n.kidsJourneyTitle,
                  subtitle: context.l10n.kidsJourneySubtitle,
                  onBack: widget.onBack,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: widget.onRefresh ?? () async {},
                    child: CustomScrollView(
                      key: const PageStorageKey<String>(
                        'kids-gamified-journey',
                      ),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // Top Companion Hero Card & Map Title
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          sliver: SliverList.list(
                            children: [
                              KidsProgressHeader(
                                progress: widget.state.progress,
                                onSettingsTap: widget.onPathSettingsTap,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _JourneyMapHeader(
                                mapTitle: context.l10n.kidsJourneyMapTitle,
                                subtitle: context.l10n.kidsJourneySubtitle,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (widget.state.stages.isEmpty) ...[
                                const SizedBox(height: AppSpacing.lg),
                                // No stages for this surah at all (e.g. the
                                // whole Juz Amma journey is done) — a real
                                // celebration instead of an empty map (W2).
                                const KidsJourneyCompleteCard(),
                              ],
                            ],
                          ),
                        ),

                        if (widget.state.stages.isNotEmpty)
                          SliverList.builder(
                            itemCount: widget.state.stages.length,
                            itemBuilder: (context, index) {
                              final stage = widget.state.stages[index];
                              final isActive = index == _activeStageIndex;
                              final isLeft = index.isEven;
                              final showSignpost =
                                  (index + 1) % 4 == 0 &&
                                  index != widget.state.stages.length - 1;

                              return KidsJourneySegment(
                                key: isActive ? _activeStageKey : null,
                                stage: stage,
                                index: index,
                                isLeft: isLeft,
                                isFirst: index == 0,
                                isLast: index == widget.state.stages.length - 1,
                                surahName:
                                    widget.state.surahName ??
                                    '${context.l10n.surah} ${widget.state.surahId}',
                                showSignpost: showSignpost,
                                celebrate: _celebrate.contains(
                                  stage.stageNumber,
                                ),
                                onTap: () => widget.onStageSelected(stage),
                                onLockedTap: () =>
                                    _showLockedStageMessage(context),
                              );
                            },
                          ),

                        const SliverToBoxAdapter(child: SizedBox(height: 96)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLockedStageMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.kidsGamifiedLockedStage)),
    );
  }
}

/// Header for the Journey Map section
class _JourneyMapHeader extends StatelessWidget {
  const _JourneyMapHeader({required this.mapTitle, required this.subtitle});

  final String mapTitle;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.explore_rounded,
              color: KidsTheme.goldLight,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              mapTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: KidsTheme.shellTextPrimary,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                letterSpacing: 0,
                shadows: const [
                  Shadow(
                    color: Color(0x66000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: KidsTheme.shellTextSecondary,
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
      ],
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
    },
  ).query;
  return '${AppRoutes.memorizationPlusKidsStage}?$query';
}
