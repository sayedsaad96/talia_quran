import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted || _hasNavigated) return;

    final prefs = getIt<SharedPreferences>();
    final isFirstTime = prefs.getBool('isFirstTimeAppOpen') ?? true;
    _hasNavigated = true;

    if (!mounted) return;
    context.go(isFirstTime ? AppRoutes.onboarding : AppRoutes.home);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final textColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final subTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              background,
              isDark ? const Color(0xFF10251F) : const Color(0xFFEAF5EE),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LogoMark(primary: primary, isDark: isDark)
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOutBack)
                      .scaleXY(begin: 0.82, end: 1.0, curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.lg),
                  Column(
                    children: [
                      Text(
                        context.l10n.appName,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium.copyWith(
                          color: textColor,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.l10n.splashSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: subTextColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'رفيقك في رحاب القرآن',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium.copyWith(
                      color: primary,
                      fontFamily: 'Amiri',
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate(delay: 600.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: AppSpacing.xl),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SplashFeatureHint(
                          icon: Icons.menu_book_rounded,
                          label: context.l10n.splashFeatureRead,
                          color: primary,
                        ).animate(delay: 800.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(width: AppSpacing.sm),
                        _SplashFeatureHint(
                          icon: Icons.psychology_alt_rounded,
                          label: context.l10n.splashFeatureMemorize,
                          color: AppColors.gold,
                        ).animate(delay: 900.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(width: AppSpacing.sm),
                        _SplashFeatureHint(
                          icon: Icons.rate_review_rounded,
                          label: context.l10n.splashFeatureReview,
                          color: AppColors.info,
                        ).animate(delay: 1000.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(width: AppSpacing.sm),
                        _SplashFeatureHint(
                          icon: Icons.workspace_premium_rounded,
                          label: context.l10n.splashFeatureGrow,
                          color: AppColors.warning,
                        ).animate(delay: 1100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.primary, required this.isDark});

  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: isDark ? 0.34 : 0.18),
            AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.14),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.28), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.2 : 0.14),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/images/onboarding/splash_new.png',
              width: 72,
              height: 72,
              cacheWidth: 144, // 72 * 2 (for high density screens)
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFeatureHint extends StatelessWidget {
  const _SplashFeatureHint({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
