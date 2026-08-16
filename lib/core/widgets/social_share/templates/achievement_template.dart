import 'package:flutter/material.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Unlocked Achievements
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Glowing 3D Golden Medal Emblem ────────────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              // Radial Glow Aura
              Container(
                width: isCompact ? 58 : 72,
                height: isCompact ? 58 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.accentColor.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),

              // Golden Medal
              Container(
                width: isCompact ? 50 : 62,
                height: isCompact ? 50 : 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.accentColor,
                      const Color(0xFFD4AF37),
                      const Color(0xFF8B6508),
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
                  child: data.achievementIcon != null && data.achievementIcon!.isNotEmpty
                      ? Text(
                          data.achievementIcon!,
                          style: TextStyle(fontSize: isCompact ? 22 : 28),
                        )
                      : Icon(
                          Icons.emoji_events_rounded,
                          color: const Color(0xFF2C1E03),
                          size: isCompact ? 28 : 34,
                        ),
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 2. Achievement Title ─────────────────────────────────────────
          if (data.title != null && data.title!.isNotEmpty)
            Text(
              data.title!,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.title(
                color: theme.accentColor,
                fontSize: isCompact ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Description Content ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              textDirection: copy.direction,
              style: TaliaShareTypography.body(
                color: theme.textPrimary,
                fontSize: isCompact ? 13 : 15,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Progress / Status Chip ────────────────────────────────────
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
                Text(
                  data.targetValue != null && data.currentValue != null
                      ? '${data.achievementUnlocked == false ? copy.progress(data.currentValue!, data.targetValue!) : copy.completed} (${copy.progress(data.currentValue!, data.targetValue!)})'
                      : copy.achievementComplete,
                  style: TaliaShareTypography.badge(
                    color: theme.badgeTextColor,
                    fontSize: isCompact ? 10.5 : 12,
                  ),
                ),
              ],
            ),
          ),

          // ─── 5. Talia Celebratory Companion ───────────────────────────────
          if (data.showCharacter) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 16 : 10)),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                data.effectiveCharacterAssetPath,
                height: isCompact ? 52 : (isStory ? 84 : 64),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
