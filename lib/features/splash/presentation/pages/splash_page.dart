import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app.dart' show appInitializedNotifier;
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_initializer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';

/// Serene, brand-first splash screen for Talia.
///
/// Designed as a dignified entrance into the Quran companion experience,
/// avoiding technical loading bars, step percentages, or internal system descriptions.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    if (AppInitializer.isInitialized) {
      // Already initialized (e.g. hot restart / returning) — route smoothly after frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToNextScreen();
      });
      return;
    }

    try {
      await AppInitializer.initialize();

      // Signal to TaliaApp that initialization is complete so it can rebuild
      // into the full BlocProvider tree and GoRouter without navigation race conditions.
      appInitializedNotifier.value = true;
    } catch (error, stack) {
      TaliaLogger.e('Splash initialization failed', error, stack);
      if (mounted) {
        setState(() {
          _initError = true;
        });
      }
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final prefs = getIt<SharedPreferences>();
    final isFirstTime = prefs.getBool('isFirstTimeAppOpen') ?? true;
    context.go(isFirstTime ? AppRoutes.onboarding : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    // Align background with Android/iOS native splash (#061811 in dark) to prevent visual flash
    final background = isDark ? const Color(0xFF061811) : AppColors.lightBackground;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Subtle ambient backdrop gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    background,
                    isDark ? const Color(0xFF0D251F) : const Color(0xFFF4F7F4),
                    background,
                  ],
                ),
              ),
            ),
          ),
          // Center brand identity
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    // Logo with soft ambient breathing aura
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primary.withValues(alpha: isDark ? 0.08 : 0.05),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 0.95, end: 1.15, duration: 2400.ms, curve: Curves.easeInOutSine)
                            .fadeIn(duration: 800.ms),
                        Image.asset(
                          'assets/images/logo_new_padded.png',
                          width: 110,
                          height: 110,
                        )
                            .animate()
                            .fadeIn(duration: 700.ms, curve: Curves.easeOutCubic)
                            .scaleXY(begin: 0.88, end: 1.0, duration: 700.ms, curve: Curves.easeOutCubic),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Brand Name (Amiri Calligraphy)
                    Text(
                      'تالية',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium.copyWith(
                        color: textColor,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w800,
                        fontSize: 38,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: AppSpacing.xs),
                    // Tagline
                    Text(
                      'رفيقك في رحاب القرآن',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: isDark ? AppColors.goldLight : primary,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    const Spacer(flex: 3),
                    // Serene quiet indicator or error retry
                    if (_initError) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'تعذر إكمال التحميل، يرجى المحاولة ثانية',
                              style: AppTypography.bodySmall.copyWith(color: subTextColor),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _initError = false);
                                _runInitialization();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('إعادة المحاولة'),
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ] else ...[
                      // Gentle, non-technical breathing glow dot
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppColors.goldLight : primary).withValues(alpha: 0.6),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.8, end: 1.5, duration: 1200.ms, curve: Curves.easeInOutSine)
                          .fade(begin: 0.2, end: 0.8, duration: 1200.ms),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
