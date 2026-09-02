import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart' show SocialShareTheme;
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Quran Verses.
///
/// The verse text is the hero: its trusted Quran wording is preserved while
/// the duplicate terminal number is omitted for display. The composition is
/// calm and typography-focused —
/// an ornament divider above, the illuminated verse, then the reference.
class QuranVerseTemplate extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final SocialShareFormat format;

  const QuranVerseTemplate({
    super.key,
    required this.data,
    required this.theme,
    required this.format,
  });

  double _getVerseFontSize(int length) {
    if (format == SocialShareFormat.square) {
      if (length > 250) return 12.5;
      if (length > 150) return 14.0;
      if (length > 80) return 16.0;
      return 18.0;
    }
    if (length > 300) return 13.5;
    if (length > 180) return 15.5;
    if (length > 90) return 18.0;
    return 21.0;
  }

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final contentLength = data.content.length;
    final verseFontSize = _getVerseFontSize(contentLength);
    final isCompact = format == SocialShareFormat.square;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ─── 1. Ornament crown over the verse ──────────────────────────
          ShareStarOrnament(
            color: theme.accentColor.withValues(alpha: 0.85),
            size: isCompact ? 11 : 13,
          ),

          SizedBox(height: isCompact ? 5 : 8),

          // ─── 2. The verse itself (the hero, verbatim) ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '﴿ ${data.content} ﴾',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TaliaShareTypography.quranVerse(
                color: theme.textPrimary,
                fontSize: verseFontSize,
                fontWeight: FontWeight.w600,
                height: 1.85,
              ),
            ),
          ),

          // Optional translation — English content is only shown to English
          // users so Arabic cards never mix in untranslated foreign text.
          if (!copy.isArabic &&
              data.translation != null &&
              data.translation!.isNotEmpty) ...[
            SizedBox(height: isCompact ? 6 : 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '“${data.translation}”',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: TaliaShareTypography.body(
                  color: theme.textSecondary,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ),
          ],

          SizedBox(height: isCompact ? 7 : 12),

          // ─── 3. Gold divider under the verse ───────────────────────────
          GoldDivider(color: theme.accentColor, width: isCompact ? 96 : 120),

          SizedBox(height: isCompact ? 7 : 12),

          // ─── 4. Surah & Ayah reference medallion chip ──────────────────
          ShareLabelChip(
            icon: Icons.menu_book_rounded,
            accent: theme.accentColor,
            background: theme.cardBackground,
            border: theme.borderColor,
            isCompact: isCompact,
            children: [
              Flexible(
                child: Text(
                  data.surahName == null
                      ? copy.holyQuran
                      : copy.surah(data.surahName!),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TaliaShareTypography.title(
                    color: theme.accentColor,
                    fontSize: isCompact ? 13 : 14.5,
                  ),
                ),
              ),
              if (data.ayahNumber != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(width: 3.5, height: 3.5),
                  ),
                ),
                Flexible(
                  child: Text(
                    copy.ayah(data.ayahNumber!),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TaliaShareTypography.badge(
                      color: theme.accentColor.withValues(alpha: 0.9),
                      fontSize: isCompact ? 11 : 12.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
