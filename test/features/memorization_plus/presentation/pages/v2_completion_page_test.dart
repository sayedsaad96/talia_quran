import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/widgets/closing_moment.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_completion_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// Canonical Uthmani text of Ar-Ra'd 13:28 as stored in assets/data/quran.json.
const _canonical1328 =
    'ٱلَّذِينَ ءَامَنُوا۟ وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ ٱللَّهِ ۗ أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ';

void main() {
  setUp(() async {
    await getIt.reset();
    ClosingMomentAyahCard.resetCacheForTest();
    getIt.registerSingleton<QuranRepository>(_ClosingAyahRepository());
    getIt.registerLazySingleton<KhatmDuaDatasource>(KhatmDuaDatasource.new);
  });

  tearDown(() async {
    await getIt.reset();
    ClosingMomentAyahCard.resetCacheForTest();
  });

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
      // The full ayah from the corpus, never a hand-typed excerpt.
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('closing_moment_ayah')), findsOneWidget);
      expect(find.text(_canonical1328), findsOneWidget);
      expect(
        find.text('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ'),
        findsNothing,
      );
      expect(
        find.text(
          'You learned 3 ayahs this session — reviews will make them stick, in shaa Allah.',
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

    testWidgets('shows no ayah when the canonical corpus is unavailable', (
      tester,
    ) async {
      await getIt.reset();
      ClosingMomentAyahCard.resetCacheForTest();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: V2CompletionPage(finalState: _completedState(passed: 3)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('v2_closing_moment')), findsOneWidget);
      expect(find.byKey(const Key('closing_moment_ayah')), findsNothing);
    });

    testWidgets(
      "offers the next item of today's plan as the primary action (M-U6)",
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(900, 1600);
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _TestApp(
            child: V2CompletionPage(
              finalState: _completedState(passed: 3),
              nextStepLoader: () async =>
                  (route: '/memorization-v2?surahId=36', remaining: 4),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byKey(const Key('v2_next_plan_item_button')), findsOneWidget);
        expect(find.textContaining('4'), findsWidgets);
      },
    );

    testWidgets('without remaining plan work only the hub is offered', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: V2CompletionPage(
            finalState: _completedState(passed: 3),
            nextStepLoader: () async => null,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('v2_next_plan_item_button')), findsNothing);
    });

    testWidgets('the closing dua is the first paragraph of the approved '
        'khatm dua, verbatim', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _TestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showClosingDuaSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      final record =
          jsonDecode(File('assets/data/khatm_dua.json').readAsStringSync())
              as Map<String, dynamic>;
      expect(record['reviewStatus'], 'approved');
      final firstParagraph = (record['arabicText'] as String)
          .split('\n\n')
          .first
          .trim();
      final shown = tester.widget<Text>(
        find.byKey(const Key('closing_dua_text')),
      );
      expect(shown.data, firstParagraph);
      expect(find.byKey(const Key('closing_dua_amen')), findsOneWidget);
      expect(find.text('Ameen'), findsOneWidget);
    });

    testWidgets('an unapproved khatm dua record opens nothing', (
      tester,
    ) async {
      await getIt.unregister<KhatmDuaDatasource>();
      getIt.registerSingleton<KhatmDuaDatasource>(_PendingKhatmDuaDatasource());

      await tester.pumpWidget(
        _TestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showClosingDuaSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('closing_dua_text')), findsNothing);
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

class _ClosingAyahRepository implements QuranRepository {
  @override
  Future<Either<Failure, SurahDetail>> getSurahDetail(int surahId) async {
    return const Right(
      SurahDetail(
        surah: Surah(
          id: 13,
          nameAr: 'الرعد',
          nameEn: "Ar-Ra'd",
          ayahCount: 43,
          type: 'medinan',
          juz: 13,
          page: 249,
        ),
        ayahs: [
          Ayah(
            surahId: 13,
            numberInSurah: 28,
            number: 1735,
            juz: 13,
            page: 252,
            text: _canonical1328,
          ),
        ],
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PendingKhatmDuaDatasource extends KhatmDuaDatasource {
  @override
  Future<KhatmDuaData> loadDua() async =>
      const KhatmDuaData(
        arabicText: 'text',
        source: 'source',
        sourceNote: 'note',
        tier: 'guidance',
        dedicationInserts: {},
      );
}
