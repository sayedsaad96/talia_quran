import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Memorization Milestones — progress & mastery.
///
/// An illuminated open Quran sets the theme; the real ayah/surah counts are
/// presented as gold medallion milestones.
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
    final target = data.targetValue;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Illuminated open Quran emblem ──────────────────────────
          OpenQuranEmblem(theme: theme, size: isCompact ? 50 : 60),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Title ─────────────────────────────────────────────────
          Text(
            data.title ?? copy.memorizationTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 21,
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 3. Milestone medallions (real ayah + surah counts) ───────
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatMedallion(
                  icon: Icons.auto_stories_rounded,
                  value: '$ayahs',
                  label: copy.ayahsLabel,
                  valueColor: theme.accentColor,
                  theme: theme,
                  isCompact: isCompact,
                ),
                if (surahs != null) ...[
                  SizedBox(
                    width: isCompact ? 14 : 22,
                    child: Center(
                      child: Container(
                        height: 1,
                        color: theme.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  StatMedallion(
                    icon: Icons.library_books_rounded,
                    value: '$surahs',
                    label: copy.surahsLabel,
                    valueColor: theme.accentColor,
                    theme: theme,
                    isCompact: isCompact,
                  ),
                ],
                if (surahs == null &&
                    data.subtitle != null &&
                    data.subtitle!.isNotEmpty) ...[
                  SizedBox(width: isCompact ? 10 : 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isCompact ? 90 : 110),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: TaliaShareColors.warmGold,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
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

          // Optional gold progress bar when a real target exists.
          if (target != null && target > 0) ...[
            SizedBox(height: isCompact ? 8 : 12),
            _GoldProgressBar(
              value: (ayahs / target).clamp(0.0, 1.0),
              caption: copy.progress(ayahs, target),
              theme: theme,
              isCompact: isCompact,
            ),
          ],

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 4. Motivational Message ──────────────────────────────────
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

          // ─── 5. Talia companion (adult opt-in path) ────────────────────
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

class _GoldProgressBar extends StatelessWidget {
  final double value;
  final String caption;
  final SocialShareTheme theme;
  final bool isCompact;

  const _GoldProgressBar({
    required this.value,
    required this.caption,
    required this.theme,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 150 : 180,
          height: 6,
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.45),
              width: 0.8,
            ),
          ),
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [
                    TaliaShareColors.deepGold,
                    TaliaShareColors.medalGold,
                    TaliaShareColors.champagneGold,
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isCompact ? 3 : 4),
        Text(
          caption,
          style: TaliaShareTypography.badge(
            color: theme.textSecondary,
            fontSize: isCompact ? 9 : 10,
          ),
        ),
      ],
    );
  }
}
