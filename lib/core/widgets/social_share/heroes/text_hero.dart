import 'package:flutter/material.dart';

import '../share_card_content.dart';
import '../share_card_palette.dart';
import '../social_share_copy.dart';
import '../social_share_model.dart';
import '../talia_share_tokens.dart';

/// Quran verse, dua or dhikr as the hero. The text is rendered exactly as
/// the data carries it; only the enclosing brackets are presentation.
class TextHero extends StatelessWidget {
  const TextHero({
    super.key,
    required this.data,
    required this.palette,
    required this.metrics,
  });

  final SocialShareData data;
  final SharePalette palette;
  final TaliaShareMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final copy = SocialShareCopy.of(context);
    final isQuran = data.category == SocialShareCategory.quranAyah;
    final text = isQuran ? '﴿ ${data.content} ﴾' : '« ${data.content} »';
    final reference = isQuran
        ? copy.ayahReference(data.surahName, data.ayahNumber)
        : data.subtitle;
    final translation = data.translation;
    final showTranslation =
        !copy.isArabic && translation != null && translation.isNotEmpty;

    return ShareCardContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            key: const ValueKey('share-hero-text'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TaliaShareTypography.quranVerse(
              color: palette.textPrimary,
              fontSize: metrics.verseSize(data.content.length),
              fontWeight: FontWeight.w600,
              height: 1.85,
            ),
          ),
          if (showTranslation) ...[
            SizedBox(height: metrics.gap),
            Text(
              '“$translation”',
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: TaliaShareTypography.body(
                color: palette.textSecondary,
                fontSize: metrics.bodySize,
              ),
            ),
          ],
          if (reference != null && reference.isNotEmpty) ...[
            SizedBox(height: metrics.gap * 1.5),
            Text(
              reference,
              key: const ValueKey('share-reference'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TaliaShareTypography.badge(
                color: palette.textAccent,
                fontSize: metrics.referenceSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
