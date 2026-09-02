import 'package:flutter/material.dart';

import 'share_card_widgets.dart';
import 'social_share_copy.dart';
import 'social_share_model.dart';
import 'social_share_theme.dart';
import 'talia_share_tokens.dart';

/// Unified Luxury Islamic Shell for all Talia Share Cards.
///
/// Visual language (recreated from the reference, fully vector):
///  * a deep emerald night sky with a deterministic star field, a soft
///    crescent moon and hanging gold lanterns (dark palettes);
///  * a tall gold-outlined mihrab arch framing the dynamic hero content;
///  * a curved parchment footer whose keyline arcs up to a star medallion
///    holding the official logo.
class ShareCardShell extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;
  final double width;
  final Widget child;
  final SocialShareCopy copy;

  const ShareCardShell({
    super.key,
    required this.data,
    required this.theme,
    required this.format,
    required this.child,
    required this.copy,
    this.width = TaliaShareDimensions.baseWidth,
  });

  double get _aspectRatio => TaliaShareDimensions.aspectRatioFor(format);

  EdgeInsets get _contentPadding {
    switch (format) {
      case SocialShareFormat.square:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case SocialShareFormat.portrait:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 13);
      case SocialShareFormat.story:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 22);
    }
  }

  bool get _isKids => data.audience == SocialShareAudience.kids;

  bool get _usesCharacterHero =>
      _isKids &&
      data.showCharacter &&
      data.category != SocialShareCategory.quranAyah &&
      data.category != SocialShareCategory.dua &&
      data.category != SocialShareCategory.azkar;

  /// Text-hero categories keep the arch interior calm and illuminated;
  /// celebratory/stat categories get the atmospheric scene.
  bool get _warmArchInterior =>
      data.category == SocialShareCategory.quranAyah ||
      data.category == SocialShareCategory.dua ||
      data.category == SocialShareCategory.azkar;

  @override
  Widget build(BuildContext context) {
    // Cards are exported offscreen where ambient Directionality is not
    // guaranteed; pinning it to the localized copy direction keeps the
    // preview and the exported PNG identical for both locales.
    return Directionality(
      textDirection: copy.direction,
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.backgroundGradient,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: theme.borderColor, width: 1.25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: theme.accentColor.withValues(alpha: 0.15),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // ─── 1. Atmosphere: star field / geometric pattern ─────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: theme.isDark
                        ? StarFieldPainter(
                            color: TaliaShareColors.starlight,
                            sparkleColor: TaliaShareColors.starlightWarm,
                            cellSize: _isKids ? 40 : 48,
                            opacity: theme.isDark ? 1 : 0.35,
                            seed: 11,
                          )
                        : IslamicOctagramPainter(
                            color: theme.patternColor,
                            density: 72,
                          ),
                  ),
                ),

                // ─── 1b. Category-specific secondary pattern overlay ───────
                // Each content category gets its own subtle geometric
                // language so every card feels visually distinct.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _categoryPattern(data.category, theme),
                  ),
                ),

                // ─── 2. Ambient radial glow behind the arch ────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 0.9,
                        colors: [theme.glowColor, Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Kids cards get an extra warm halo so they read friendlier
                // than the adult variants without leaving the brand palette.
                if (_isKids)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.2, 0.75),
                          radius: 0.9,
                          colors: [
                            TaliaShareColors.glowGold.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                // ─── 3. Night sky ornaments (dark palettes only) ───────────
                if (theme.isDark) ...[
                  const Positioned(
                    top: 58,
                    right: 27,
                    child: CustomPaint(
                      size: Size(22, 22),
                      painter: CrescentMoonPainter(
                        color: TaliaShareColors.moonCream,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 20,
                    child: CustomPaint(
                      size: const Size(26, 50),
                      painter: HangingLanternPainter(
                        gold: theme.accentColor,
                        glow: TaliaShareColors.lanternGlow,
                        lineFraction: 0.52,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 54,
                    child: CustomPaint(
                      size: const Size(18, 38),
                      painter: HangingLanternPainter(
                        gold: theme.accentColor.withValues(alpha: 0.8),
                        glow: TaliaShareColors.lanternGlow,
                        lineFraction: 0.3,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 56,
                    child: CustomPaint(
                      size: const Size(18, 38),
                      painter: HangingLanternPainter(
                        gold: theme.accentColor.withValues(alpha: 0.8),
                        glow: TaliaShareColors.lanternGlow,
                        lineFraction: 0.34,
                      ),
                    ),
                  ),
                ],

                // Kids sparkle accents, kept near the card corners so they
                // decorate without competing with the content hierarchy.
                if (_isKids) ..._kidsSparkles(),

                // ─── 4. Golden corner arabesques ───────────────────────────
                Positioned(
                  top: 9,
                  left: 9,
                  child: CustomPaint(
                    size: const Size(30, 30),
                    painter: GoldenCornerPainter(color: theme.accentColor),
                  ),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Transform.scale(
                    scaleX: -1,
                    child: CustomPaint(
                      size: const Size(30, 30),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 9,
                  left: 9,
                  child: Transform.scale(
                    scaleY: -1,
                    child: CustomPaint(
                      size: const Size(30, 30),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 9,
                  right: 9,
                  child: Transform.scale(
                    scaleX: -1,
                    scaleY: -1,
                    child: CustomPaint(
                      size: const Size(30, 30),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),

                // ─── 5. Main card content body ─────────────────────────────
                Padding(
                  padding: _contentPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TaliaShareBrandHeader(
                        theme: theme,
                        badgeText: data.badgeText,
                        category: data.category,
                        copy: copy,
                        isCompact: format == SocialShareFormat.square,
                        isKids: _isKids,
                      ),

                      // The arch is the single visual frame for dynamic
                      // content: each template keeps its own identity inside.
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: format == SocialShareFormat.square
                                ? 5
                                : 9,
                          ),
                          child: IslamicHeroArch(
                            theme: theme,
                            kidsMode: _isKids,
                            warmInterior: _warmArchInterior,
                            showScene:
                                !_warmArchInterior && !_usesCharacterHero,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    format == SocialShareFormat.square
                                        ? 18
                                        : 24,
                                    format == SocialShareFormat.story ? 36 : 26,
                                    _usesCharacterHero
                                        ? (format == SocialShareFormat.story
                                              ? 132
                                              : 118)
                                        : (format == SocialShareFormat.square
                                              ? 18
                                              : 24),
                                    format == SocialShareFormat.story ? 24 : 18,
                                  ),
                                  child: Center(child: child),
                                ),
                                if (_usesCharacterHero)
                                  Positioned(
                                    right: format == SocialShareFormat.square
                                        ? -2
                                        : 2,
                                    bottom: format == SocialShareFormat.story
                                        ? 2
                                        : -3,
                                    child: TaliaCharacterHero(
                                      key: const ValueKey(
                                        'share-character-image',
                                      ),
                                      assetPath:
                                          data.effectiveCharacterAssetPath,
                                      height: format == SocialShareFormat.story
                                          ? 230
                                          : format == SocialShareFormat.square
                                          ? 128
                                          : 174,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      ParchmentShareFooter(
                        theme: theme,
                        userName: data.userName,
                        copy: copy,
                        isCompact: format == SocialShareFormat.square,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _kidsSparkles() {
    return const [
      Positioned(
        top: 36,
        left: 17,
        child: Icon(
          Icons.star_rounded,
          color: TaliaShareColors.kidsStarGold,
          size: 16,
        ),
      ),
      Positioned(
        top: 84,
        right: 22,
        child: Icon(
          Icons.auto_awesome_rounded,
          color: TaliaShareColors.kidsSparkleTeal,
          size: 13,
        ),
      ),
      Positioned(
        bottom: 52,
        right: 18,
        child: Icon(
          Icons.star_rounded,
          color: TaliaShareColors.kidsSparkleTeal,
          size: 14,
        ),
      ),
    ];
  }

  /// Routes each content category to its own characteristic secondary pattern.
  ///
  /// These faint overlays live between the base atmosphere layer and the main
  /// card content so they contribute texture without ever competing with text.
  static CustomPainter _categoryPattern(
    SocialShareCategory category,
    SocialShareTheme theme,
  ) {
    switch (category) {
      // Quran, dua, and dhikr: calligraphic border arches along all edges —
      // contemplative, manuscript-inspired, keeps the typographic focus.
      case SocialShareCategory.quranAyah:
      case SocialShareCategory.dua:
      case SocialShareCategory.azkar:
        return CalligraphyBorderPainter(
          color: theme.accentColor,
          opacity: theme.isDark ? 0.09 : 0.07,
        );

      // Achievement and memorization: hexagonal honeycomb —
      // evokes structure, persistence, and the reward of mastery.
      case SocialShareCategory.achievement:
      case SocialShareCategory.memorization:
        return HexagonalTessellationPainter(
          color: theme.accentColor,
          opacity: theme.isDark ? 0.08 : 0.06,
        );

      // Certificates: geometric rosette — formal, distinguished,
      // classic in Islamic illuminated manuscripts.
      case SocialShareCategory.certificate:
      case SocialShareCategory.khatmah:
        return GeometricRosettePainter(
          color: theme.accentColor,
          opacity: theme.isDark ? 0.1 : 0.08,
        );

      // Streak and progress: the base octagram/star field is already
      // energetic — use the calligraphy border for a subtle accent.
      case SocialShareCategory.streak:
      case SocialShareCategory.progress:
        return CalligraphyBorderPainter(
          color: theme.accentColor,
          opacity: theme.isDark ? 0.07 : 0.05,
        );
    }
  }
}

/// Official top brand block: logo in a gold ring, wordmark + tagline, and
/// the content-type badge. Centered like the reference composition.
class TaliaShareBrandHeader extends StatelessWidget {
  final SocialShareTheme theme;
  final String badgeText;
  final SocialShareCategory category;
  final bool isCompact;
  final SocialShareCopy copy;
  final bool isKids;

  const TaliaShareBrandHeader({
    super.key,
    required this.theme,
    required this.badgeText,
    required this.category,
    required this.copy,
    required this.isKids,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final localizedBadge = badgeText.isNotEmpty
        ? badgeText
        : copy.localizedBadge(category);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Official Talia app logo in a gold ring.
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor.withValues(alpha: 0.0),
                    theme.accentColor.withValues(alpha: 0.28),
                  ],
                ),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 9,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_new.png',
                  width: isCompact ? 28 : 34,
                  height: isCompact ? 28 : 34,
                  fit: BoxFit.cover,
                  // The bundled logo is 2090x2090; decode it near display
                  // resolution instead of wasting memory per card render.
                  cacheWidth: 108,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.accentColor,
                    size: isCompact ? 18 : 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.appName,
                  style: TaliaShareTypography.title(
                    color: theme.accentColor,
                    fontSize: isCompact ? 18 : 21,
                  ),
                ),
                Text(
                  isKids ? copy.kidsLabel : copy.tagline,
                  style: TaliaShareTypography.badge(
                    color: theme.textSecondary.withValues(alpha: 0.9),
                    fontSize: isCompact ? 8 : 9,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isCompact ? 4 : 6),
        // Content-type badge with a gold keyline.
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 11 : 14,
            vertical: isCompact ? 2.5 : 3.5,
          ),
          decoration: BoxDecoration(
            color: theme.badgeBackground,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                size: isCompact ? 12 : 13.5,
                color: theme.badgeTextColor,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  localizedBadge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TaliaShareTypography.badge(
                    color: theme.badgeTextColor,
                    fontSize: isCompact ? 10.5 : 11.5,
                  ),
                ),
              ),
              if (isKids) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  size: 11,
                  color: TaliaShareColors.kidsStarGold,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Premium curved parchment signature shared by every card format.
///
/// The panel's top edge arcs upward like the reference's cream section and
/// carries a gold keyline; the apex is crowned by an eight-point star
/// medallion holding the official logo. The lower lines turn every exported
/// image into a quiet product invitation: the memorization loop and a stable
/// landing-page address remain readable even after social-media compression.
class ParchmentShareFooter extends StatelessWidget {
  final SocialShareTheme theme;
  final String? userName;
  final bool isCompact;
  final SocialShareCopy copy;

  const ParchmentShareFooter({
    super.key,
    required this.theme,
    this.userName,
    required this.copy,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final curve = isCompact ? 14.0 : 17.0;
    final medallion = isCompact ? 24.0 : 28.0;
    return Stack(
      key: const ValueKey('share-parchment-footer'),
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          painter: _ParchmentCurvePainter(
            gold: theme.borderColor,
            curveDepth: curve,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 12 : 16,
              curve + 3,
              isCompact ? 12 : 16,
              isCompact ? 6 : 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userName != null && userName!.isNotEmpty) ...[
                  Text(
                    copy.journeyFor(userName!),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TaliaShareTypography.title(
                      color: TaliaShareColors.parchmentInk,
                      fontSize: isCompact ? 10.5 : 11.5,
                    ),
                  ),
                  SizedBox(height: isCompact ? 1 : 2),
                ],
                Text(
                  isCompact ? copy.compactBrandPromise : copy.brandPromise,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TaliaShareTypography.badge(
                    color: TaliaShareColors.parchmentInk,
                    fontSize: isCompact ? 7.5 : 9.5,
                  ),
                ),
                SizedBox(height: isCompact ? 3 : 4),
                // ─── Marketing CTA pill — replaces plain domain text ────────
                // This converts every shared card into an app install driver.
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 9 : 12,
                    vertical: isCompact ? 2.5 : 3.5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TaliaShareColors.royalTeal.withValues(alpha: 0.25),
                        TaliaShareColors.royalTealLight.withValues(alpha: 0.18),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: TaliaShareColors.parchmentInk.withValues(alpha: 0.18),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        color: TaliaShareColors.parchmentInk,
                        size: isCompact ? 8 : 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCompact ? copy.downloadCTAShort : copy.downloadCTA,
                        textDirection: TextDirection.ltr,
                        style: TaliaShareTypography.badge(
                          color: TaliaShareColors.parchmentInk,
                          fontSize: isCompact ? 7 : 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      // Subtle separator dot.
                      Container(
                        width: 2.5,
                        height: 2.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TaliaShareColors.parchmentInk.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        copy.appDomain,
                        textDirection: TextDirection.ltr,
                        style: TaliaShareTypography.badge(
                          color: TaliaShareColors.parchmentInkSoft,
                          fontSize: isCompact ? 6.5 : 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Star medallion crowning the curve apex with the official logo.
        Transform.translate(
          offset: Offset(0, curve * 0.4 - medallion / 2),
          child: SizedBox(
            width: medallion,
            height: medallion,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ShareStarOrnament(color: theme.borderColor, size: medallion),
                Container(
                  width: medallion * 0.58,
                  height: medallion * 0.58,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A3932),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_new.png',
                      fit: BoxFit.cover,
                      cacheWidth: 66,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.auto_awesome_rounded,
                        size: isCompact ? 9 : 10,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Draws the parchment panel: an upward top arc with a gold keyline and
/// softly rounded bottom corners that echo the card frame.
class _ParchmentCurvePainter extends CustomPainter {
  final Color gold;
  final double curveDepth;

  const _ParchmentCurvePainter({required this.gold, required this.curveDepth});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const bottomRadius = 14.0;

    final panel = Path()
      ..moveTo(0, curveDepth)
      ..quadraticBezierTo(w * 0.5, -curveDepth * 0.55, w, curveDepth)
      ..lineTo(w, h - bottomRadius)
      ..quadraticBezierTo(w, h, w - bottomRadius, h)
      ..lineTo(bottomRadius, h)
      ..quadraticBezierTo(0, h, 0, h - bottomRadius)
      ..close();

    // Soft warm parchment with a gentle vertical gradient.
    canvas.drawPath(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDF8EA), Color(0xFFFBF4E4)],
        ).createShader(Offset.zero & size),
    );

    // Gold keyline follows the arc and the panel outline.
    canvas.drawPath(
      panel,
      Paint()
        ..color = gold.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // A second, fainter arc slightly below the keyline for depth.
    final echo = Path()
      ..moveTo(10, curveDepth + 6)
      ..quadraticBezierTo(
        w * 0.5,
        -curveDepth * 0.1 + 6,
        w - 10,
        curveDepth + 6,
      );
    canvas.drawPath(
      echo,
      Paint()
        ..color = gold.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Tiny botanical accents at the panel's upper corners.
    const sprig = BotanicalSprigPainter(color: TaliaShareColors.lanternAmber);
    canvas.save();
    canvas.translate(w * 0.035, curveDepth - 2);
    sprig.paint(canvas, const Size(16, 18));
    canvas.restore();
    canvas.save();
    canvas.translate(w - w * 0.035, curveDepth - 2);
    canvas.scale(-1, 1);
    sprig.paint(canvas, const Size(16, 18));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParchmentCurvePainter oldDelegate) =>
      oldDelegate.gold != gold || oldDelegate.curveDepth != curveDepth;
}

/// Reusable mihrab-like hero frame shared by every dynamic card template.
class IslamicHeroArch extends StatelessWidget {
  final SocialShareTheme theme;
  final bool kidsMode;
  final Widget child;

  /// Text-hero categories (Quran, dua, dhikr) get a calm illuminated
  /// interior instead of the scenic mosque silhouette.
  final bool warmInterior;

  /// Whether to paint the atmospheric scene (skyline + hanging lamp).
  final bool showScene;

  const IslamicHeroArch({
    super.key,
    required this.theme,
    required this.kidsMode,
    required this.child,
    this.warmInterior = false,
    this.showScene = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        key: const ValueKey('islamic-hero-arch'),
        painter: _IslamicHeroArchPainter(
          gold: theme.accentColor,
          fill: theme.cardBackground,
          glow: theme.glowColor,
          playful: kidsMode,
          warmInterior: warmInterior,
          showScene: showScene,
        ),
        child: child,
      ),
    );
  }
}

/// The official companion asset, framed as part of the kids hero rather than
/// a detached illustration. It is deliberately absent from adult cards.
class TaliaCharacterHero extends StatelessWidget {
  final String assetPath;
  final double height;

  const TaliaCharacterHero({
    super.key,
    required this.assetPath,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Warm ground glow anchors the character into the arch scene.
          Positioned(
            bottom: 2,
            child: Container(
              width: height * 0.66,
              height: 16,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.all(Radius.elliptical(44, 8)),
                gradient: RadialGradient(
                  colors: [
                    TaliaShareColors.lanternGlow.withValues(alpha: 0.4),
                    TaliaShareColors.lanternGlow.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Image.asset(
            key: const ValueKey('share-hero-character'),
            assetPath,
            // The official companion art is square; pinning both axes keeps
            // the layout correct even before the codec reports intrinsic
            // dimensions (e.g. in offscreen export renders).
            width: height,
            height: height,
            fit: BoxFit.contain,
            cacheWidth: 540,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _IslamicHeroArchPainter extends CustomPainter {
  final Color gold;
  final Color fill;
  final Color glow;
  final bool playful;
  final bool warmInterior;
  final bool showScene;

  const _IslamicHeroArchPainter({
    required this.gold,
    required this.fill,
    required this.glow,
    required this.playful,
    required this.warmInterior,
    required this.showScene,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.045;
    final top = size.height * 0.03;
    final bottom = size.height * 0.985;
    final shoulder = size.height * 0.24;

    Path archPath(double inset, double top, double shoulder) => Path()
      ..moveTo(inset, bottom)
      ..lineTo(inset, shoulder)
      ..cubicTo(
        inset,
        top + size.height * 0.06,
        size.width * 0.3,
        top,
        size.width / 2,
        top,
      )
      ..cubicTo(
        size.width * 0.7,
        top,
        size.width - inset,
        top + size.height * 0.06,
        size.width - inset,
        shoulder,
      )
      ..lineTo(size.width - inset, bottom)
      ..close();

    final arch = archPath(inset, top, shoulder);

    // Interior wash: warm illumination for text heroes, atmospheric glow
    // for celebratory/stat cards.
    final interior = warmInterior
        ? [glow.withValues(alpha: 0.6), fill.withValues(alpha: 0.3)]
        : [glow.withValues(alpha: 0.72), fill.withValues(alpha: 0.46)];
    canvas.drawPath(
      arch,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: interior,
        ).createShader(Offset.zero & size),
    );

    if (showScene && !warmInterior) {
      _paintSkyline(canvas, size, gold);
      _paintApexLamp(canvas, size, top);
    }

    if (warmInterior) {
      // Soft light rays falling from the apex onto the verse.
      final ray = Paint()
        ..color = gold.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      for (final spread in [0.16, 0.3]) {
        final rays = Path()
          ..moveTo(size.width / 2, top + 6)
          ..lineTo(size.width / 2 - size.width * spread, bottom)
          ..lineTo(size.width / 2 + size.width * spread, bottom)
          ..close();
        canvas.drawPath(rays, ray);
      }
    }

    // Double gold outline: strong outer keyline + faint inner echo.
    canvas.drawPath(
      arch,
      Paint()
        ..color = gold.withValues(alpha: 0.88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.5);
    canvas.scale(0.94, 0.965);
    canvas.translate(-size.width / 2, -size.height * 0.5);
    canvas.drawPath(
      arch,
      Paint()
        ..color = gold.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    canvas.restore();

    // Botanical sprigs at the arch base.
    const sprig = BotanicalSprigPainter(color: TaliaShareColors.lanternAmber);
    canvas.save();
    canvas.translate(inset + 2, bottom - 34);
    sprig.paint(canvas, const Size(18, 30));
    canvas.restore();
    canvas.save();
    canvas.translate(size.width - inset - 2, bottom - 34);
    canvas.scale(-1, 1);
    sprig.paint(canvas, const Size(18, 30));
    canvas.restore();

    if (playful) {
      final sparkle = Paint()..color = gold.withValues(alpha: 0.75);
      for (final point in [
        Offset(size.width * .16, size.height * .2),
        Offset(size.width * .84, size.height * .32),
        Offset(size.width * .2, size.height * .74),
      ]) {
        canvas.drawCircle(point, 2.2, sparkle);
      }
    }
  }

  /// Quiet mosque skyline keeps the atmospheric reference language without
  /// competing with card data.
  void _paintSkyline(Canvas canvas, Size size, Color gold) {
    final silhouette = Paint()
      ..color = gold.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final ground = size.height * 0.85;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .19,
        ground,
        size.width * .62,
        size.height * .05,
      ),
      silhouette,
    );
    // Central dome.
    final dome = Path()
      ..moveTo(size.width * .38, ground)
      ..quadraticBezierTo(
        size.width * .5,
        ground - size.height * .1,
        size.width * .62,
        ground,
      )
      ..close();
    canvas.drawPath(dome, silhouette);
    canvas.drawCircle(
      Offset(size.width * .5, ground - size.height * .1),
      1.4,
      silhouette..color = gold.withValues(alpha: 0.3),
    );
    // Minarets.
    for (final mx in [.24, .76]) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * mx - size.width * .018,
          size.height * .44,
          size.width * .036,
          ground - size.height * .44,
        ),
        silhouette,
      );
      canvas.drawCircle(
        Offset(size.width * mx, size.height * .43),
        size.width * .03,
        silhouette,
      );
    }
  }

  /// A tiny lamp hanging from the arch apex.
  void _paintApexLamp(Canvas canvas, Size size, double top) {
    final gold = this.gold.withValues(alpha: 0.55);
    final line = Paint()
      ..color = gold
      ..strokeWidth = 0.8;
    final cx = size.width / 2;
    final stringEnd = top + size.height * 0.1;
    canvas.drawLine(Offset(cx, top + 4), Offset(cx, stringEnd), line);
    final glowCenter = Offset(cx, stringEnd + 5);
    canvas.drawCircle(
      glowCenter,
      6,
      Paint()..color = TaliaShareColors.lanternGlow.withValues(alpha: 0.2),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: glowCenter, width: 5.5, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = gold,
    );
  }

  @override
  bool shouldRepaint(covariant _IslamicHeroArchPainter old) =>
      old.gold != gold ||
      old.fill != fill ||
      old.glow != glow ||
      old.playful != playful ||
      old.warmInterior != warmInterior ||
      old.showScene != showScene;
}
