import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/widgets/app_quran_page_view.dart';

void main() {
  testWidgets(
    'structural basmalah is absent for Al-Fatihah, present for Al-Baqarah, '
    'and absent for At-Tawbah',
    (tester) async {
      final builderCalls = <int>[];
      final controller = PageController();
      final view = AppQuranPageView(
        pageController: controller,
        highlights: const [],
        quranPagesCount: 604,
        isDarkMode: false,
        basmallahBuilder: (context, surahNumber) {
          builderCalls.add(surahNumber);
          return SizedBox(key: ValueKey('custom_basmallah_$surahNumber'));
        },
      );

      Future<({int appMarkers, int customMarkers})> pumpSurah(
        int surahNumber,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => view.basmallahBuilder(context, surahNumber),
            ),
          ),
        );
        return (
          appMarkers: find
              .byKey(ValueKey('app_structural_basmallah_$surahNumber'))
              .evaluate()
              .length,
          customMarkers: find
              .byKey(ValueKey('custom_basmallah_$surahNumber'))
              .evaluate()
              .length,
        );
      }

      final fatihah = await pumpSurah(1);
      expect(fatihah.appMarkers, 0);
      expect(fatihah.customMarkers, 0);
      expect(builderCalls, isEmpty);

      final baqarah = await pumpSurah(2);
      expect(baqarah.appMarkers, 1);
      expect(baqarah.customMarkers, 1);
      expect(builderCalls, [2]);

      final tawbah = await pumpSurah(9);
      expect(tawbah.appMarkers, 0);
      expect(tawbah.customMarkers, 0);
      expect(builderCalls, [2]);

      controller.dispose();
    },
  );
}
