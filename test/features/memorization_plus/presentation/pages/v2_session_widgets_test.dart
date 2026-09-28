import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/core/widgets/memorization_ayah_display.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_session_widgets.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  const ayahText = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ';

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  testWidgets('full V2 ayah keeps supplied text and Home ayah treatment', (
    tester,
  ) async {
    await tester.pumpWidget(host(const V2AyahTextCard(session: _session)));

    expect(find.text(ayahText), findsOneWidget);
    expect(find.byType(MemorizationAyahDisplay), findsOneWidget);
    expect(find.text('﴿'), findsOneWidget);
    expect(find.text('﴾'), findsOneWidget);
    expect(find.text('Surah Al-Fatihah, Ayah 1'), findsOneWidget);

    final text = tester.widget<Text>(
      find.byKey(const Key('memorization-ayah-text')),
    );
    expect(text.style?.fontFamily, 'Amiri');
    expect(text.style?.fontSize, 24);
    expect(text.style?.height, 2);
  });

  testWidgets('masked hint preserves masking and uses the shared Amiri style', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        V2MaskedWordsCard(
          text: ayahText,
          surahId: 1,
          ayahNumber: 1,
          revealed: false,
          onToggle: () {},
        ),
      ),
    );

    final maskedWord = tester.widget<Text>(find.textContaining('ٱ•••••').first);
    expect(maskedWord.style?.fontFamily, 'Amiri');
    expect(maskedWord.style?.fontSize, 24);
  });

  testWidgets('revealed masked hint adds the localized full-ayah reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        V2MaskedWordsCard(
          text: ayahText,
          surahId: 1,
          ayahNumber: 1,
          revealed: true,
          onToggle: () {},
        ),
      ),
    );

    expect(find.byType(MemorizationAyahDisplay), findsOneWidget);
    expect(find.text('Surah Al-Fatihah, Ayah 1'), findsOneWidget);
  });
}

const _session = V2SessionState(
  surahId: 1,
  blockAyahs: [
    Ayah(
      number: 1,
      surahId: 1,
      text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
      numberInSurah: 1,
    ),
  ],
  currentAyahIndex: 0,
  phase: V2SessionPhase.learning,
  passedAyahNumbers: {},
  hintTracker: V2HintTracker.empty,
  failureTracker: V2AyahFailureTracker.empty,
  blockReviewRequired: false,
);
