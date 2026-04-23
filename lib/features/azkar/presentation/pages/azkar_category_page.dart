import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/azkar_entities.dart';
import '../cubits/azkar_cubit.dart';

class AzkarCategoryPage extends StatelessWidget {
  const AzkarCategoryPage({super.key, required this.category});
  final String category;

  AzkarCategory get _category => switch (category) {
    'morning' => AzkarCategory.morning,
    'evening' => AzkarCategory.evening,
    _ => AzkarCategory.general,
  };

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AzkarCubit>()..load(_category),
      child: _AzkarCategoryView(category: _category),
    );
  }
}

class _AzkarCategoryView extends StatelessWidget {
  const _AzkarCategoryView({required this.category});
  final AzkarCategory category;

  String _title(BuildContext ctx) => switch (category) {
    AzkarCategory.morning => ctx.l10n.morningAzkar,
    AzkarCategory.evening => ctx.l10n.eveningAzkar,
    AzkarCategory.general => ctx.l10n.generalAzkar,
  };

  List<Color> _gradientColors() => switch (category) {
    AzkarCategory.morning => [const Color(0xFFFF8C42), const Color(0xFFFF6B00)],
    AzkarCategory.evening => [const Color(0xFF2D5A8E), const Color(0xFF1A3A5C)],
    AzkarCategory.general => [AppColors.primary, AppColors.primaryDark],
  };

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final gradColors = _gradientColors();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) {
          if (state is AzkarLoading) {
            return const Center(child: LoadingWidget());
          }
          if (state is AzkarError) {
            return ErrorStateWidget(message: state.message);
          }
          if (state is AzkarLoaded) {
            if (state.allDone) {
              return _CompletionScreen(
                isDark: isDark,
                gradColors: gradColors,
                onReset: () => context.read<AzkarCubit>().reset(),
              );
            }
            return _ActiveAzkarScreen(
              state: state,
              title: _title(context),
              isDark: isDark,
              gradColors: gradColors,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ActiveAzkarScreen extends StatelessWidget {
  const _ActiveAzkarScreen({
    required this.state,
    required this.title,
    required this.isDark,
    required this.gradColors,
  });

  final AzkarLoaded state;
  final String title;
  final bool isDark;
  final List<Color> gradColors;

  @override
  Widget build(BuildContext context) {
    final session = state.current;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Column(
      children: [
        // ─── Header ─────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradColors,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () => context.read<AzkarCubit>().reset(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      state.sessions.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: i == state.currentIndex ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: state.sessions[i].isDone
                              ? Colors.white
                              : i == state.currentIndex
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${state.completedCount} / ${state.sessions.length} مكتمل',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ─── Zikr Content ────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              children: [
                // Arabic text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    session.zikr.text,
                    style: AppTypography.azkarText.copyWith(
                      color: textPrimary,
                      fontSize: 20,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(duration: 300.ms),

                if (session.zikr.reference.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    session.zikr.reference,
                    style: AppTypography.labelSmall.copyWith(
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // ─── Counter ──────────────────────────────────────────────
                _CounterWidget(
                  session: session,
                  gradColors: gradColors,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<AzkarCubit>().increment();
                  },
                  onNext: () => context.read<AzkarCubit>().goNext(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CounterWidget extends StatefulWidget {
  const _CounterWidget({
    required this.session,
    required this.gradColors,
    required this.isDark,
    required this.onTap,
    required this.onNext,
  });

  final ZikrSession session;
  final List<Color> gradColors;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onNext;

  @override
  State<_CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<_CounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.session.isDone) return;
    _pulseCtrl.forward().then((_) => _pulseCtrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isDone = session.isDone;

    return Column(
      children: [
        // Tap circle
        GestureDetector(
          onTap: _handleTap,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) =>
                Transform.scale(scale: _pulseAnim.value, child: child),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                gradient: isDone
                    ? const LinearGradient(
                        colors: [Color(0xFF2E7D5E), Color(0xFF1A5E40)],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.gradColors,
                      ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.gradColors[0].withValues(alpha:0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isDone)
                    const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    )
                  else ...[
                    Text(
                      '${session.currentCount}',
                      style: AppTypography.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 52,
                      ),
                    ),
                    Text(
                      '/ ${session.zikr.totalCount}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Arc progress
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: session.progress,
              backgroundColor: widget.gradColors[0].withValues(alpha:0.15),
              valueColor: AlwaysStoppedAnimation<Color>(widget.gradColors[0]),
              minHeight: 6,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        if (isDone)
          GestureDetector(
            onTap: widget.onNext,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: widget.gradColors[0].withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: widget.gradColors[0].withValues(alpha:0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الذكر التالي',
                    style: AppTypography.labelLarge.copyWith(
                      color: widget.gradColors[0],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: widget.gradColors[0],
                    size: 18,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().scale(),
      ],
    );
  }
}

class _CompletionScreen extends StatelessWidget {
  const _CompletionScreen({
    required this.isDark,
    required this.gradColors,
    required this.onReset,
  });

  final bool isDark;
  final List<Color> gradColors;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradColors,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradColors[0].withValues(alpha:0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 56,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'تم بحمد الله',
              style: AppTypography.displaySmall.copyWith(
                fontFamily: 'Amiri',
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اكتملت جميع الأذكار',
              style: AppTypography.bodyLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('إعادة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gradColors[0],
                      side: BorderSide(color: gradColors[0].withValues(alpha:0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: Text(context.l10n.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gradColors[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
