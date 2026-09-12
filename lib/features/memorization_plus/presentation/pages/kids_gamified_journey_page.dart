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
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../cubits/kids_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_house_card.dart';
import '../widgets/kids_journey_signpost.dart';
import '../widgets/kids_progress_header.dart';
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
      backgroundColor: KidsTheme.landscapeGrass,
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
class KidsGamifiedJourneyContent extends StatefulWidget {
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
  State<KidsGamifiedJourneyContent> createState() =>
      _KidsGamifiedJourneyContentState();
}

class _KidsGamifiedJourneyContentState
    extends State<KidsGamifiedJourneyContent> {
  final GlobalKey _activeStageKey = GlobalKey();
  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _scheduleAutoScroll();
  }

  @override
  void didUpdateWidget(covariant KidsGamifiedJourneyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.surahId != widget.state.surahId) {
      _didAutoScroll = false;
      _scheduleAutoScroll();
    }
  }

  void _scheduleAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoScroll) return;
      final activeContext = _activeStageKey.currentContext;
      if (activeContext != null) {
        _didAutoScroll = true;
        Scrollable.ensureVisible(
          activeContext,
          alignment: 0.28,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: KidsTheme.skyLandscapeGradient,
      ),
      child: Stack(
        children: [
          // Lightweight vector horizon scenery (0 raster overhead)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LandscapeBackdropPainter()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _KidsGamifiedJourneyAppBar(onBack: widget.onBack),
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
                                EmptyStateWidget(
                                  message:
                                      context.l10n.kidsGamifiedJourneyComplete,
                                  icon: Icons.emoji_events_rounded,
                                ),
                              ],
                            ],
                          ),
                        ),

                        if (widget.state.stages.isNotEmpty)
                          SliverList.builder(
                            itemCount: widget.state.stages.length,
                            itemBuilder: (context, index) {
                              final stage = widget.state.stages[index];
                              final activeIndex = widget.state.stages.indexWhere(
                                (s) =>
                                    s.status == KidsJourneyStageStatus.current ||
                                    s.status ==
                                        KidsJourneyStageStatus.needsReview,
                              );
                              final isActive = index == activeIndex;
                              final isLeft = index.isEven;
                              final showSignpost = (index + 1) % 4 == 0 &&
                                  index != widget.state.stages.length - 1;

                              return _JourneyMapSegment(
                                key: isActive ? _activeStageKey : null,
                                stage: stage,
                                index: index,
                                isLeft: isLeft,
                                isFirst: index == 0,
                                isLast: index == widget.state.stages.length - 1,
                                surahName: widget.state.surahName ??
                                    '${context.l10n.surah} ${widget.state.surahId}',
                                showSignpost: showSignpost,
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
  const _JourneyMapHeader({
    required this.mapTitle,
    required this.subtitle,
  });

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
              color: KidsTheme.pathStone,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              mapTitle,
              style: AppTypography.headlineSmall.copyWith(
                color: Colors.white,
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
            color: Colors.white.withValues(alpha: 0.88),
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// A single segment of the 2.5D winding path carrying an alternating destination node
class _JourneyMapSegment extends StatelessWidget {
  const _JourneyMapSegment({
    super.key,
    required this.stage,
    required this.index,
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
    required this.surahName,
    required this.showSignpost,
    required this.onTap,
    required this.onLockedTap,
  });

  final KidsJourneyStage stage;
  final int index;
  final bool isLeft;
  final bool isFirst;
  final bool isLast;
  final String surahName;
  final bool showSignpost;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const cardWidth = 176.0;
        const sideMargin = 16.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: _WindingPathPainter(
                isLeft: isLeft,
                isFirst: isFirst,
                isLast: isLast,
                totalWidth: totalWidth,
                cardWidth: cardWidth,
                sideMargin: sideMargin,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Align(
                  alignment: isLeft
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isLeft ? sideMargin : 0,
                      right: isLeft ? 0 : sideMargin,
                    ),
                    child: KidsHouseCard(
                      width: cardWidth,
                      stage: stage,
                      surahName: surahName,
                      onTap: onTap,
                      onLockedTap: onLockedTap,
                    ),
                  ),
                ),
              ),
            ),
            if (showSignpost)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: KidsJourneySignpost(quoteIndex: index ~/ 3),
              ),
          ],
        );
      },
    );
  }
}

