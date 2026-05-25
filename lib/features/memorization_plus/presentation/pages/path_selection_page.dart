import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_info_banner.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/memorization_entities.dart';
import '../cubits/memorization_identity_cubit.dart';
import '../../../../core/extensions/context_extensions.dart';

class PathSelectionPage extends StatelessWidget {
  const PathSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<MemorizationIdentityCubit>(),
      child: const _PathSelectionView(),
    );
  }
}

class _PathSelectionView extends StatelessWidget {
  const _PathSelectionView();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.memorizationPathTitle,
      body: BlocConsumer<MemorizationIdentityCubit, MemorizationIdentityState>(
        listener: (context, state) {
          if (state is MemorizationIdentitySuccess) {
            final profile = state.profile;
            if (profile.isAdult) {
              context.go(AppRoutes.memorizationPlusCustomPlan);
            } else if (profile.isChild) {
              context.go(AppRoutes.memorizationPlusGuardianLinking);
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is MemorizationIdentityLoading;
          final isDark = context.isDark;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.memorizationPathQuestion,
                  style: AppTypography.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.memorizationPathDescription,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state is MemorizationIdentityError) ...[
                  const SizedBox(height: 20),
                  ErrorInfoBanner(
                    type: ErrorInfoBannerType.error,
                    title: 'تعذر حفظ اختيارك',
                    message: state.message,
                  ),
                ],
                const SizedBox(height: 48),
                _buildPathCard(
                  context: context,
                  title: context.l10n.memorizationPathAdultsTitle,
                  description: context.l10n.memorizationPathAdultsDesc,
                  icon: Icons.person_outline,
                  color: AppColors.primary,
                  isLoading: isLoading,
                  onTap: () {
                    _confirmPathSelection(
                      context,
                      path: MemorizationPath.adult,
                      title: context.l10n.memorizationPathAdultsTitle,
                      description: context.l10n.memorizationPathAdultsDesc,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _buildPathCard(
                  context: context,
                  title: context.l10n.memorizationPathKidsTitle,
                  description: context.l10n.memorizationPathKidsDesc,
                  icon: Icons.child_care,
                  color: AppColors.gold,
                  isLoading: isLoading,
                  onTap: () {
                    _confirmPathSelection(
                      context,
                      path: MemorizationPath.child,
                      title: context.l10n.memorizationPathKidsTitle,
                      description: context.l10n.memorizationPathKidsDesc,
                    );
                  },
                ),
                if (isLoading) ...[
                  const SizedBox(height: 32),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmPathSelection(
    BuildContext context, {
    required MemorizationPath path,
    required String title,
    required String description,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ماذا سيحدث بعد ذلك؟',
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$title\n$description',
                style: AppTypography.bodyMedium.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'يمكن تغييره من الإعدادات لاحقاً بدون فقدان تقدمك.',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                child: const Text('تأكيد'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      unawaited(context.read<MemorizationIdentityCubit>().selectPath(path));
    }
  }

  Widget _buildPathCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDark;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}
