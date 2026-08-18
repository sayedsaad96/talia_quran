part of '../pages/progress_page.dart';

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakDays, required this.isDark});
  final int streakDays;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.streakOrange, Color(0xFFFF5500)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.streakOrange.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$streakDays',
            style: AppTypography.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            context.l10n.days,
            style: AppTypography.bodySmall.copyWith(color: Colors.white70),
          ),
          Text(
            context.l10n.streak,
            style: AppTypography.labelSmall.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.isDark,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool isDark;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detailed Progress Card ───────────────────────────────────────────────────
