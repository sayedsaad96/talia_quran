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
            border: Border.all(
              color: theme.borderColor,
              width: 1.25,
            ),
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
                    painter: IslamicOctagramPainter(
                      color: theme.patternColor,
                    ),
                  ),
                ),

                // ─── 2. Top & Center Ambient Radial Glow ──────────────────────
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.45),
                        radius: 0.85,
                        colors: [
                          theme.glowColor,
                          Colors.transparent,
                        ],
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

                      // Middle Dynamic Template Content Container
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                            vertical: format == SocialShareFormat.square ? 6 : 10,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: format == SocialShareFormat.square ? 12 : 16,
                            vertical: format == SocialShareFormat.square ? 8 : 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardBackground.withValues(alpha: 0.84),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.borderColor.withValues(alpha: 0.38),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: child,
                          ),
                        ),
                      ),

                      // Official Footer Brand Signature
                      _BrandFooter(
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
    final localizedBadge =
        badgeText.isNotEmpty ? badgeText : copy.localizedBadge(category);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
        Container(
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
      ],
    );
  }
}

/// Official Card Footer Widget
class _BrandFooter extends StatelessWidget {
  final SocialShareTheme theme;
  final String? userName;
  final bool isCompact;
  final SocialShareCopy copy;

  const _BrandFooter({
    required this.theme,
    this.userName,
    required this.copy,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userName != null && userName!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: isCompact ? 11 : 13,
                color: theme.accentColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  copy.journeyFor(userName!),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 10 : 11,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 2 : 4),
        ],
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      theme.borderColor.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.stars_rounded,
                size: isCompact ? 10 : 12,
                color: theme.accentColor,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.borderColor.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 2 : 4),
        Text(
          copy.sharedFrom,
          style: AppTypography.labelSmall.copyWith(
            color: theme.textSecondary.withValues(alpha: 0.78),
            fontSize: isCompact ? 8.5 : 9.5,
          ),
        ),
      ],
    );
  }
}
