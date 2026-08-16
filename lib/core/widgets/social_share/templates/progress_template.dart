import 'package:flutter/material.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Multi-Stat Progress Harvest
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

    final pages = data.readPagesCount ?? 0;
    final ayahs = data.memorizedAyahsCount ?? 0;
    final streak = data.streakDays ?? 0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Header Emblem ─────────────────────────────────────────────
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

          // ─── 2. Title ─────────────────────────────────────────────────────
          Text(
            data.title ?? copy.progressTitle,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.title(
              color: theme.accentColor,
              fontSize: isCompact ? 18 : 21,
            ),
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 3. 3-Stat Metric Grid ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(
                icon: Icons.menu_book_rounded,
                value: '$pages',
                label: copy.isArabic ? 'صفحات مقروءة' : 'pages read',
                color: theme.accentColor,
                theme: theme,
                isCompact: isCompact,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              _StatPill(
                icon: Icons.psychology_rounded,
                value: '$ayahs',
                label: copy.isArabic ? 'آيات محفوظة' : 'ayahs memorized',
                color: TaliaShareColors.royalTealLight,
                theme: theme,
                isCompact: isCompact,
              ),
              SizedBox(width: isCompact ? 6 : 8),
              _StatPill(
                icon: Icons.local_fire_department_rounded,
                value: '$streak',
                label: copy.isArabic ? 'أيام متتالية' : 'streak days',
                color: const Color(0xFFFF8C42),
                theme: theme,
                isCompact: isCompact,
              ),
            ],
          ),

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Motivational Message ──────────────────────────────────────
          if (data.content.trim().isNotEmpty) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              data.content,
              textAlign: TextAlign.center,
              textDirection: copy.direction,
              style: TaliaShareTypography.body(
                color: theme.textPrimary,
                fontSize: isCompact ? 12 : 13.5,
                height: 1.45,
              ),
            ),
          ),

          // ─── 5. Talia Celebratory Companion ───────────────────────────────
          if (data.showCharacter) ...[
            SizedBox(height: isCompact ? 6 : (isStory ? 14 : 8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                data.effectiveCharacterAssetPath,
                height: isCompact ? 46 : (isStory ? 74 : 56),
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

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final SocialShareTheme theme;
  final bool isCompact;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.theme,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCompact ? 84 : 96,
      padding: EdgeInsets.symmetric(
        vertical: isCompact ? 6 : 8,
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 15 : 18, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TaliaShareTypography.metricValue(
              color: theme.textPrimary,
              fontSize: isCompact ? 17 : 20,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TaliaShareTypography.badge(
              color: theme.textSecondary,
              fontSize: isCompact ? 8.5 : 9.5,
            ),
          ),
        ],
      ),
    );
  }
}
