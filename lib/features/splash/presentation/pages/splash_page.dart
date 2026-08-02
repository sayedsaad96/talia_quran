import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_initializer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../../app.dart' show appInitializedNotifier;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;
  String _currentStep = '';
  double _progress = 0.0;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    if (AppInitializer.isInitialized) {
      // Already initialized (e.g. hot restart) — navigate immediately.
      _navigateToNextScreen();
      return;
    }

    try {
      await AppInitializer.initialize(
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _currentStep = step;
              _progress = progress;
            });
          }
        },
      );

      // Signal to TaliaApp that initialization is complete so it can
      // rebuild with the full BlocProvider tree and GoRouter.
      appInitializedNotifier.value = true;

      // Give the framework one frame to rebuild TaliaApp with the full router.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (error, stack) {
      TaliaLogger.e('Splash initialization failed', error, stack);
      if (mounted) {
        setState(() {
          _initError = true;
          _currentStep = 'حدث خطأ أثناء تحميل التطبيق';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  // App logo / icon
                  Image.asset(
                    'assets/images/logo_new_padded.png',
                    width: 120,
                    height: 120,
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, curve: Curves.easeOutBack)
                      .scaleXY(
                          begin: 0.82,
                          end: 1.0,
                          curve: Curves.easeOutBack),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                        'تالية',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium.copyWith(
                          color: textColor,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w800,
                        ),
                      )
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                        'رفيقك في رحاب القرآن',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          color: primary,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                        ),
                      )
                      .animate(delay: 500.ms)
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: AppSpacing.xl + AppSpacing.lg),
                  // Progress indicator
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                          child: LinearProgressIndicator(
                            value: _progress > 0 ? _progress : null,
                            minHeight: 4,
                            backgroundColor:
                                primary.withValues(alpha: 0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primary),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _currentStep,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate(delay: 700.ms)
                      .fadeIn(duration: 400.ms),
                  if (_initError) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _initError = false;
                          _progress = 0;
                          _currentStep = '';
                        });
                        _runInitialization();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('إعادة المحاولة'),
                      style: TextButton.styleFrom(
                        foregroundColor: primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