/// Continuous winding dirt path painter that guarantees seamless C1 continuity
/// between consecutive segments at (midX, 0) and (midX, h).
class _WindingPathPainter extends CustomPainter {
  const _WindingPathPainter({
    required this.isLeft,
    required this.isFirst,
    required this.isLast,
    required this.totalWidth,
    required this.cardWidth,
    required this.sideMargin,
  });

  final bool isLeft;
  final bool isFirst;
  final bool isLast;
  final double totalWidth;
  final double cardWidth;
  final double sideMargin;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final midX = w * 0.5;
    final leftX = sideMargin + cardWidth * 0.5;
    final rightX = w - sideMargin - cardWidth * 0.5;
    final nodeX = isLeft ? leftX : rightX;
    final nodeY = h * 0.5;

    // Build the smooth path
    final path = Path();
    final startX = isFirst ? nodeX : midX;
    const startY = 0.0;
    path.moveTo(startX, startY);

    // Segment 1: from top to destination node
    path.cubicTo(
      startX,
      h * 0.18,
      nodeX,
      h * 0.28,
      nodeX,
      nodeY,
    );

    // Segment 2: from destination node to bottom midpoint
    final endX = isLast ? nodeX : midX;
    final endY = h;
    path.cubicTo(
      nodeX,
      h * 0.72,
      endX,
      h * 0.82,
      endX,
      endY,
    );

    // 1. Path Earth Border / Drop Shadow
    final borderPaint = Paint()
      ..color = KidsTheme.pathEdge
      ..strokeWidth = 32
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, borderPaint);

    // 2. Cobblestone / Dirt Road Surface
    final roadPaint = Paint()
      ..color = KidsTheme.pathDirt
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, roadPaint);

    // 3. Stepping Stone Platform under the Destination Building
    final stonePlatformCenter = Offset(nodeX, nodeY - 32);

    final stoneBasePaint = Paint()
      ..color = KidsTheme.pathEdge
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stonePlatformCenter, 44, stoneBasePaint);

    final stoneSurfacePaint = Paint()
      ..color = KidsTheme.pathStone
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stonePlatformCenter, 40, stoneSurfacePaint);

    final stoneRingPaint = Paint()
      ..color = KidsTheme.pathEdge.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(stonePlatformCenter, 32, stoneRingPaint);
  }

  @override
  bool shouldRepaint(covariant _WindingPathPainter oldDelegate) {
    return oldDelegate.isLeft != isLeft ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.totalWidth != totalWidth;
  }
}

/// Lightweight landscape backdrop with gentle rolling hills silhouettes
class _LandscapeBackdropPainter extends CustomPainter {
  const _LandscapeBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Horizon rolling green hill
    final hillPaint1 = Paint()
      ..color = const Color(0x334CAF50)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, h * 0.4)
      ..quadraticBezierTo(w * 0.35, h * 0.34, w * 0.7, h * 0.42)
      ..quadraticBezierTo(w * 0.88, h * 0.45, w, h * 0.41)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path1, hillPaint1);

    // Second hill silhouette
    final hillPaint2 = Paint()
      ..color = const Color(0x222E7D32)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, h * 0.48)
      ..quadraticBezierTo(w * 0.25, h * 0.53, w * 0.55, h * 0.47)
      ..quadraticBezierTo(w * 0.8, h * 0.43, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path2, hillPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _KidsGamifiedJourneyAppBar extends StatelessWidget {
  const _KidsGamifiedJourneyAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const BackButtonIcon(),
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.kidsJourneyTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
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
    },
  ).query;
  return '${AppRoutes.memorizationPlusKidsStage}?$query';
}
