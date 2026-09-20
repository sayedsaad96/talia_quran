import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('V2CompletionPage closing moment', () {
    testWidgets('renders serene closing moment before statistics',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: V2CompletionPage(finalState: _completedState(passed: 3)),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('v2_closing_moment')), findsOneWidget);
      expect(find.text('A moment of closure'), findsOneWidget);
      expect(
        find.text('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'),
        findsOneWidget,
      );
      expect(find.text("Surah Ar-Ra'd · Ayah 28"), findsOneWidget);
      expect(
        find.text(
          'You committed 3 ayahs to memory this session — a lasting impact, in shaa Allah.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Take a breath… your memorization awaits you tomorrow, in shaa Allah.',
        ),
        findsOneWidget,
      );
      expect(find.text('3/3'), findsOneWidget);
      expect(find.text('Closing dua'), findsOneWidget);
      expect(find.text('Share memorization milestone'), findsOneWidget);
    });

    testWidgets('opening closing dua shows serene dua sheet', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: V2CompletionPage(finalState: _completedState(passed: 3)),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('v2_closing_dua_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('closing_dua_text')), findsOneWidget);
      expect(find.byKey(const Key('closing_dua_amen')), findsOneWidget);
      expect(find.text('Ameen'), findsOneWidget);
    });
  });
}

V2SessionState _completedState({required int passed}) {
  final blockAyahs = List<Ayah>.generate(
    passed,
    (i) => Ayah(
      number: i + 1,
      surahId: 1,
      text: 'آية تجريبية ${i + 1}',
      numberInSurah: i + 1,
    ),
  );
  return V2SessionState.initial(
    surahId: 1,
    blockAyahs: blockAyahs,
    blockReviewRequired: false,
  ).copyWith(
    phase: V2SessionPhase.completed,
    passedAyahNumbers: Set<int>.from(
      Iterable<int>.generate(passed, (i) => i + 1),
    ),
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }
}
