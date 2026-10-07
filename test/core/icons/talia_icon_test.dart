import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/theme/app_colors.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

List<Icon> _icons(WidgetTester tester) =>
    tester.widgetList<Icon>(find.byType(Icon)).toList();

void main() {
  group('TaliaIcon', () {
    testWidgets('lights the nuqta in gold when active', (tester) async {
      await tester.pumpWidget(
        _host(const TaliaIcon(TaliaIcons.home, color: Colors.teal)),
      );

      final icons = _icons(tester);
      expect(icons.map((i) => i.icon), [
        TaliaIcons.home,
        taliaAccentLayers[TaliaIcons.home.codePoint],
      ]);
      expect(icons.last.color, isNot(Colors.teal));
    });

    testWidgets('an inactive icon is a single glyph', (tester) async {
      await tester.pumpWidget(
        _host(const TaliaIcon(TaliaIcons.home, active: false)),
      );

      expect(_icons(tester).map((i) => i.icon), [TaliaIcons.home]);
    });

    testWidgets('icons without a nuqta stay a single glyph', (tester) async {
      await tester.pumpWidget(_host(const TaliaIcon(TaliaIcons.close)));

      expect(_icons(tester).map((i) => i.icon), [TaliaIcons.close]);
    });

    testWidgets('a kids scope swaps in the kids glyph, tint and sparkle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const TaliaIconScope.kids(
            child: TaliaIcon(TaliaIcons.mushaf, color: Colors.teal),
          ),
        ),
      );

      final cp = TaliaIcons.mushaf.codePoint;
      final icons = _icons(tester);
      expect(icons.map((i) => i.icon), [
        taliaKidsFillLayers[cp],
        TaliaKidsIcons.mushaf,
        taliaKidsAccentLayers[cp],
      ]);
      expect(icons.last.color, AppColors.kidsSparkle);
    });

    testWidgets('kids glyphs are kids without a scope', (tester) async {
      await tester.pumpWidget(_host(const TaliaIcon(TaliaKidsIcons.flame)));

      expect(_icons(tester).map((i) => i.icon), contains(TaliaKidsIcons.flame));
      expect(
        _icons(tester).map((i) => i.icon),
        contains(taliaKidsFillLayers[TaliaIcons.flame.codePoint]),
      );
    });

    testWidgets('only the main glyph carries the semantic label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const TaliaIcon(TaliaIcons.hifz, semanticLabel: 'hifz')),
      );

      expect(find.bySemanticsLabel('hifz'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('non-Talia icons render like Icon', (tester) async {
      await tester.pumpWidget(_host(const TaliaIcon(Icons.abc)));

      expect(_icons(tester).map((i) => i.icon), [Icons.abc]);
    });
  });

  testWidgets('TaliaFeatureDoor shows the kids glyph under one label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const TaliaFeatureDoor(
          icon: TaliaIcons.journey,
          color: AppColors.kidsDoorTeal,
          semanticLabel: 'journey',
        ),
      ),
    );

    expect(find.byIcon(TaliaKidsIcons.journey), findsOneWidget);
    expect(find.bySemanticsLabel('journey'), findsOneWidget);
    handle.dispose();
  });

  group('icon set', () {
    test('every icon has a kids variant at the same codepoint', () {
      for (final entry in taliaIconsByName.entries) {
        final kids = taliaKidsVariants[entry.value.codePoint];
        expect(kids, isNotNull, reason: entry.key);
        expect(kids!.codePoint, entry.value.codePoint, reason: entry.key);
        expect(kids.fontFamily, 'TaliaIconsKids', reason: entry.key);
        expect(
          kids.matchTextDirection,
          entry.value.matchTextDirection,
          reason: entry.key,
        );
      }
    });

    test('codepoints are unique and in the private use area', () {
      final cps = taliaIconsByName.values.map((i) => i.codePoint).toList();
      expect(cps.toSet().length, cps.length);
      for (final cp in cps) {
        expect(cp, inInclusiveRange(0xE000, 0xF8FF));
      }
    });

    test('directional icons mirror in RTL', () {
      for (final icon in [
        TaliaIcons.arrowBack,
        TaliaIcons.arrowForward,
        TaliaIcons.chevronBack,
        TaliaIcons.chevronForward,
        TaliaIcons.send,
        TaliaIcons.undo,
      ]) {
        expect(icon.matchTextDirection, isTrue);
      }
    });

    test('the fonts are bundled', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final family in ['TaliaIcons', 'TaliaIconsKids']) {
        expect(pubspec, contains('family: $family'));
        expect(
          File('assets/fonts/TaliaIcons/$family.ttf').existsSync(),
          isTrue,
        );
      }
    });

    // The app uses one icon language. Material `Icons.*` would bring back
    // the generic look this system replaced.
    test('lib/ does not use Material Icons', () {
      final offenders = <String>[];
      final pattern = RegExp(r'(?<![A-Za-z_])Icons\.[a-z]');
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (pattern.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
