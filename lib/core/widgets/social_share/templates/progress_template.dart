import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Multi-Stat Progress Harvest.
///
/// Three gold medallions — pages read, ayahs memorized, streak days — are
/// joined by thin gold connectors into a single harmonious milestone strip.
class ProgressTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const ProgressTemplate({
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

    final pages = data.readPagesCount ?? 0;
    final ayahs = data.memorizedAyahsCount ?? 0;
    final streak = data.streakDays ?? 0;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Emblem ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.accentColor.withValues(alpha: 0.15),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.insights_rounded,
              color: theme.accentColor,
              size: isCompact ? 22 : 28,
            ),
          ),

          SizedBox(height: isCompact ? 4 : 8),

          // ─── 2. Title ─────────────────────────────────────────────────
          Text(
            data.title ?? copy.progressTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 21,
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 3. Medallion milestone strip ─────────────────────────────
          // Fixed-width medallions can outgrow narrow content regions, so
          // the row measures naturally and scales down instead of clipping.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatMedallion(
                  icon: Icons.menu_book_rounded,
                  value: '$pages',
                  label: copy.pagesReadLabel,
                  valueColor: theme.textPrimary,
                  theme: theme,
                  isCompact: isCompact,
                ),
                _connector(isCompact),
                StatMedallion(
                  icon: Icons.psychology_rounded,
                  value: '$ayahs',
                  label: copy.ayahsMemorizedLabel,
                  valueColor: theme.textPrimary,
                  theme: theme,
                  isCompact: isCompact,
                  ringColor: TaliaShareColors.royalTealLight,
                ),
                _connector(isCompact),
                StatMedallion(
                  icon: Icons.local_fire_department_rounded,
                  value: '$streak',
                  label: copy.streakDaysLabel,
                  valueColor: theme.textPrimary,
                  theme: theme,
                  isCompact: isCompact,
                  ringColor: TaliaShareColors.streakEmberLight,
                ),
              ],
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Motivational Message ──────────────────────────────────
          if (data.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                data.content,
                textAlign: TextAlign.center,
                style: TaliaShareTypography.body(
                  color: theme.textPrimary,
                  fontSize: isCompact ? 12 : 13.5,
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

          // ─── 5. Talia companion (adult opt-in path) ────────────────────
          if (data.showCharacter && !isKids) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 14 : 8)),
            TaliaCharacterInline(
              assetPath: data.effectiveCharacterAssetPath,
              height: isCompact ? 46 : (isStory ? 74 : 56),
            ),
          ],
        ],
      ),
    );
  }

  Widget _connector(bool isCompact) {
    return SizedBox(
      width: isCompact ? 12 : 18,
      child: Center(
        child: Container(
          height: 1,
          color: theme.accentColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
