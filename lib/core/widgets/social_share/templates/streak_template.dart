import 'package:flutter/material.dart';
import '../share_card_content.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Streak & Daily Consistency — continuity & fire.
class StreakTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const StreakTemplate({
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
    final days = data.streakDays ?? data.currentValue ?? 0;
    final longest = data.targetValue;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Radiant Fire / Sun Consistency Emblem ─────────────────────
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: isCompact ? 56 : 68,
                height: isCompact ? 56 : 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TaliaShareColors.streakEmber.withValues(alpha: 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: TaliaShareColors.streakEmber.withValues(alpha: 0.4),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              Container(
                width: isCompact ? 48 : 58,
                height: isCompact ? 48 : 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TaliaShareColors.streakEmberLight,
                      TaliaShareColors.streakEmberDeep,
                    ],
                  ),
                  border: Border.all(
                    color: TaliaShareColors.champagneGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Title ─────────────────────────────────────────────────────
          Text(
            data.title ?? copy.streakTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 22,
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Giant Streak Counter Banner ───────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 18 : 24,
              vertical: isCompact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: TaliaShareColors.streakEmber.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$days',
                  style: TaliaShareTypography.metricValue(
                    color: TaliaShareColors.streakEmber,
                    fontSize: isCompact ? 28 : 36,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        copy.consecutiveDays,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TaliaShareTypography.title(
                          color: theme.textPrimary,
                          fontSize: isCompact ? 13 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        copy.quranCommitment,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TaliaShareTypography.badge(
                          color: theme.textSecondary,
                          fontSize: isCompact ? 9.5 : 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 4. Context line: record or longest streak ───────────────────
          if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              data.subtitle!,
              style: TaliaShareTypography.badge(
                color: theme.accentColor,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ] else if (longest != null && longest <= days) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              copy.newRecord,
              style: TaliaShareTypography.badge(
                color: TaliaShareColors.streakEmber,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ] else if (longest != null && longest > days) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              copy.longestStreak(longest),
              style: TaliaShareTypography.badge(
                color: theme.accentColor,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ],

          // ─── 5. Motivational Message ──────────────────────────────────────
          if (data.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                data.content,
                textAlign: TextAlign.center,
                style: TaliaShareTypography.body(
                  color: theme.textPrimary,
                  fontSize: isCompact ? 12 : 14,
                  height: 1.45,
                ),
              ),
            ),

          if (isKids) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              copy.kidsEncouragement,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.badge(
                color: theme.textSecondary,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ],

          // ─── 6. Talia Celebratory Companion ───────────────────────────────
          if (data.showCharacter && !isKids) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 14 : 8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                key: const ValueKey('share-character-image'),
                data.effectiveCharacterAssetPath,
                height: isCompact ? 48 : (isStory ? (isKids ? 88 : 76) : (isKids ? 68 : 58)),
                fit: BoxFit.contain,
                cacheWidth: 288,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
