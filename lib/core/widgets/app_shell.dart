import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../constants/app_spacing.dart';
import '../theme/app_typography.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, route: AppRoutes.home),
    _TabItem(icon: Icons.menu_book_rounded, route: AppRoutes.quran),
    _TabItem(icon: Icons.auto_stories_rounded, route: AppRoutes.hifz),
    _TabItem(icon: Icons.spa_rounded, route: AppRoutes.azkar),
    _TabItem(icon: Icons.bar_chart_rounded, route: AppRoutes.progress),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.progress)) return 4;
    if (location.startsWith(AppRoutes.azkar)) return 3;
    if (location.startsWith(AppRoutes.hifz)) return 2;
    if (location.startsWith(AppRoutes.quran)) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    final isDark = context.isDark;

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _TaliaBottomNav(
        currentIndex: currentIndex,
        isDark: isDark,
        tabs: _tabs,
        onTap: (i) => context.go(_tabs[i].route),
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
    ctx.l10n.hifz,
    ctx.l10n.azkar,
    ctx.l10n.progress,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(context);
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha:0.3)
                : AppColors.primary.withValues(alpha:0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSpacing.bottomNavHeight,
          child: Row(
            children: [
              // 5 nav tabs
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
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final inactive = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final color = isSelected ? primary : inactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child:
          Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withValues(alpha:0.1)
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
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    child: Text(label),
                  ),
                ],
              )
              .animate(target: isSelected ? 1 : 0)
              .scaleXY(begin: 1, end: 1.04, duration: 150.ms),
    );
  }
}



class _TabItem {
  const _TabItem({required this.icon, required this.route});
  final IconData icon;
  final String route;
}
