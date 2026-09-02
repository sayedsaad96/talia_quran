import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SettingsSection extends StatefulWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.accentColor,
    this.icon,
    this.subtitle,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final String title;
  final List<Widget> children;
  final Color? accentColor;
  final IconData? icon;
  final String? subtitle;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  State<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<SettingsSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.collapsible || widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = (isDark ? AppColors.darkDivider : AppColors.lightDivider)
        .withValues(alpha: isDark ? 0.55 : 0.8);
    final accent =
        widget.accentColor ??
        (isDark ? AppColors.primaryLight : AppColors.primary);
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subtextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Material(
      color: surface,
      elevation: isDark ? 0 : 1,
      shadowColor: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: border, width: 0.7),
        ),
        child: Column(
          children: [
            Semantics(
              button: widget.collapsible,
              expanded: widget.collapsible ? _isExpanded : null,
              child: InkWell(
                onTap: widget.collapsible
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.16 : 0.09),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Icon(
                          widget.icon ?? Icons.tune_rounded,
                          size: 21,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: AppTypography.titleMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.subtitle case final subtitle?) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.collapsible)
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: subtextColor,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      children: [
                        Divider(height: 1, thickness: 0.7, color: border),
                        ...widget.children,
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsAdaptiveGrid extends StatelessWidget {
  const SettingsAdaptiveGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final usesTwoColumns = constraints.maxWidth >= 760;

        if (!usesTwoColumns) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) const SizedBox(height: gap),
              ],
            ],
          );
        }

        final itemWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, required this.isDark, this.indent = 56});

  final bool isDark;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      thickness: 0.5,
      color: (isDark ? AppColors.darkDivider : AppColors.lightDivider)
          .withValues(alpha: 0.6),
      indent: indent,
    );
  }
}

class SettingsTrailingChevron extends StatelessWidget {
  const SettingsTrailingChevron({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Directionality.of(context) == TextDirection.rtl
          ? Icons.arrow_back_ios_rounded
          : Icons.arrow_forward_ios_rounded,
      size: 14,
      color: color,
    );
  }
}

class SettingsInlineHeader extends StatelessWidget {
  const SettingsInlineHeader({
    super.key,
    required this.isDark,
    required this.icon,
    required this.title,
  });

  final bool isDark;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final iconColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
