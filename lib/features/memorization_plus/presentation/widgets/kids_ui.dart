import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// Shared visual shell for every screen in the kids memorization path.
class KidsBackground extends StatelessWidget {
  const KidsBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: child,
    );
  }
}

/// Shared top bar so internal kids screens keep the same navigation language.
class KidsTopBar extends StatelessWidget {
  const KidsTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: const BackButtonIcon(),
            color: KidsTheme.shellTextPrimary,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              minimumSize: const Size(48, 48),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: KidsTheme.shellTextPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSmall.copyWith(
                      color: KidsTheme.shellTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
