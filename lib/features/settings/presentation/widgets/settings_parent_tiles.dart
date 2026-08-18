import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../memorization_plus/domain/navigation/memorization_navigation_resolver.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'settings_section.dart';

class ParentDashboardTile extends StatelessWidget {
  const ParentDashboardTile({super.key, required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState is! AuthAuthenticated;
    final subtitle = isGuest
        ? context.l10n.parentDashboardGuestSubtitle
        : context.l10n.parentDashboardSubtitle;

    return InkWell(
      onTap: () => unawaited(_openParentDashboard(context)),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.family_restroom_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.parentDashboardTitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SettingsTrailingChevron(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openParentDashboard(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      unawaited(context.push(AppRoutes.login));
      return;
    }
    final location = await MemorizationNavigationResolver(
      getIt<MemorizationPlusRepository>(),
    ).parentDashboardLocation();
    if (context.mounted) unawaited(context.push(location));
  }
}

class ParentModeToggle extends StatelessWidget {
  const ParentModeToggle({
    super.key,
    required this.isDark,
    required this.isParentMode,
    required this.onChanged,
  });

  final bool isDark;
  final bool isParentMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.parentGuardianMode,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.parentModeSubtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isParentMode,
            activeThumbColor: isDark
                ? AppColors.primaryLight
                : AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
