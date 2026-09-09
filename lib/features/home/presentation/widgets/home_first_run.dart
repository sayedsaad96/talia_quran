import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HomeFirstRun extends StatelessWidget {
  const HomeFirstRun({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.homeFirstRunTitle,
          style: AppTypography.headlineSmall.copyWith(
            color: textColor,
            fontFamily: 'Amiri',
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.l10n.homeFirstRunBody,
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.quran),
            icon: const Icon(Icons.menu_book_rounded),
            label: Text(
              context.l10n.homeFirstRunRead,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.memorizationHub),
            icon: const Icon(Icons.psychology_alt_rounded),
            label: Text(
              context.l10n.homeFirstRunMemorize,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: () => context.push(AppRoutes.khatmahSetup),
          child: Text(context.l10n.khatmahStartAction),
        ),
      ],
    );
  }
}
