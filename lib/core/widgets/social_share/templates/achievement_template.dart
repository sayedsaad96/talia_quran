import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Unlocked Achievements.
///
/// Celebratory and badge-led: a gold medal with soft rays crowns the real
/// achievement title. Adults get a refined variant; kids get extra sparkle
/// and the Talia companion cheering inside the shared hero arch.
class AchievementTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const AchievementTemplate({
    super.key,
    required this.data,
    required this.theme,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isCompact = format == SocialShareFormat.square;
    final isStory = format == SocialShareFormat.story;
    final isKids = data.audience == SocialShareAudience.kids;

    final medalSize = isCompact ? 52.0 : (isStory ? 66.0 : 62.0);

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Gold medal with celebration rays ────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: medalSize * 1.9,
                height: medalSize * 1.9,
                child: CustomPaint(
                  painter: RadialRaysPainter(
                    color: theme.accentColor,
                    opacity: isKids ? 0.26 : 0.15,
                    rayCount: isKids ? 16 : 12,
                  ),
                ),
              ),
              Container(
                width: medalSize * 1.2,
                height: medalSize * 1.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accentColor.withValues(alpha: 0.18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.35),
                      blurRadius: 22,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Container(
                width: medalSize,
                height: medalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.accentColor,
                      TaliaShareColors.medalGold,
                      TaliaShareColors.deepGold,
                    ],
                  ),
                  border: Border.all(
                    color: TaliaShareColors.champagneGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child:
                      data.achievementIcon != null &&
                          data.achievementIcon!.isNotEmpty
                      ? Text(
                          data.achievementIcon!,
                          style: TextStyle(
                            fontSize: medalSize * 0.45,
                            fontFamilyFallback:
                                TaliaShareTypography.emojiFallback,
                          ),
                        )
                      : Icon(
                          Icons.emoji_events_rounded,
                          color: TaliaShareColors.medalInk,
                          size: medalSize * 0.55,
                        ),
                ),
              ),
              // Kids medal gets a star crown.
              if (isKids)
                Positioned(
                  top: 0,
                  child: Icon(
                    Icons.star_rounded,
                    color: TaliaShareColors.kidsStarGold,
                    size: medalSize * 0.34,
                  ),
                ),
            ],
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 2. Achievement Title ─────────────────────────────────────
          if (data.title != null && data.title!.isNotEmpty)
            Text(
              data.title!,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.title(
                color: theme.accentColor,
                fontSize: isCompact ? 18 : (isKids ? 23 : 22),
                fontWeight: FontWeight.bold,
              ),
            ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Description Content ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.body(
                color: theme.textPrimary,
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Progress / Status Chip ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.badgeBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 13,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    data.targetValue != null && data.currentValue != null
                        ? '${data.achievementUnlocked == false ? copy.progress(data.currentValue!, data.targetValue!) : copy.completed} (${copy.progress(data.currentValue!, data.targetValue!)})'
                        : copy.achievementComplete,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TaliaShareTypography.badge(
                      color: theme.badgeTextColor,
                      fontSize: isCompact ? 10.5 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 5. Kids encouragement + Talia companion ──────────────────
          if (isKids) ...[
            SizedBox(height: isCompact ? 6 : 10),
            Text(
              copy.kidsEncouragement,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.badge(
                color: theme.textSecondary,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ],
          // Kids characters are composed by the shared hero arch so they read
          // as part of the illustration rather than a second, detached image.
          if (data.showCharacter && !isKids) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 16 : 10)),
            TaliaCharacterInline(
              assetPath: data.effectiveCharacterAssetPath,
              height: isCompact ? 52 : (isStory ? 84 : 64),
            ),
          ],
        ],
      ),
    );
  }
}
