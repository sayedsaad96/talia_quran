import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_spacing.dart';
import '../extensions/context_extensions.dart';
import 'app_button.dart';

// ─── Loading Widget ───────────────────────────────────────────────────────────

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: _TaliaSpinner());
  }
}

class _TaliaSpinner extends StatefulWidget {
  const _TaliaSpinner();

  @override
  State<_TaliaSpinner> createState() => _TaliaSpinnerState();
}

class _TaliaSpinnerState extends State<_TaliaSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!mounted) return;
    final disable = MediaQuery.of(context).disableAnimations;
    if (disable) {
      _ctrl.value = 1.0;
    } else if (!_ctrl.isAnimating) {
      if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
        _ctrl.repeat();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final color = isDark ? AppColors.primaryLight : AppColors.primary;

    return SizedBox(
      width: 40,
      height: 40,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CircularProgressIndicator(
          value: null,
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}

// ─── Shimmer List ─────────────────────────────────────────────────────────────

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 6, this.height = 80});

  final int itemCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final base = isDark ? AppColors.shimmerBase : AppColors.shimmerBaseLight;
    final highlight = isDark
        ? AppColors.shimmerHighlight
        : AppColors.shimmerHighlightLight;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.action,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;
  final Widget? action;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_rounded,
                size: 36,
                color: context.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: context.colorScheme.error.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: retryLabel ?? context.l10n.tryAgain,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Empty Journey Widget ───────────────────────────────────────────────────

class EmptyJourneyWidget extends StatelessWidget {
  const EmptyJourneyWidget({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.startYourJourneyWithQuran,
              style: AppTypography.headlineSmall.copyWith(fontFamily: 'Amiri'),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.l10n.startNow,
              onPressed: onStart,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }
}
