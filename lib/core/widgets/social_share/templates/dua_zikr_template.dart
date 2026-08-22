import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../social_share_theme.dart';
import '../share_card_widgets.dart';
import '../talia_share_tokens.dart';

/// Specialized Template for Duas & Azkar — calm, reflective composition.
///
/// A quiet hanging lantern sets the mood; the supplication itself stays the
/// hero with generous line height and minimal ornamentation.
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
          // ─── 1. Hanging lantern emblem ──────────────────────────────────
          LanternEmblem(theme: theme, size: isCompact ? 38 : 46),

          SizedBox(height: isCompact ? 5 : 8),

          // ─── 2. Title ─────────────────────────────────────────────────
          if (data.title != null && data.title!.isNotEmpty) ...[
            Text(
              data.title!,
              textAlign: TextAlign.center,
              style: TaliaShareTypography.title(
                color: theme.accentColor,
                fontSize: isCompact ? 16 : 19,
              ),
            ),
            SizedBox(height: isCompact ? 5 : 8),
          ],

          // ─── 3. Dua / Zikr Arabic Text ────────────────────────────────
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
                textDirection: TextDirection.ltr,
                style: TaliaShareTypography.body(
                  color: theme.textSecondary,
                  fontSize: isCompact ? 10.5 : 12,
                ),
              ),
            ),
          ],

          SizedBox(height: isCompact ? 8 : 12),

          // ─── 4. Reference / Source chip ───────────────────────────────
          if (data.subtitle != null && data.subtitle!.isNotEmpty)
            ShareLabelChip(
              icon: Icons.bookmark_outline_rounded,
              accent: theme.accentColor,
              background: theme.cardBackground,
              border: theme.borderColor,
              isCompact: isCompact,
              children: [
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
        ],
      ),
    );
  }
}
