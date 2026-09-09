import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../memorization_plus/domain/entities/family_dashboard.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

class HomeParentChildren extends StatelessWidget {
  const HomeParentChildren({
    super.key,
    required this.children,
    required this.skin,
  });

  final List<FamilyChildEntry> children;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, size: 16, color: skin.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.homeParentToolsTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: skin.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final child in children)
            _ChildRow(child: child, skin: skin),
        ],
      ),
    );
  }
}

class _ChildRow extends StatelessWidget {
  const _ChildRow({required this.child, required this.skin});

  final FamilyChildEntry child;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: child.displayName,
      child: InkWell(
        onTap: () => context.push(AppRoutes.familyDashboard),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skin.accent.withValues(alpha: 0.16),
                ),
                child: Text(
                  _initials(child.displayName),
                  style: AppTypography.titleMedium.copyWith(
                    color: skin.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      child.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: skin.textPrimary,
                      ),
                    ),
                    Text(
                      context.l10n.homeChildStreak(child.currentStreak),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                        color: skin.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                child.isActiveToday ? Icons.check_circle : Icons.schedule,
                size: 18,
                color: child.isActiveToday
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCodes(trimmed.runes.take(1));
}
