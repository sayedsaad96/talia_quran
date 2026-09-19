import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import '../../features/quran/presentation/widgets/quran_background_exit_dialog.dart';
import '../../features/quran/presentation/widgets/quran_mini_player_bar.dart';
import '../constants/app_spacing.dart';
import '../constants/surah_names.dart';
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
    _TabItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      route: AppRoutes.home,
    ),
    _TabItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
      route: AppRoutes.quran,
    ),
    _TabItem(
      icon: Icons.psychology_outlined,
      selectedIcon: Icons.psychology_rounded,
      route: AppRoutes.memorizationHub,
    ),
    _TabItem(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome_rounded,
      route: AppRoutes.azkar,
    ),
    _TabItem(
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
      route: AppRoutes.progress,
    ),
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

  Future<void> _handlePopScope(BuildContext context, bool didPop) async {
    if (didPop) return;

    // If user is on a secondary tab, return to Home tab first
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }

    final audioCubit = context.read<QuranAudioPlayerCubit>();
    if (audioCubit.state.isPlaying) {
      final surahId = audioCubit.state.currentSurahId;
      final surahName = surahId != null ? SurahNames.arabic[surahId] : null;

      final action = await showQuranBackgroundExitDialog(
        context: context,
        surahName: surahName,
      );

      if (action == null) return;

      if (action == QuranBackgroundExitAction.continueInBackground) {
        await SystemNavigator.pop();
      } else if (action == QuranBackgroundExitAction.stopAndExit) {
        await audioCubit.stop();
        await SystemNavigator.pop();
      }
    } else {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isWide = context.screenWidth >= 600;

    final Widget scaffold = isWide
        ? Scaffold(
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
                Expanded(
                  child: Stack(
                    children: [
                      navigationShell,
                      const PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: QuranMiniPlayerBar(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Scaffold(
            body: navigationShell,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const QuranMiniPlayerBar(),
                _TaliaBottomNav(
                  currentIndex: navigationShell.currentIndex,
                  isDark: isDark,
                  tabs: _tabs,
                  onTap: _onTap,
                ),
              ],
            ),
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _handlePopScope(context, didPop),
      child: scaffold,
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
    final selectedColor = isDark ? AppColors.goldLight : AppColors.primary;
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
          selectedIcon: Icon(tabs[i].selectedIcon),
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: isDark ? const Color(0xEB041D1A) : const Color(0xF2FFFFFF),
            border: Border.all(
              color: isDark ? const Color(0x26FFFFFF) : const Color(0x1F0D5C53),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.primaryDark.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              if (isDark)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(tabs.length, (index) {
                      final isSelected = index == currentIndex;
                      final tab = tabs[index];
                      final label = labels[index];

                      return Expanded(
                        child: _TaliaNavItem(
                          tab: tab,
                          label: label,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaliaNavItem extends StatelessWidget {
  const _TaliaNavItem({
    required this.tab,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _TabItem tab;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? AppColors.goldLight : AppColors.primary;
    final inactiveColor = isDark
        ? AppColors.darkTextHint
        : AppColors.lightTextHint;

    final capsuleBg = isDark
        ? AppColors.gold.withValues(alpha: 0.14)
        : AppColors.primary.withValues(alpha: 0.1);
    final capsuleBorder = isDark
        ? AppColors.gold.withValues(alpha: 0.28)
        : AppColors.primary.withValues(alpha: 0.18);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: (isDark ? AppColors.gold : AppColors.primary)
            .withValues(alpha: 0.08),
        radius: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon capsule
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 12 : 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? capsuleBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? capsuleBorder : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? tab.selectedIcon : tab.icon,
                    color: isSelected ? activeColor : inactiveColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Animated Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(label),
              ),
              const SizedBox(height: 3),
              // Subtle Glowing Indicator Dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? AppColors.gold : AppColors.primary,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isDark ? AppColors.gold : AppColors.primary)
                                .withValues(alpha: 0.6),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
