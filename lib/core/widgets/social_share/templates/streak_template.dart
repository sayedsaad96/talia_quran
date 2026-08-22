import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Streak & Daily Consistency — continuity & fire.
///
/// The real streak number is the hero: a giant ember-warmed numeral between
/// two fading gold rules, with the record context beneath.
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
          // ─── 1. Radiant ember emblem ───────────────────────────────────
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
                width: isCompact ? 46 : 56,
                height: isCompact ? 46 : 56,
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
                  size: 30,
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Title ─────────────────────────────────────────────────
          Text(
            data.title ?? copy.streakTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 22,
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 3. Hero streak counter between fading gold rules ─────────
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor.withValues(alpha: 0),
                        theme.accentColor.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$days',
                    style: TaliaShareTypography.metricValue(
                      color: TaliaShareColors.streakEmber,
                      fontSize: isCompact ? 40 : (isStory ? 54 : 48),
                    ),
                  ),
                  Text(
                    copy.consecutiveDays,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TaliaShareTypography.title(
                      color: theme.textPrimary,
                      fontSize: isCompact ? 12.5 : 14,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor.withValues(alpha: 0.65),
                        theme.accentColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 3 : 5),
          Text(
            copy.quranCommitment,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TaliaShareTypography.badge(
              color: theme.textSecondary,
              fontSize: isCompact ? 9.5 : 10.5,
            ),
          ),

          // ─── 4. Context line: record or longest streak ───────────────
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

          // ─── 5. Motivational Message ──────────────────────────────────
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

          // ─── 6. Talia companion (adult opt-in path) ────────────────────
          if (data.showCharacter && !isKids) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 14 : 8)),
            TaliaCharacterInline(
              assetPath: data.effectiveCharacterAssetPath,
              height: isCompact ? 48 : (isStory ? 76 : 58),
            ),
          ],
        ],
      ),
    );
  }
}
