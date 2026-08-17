import 'package:flutter/material.dart';
import '../../theme/app_typography.dart';
import 'social_share_model.dart';
import 'social_share_copy.dart';
import 'social_share_theme.dart';
import 'talia_share_tokens.dart';

/// Unified Luxury Islamic Shell for all Talia Share Cards
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

  double get _aspectRatio {
    switch (format) {
      case SocialShareFormat.square:
        return TaliaShareDimensions.squareRatio; // 1:1
      case SocialShareFormat.portrait:
        return TaliaShareDimensions.portraitRatio; // 4:5
      case SocialShareFormat.story:
        return TaliaShareDimensions.storyRatio; // 9:16
    }
  }

  EdgeInsets get _contentPadding {
    switch (format) {
      case SocialShareFormat.square:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case SocialShareFormat.portrait:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
      case SocialShareFormat.story:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
    }
  }

  bool get _isKids => data.audience == SocialShareAudience.kids;

  bool get _usesCharacterHero =>
      _isKids &&
      data.showCharacter &&
      data.category != SocialShareCategory.quranAyah &&
      data.category != SocialShareCategory.dua &&
      data.category != SocialShareCategory.azkar;

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
                // ─── 1. Background Islamic Geometric Pattern ──────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: IslamicOctagramPainter(color: theme.patternColor),
                  ),
                ),

                // ─── 2. Top & Center Ambient Radial Glow ──────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.45),
                        radius: 0.85,
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

                // Kids sparkle accents, kept near the card corners so they
                // decorate without competing with the content hierarchy.
                if (_isKids)
                  const Positioned(
                    top: 34,
                    left: 16,
                    child: Icon(
                      Icons.star_rounded,
                      color: TaliaShareColors.kidsStarGold,
                      size: 16,
                    ),
                  ),
                if (_isKids)
                  const Positioned(
                    top: 52,
                    right: 20,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: TaliaShareColors.kidsSparkleTeal,
                      size: 13,
                    ),
                  ),
                if (_isKids)
                  const Positioned(
                    bottom: 46,
                    right: 18,
                    child: Icon(
                      Icons.star_rounded,
                      color: TaliaShareColors.kidsSparkleTeal,
                      size: 14,
                    ),
                  ),

                // ─── 3. Islamic Mihrab Arch Silhouette Overlay ─────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: MihrabArchPainter(
                      color: theme.accentColor.withValues(alpha: 0.14),
                    ),
                  ),
                ),

                // ─── 4. Golden Corner Arabesques (Top & Bottom) ───────────────
                Positioned(
                  top: 10,
                  left: 10,
                  child: CustomPaint(
                    size: const Size(28, 28),
                    painter: GoldenCornerPainter(color: theme.accentColor),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Transform.scale(
                    scaleX: -1,
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Transform.scale(
                    scaleY: -1,
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Transform.scale(
                    scaleX: -1,
                    scaleY: -1,
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: GoldenCornerPainter(color: theme.accentColor),
                    ),
                  ),
                ),

                // ─── 5. Main Card Content Body ────────────────────────────────
                Padding(
                  padding: _contentPadding,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Official Top Brand Header
                      _BrandHeader(
                        theme: theme,
                        badgeText: data.badgeText,
                        category: data.category,
                        copy: copy,
                        isCompact: format == SocialShareFormat.square,
                        isKids: _isKids,
                      ),

                      // The arch is the single visual frame for dynamic content.
                      // Unlike the former opaque panel, it leaves the layered
                      // emerald atmosphere visible and lets each template keep
                      // its own content-specific visual identity.
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    format == SocialShareFormat.square
                                        ? 18
                                        : 24,
                                    format == SocialShareFormat.story ? 34 : 24,
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

                      // The light parchment footer deliberately separates the
                      // sharing statement from the dark hero composition.
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
}

/// Official Top Brand Header Widget
class _BrandHeader extends StatelessWidget {
  final SocialShareTheme theme;
  final String badgeText;
  final SocialShareCategory category;
  final bool isCompact;
  final SocialShareCopy copy;
  final bool isKids;

  const _BrandHeader({
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
          mainAxisAlignment: isKids
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            // Official Talia App Logo Icon
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_icon_padded.png',
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
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.88),
                    fontSize: isCompact ? 8.5 : 9.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isCompact ? 4 : 6),
        // Category Badge Chip
        Align(
          alignment: isKids
              ? AlignmentDirectional.centerStart
              : Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 14,
              vertical: isCompact ? 2 : 3.5,
            ),
            decoration: BoxDecoration(
              color: theme.badgeBackground,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.45),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Premium parchment signature shared by every card format.
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
    const ink = Color(0xFF123D36);
    return Container(
      key: const ValueKey('share-parchment-footer'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF4E4),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        border: Border.all(color: theme.borderColor.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
              style: AppTypography.labelSmall.copyWith(
                color: ink,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 9 : 10,
                fontFamily: 'Amiri',
              ),
            ),
            SizedBox(height: isCompact ? 1 : 2),
          ],
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: theme.borderColor.withValues(alpha: 0.65),
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Container(
                  width: isCompact ? 18 : 22,
                  height: isCompact ? 18 : 22,
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A3932),
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.borderColor),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_icon_padded.png',
                      fit: BoxFit.cover,
                      cacheWidth: 66,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.auto_awesome_rounded,
                        size: isCompact ? 10 : 12,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: theme.borderColor.withValues(alpha: 0.65),
                  height: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 3),
          Text(
            copy.sharedFrom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: ink.withValues(alpha: 0.82),
              fontSize: isCompact ? 8 : 9,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable mihrab-like hero frame shared by every dynamic card template.
class IslamicHeroArch extends StatelessWidget {
  final SocialShareTheme theme;
  final bool kidsMode;
  final Widget child;

  const IslamicHeroArch({
    super.key,
    required this.theme,
    required this.kidsMode,
    required this.child,
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
        ),
        child: child,
      ),
    );
  }
}

