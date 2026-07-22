import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../constants/app_spacing.dart';
import '../theme/app_typography.dart';

class AppShell extends StatelessWidget {
  // UX-4 FIX: AppShell now accepts StatefulNavigationShell instead of a plain
  // child Widget. This lets each branch manage its own Navigator independently,
  // preserving tab state (scroll position, loaded data) across tab switches.
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, route: AppRoutes.home),
    _TabItem(icon: Icons.menu_book_rounded, route: AppRoutes.quran),
    _TabItem(
      icon: Icons.auto_stories_rounded,
      route: AppRoutes.memorizationHub,
    ),
    _TabItem(icon: Icons.spa_rounded, route: AppRoutes.azkar),
    _TabItem(icon: Icons.bar_chart_rounded, route: AppRoutes.progress),
  ];

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    // goBranch with initialLocation: true re-triggers the branch's initial
    // route if the user taps the already-selected tab (scroll-to-top UX).
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: _TaliaBottomNav(
        currentIndex: navigationShell.currentIndex,
        isDark: isDark,
        tabs: _tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _TaliaBottomNav extends StatelessWidget {
  const _TaliaBottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final List<_TabItem> tabs;
  final ValueChanged<int> onTap;

  List<String> _labels(BuildContext ctx) => [
    ctx.l10n.home,
    ctx.l10n.quran,
    ctx.l10n.memorization,
    ctx.l10n.azkar,
    ctx.l10n.progress,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: AppDecorations.floatingGlass(
                isDark: isDark,
                radius: AppSpacing.radiusFull,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                children: [
                  ...List.generate(tabs.length, (i) {
                    final isSelected = i == currentIndex;
                    return Expanded(
                      child: _NavItem(
                        icon: tabs[i].icon,
                        label: labels[i],
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => onTap(i),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.goldLight : AppColors.primary;
    final inactive = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final color = isSelected ? primary : inactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : AppColors.primary.withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                AppSpacing.radiusFull,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w400,
              fontSize: 10.5,
            ),
            child: Text(label),
          ),
        ],
      ).animate(target: isSelected ? 1 : 0).scaleXY(begin: 1, end: 1.05, duration: 150.ms),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.route});
  final IconData icon;
  final String route;
}
