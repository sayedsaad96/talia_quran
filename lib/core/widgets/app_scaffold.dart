import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../extensions/context_extensions.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.backgroundColor,
    this.padding,
    this.floatingActionButton,
    this.bottomBar,
    this.showAppBar = true,
    this.centerTitle = true,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.gradient,
  });

  final Widget body;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool showAppBar;
  final bool centerTitle;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg =
        backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.lightBackground);

    return Scaffold(
      backgroundColor: gradient != null ? Colors.transparent : bg,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      appBar: showAppBar
          ? AppBar(
              title:
                  titleWidget ??
                  (title != null
                      ? Text(
                          title!,
                          style: AppTypography.headlineSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        )
                      : null),
              centerTitle: centerTitle,
              leading: leading,
              actions: actions,
              backgroundColor: extendBodyBehindAppBar
                  ? Colors.transparent
                  : (gradient != null ? Colors.transparent : bg),
            )
          : null,
      body: gradient != null
          ? Container(
              decoration: BoxDecoration(gradient: gradient),
              child: _buildBody(context),
            )
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (padding != null) {
      return Padding(padding: padding!, child: body);
    }
    return body;
  }
}

/// Sliver-based scaffold for complex scrolling
class AppSliverScaffold extends StatelessWidget {
  const AppSliverScaffold({
    super.key,
    required this.slivers,
    this.backgroundColor,
    this.floatingActionButton,
  });

  final List<Widget> slivers;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg =
        backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.lightBackground);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(slivers: slivers),
    );
  }
}