/// The official companion asset, framed as part of the kids hero rather than
/// a detached illustration.  It is deliberately absent from adult cards.
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
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9D67A).withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Image.asset(
        key: const ValueKey('share-hero-character'),
        assetPath,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: 540,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _IslamicHeroArchPainter extends CustomPainter {
  final Color gold;
  final Color fill;
  final Color glow;
  final bool playful;

  const _IslamicHeroArchPainter({
    required this.gold,
    required this.fill,
    required this.glow,
    required this.playful,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.width * 0.045;
    final top = size.height * 0.045;
    final bottom = size.height * 0.975;
    final arch = Path()
      ..moveTo(inset, bottom)
      ..lineTo(inset, size.height * 0.28)
      ..cubicTo(
        inset,
        top + size.height * 0.08,
        size.width * 0.28,
        top,
        size.width / 2,
        top,
      )
      ..cubicTo(
        size.width * 0.72,
        top,
        size.width - inset,
        top + size.height * 0.08,
        size.width - inset,
        size.height * 0.28,
      )
      ..lineTo(size.width - inset, bottom)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [glow.withValues(alpha: 0.74), fill.withValues(alpha: 0.48)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(arch, fillPaint);

    // A quiet mosque silhouette keeps the atmospheric reference language
    // without introducing a raster background or competing with card data.
    final silhouette = Paint()
      ..color = gold.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final ground = size.height * 0.83;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .19,
        ground,
        size.width * .62,
        size.height * .05,
      ),
      silhouette,
    );
    canvas.drawCircle(
      Offset(size.width * .67, ground),
      size.width * .09,
      silhouette,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .76,
        size.height * .42,
        size.width * .035,
        ground - size.height * .42,
      ),
      silhouette,
    );
    canvas.drawCircle(
      Offset(size.width * .778, size.height * .42),
      size.width * .03,
      silhouette,
    );
    final stroke = Paint()
      ..color = gold.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(arch, stroke);
    final leaves = Paint()
      ..color = gold.withValues(alpha: playful ? 0.52 : 0.28);
    for (final leaf in [
      Offset(size.width * .15, size.height * .47),
      Offset(size.width * .2, size.height * .54),
      Offset(size.width * .17, size.height * .62),
    ]) {
      canvas.save();
      canvas.translate(leaf.dx, leaf.dy);
      canvas.rotate(-0.6);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
        leaves,
      );
      canvas.restore();
    }
    if (playful) {
      final sparkle = Paint()..color = gold.withValues(alpha: 0.72);
      for (final point in [
        Offset(size.width * .16, size.height * .22),
        Offset(size.width * .82, size.height * .34),
        Offset(size.width * .2, size.height * .72),
      ]) {
        canvas.drawCircle(point, 2.2, sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicHeroArchPainter old) =>
      old.gold != gold ||
      old.fill != fill ||
      old.glow != glow ||
      old.playful != playful;
}
