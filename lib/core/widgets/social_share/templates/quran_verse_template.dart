import 'package:flutter/material.dart';
import '../share_card_content.dart';
import '../social_share_model.dart';
import '../social_share_copy.dart';
import '../social_share_theme.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Quran Verses.
///
/// The verse text is the hero: it comes verbatim from the trusted Quran
/// source (`Ayah.text`) and no Quran wording is ever composed or hardcoded
/// in presentation code.
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
          // ─── 1. Decorative Quran Verse Text (the hero) ───────────────────
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
                style: TaliaShareTypography.body(
                  color: theme.textSecondary,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ),
          ],

          SizedBox(height: isCompact ? 8 : 14),

          // ─── 2. Surah & Ayah Badge Footer ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.borderColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: isCompact ? 13 : 15,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    data.surahName == null ? copy.holyQuran : copy.surah(data.surahName!),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TaliaShareTypography.title(
                      color: theme.accentColor,
                      fontSize: isCompact ? 13 : 14.5,
                    ),
                  ),
                ),
                if (data.ayahNumber != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('•'),
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
          ),
        ],
      ),
    );
  }
}
