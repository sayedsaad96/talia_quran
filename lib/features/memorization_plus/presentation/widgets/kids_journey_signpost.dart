import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../theme/kids_theme.dart';

/// A charming 2.5D wooden milestone signpost with inspiring Quranic motivation
/// along the child's memorization adventure path.
class KidsJourneySignpost extends StatelessWidget {
  const KidsJourneySignpost({
    super.key,
    required this.quoteIndex,
    this.width = 240,
  });

  final int quoteIndex;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = switch (quoteIndex % 3) {
      0 => l10n.kidsJourneySignpost1,
      1 => l10n.kidsJourneySignpost2,
      _ => l10n.kidsJourneySignpost3,
    };

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wooden signboard
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD4A373),
                  Color(0xFFA97142),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: const Color(0xFF7F4F24),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: KidsTheme.pathStone,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                      shadows: const [
                        Shadow(
                          color: Color(0x80000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: KidsTheme.pathStone,
                  size: 16,
                ),
              ],
            ),
          ),
          // Wooden post
          Container(
            width: 12,
            height: 14,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B5A2B), Color(0xFF5C3A1E)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
