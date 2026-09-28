import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Talia-specific design tokens that have no slot in Material's [ColorScheme].
///
/// Registered on every [ThemeData] built by `AppTheme`, one instance per
/// brightness (plus [oled]). Widgets read it via `context.tokens` instead of
/// branching on `isDark`, so light, dark and OLED stay consistent by
/// construction.
@immutable
class TaliaTokens extends ThemeExtension<TaliaTokens> {
  const TaliaTokens({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.accent,
    required this.gold,
    required this.goldSoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.glassBorder,
    required this.shadow,
    required this.readingSurface,
    required this.heroGradient,
    required this.primaryGradient,
    required this.goldGradient,
    required this.glassGradient,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  /// Brand teal tuned for the current brightness (== `colorScheme.primary`).
  final Color accent;
  final Color gold;

  /// Low-emphasis gold for tinted backgrounds and badges.
  final Color goldSoft;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color glassBorder;
  final Color shadow;

  /// Parchment surface behind reading content (not the Mushaf page itself).
  final Color readingSurface;
  final LinearGradient heroGradient;
  final LinearGradient primaryGradient;
  final LinearGradient goldGradient;
  final LinearGradient glassGradient;

  static const light = TaliaTokens(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceVariant: AppColors.lightSurfaceVariant,
    card: AppColors.lightCard,
    divider: AppColors.lightDivider,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textHint: AppColors.lightTextHint,
    accent: AppColors.primary,
    gold: AppColors.goldDark,
    goldSoft: Color(0x1FF59E0B),
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    glassBorder: AppColors.glassBorderLight,
    shadow: AppColors.shadowMedium,
    readingSurface: AppColors.parchmentLight,
    heroGradient: AppColors.heroGradientLight,
    primaryGradient: AppColors.primaryGradient,
    goldGradient: AppColors.goldGradient,
    glassGradient: AppColors.surfaceGlassLight,
  );

  static const dark = TaliaTokens(
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: AppColors.darkSurfaceVariant,
    card: AppColors.darkCard,
    divider: AppColors.darkDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    accent: AppColors.primaryLight,
    gold: AppColors.gold,
    goldSoft: Color(0x26F59E0B),
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    glassBorder: AppColors.glassBorderDark,
    shadow: AppColors.shadowDark,
    readingSurface: AppColors.parchmentDark,
    heroGradient: AppColors.heroGradientDark,
    primaryGradient: AppColors.primaryGradient,
    goldGradient: AppColors.goldGradient,
    glassGradient: AppColors.surfaceGlassDark,
  );

  /// Pure-black variant of [dark] for OLED screens.
  static const oled = TaliaTokens(
    background: AppColors.oledBackground,
    surface: AppColors.oledSurface,
    surfaceVariant: AppColors.oledSurfaceVariant,
    card: AppColors.oledCard,
    divider: AppColors.oledDivider,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textHint: AppColors.darkTextHint,
    accent: AppColors.primaryLight,
    gold: AppColors.gold,
    goldSoft: Color(0x26F59E0B),
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    glassBorder: AppColors.glassBorderDark,
    shadow: AppColors.shadowDark,
    readingSurface: AppColors.oledBackground,
    heroGradient: AppColors.heroGradientOled,
    primaryGradient: AppColors.primaryGradient,
    goldGradient: AppColors.goldGradient,
    glassGradient: AppColors.surfaceGlassDark,
  );

  /// Fallback for widgets pumped without `AppTheme` (e.g. bare widget tests).
  static TaliaTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TaliaTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  TaliaTokens copyWith({
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? card,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? accent,
    Color? gold,
    Color? goldSoft,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? glassBorder,
    Color? shadow,
    Color? readingSurface,
    LinearGradient? heroGradient,
    LinearGradient? primaryGradient,
    LinearGradient? goldGradient,
    LinearGradient? glassGradient,
  }) {
    return TaliaTokens(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      card: card ?? this.card,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      accent: accent ?? this.accent,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      glassBorder: glassBorder ?? this.glassBorder,
      shadow: shadow ?? this.shadow,
      readingSurface: readingSurface ?? this.readingSurface,
      heroGradient: heroGradient ?? this.heroGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      goldGradient: goldGradient ?? this.goldGradient,
      glassGradient: glassGradient ?? this.glassGradient,
    );
  }

  @override
  TaliaTokens lerp(TaliaTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    LinearGradient g(LinearGradient a, LinearGradient b) =>
        LinearGradient.lerp(a, b, t)!;
    return TaliaTokens(
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceVariant: c(surfaceVariant, other.surfaceVariant),
      card: c(card, other.card),
      divider: c(divider, other.divider),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textHint: c(textHint, other.textHint),
      accent: c(accent, other.accent),
      gold: c(gold, other.gold),
      goldSoft: c(goldSoft, other.goldSoft),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      error: c(error, other.error),
      info: c(info, other.info),
      glassBorder: c(glassBorder, other.glassBorder),
      shadow: c(shadow, other.shadow),
      readingSurface: c(readingSurface, other.readingSurface),
      heroGradient: g(heroGradient, other.heroGradient),
      primaryGradient: g(primaryGradient, other.primaryGradient),
      goldGradient: g(goldGradient, other.goldGradient),
      glassGradient: g(glassGradient, other.glassGradient),
    );
  }
}

/// Quran/azkar/surah text styles with the current theme's text color applied.
///
/// Features use these instead of `AppTypography.quran*` + a manual
/// `isDark` color. The glyph shaping and sizes are unchanged.
@immutable
class TaliaTextStyles {
  const TaliaTextStyles(this._tokens);

  final TaliaTokens _tokens;

  TextStyle get quranLarge =>
      AppTypography.quranLarge.copyWith(color: _tokens.textPrimary);
  TextStyle get quranMedium =>
      AppTypography.quranMedium.copyWith(color: _tokens.textPrimary);
  TextStyle get quranSmall =>
      AppTypography.quranSmall.copyWith(color: _tokens.textPrimary);
  TextStyle get quranVerse =>
      AppTypography.quranVerse.copyWith(color: _tokens.textPrimary);
  TextStyle get quranHeader =>
      AppTypography.quranHeader.copyWith(color: _tokens.textPrimary);
  TextStyle get surahTitle =>
      AppTypography.surahTitle.copyWith(color: _tokens.textPrimary);
  TextStyle get azkarText =>
      AppTypography.azkarText.copyWith(color: _tokens.textPrimary);

  /// Large decorative numerals (streak counts, completion scores). The only
  /// sanctioned size above `displayLarge`.
  TextStyle get heroNumber => AppTypography.displayLarge.copyWith(
    fontSize: 72,
    height: 1.0,
    color: _tokens.textPrimary,
  );
}
