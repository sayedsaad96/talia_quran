import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';

class HomeQuickAccess extends StatelessWidget {
  const HomeQuickAccess({super.key, required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final isFridayKahf = now.weekday == DateTime.friday && hour < 18;
    final azkarRoute = hour < 12
        ? '/azkar/morning'
        : hour >= 16
        ? '/azkar/evening'
        : '/azkar/general';
    final items = [
      (
        Icons.bookmark_rounded,
        context.l10n.bookmark,
        state.recentBookmarkRoute ?? AppRoutes.quranBookmarks,
      ),
      if (isFridayKahf)
        (
          Icons.menu_book_rounded,
          context.l10n.homeSlotFridayTitle,
          '/quran/surah/18',
        )
      else
        (Icons.spa_rounded, context.l10n.azkar, azkarRoute),
      (
        Icons.auto_stories_rounded,
        context.l10n.khatmahStartAction,
        AppRoutes.khatmahDashboard,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxChipWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - AppSpacing.pagePadding * 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in items)
              Semantics(
                button: true,
                label: item.$2,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxChipWidth),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(item.$3),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: skin.glassFill,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(color: skin.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(item.$1, size: 16, color: skin.accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(
                                  color: skin.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
