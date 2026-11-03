import 'package:flutter/material.dart';

/// Renders the source's Quran-quotation markers without changing their text.
/// Unknown or incomplete markup remains visible rather than being discarded.
class StudyText extends StatelessWidget {
  const StudyText({super.key, required this.text, required this.isTafsir});

  final String text;
  final bool isTafsir;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (!isTafsir) return SelectableText(text, style: style);
    final marker = RegExp(r"<span class='aya'>([^<>]*)</span>");
    final spans = <InlineSpan>[];
    var offset = 0;
    for (final match in marker.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(offset, match.start)));
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(
            fontFamily: 'TafsirUthmanic',
            fontFamilyFallback: ['Amiri'],
          ),
        ),
      );
      offset = match.end;
    }
    spans.add(TextSpan(text: text.substring(offset)));
    return SelectableText.rich(TextSpan(style: style, children: spans));
  }
}
