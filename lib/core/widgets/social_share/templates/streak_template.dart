import 'package:flutter/material.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Streak & Daily Consistency
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
    final days = data.streakDays ?? data.currentValue ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
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
                  color: const Color(0xFFFF8C42).withValues(alpha: 0.22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C42).withValues(alpha: 0.4),
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
                      Color(0xFFFFB03A),
                      Color(0xFFFF6A00),
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
                color: const Color(0xFFFF8C42).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$days',
                  style: TaliaShareTypography.metricValue(
                    color: const Color(0xFFFF8C42),
                    fontSize: isCompact ? 28 : 36,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      copy.consecutiveDays,
                      style: TaliaShareTypography.title(
                        color: theme.textPrimary,
                        fontSize: isCompact ? 13 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      copy.quranCommitment,
                      style: TaliaShareTypography.badge(
                        color: theme.textSecondary,
                        fontSize: isCompact ? 9.5 : 10.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 4. Motivational Message ──────────────────────────────────────
          if (data.content.trim().isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              textDirection: copy.direction,
              style: TaliaShareTypography.body(
                color: theme.textPrimary,
                fontSize: isCompact ? 12 : 14,
                height: 1.45,
              ),
            ),
          ),

          if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(
              data.subtitle!,
              style: TaliaShareTypography.badge(
                color: theme.accentColor,
                fontSize: isCompact ? 10 : 11.5,
              ),
            ),
          ],
          if (data.subtitle == null && data.targetValue != null && data.targetValue! > days) ...[
            SizedBox(height: isCompact ? 4 : 6),
            Text(copy.longestStreak(data.targetValue!), style: TaliaShareTypography.badge(color: theme.accentColor, fontSize: isCompact ? 10 : 11.5)),
          ],

          // ─── 5. Talia Celebratory Companion ───────────────────────────────
          if (data.showCharacter) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 14 : 8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                data.effectiveCharacterAssetPath,
                height: isCompact ? 48 : (isStory ? 76 : 58),
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
