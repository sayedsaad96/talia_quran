import 'package:flutter/material.dart';
import '../share_card_content.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Memorization Milestones — progress & mastery.
class MemorizationTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const MemorizationTemplate({
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
    final ayahs = data.memorizedAyahsCount ?? data.currentValue ?? 0;
    final surahs = data.memorizedSurahsCount;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Memorization Icon Badge ───────────────────────────────────
          Container(
            width: isCompact ? 48 : 58,
            height: isCompact ? 48 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  TaliaShareColors.royalTealLight,
                  TaliaShareColors.royalTeal,
                ],
              ),
              border: Border.all(
                color: theme.accentColor,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: TaliaShareColors.champagneGold,
              size: isCompact ? 26 : 32,
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Title ─────────────────────────────────────────────────────
          Text(
            data.title ?? copy.memorizationTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 21,
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 3. Stat Card Highlight (real ayah + surah counts) ───────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: isCompact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$ayahs',
                        style: TaliaShareTypography.metricValue(
                          color: theme.accentColor,
                          fontSize: isCompact ? 24 : 32,
                        ),
                      ),
                      Text(
                        copy.ayahsLabel,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TaliaShareTypography.badge(
                          color: theme.textSecondary,
                          fontSize: isCompact ? 10 : 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (surahs != null) ...[
                  Container(
                    height: 28,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: TaliaShareColors.warmGold,
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$surahs',
                          style: TaliaShareTypography.metricValue(
                            color: theme.accentColor,
                            fontSize: isCompact ? 24 : 32,
                          ),
                        ),
                        Text(
                          copy.surahsLabel,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TaliaShareTypography.badge(
                            color: theme.textSecondary,
                            fontSize: isCompact ? 10 : 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (surahs == null &&
                    data.subtitle != null &&
                    data.subtitle!.isNotEmpty) ...[
                  Container(
                    height: 28,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: theme.borderColor.withValues(alpha: 0.4),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: TaliaShareColors.warmGold,
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.subtitle!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TaliaShareTypography.badge(
                            color: theme.accentColor,
                            fontSize: isCompact ? 10 : 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 4. Motivational Message ──────────────────────────────────────
          if (data.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                data.content,
                textAlign: TextAlign.center,
                style: TaliaShareTypography.body(
                  color: theme.textPrimary,
                  fontSize: isCompact ? 12.5 : 14,
                  height: 1.5,
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

          // ─── 5. Talia Companion Asset ─────────────────────────────────────
          if (data.showCharacter) ...[
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
