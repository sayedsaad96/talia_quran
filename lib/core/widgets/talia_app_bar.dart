import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

/// The one back button used by every Talia page header.
///
/// Pops when there is history; otherwise (page opened from a notification,
/// deep link or `context.go`) it goes to [fallbackLocation] — normally the
/// feature's own tab, so Azkar pages return to `/azkar`, not Home.
class TaliaBackButton extends StatelessWidget {
  const TaliaBackButton({
    super.key,
    this.fallbackLocation = AppRoutes.home,
    this.onPressed,
    this.color,
  });

  final String fallbackLocation;

  /// Replaces the default pop/fallback behaviour entirely (e.g. to confirm
  /// leaving an in-progress session first).
  final VoidCallback? onPressed;
  final Color? color;

  static void navigateBack(
    BuildContext context, {
    String fallbackLocation = AppRoutes.home,
  }) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      color: color,
      onPressed:
          onPressed ??
          () => navigateBack(context, fallbackLocation: fallbackLocation),
    );
  }
}

/// Standard page header: centered title in the theme's app-bar style and a
/// [TaliaBackButton]. Use this instead of hand-built header rows so every
/// page has the same title size, back affordance and spacing.
class TaliaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TaliaAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.fallbackLocation = AppRoutes.home,
    this.onBack,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.centerTitle = true,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  /// Overrides the back button slot entirely.
  final Widget? leading;

  /// Set to `false` on shell tab roots. Defaults to `true` even when there
  /// is no history, so deep-linked pages still get a way out.
  final bool showBackButton;
  final String fallbackLocation;
  final VoidCallback? onBack;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading:
          leading ??
          (showBackButton
              ? TaliaBackButton(
                  fallbackLocation: fallbackLocation,
                  onPressed: onBack,
                  color: foregroundColor,
                )
              : null),
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: bottom,
    );
  }
}
