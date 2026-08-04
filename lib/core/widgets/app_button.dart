import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, goldPrimary }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final Gradient? gradient;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();
  void _onTapUp(_) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  double get _height => switch (widget.size) {
    AppButtonSize.small => 40,
    AppButtonSize.medium => 48,
    AppButtonSize.large => AppSpacing.buttonHeight,
  };

  EdgeInsets get _padding => switch (widget.size) {
    AppButtonSize.small => const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
    AppButtonSize.medium => const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 12,
    ),
    AppButtonSize.large => const EdgeInsets.symmetric(
      horizontal: 32,
      vertical: 16,
    ),
  };

  TextStyle get _textStyle => switch (widget.size) {
    AppButtonSize.small => AppTypography.labelMedium,
    AppButtonSize.medium => AppTypography.labelLarge,
    AppButtonSize.large => AppTypography.titleMedium,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = !widget.isDisabled && !widget.isLoading;

    return GestureDetector(
      onTapDown: isActive ? _onTapDown : null,
      onTapUp: isActive ? _onTapUp : null,
      onTapCancel: isActive ? _onTapCancel : null,
      onTap: isActive ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.isDisabled ? 0.5 : 1.0,
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _PrimaryButton(
          label: widget.label,
          icon: widget.icon,
          isLoading: widget.isLoading,
          height: _height,
          padding: _padding,
          textStyle: _textStyle,
          width: widget.width,
          gradient: widget.gradient ?? AppColors.primaryGradient,
        );
      case AppButtonVariant.secondary:
        return _SecondaryButton(
          label: widget.label,
          icon: widget.icon,
          isLoading: widget.isLoading,
          height: _height,
          padding: _padding,
          textStyle: _textStyle,
          width: widget.width,
          isDark: isDark,
        );
      case AppButtonVariant.ghost:
        return _GhostButton(
          label: widget.label,
          icon: widget.icon,
          isLoading: widget.isLoading,
          height: _height,
          padding: _padding,
          textStyle: _textStyle,
          width: widget.width,
          isDark: isDark,
        );
      case AppButtonVariant.danger:
        return _PrimaryButton(
          label: widget.label,
          icon: widget.icon,
          isLoading: widget.isLoading,
          height: _height,
          padding: _padding,
          textStyle: _textStyle,
          width: widget.width,
          gradient: const LinearGradient(
            colors: [Color(0xFFC0392B), Color(0xFF922B21)],
          ),
        );
      case AppButtonVariant.goldPrimary:
        return _PrimaryButton(
          label: widget.label,
          icon: widget.icon,
          isLoading: widget.isLoading,
          height: _height,
          padding: _padding,
          textStyle: _textStyle,
          width: widget.width,
          gradient: AppColors.goldGradient,
        );
    }
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.gradient,
    this.icon,
    this.width,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double? width;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textStyle: textStyle.copyWith(color: Colors.white),
        padding: padding,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.isLoading,
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.isDark,
    this.icon,
    this.width,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final bool isDark;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: primary.withValues(alpha: 0.3), width: 1),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textStyle: textStyle.copyWith(color: primary),
        padding: padding,
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.isLoading,
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.isDark,
    this.icon,
    this.width,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final bool isDark;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    return SizedBox(
      width: width,
      height: height,
      child: _ButtonContent(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textStyle: textStyle.copyWith(color: textColor),
        padding: padding,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.textStyle,
    required this.padding,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final TextStyle textStyle;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textStyle.color!),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textStyle.color, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: textStyle),
                ],
              ),
      ),
    );
  }
}
