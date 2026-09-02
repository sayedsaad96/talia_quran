import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/presentation/widgets/juz_grid_view.dart';

void main() {
  testWidgets(
    'uses two columns on a phone and keeps long Arabic juz names complete',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(537, 808));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_JuzGridTestApp(onJuzSelected: (_, _) {}));
      await tester.pumpAndSettle();

      final first = tester.getTopLeft(find.byKey(const ValueKey('juz_card_1')));
      final second = tester.getTopLeft(
        find.byKey(const ValueKey('juz_card_2')),
      );
      final third = tester.getTopLeft(find.byKey(const ValueKey('juz_card_3')));

      expect(second.dy, first.dy);
      expect(second.dx, isNot(first.dx));
      expect(third.dy, greaterThan(first.dy));

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('juz_card_21')),
        320,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      final longTitle = tester.widget<Text>(find.text('الجزء الحادي والعشرون'));
      expect(longTitle.maxLines, isNull);
      expect(longTitle.overflow, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reports the selected juz and its starting page', (tester) async {
    int? selectedJuz;
    int? selectedPage;

    await tester.pumpWidget(
      _JuzGridTestApp(
        onJuzSelected: (juz, page) {
          selectedJuz = juz;
          selectedPage = page;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('juz_card_1')));
    await tester.pump();

    expect(selectedJuz, 1);
    expect(selectedPage, 1);
  });

  testWidgets('adapts columns for tablets and large accessibility text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(840, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_JuzGridTestApp(onJuzSelected: (_, _) {}));
    await tester.pumpAndSettle();

    final tabletFirst = tester.getTopLeft(
      find.byKey(const ValueKey('juz_card_1')),
    );
    final tabletThird = tester.getTopLeft(
      find.byKey(const ValueKey('juz_card_3')),
    );
    final tabletFourth = tester.getTopLeft(
      find.byKey(const ValueKey('juz_card_4')),
    );
    expect(tabletThird.dy, tabletFirst.dy);
    expect(tabletFourth.dy, greaterThan(tabletFirst.dy));

    await tester.binding.setSurfaceSize(const Size(360, 808));
    await tester.pumpWidget(
      _JuzGridTestApp(
        textScaler: const TextScaler.linear(1.5),
        onJuzSelected: (_, _) {},
      ),
    );
    await tester.pumpAndSettle();

    final accessibleFirst = tester.getTopLeft(
      find.byKey(const ValueKey('juz_card_1')),
    );
    final accessibleSecond = tester.getTopLeft(
      find.byKey(const ValueKey('juz_card_2')),
    );
    expect(accessibleSecond.dy, greaterThan(accessibleFirst.dy));
    expect(tester.takeException(), isNull);
  });
}

class _JuzGridTestApp extends StatelessWidget {
  const _JuzGridTestApp({
    required this.onJuzSelected,
    this.textScaler = TextScaler.noScaling,
  });

  final void Function(int juz, int page) onJuzSelected;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(body: JuzGridView(onJuzSelected: onJuzSelected)),
    );
  }
}
