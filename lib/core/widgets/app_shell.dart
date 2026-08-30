import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
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
    final isWide = context.screenWidth >= 600;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _TaliaNavRail(
              currentIndex: navigationShell.currentIndex,
              isDark: isDark,
              tabs: _tabs,
              onTap: _onTap,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _TaliaBottomNav(
        currentIndex: navigationShell.currentIndex,
        isDark: isDark,
        tabs: _tabs,
        onTap: _onTap,
      ),
    );
  }
}

class _TaliaNavRail extends StatelessWidget {
  const _TaliaNavRail({
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
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.darkTextHint
        : AppColors.lightTextHint;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      selectedIconTheme: IconThemeData(color: selectedColor, size: 24),
      unselectedIconTheme: IconThemeData(color: unselectedColor, size: 24),
      selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: selectedColor,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: unselectedColor,
      ),
      indicatorColor: selectedColor.withValues(alpha: isDark ? 0.2 : 0.12),
      destinations: List.generate(
        tabs.length,
        (i) => NavigationRailDestination(
          icon: Icon(tabs[i].icon),
          selectedIcon: Icon(tabs[i].icon),
          label: Text(labels[i]),
        ),
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
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.darkTextHint
        : AppColors.lightTextHint;

    return SafeArea(
      top: false,
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          indicatorColor: selectedColor.withValues(alpha: isDark ? 0.2 : 0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected ? selectedColor : unselectedColor,
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return AppTypography.labelSmall.copyWith(
              color: selected ? selectedColor : unselectedColor,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onTap,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: List.generate(
            tabs.length,
            (i) => NavigationDestination(
              icon: Icon(tabs[i].icon),
              selectedIcon: Icon(tabs[i].icon),
              label: labels[i],
              tooltip: labels[i],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.route});
  final IconData icon;
  final String route;
}
