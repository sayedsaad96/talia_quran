import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/kids_mode_cubit.dart';

class KidsModePage extends StatelessWidget {
  const KidsModePage({
    super.key,
    required this.surahId,
    required this.ayahNumber,
    required this.ayahText,
  });
  final int surahId;
  final int ayahNumber;
  final String ayahText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsModeCubit>()
        ..load(surahId, ayahNumber, ayahText),
      child: const _KidsModeView(),
    );
  }
}

class _KidsModeView extends StatelessWidget {
  const _KidsModeView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF0F7F4),
      body: BlocBuilder<KidsModeCubit, KidsModeState>(
        builder: (context, state) {
          if (state is KidsModeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is KidsModeLoaded) {
            return _KidsModeBody(state: state, isDark: isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _KidsModeBody extends StatelessWidget {
  const _KidsModeBody({required this.state, required this.isDark});
  final KidsModeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // App bar with stars and level
        SliverAppBar(
          pinned: true,
          expandedHeight: 100,
          backgroundColor: const Color(0xFF2D8E4C),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D8E4C), Color(0xFF1A6B5A)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pagePadding,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 48), // for leading
                      const Spacer(),
                      // Level badge
                      _LevelBadge(level: state.progress.currentLevel),
                      const SizedBox(width: AppSpacing.md),
                      // Stars
                      Row(
                        children: List.generate(
                          3,
                          (i) => Icon(
                            i < state.progress.starsForLevel
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Points bar
        SliverToBoxAdapter(
          child: _PointsBar(state: state),
        ),

        // Ayah card
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _AyahCard(state: state, isDark: isDark),
              const SizedBox(height: AppSpacing.xl),

              // Loop indicator
              _LoopIndicator(state: state),
              const SizedBox(height: AppSpacing.xl),

              // Play button
              _PlayButton(state: state),
              const SizedBox(height: AppSpacing.lg),

              // Complete button
              if (!state.isPlaying)
                _CompleteButton(state: state),

              // Completion reward
              if (state.isCompleted)
                _CompletionCelebration(state: state, isDark: isDark),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Level Badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_rounded,
              color: Colors.amber, size: 16),
          const SizedBox(width: 4),
          Text(
            'المستوى $level',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Points Bar ───────────────────────────────────────────────────────────────

class _PointsBar extends StatelessWidget {
  const _PointsBar({required this.state});
  final KidsModeLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2D8E4C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: const Color(0xFF2D8E4C).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded,
              color: Color(0xFF2D8E4C), size: 18),
          const SizedBox(width: 8),
          Text(
            '${state.progress.totalPoints} نقطة',
            style: AppTypography.labelMedium.copyWith(
              color: const Color(0xFF2D8E4C),
              fontWeight: FontWeight.w600,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.progress.levelProgress,
                backgroundColor: const Color(0xFF2D8E4C).withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF2D8E4C),
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'المستوى ${state.progress.currentLevel + 1}',
            style: AppTypography.labelSmall.copyWith(
              color: const Color(0xFF2D8E4C),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ayah Card ────────────────────────────────────────────────────────────────

class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.state, required this.isDark});
  final KidsModeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D8E4C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'آية ${state.ayahNumber}',
                  style: AppTypography.labelMedium.copyWith(
                    color: const Color(0xFF2D8E4C),
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              Icon(
                Icons.format_quote_rounded,
                color: const Color(0xFF2D8E4C).withValues(alpha: 0.3),
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            state.ayahText,
            style: AppTypography.displaySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontFamily: 'Amiri',
              height: 1.8,
              fontSize: 26,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}

// ─── Loop Indicator ───────────────────────────────────────────────────────────

class _LoopIndicator extends StatelessWidget {
  const _LoopIndicator({required this.state});
  final KidsModeLoaded state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(state.maxLoops, (i) {
          final isActive = i < state.currentLoop;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 28 : 14,
            height: 14,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF2D8E4C)
                  : const Color(0xFF2D8E4C).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(7),
            ),
          );
        }),
        const SizedBox(width: 12),
        Text(
          '${state.currentLoop} / ${state.maxLoops}',
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF2D8E4C),
          ),
        ),
      ],
    );
  }
}

// ─── Play Button ──────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.state});
  final KidsModeLoaded state;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: state.isPlaying
          ? () => context.read<KidsModeCubit>().stopAudio()
          : () => context.read<KidsModeCubit>().playAudio(),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D8E4C), Color(0xFF1A6B5A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D8E4C).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.isPlaying
                ? const Icon(Icons.stop_rounded,
                    color: Colors.white, size: 48,
                    key: ValueKey('stop'))
                : const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 52,
                    key: ValueKey('play')),
          ),
        ),
      ),
    );
  }
}

// ─── Complete Button ──────────────────────────────────────────────────────────

class _CompleteButton extends StatelessWidget {
  const _CompleteButton({required this.state});
  final KidsModeLoaded state;

  @override
  Widget build(BuildContext context) {
    if (state.isCompleted) return const SizedBox.shrink();
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => context.read<KidsModeCubit>().markCompleted(),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2D8E4C),
          side: const BorderSide(color: Color(0xFF2D8E4C)),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('أنهيت المراجعة'),
      ),
    );
  }
}

// ─── Completion Celebration ───────────────────────────────────────────────────

class _CompletionCelebration extends StatelessWidget {
  const _CompletionCelebration(
      {required this.state, required this.isDark});
  final KidsModeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D8E4C), Color(0xFF1A6B5A)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          const Text('🎉⭐🎉',
              style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'أحسنت! ربحت نقاط جديدة',
            style: AppTypography.headlineSmall.copyWith(
              color: Colors.white,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'المستوى ${state.progress.currentLevel} • '
            '${state.progress.totalPoints} نقطة',
            style: AppTypography.bodySmall
                .copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white60),
            ),
            child: const Text('العودة للقائمة'),
          ),
        ],
      ),
    );
  }
}
