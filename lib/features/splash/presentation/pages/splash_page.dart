import 'package:flutter/material.dart';
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

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
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
    _controller.dispose();
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
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final logoValue = Curves.easeOutBack.transform(
                    _interval(0.0, 0.48),
                  );
                  final copyValue = Curves.easeOutCubic.transform(
                    _interval(0.22, 0.7),
                  );
                  final sloganValue = Curves.easeOutCubic.transform(
                    _interval(0.35, 0.8),
                  );

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: logoValue.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.82 + (logoValue * 0.18),
                          child: _LogoMark(primary: primary, isDark: isDark),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Opacity(
                        opacity: copyValue.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - copyValue)),
                          child: Column(
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
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Opacity(
                        opacity: sloganValue.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 15 * (1 - sloganValue)),
                          child: Text(
                            'رفيقك في رحاب القرآن',
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: primary,
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SplashFeatureHint(
                              progress: _interval(0.42, 0.72),
                              icon: Icons.menu_book_rounded,
                              label: context.l10n.splashFeatureRead,
                              color: primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SplashFeatureHint(
                              progress: _interval(0.52, 0.82),
                              icon: Icons.psychology_alt_rounded,
                              label: context.l10n.splashFeatureMemorize,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SplashFeatureHint(
                              progress: _interval(0.62, 0.92),
                              icon: Icons.rate_review_rounded,
                              label: context.l10n.splashFeatureReview,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SplashFeatureHint(
                              progress: _interval(0.72, 1.0),
                              icon: Icons.workspace_premium_rounded,
                              label: context.l10n.splashFeatureGrow,
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _interval(double begin, double end) {
    final value = ((_controller.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return value;
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
    required this.progress,
    required this.icon,
    required this.label,
    required this.color,
  });

  final double progress;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);

    return Opacity(
      opacity: eased.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - eased)),
        child: Container(
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
        ),
      ),
    );
  }
}
