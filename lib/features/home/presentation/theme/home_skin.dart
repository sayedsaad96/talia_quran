import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Visual tokens for the Home surface. Light and dark share layout; only
/// materials, scrims, and type colors change.
///
/// The mosque photo lives in one place only: the header banner. Because that
/// banner is dark in both themes, everything drawn on top of it uses the
/// `onHero` colors rather than the theme's text colors.
class HomeSkin {
  const HomeSkin({
    required this.isDark,
    required this.scaffold,
    required this.ambientGlow,
    required this.heroVeil,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnHero,
    required this.textOnHeroMuted,
    required this.onHeroFill,
    required this.onHeroBorder,
    required this.accent,
    required this.gold,
    required this.progressTrack,
    required this.heroGradient,
    required this.shadow,
  });

  final bool isDark;
  final Color scaffold;

  /// Soft gold halo painted behind the top of the page.
  final Color ambientGlow;

  /// Darkening veil over the mosque photo so header text stays legible.
  final LinearGradient heroVeil;

  final Color glassFill;
  final Color glassBorder;
  final Color glassHighlight;
  final Color textPrimary;
  final Color textSecondary;

  /// Text drawn on the mosque banner or the emerald continue card.
  final Color textOnHero;
  final Color textOnHeroMuted;

  /// Chip/avatar materials drawn on the mosque banner.
  final Color onHeroFill;
  final Color onHeroBorder;

  final Color accent;
  final Color gold;
  final Color progressTrack;
  final LinearGradient heroGradient;
  final List<BoxShadow> shadow;

  static const backgroundAsset = 'assets/images/mosque_bg.png';
  static const logoAsset = 'assets/images/logo_new_padded.png';

  /// Tests and goldens can disable blur so snapshots stay deterministic.
  static bool blurEnabled = true;

  /// The mosque photo is already a dark silhouette, so the veil only needs to
  /// deepen the top (behind the avatar row) and the bottom edge where the
  /// banner meets the page.
  static final LinearGradient _veil = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFF021210).withValues(alpha: 0.62),
      const Color(0xFF021210).withValues(alpha: 0.20),
      const Color(0xFF021210).withValues(alpha: 0.72),
    ],
    stops: const [0.0, 0.45, 1.0],
  );

  factory HomeSkin.forBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return HomeSkin(
        isDark: true,
        scaffold: AppColors.darkBackground,
        ambientGlow: AppColors.gold.withValues(alpha: 0.16),
        heroVeil: _veil,
        glassFill: const Color(0xF00A2925),
        glassBorder: Colors.white.withValues(alpha: 0.10),
        glassHighlight: Colors.white.withValues(alpha: 0.06),
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textOnHero: AppColors.moonlight,
        textOnHeroMuted: AppColors.moonlight.withValues(alpha: 0.74),
        onHeroFill: Colors.white.withValues(alpha: 0.14),
        onHeroBorder: Colors.white.withValues(alpha: 0.22),
        accent: AppColors.primaryLight,
        gold: AppColors.goldLight,
        progressTrack: Colors.white.withValues(alpha: 0.14),
        heroGradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF12655A), Color(0xFF06312B)],
        ),
        shadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );
    }
    return HomeSkin(
      isDark: false,
      scaffold: AppColors.lightBackground,
      ambientGlow: AppColors.gold.withValues(alpha: 0.10),
      heroVeil: _veil,
      glassFill: Colors.white,
      glassBorder: AppColors.primary.withValues(alpha: 0.12),
      glassHighlight: Colors.white.withValues(alpha: 0.7),
      textPrimary: AppColors.lightTextPrimary,
      textSecondary: AppColors.lightTextSecondary,
      textOnHero: AppColors.moonlight,
      textOnHeroMuted: AppColors.moonlight.withValues(alpha: 0.74),
      onHeroFill: Colors.white.withValues(alpha: 0.16),
      onHeroBorder: Colors.white.withValues(alpha: 0.26),
      accent: AppColors.primary,
      gold: AppColors.goldDark,
      progressTrack: AppColors.primary.withValues(alpha: 0.12),
      heroGradient: const LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: [Color(0xFF0D5C53), Color(0xFF06332E)],
      ),
      shadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
