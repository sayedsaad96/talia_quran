import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/features/quran/data/services/reader_display_preferences.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reader_overflow_sheet.dart';

/// N13/N14: the reader menu offered only the reciter and focus mode; the
/// tajweed colours were forced on and page navigation hid behind the title.
void main() {
  group('ReaderDisplayPreferences', () {
    test('tajweed colours default on and the choice persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      expect(ReaderDisplayPreferences.tajweedEnabled(prefs), isTrue);
      await ReaderDisplayPreferences.setTajweedEnabled(prefs, false);
      expect(ReaderDisplayPreferences.tajweedEnabled(prefs), isFalse);
    });
  });

  group('ReaderOverflowSheet', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      if (getIt.isRegistered<QuranReciterService>()) {
        await getIt.unregister<QuranReciterService>();
      }
      getIt.registerSingleton<QuranReciterService>(QuranReciterService(prefs));
    });

    tearDown(() async {
      await getIt.unregister<QuranReciterService>();
    });

    Future<void> pump(
      WidgetTester tester, {
      required bool tajweed,
      required ValueChanged<bool> onTajweed,
      required VoidCallback onNavigate,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ReaderOverflowSheet(
              onEnterFocus: () {},
              onOpenNavigation: onNavigate,
              tajweedEnabled: tajweed,
              onTajweedChanged: onTajweed,
            ),
          ),
        ),
      );
    }

    testWidgets('toggles tajweed colours', (tester) async {
      bool? changed;
      await pump(
        tester,
        tajweed: true,
        onTajweed: (value) => changed = value,
        onNavigate: () {},
      );

      final toggle = find.byKey(const Key('reader-tajweed-toggle'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(toggle);
      await tester.pump();

      expect(changed, isFalse);
    });

    testWidgets('opens page navigation', (tester) async {
      var navigated = 0;
      await pump(
        tester,
        tajweed: true,
        onTajweed: (_) {},
        onNavigate: () => navigated++,
      );

      await tester.tap(find.byKey(const Key('reader-open-navigation')));
      await tester.pump();

      expect(navigated, 1);
    });
  });
}
