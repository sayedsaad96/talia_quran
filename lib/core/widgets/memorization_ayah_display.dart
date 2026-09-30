import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../constants/surah_names.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_typography.dart';

/// Splits [text] into its original words and the exact separators between
/// them; word i takes [highlight] when `flags[i]` is true. Returns an empty
/// list when the counts differ, so the caller renders the plain text — the
/// Quran text is never re-assembled from anything but its own characters.
List<InlineSpan> highlightWordSpans(
  String text,
  List<bool> flags, {
  required TextStyle highlight,
}) {
  final words = RegExp(r'\S+').allMatches(text).toList();
  if (words.length != flags.length) return const [];
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (var index = 0; index < words.length; index++) {
    final word = words[index];
    if (word.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, word.start)));
    }
    spans.add(
      TextSpan(text: word.group(0), style: flags[index] ? highlight : null),
    );
    cursor = word.end;
  }
  if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
  return spans;
}

/// Shared presentation for a complete ayah in memorization and review flows.
///
/// The caller owns the Quran text and identity. This widget only presents that
/// text using the same Amiri treatment as the Home "Ayah of the Day" card.
class MemorizationAyahDisplay extends StatelessWidget {
  const MemorizationAyahDisplay({
    super.key,
    required this.text,
    required this.surahId,
    required this.ayahNumber,
    required this.textColor,
    required this.decorationColor,
    required this.referenceColor,
    this.surahName,
    this.isCompleted = false,
    this.wordHighlights,
    this.highlightColor,
  });

  final String text;
  final int surahId;
  final int ayahNumber;
  final Color textColor;
  final Color decorationColor;
  final Color referenceColor;
  final String? surahName;
  final bool isCompleted;

  /// Optional per-word marks (kids: the words recited right after a miss).
  /// Null keeps the plain text every other flow uses.
  final List<bool>? wordHighlights;
  final Color? highlightColor;

  /// Matches the text styling used by HomeAyahOfDayCard.
  static TextStyle textStyle({Color? color}) => AppTypography.quranMedium
      .copyWith(fontSize: 24, height: 2.0, color: color);

  @override
  Widget build(BuildContext context) {
    final localizedSurahName =
        surahName ??
        (context.isArabic
            ? SurahNames.arabic[surahId]
            : SurahNames.english[surahId]) ??
        '';
    final reference = context.l10n.surahAyahFormat(
      localizedSurahName,
      context.numText(ayahNumber),
    );
    final highlights = wordHighlights;
    final spans = highlights == null
        ? const <InlineSpan>[]
        : highlightWordSpans(
            text,
            highlights,
            highlight: TextStyle(backgroundColor: highlightColor),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '﴿',
              key: const Key('memorization-ayah-opening-bracket'),
              style: _bracketStyle(decorationColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Directionality(
              textDirection: TextDirection.rtl,
              child: spans.isEmpty
                  ? Text(
                      text,
                      key: const Key('memorization-ayah-text'),
                      textAlign: TextAlign.center,
                      style: textStyle(color: textColor),
                    )
                  : Text.rich(
                      TextSpan(children: spans),
                      key: const Key('memorization-ayah-text'),
                      textAlign: TextAlign.center,
                      style: textStyle(color: textColor),
                    ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '﴾',
              key: const Key('memorization-ayah-closing-bracket'),
              style: _bracketStyle(decorationColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              reference,
              key: const Key('memorization-ayah-reference'),
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: referenceColor,
              ),
            ),
          ],
        ),
        if (isCompleted)
          const Positioned(
            top: -4,
            right: -4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.check_rounded, color: Colors.white, size: 12),
              ),
            ),
          ),
      ],
    );
  }

  TextStyle _bracketStyle(Color color) =>
      TextStyle(fontFamily: 'Amiri', fontSize: 32, color: color, height: 1);
}
