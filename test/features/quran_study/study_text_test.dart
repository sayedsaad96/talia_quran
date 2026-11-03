import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/presentation/widgets/study_text.dart';

void main() {
  testWidgets('formats only complete source quotation markers', (tester) async {
    const source = "before <span class='aya'>quoted</span> after <b>literal</b>";
    await tester.pumpWidget(const MaterialApp(home: StudyText(text: source, isTafsir: true)));
    final widget = tester.widget<SelectableText>(find.byType(SelectableText));
    final root = widget.textSpan!;
    expect(root.toPlainText(), 'before quoted after <b>literal</b>');
    final quote = root.children![1] as TextSpan;
    expect(quote.text, 'quoted');
    expect(quote.style!.fontFamily, 'TafsirUthmanic');
  });

  testWidgets('preserves unknown, incomplete and translation markup', (tester) async {
    const source = "<span class='aya'>unfinished <b>text</b>";
    await tester.pumpWidget(const MaterialApp(home: StudyText(text: source, isTafsir: true)));
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).textSpan!.toPlainText(), source);
    const translation = "<span class='aya'>literal</span>";
    await tester.pumpWidget(const MaterialApp(home: StudyText(text: translation, isTafsir: false)));
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data, translation);
  });
}
