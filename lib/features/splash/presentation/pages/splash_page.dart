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

  static const Duration _minDisplayDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    final stopwatch = Stopwatch()..start();

    if (AppInitializer.isInitialized) {
      // Already initialized (e.g. hot restart / returning) — display for minimum duration.
      await Future.delayed(_minDisplayDuration);
      if (mounted) {
        _navigateToNextScreen();
      }
      return;
    }

    try {
      await AppInitializer.initialize();

      // Ensure splash screen remains visible for at least _minDisplayDuration
      // so users can comfortably appreciate the serene branding and animations.
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minDisplayDuration) {
        await Future.delayed(_minDisplayDuration - elapsed);
      }

      // Signal to TaliaApp that initialization is complete so it can rebuild
      // into the full BlocProvider tree and GoRouter without navigation race conditions.
      if (mounted) {
        appInitializedNotifier.value = true;
      }
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
    // Honor the system "remove animations" accessibility setting.
    final animate = !MediaQuery.disableAnimationsOf(context);
    // Align background with deep nocturnal palette to prevent any bright visual flash
    const background = Color(0xFF030D09);
    const primary = Color(0xFF5CD2A5);
    const subTextColor = Color(0xFFD4E0D9);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Serene vertical mosque background
          Positioned.fill(
            child: Image.asset(
              'assets/images/mosque_bg_vertical.jpg',
              fit: BoxFit.cover,
              cacheWidth: 1080,
              alignment: Alignment.center,
            ),
          ),
          // Subtle atmospheric overlay ensuring smooth legibility and depth
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.40),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Center brand identity
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),
                    // Dedicated hero emblem with soft ambient breathing aura
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withValues(alpha: 0.12),
                              ),
                            )
                            .animate(
                              onPlay: (c) {
                                if (!animate) c.value = 0;
                              },
                            )
                            .scaleXY(
                              begin: 0.94,
                              end: 1.12,
                              duration: animate ? 2400.ms : Duration.zero,
                              curve: Curves.easeInOutSine,
                            )
                            .fadeIn(duration: animate ? 800.ms : Duration.zero),
                        Image.asset(
                              'assets/images/splash_hero.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            )
                            .animate()
                            .fadeIn(
                              duration: animate ? 700.ms : Duration.zero,
                              curve: Curves.easeOutCubic,
                            )
                            .scaleXY(
                              begin: 0.90,
                              end: 1.0,
                              duration: animate ? 700.ms : Duration.zero,
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Poetic Brand Tagline (always in Arabic)
                    Text(
                          'رفيقك في رحاب القرآن',
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium.copyWith(
                            color: const Color(0xFFEAEAEA),
                            fontFamily: 'Amiri',
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.65),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        )
                        .animate(delay: animate ? 250.ms : Duration.zero)
                        .fadeIn(
                          duration: animate ? 700.ms : Duration.zero,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.12,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),
                    const Spacer(flex: 3),
                    // Serene quiet indicator or error retry
                    if (_initError) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071B14).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.splashInitError,
                              style: AppTypography.bodySmall.copyWith(
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _initError = false);
                                _runInitialization();
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(context.l10n.retryLabel),
                              style: TextButton.styleFrom(
                                foregroundColor: primary,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                        duration: animate ? 300.ms : Duration.zero,
                      ),
                    ] else ...[
                      // Gentle, radiant breathing pulse dot
                      Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.85),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          )
                          .animate(
                            onPlay: (c) {
                              if (!animate) c.value = 1;
                            },
                          )
                          .scaleXY(
                            begin: 0.8,
                            end: 1.4,
                            duration: animate ? 1400.ms : Duration.zero,
                            curve: Curves.easeInOutSine,
                          )
                          .fade(
                            begin: 0.3,
                            end: 0.9,
                            duration: animate ? 1400.ms : Duration.zero,
                          ),
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
