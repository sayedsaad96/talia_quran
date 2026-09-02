import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:talia_quran/core/widgets/qcf_hifz_verse_view.dart';

// ─── Test Helpers ─────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

// ─── Shared Renderer Tests ─────────────────────────────────────────────────────

void main() {
  group('QcfHifzVerseView', () {
    // ── T004 / T020: Pure presenter — no side effects ──────────────────────────

    test('is a StatelessWidget (presentation only)', () {
      const widget = QcfHifzVerseView(
        surahNumber: 1,
        verseNumber: 1,
        fallbackText: 'بِسْمِ اللَّهِ',
        isUnlocked: true,
        isMemorized: false,
      );
      expect(widget, isA<StatelessWidget>());
    });

    // ── T004: Single verse rendering ───────────────────────────────────────────

    testWidgets(
      'renders without error for a valid single verse (Al-Fatiha 1)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const QcfHifzVerseView(
              surahNumber: 1,
              verseNumber: 1,
              fallbackText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              isUnlocked: true,
              isMemorized: false,
            ),
          ),
        );
        // No exception thrown — widget builds successfully.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('renders without error for Al-Baqarah 255 (Ayatul Kursi)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 2,
            verseNumber: 255,
            fallbackText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // ── T004 / T028: Same-surah range rendering ────────────────────────────────

    testWidgets('renders a same-surah range for Al-Fatiha (1:1-7)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 1,
            verseNumber: 1,
            endVerseNumber: 7,
            fallbackText: 'الحمد لله رب العالمين',
            isUnlocked: true,
            isMemorized: false,
            displayMode: HifzVerseDisplayMode.range,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Al-Ikhlas range (112:1-4)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 112,
            verseNumber: 1,
            endVerseNumber: 4,
            fallbackText: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
            isUnlocked: true,
            isMemorized: false,
            displayMode: HifzVerseDisplayMode.range,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders last verse of a surah (Ash-Sharh 8)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 94,
            verseNumber: 8,
            fallbackText: 'وَإِلَىٰ رَبِّكَ فَارْغَب',
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // ── T004 / T027: Fallback path — invalid identity ─────────────────────────

    testWidgets('shows fallback text when surahNumber is 0 (invalid)', (
      tester,
    ) async {
      const fallback = 'fallback text here';
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 0, // invalid
            verseNumber: 1,
            fallbackText: fallback,
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(find.text('﴿ $fallback ﴾'), findsOneWidget);
    });

    testWidgets('shows fallback text when surahNumber is 115 (invalid)', (
      tester,
    ) async {
      const fallback = 'fallback text invalid surah';
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 115, // invalid
            verseNumber: 1,
            fallbackText: fallback,
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(find.text('﴿ $fallback ﴾'), findsOneWidget);
    });

    testWidgets('shows fallback text when verseNumber is 0 (invalid)', (
      tester,
    ) async {
      const fallback = 'fallback invalid verse';
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 1,
            verseNumber: 0, // invalid
            fallbackText: fallback,
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(find.text('﴿ $fallback ﴾'), findsOneWidget);
    });

    testWidgets(
      'shows fallback text when endVerseNumber < verseNumber (reversed range)',
      (tester) async {
        const fallback = 'fallback reversed range';
        await tester.pumpWidget(
          _wrap(
            const QcfHifzVerseView(
              surahNumber: 1,
              verseNumber: 7,
              endVerseNumber: 3, // reversed — invalid
              fallbackText: fallback,
              isUnlocked: true,
              isMemorized: false,
            ),
          ),
        );
        expect(find.text('﴿ $fallback ﴾'), findsOneWidget);
      },
    );

    testWidgets(
      'shows fallback when fallbackText is provided and identity invalid',
      (tester) async {
        const fallback = 'empty fallback case';
        await tester.pumpWidget(
          _wrap(
            const QcfHifzVerseView(
              surahNumber: -1,
              verseNumber: 1,
              fallbackText: fallback,
              isUnlocked: true,
              isMemorized: false,
            ),
          ),
        );
        expect(find.text('﴿ $fallback ﴾'), findsOneWidget);
      },
    );

    testWidgets('hides a matching terminal number in fallback text', (
      tester,
    ) async {
      const rawFallback = 'قُلْ أَعُوذُ بِرَبِّ النَّاسِ ١';
      const displayedFallback = '﴿ قُلْ أَعُوذُ بِرَبِّ النَّاسِ ﴾';
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 0,
            verseNumber: 1,
            fallbackText: rawFallback,
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );

      expect(find.text(displayedFallback), findsOneWidget);
      expect(find.text(rawFallback), findsNothing);
    });

    testWidgets('never rewrites Quran spacing in fallback text', (
      tester,
    ) async {
      const provided = 'مِن شَرِّالْوَسْوَاسِ';
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 0,
            verseNumber: 1,
            fallbackText: provided,
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );

      expect(find.text('﴿ $provided ﴾'), findsOneWidget);
    });

    testWidgets('hides the matching terminal number from QCF verse text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 112,
            verseNumber: 1,
            fallbackText: 'fallback',
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );

      final expectedRaw = qcf.getVerse(112, 1);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), isNot(expectedRaw));
      expect(richText.text.toPlainText(), '﴿ قُلۡ هُوَ ٱللَّهُ أَحَدٌ ﴾');
    });

    testWidgets('renders literal QCF fixtures for surahs 2, 9, 95 and 97', (
      tester,
    ) async {
      const fixtures = <({int surah, String qcfText, String displayedText})>[
        (surah: 2, qcfText: 'الٓمٓ\u00A0١', displayedText: '﴿ الٓمٓ ﴾'),
        (
          surah: 9,
          qcfText:
              '۞بَرَآءَةٞ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ إِلَى ٱلَّذِينَ عَٰهَدتُّم مِّنَ ٱلۡمُشۡرِكِينَ\u00A0١\n',
          displayedText:
              '﴿ ۞بَرَآءَةٞ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ إِلَى ٱلَّذِينَ عَٰهَدتُّم مِّنَ ٱلۡمُشۡرِكِينَ ﴾',
        ),
        (
          surah: 95,
          qcfText: 'وَٱلتِّينِ وَٱلزَّيۡتُونِ\u00A0١',
          displayedText: '﴿ وَٱلتِّينِ وَٱلزَّيۡتُونِ ﴾',
        ),
        (
          surah: 97,
          qcfText: 'إِنَّآ أَنزَلۡنَٰهُ فِي لَيۡلَةِ ٱلۡقَدۡرِ\u00A0١',
          displayedText: '﴿ إِنَّآ أَنزَلۡنَٰهُ فِي لَيۡلَةِ ٱلۡقَدۡرِ ﴾',
        ),
      ];

      for (final fixture in fixtures) {
        await tester.pumpWidget(
          _wrap(
            QcfHifzVerseView(
              surahNumber: fixture.surah,
              verseNumber: 1,
              fallbackText: 'fallback must not render',
              isUnlocked: true,
              isMemorized: false,
            ),
          ),
        );

        final richText = tester.widget<RichText>(find.byType(RichText));
        expect(
          qcf.getVerse(fixture.surah, 1),
          fixture.qcfText,
          reason: 'QCF corpus drifted at Surah ${fixture.surah}, ayah 1',
        );
        expect(
          richText.text.toPlainText(),
          fixture.displayedText,
          reason: 'Terminal number rendered at Surah ${fixture.surah}',
        );
      }
    });

    testWidgets('renders literal fallback fixtures for surahs 2, 9, 95 and 97', (
      tester,
    ) async {
      const fixtures = <({int surah, String fallbackText})>[
        (surah: 2, fallbackText: 'الٓمٓ'),
        (
          surah: 9,
          fallbackText:
              'بَرَآءَةٌۭ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ إِلَى ٱلَّذِينَ عَٰهَدتُّم مِّنَ ٱلْمُشْرِكِينَ',
        ),
        (surah: 95, fallbackText: 'وَٱلتِّينِ وَٱلزَّيْتُونِ'),
        (
          surah: 97,
          fallbackText: 'إِنَّآ أَنزَلْنَٰهُ فِى لَيْلَةِ ٱلْقَدْرِ',
        ),
      ];

      for (final fixture in fixtures) {
        await tester.pumpWidget(
          _wrap(
            QcfHifzVerseView(
              surahNumber: fixture.surah,
              verseNumber: 1,
              endVerseNumber: 0,
              fallbackText: fixture.fallbackText,
              isUnlocked: true,
              isMemorized: false,
            ),
          ),
        );

        expect(
          find.text('﴿ ${fixture.fallbackText} ﴾'),
          findsOneWidget,
          reason: 'Fallback corpus drifted at Surah ${fixture.surah}, ayah 1',
        );
      }
    });

    // ── T004: Locked state ─────────────────────────────────────────────────────

    testWidgets(
      'shows lock indicator and hides verse when isUnlocked is false',
      (tester) async {
        const fallback = 'secret quran text';
        await tester.pumpWidget(
          _wrap(
            const QcfHifzVerseView(
              surahNumber: 1,
              verseNumber: 1,
              fallbackText: fallback,
              isUnlocked: false, // locked
              isMemorized: false,
            ),
          ),
        );
        // Lock icon should be visible.
        expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
        // Fallback text must NOT be revealed.
        expect(find.text(fallback), findsNothing);
      },
    );

    // ── T004: Memorized state ─────────────────────────────────────────────────

    testWidgets(
      'renders correctly and shows memorized check when isMemorized is true',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const QcfHifzVerseView(
              surahNumber: 1,
              verseNumber: 1,
              fallbackText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              isUnlocked: true,
              isMemorized: true, // memorized
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        // Memorized check icon should be present.
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      },
    );

    testWidgets('does NOT show memorized check when isMemorized is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 1,
            verseNumber: 1,
            fallbackText: 'بِسْمِ اللَّهِ',
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    // ── T020: No repository / Cubit / route access ─────────────────────────────

    testWidgets('uses only constructor inputs — no external access in build', (
      tester,
    ) async {
      // If the widget tried to access any DI service, get_it would throw
      // because no getIt registration exists in the test environment.
      // This test passing confirms the widget is fully self-contained.
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 2,
            verseNumber: 255,
            fallbackText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
            isUnlocked: true,
            isMemorized: false,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // ── T027 / T028: Sample coverage ──────────────────────────────────────────

    testWidgets('renders first verse of a surah (Al-Fatiha 1:1)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 1,
            verseNumber: 1,
            fallbackText: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            isUnlocked: true,
            isMemorized: false,
            displayMode: HifzVerseDisplayMode.single,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // ── displayMode variants ───────────────────────────────────────────────────

    testWidgets('renders in compact mode without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 1,
            verseNumber: 2,
            fallbackText: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
            isUnlocked: true,
            isMemorized: false,
            displayMode: HifzVerseDisplayMode.compact,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in comparison mode without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const QcfHifzVerseView(
            surahNumber: 2,
            verseNumber: 255,
            fallbackText: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ',
            isUnlocked: true,
            isMemorized: false,
            displayMode: HifzVerseDisplayMode.comparison,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
