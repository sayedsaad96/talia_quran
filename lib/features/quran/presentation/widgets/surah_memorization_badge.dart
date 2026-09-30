import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/surah_memorization_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Small badge in the surah list: memorized, or memorization in progress
/// (N17). Surahs the learner never started show no badge.
class SurahMemorizationBadge extends StatelessWidget {
  const SurahMemorizationBadge(this.status, {super.key});

  final SurahMemorizationStatus status;

  @override
  Widget build(BuildContext context) {
    final memorized = status == SurahMemorizationStatus.memorized;
    final color = memorized ? AppColors.success : context.tokens.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          memorized ? Icons.verified_rounded : Icons.psychology_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          memorized
              ? context.l10n.memorized
              : context.l10n.surahInProgressBadge,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
