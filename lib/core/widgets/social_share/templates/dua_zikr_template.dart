import 'package:flutter/material.dart';
import '../share_card_content.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Duas & Azkar — calm, reflective composition.
class DuaZikrTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const DuaZikrTemplate({
    super.key,
    required this.data,
    required this.theme,
    required this.format,
  });

  double _getTextFontSize(int length) {
    if (format == SocialShareFormat.square) {
      if (length > 250) return 12.5;
      if (length > 150) return 14.0;
      if (length > 80) return 15.5;
      return 17.5;
    }
    if (length > 300) return 13.5;
    if (length > 180) return 15.5;
    if (length > 90) return 17.5;
    return 20.0;
  }

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isCompact = format == SocialShareFormat.square;
    final textFontSize = _getTextFontSize(data.content.length);

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Decorative Lantern / Spiritual Icon ───────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(
              data.category == SocialShareCategory.dua
                  ? Icons.favorite_rounded
                  : Icons.auto_awesome_rounded,
              color: theme.accentColor,
              size: isCompact ? 20 : 24,
            ),
          ),

          SizedBox(height: isCompact ? 6 : 10),

          // ─── 2. Title ─────────────────────────────────────────────────────
          if (data.title != null && data.title!.isNotEmpty) ...[
            Text(
              data.title!,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.title(
                color: theme.accentColor,
                fontSize: isCompact ? 16 : 19,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 10),
          ],

          // ─── 3. Dua / Zikr Arabic Text ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '« ${data.content} »',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TaliaShareTypography.quranVerse(
                color: theme.textPrimary,
                fontSize: textFontSize,
                fontWeight: FontWeight.w600,
                height: 1.8,
              ),
            ),
          ),

          // Optional translation — English content only for English users.
          if (!copy.isArabic &&
              data.translation != null &&
              data.translation!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 6 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '“${data.translation}”',
                textAlign: TextAlign.center,
                style: TaliaShareTypography.body(
                  color: theme.textSecondary,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ),
          ],

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Reference / Source Chip ───────────────────────────────────
          if (data.subtitle != null && data.subtitle!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3.5),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.borderColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_outline_rounded,
                    size: isCompact ? 11 : 13,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      data.subtitle!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TaliaShareTypography.badge(
                        color: theme.accentColor,
                        fontSize: isCompact ? 10.5 : 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
