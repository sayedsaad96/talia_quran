import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2/v2_memorizing_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  testWidgets('first-word hint renders its token and revealed label', (
    tester,
  ) async {
    final state = _activeState(
      V2HintTracker.empty.record(
        surahId: 99,
        ayahNumber: 1,
        level: V2HintLevel.firstWord,
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        cubit: _FakeMemorizationSessionCubit(state),
        child: V2MemorizingPage(state: state),
      ),
    );

    expect(find.text('اختبار'), findsOneWidget);
    expect(find.text('First word revealed'), findsOneWidget);
    expect(find.byKey(const Key('v2-masked-words-toggle')), findsNothing);
  });

  // N2: the default memorizing view used to show the first letter of every
  // word while recording no hint, so a prompted recall graded "excellent".
  testWidgets('without a hint the ayah stays hidden', (tester) async {
    final state = _activeState(V2HintTracker.empty);

    await tester.pumpWidget(
      _TestApp(
        cubit: _FakeMemorizationSessionCubit(state),
        child: V2MemorizingPage(state: state),
      ),
    );

    expect(find.text('Try without a hint first'), findsOneWidget);
    expect(find.textContaining('•'), findsNothing);
    expect(find.text('اختبار'), findsNothing);
  });

  testWidgets('first-letters hint is recorded before the letters show', (
    tester,
  ) async {
    final state = _activeState(V2HintTracker.empty);
    final cubit = _FakeMemorizationSessionCubit(state);

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: V2MemorizingPage(state: state),
      ),
    );
    await tester.tap(find.byKey(const Key('v2-first-letters-hint')));
    await tester.pump();

    expect(cubit.hints, [V2HintLevel.firstWord]);
    expect(find.text('ا•••••'), findsOneWidget);
    expect(find.text('First letters revealed — try to recall'), findsOneWidget);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.cubit, required this.child});

  final MemorizationSessionCubit cubit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MemorizationSessionCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }
}

class _FakeMemorizationSessionCubit extends Cubit<MemorizationSessionState>
    implements MemorizationSessionCubit {
  _FakeMemorizationSessionCubit(super.initialState);

  final hints = <V2HintLevel>[];

  @override
  Future<void> useHint(V2HintLevel level) async => hints.add(level);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MSActive _activeState(V2HintTracker hintTracker) => MSActive(
  sessionState: V2SessionState(
    surahId: 99,
    blockAyahs: const [
      Ayah(
        number: 1,
        surahId: 99,
        text: 'اختبار عبارة بديلة',
        numberInSurah: 1,
      ),
    ],
    currentAyahIndex: 0,
    phase: V2SessionPhase.memorizing,
    passedAyahNumbers: const {},
    hintTracker: hintTracker,
    failureTracker: V2AyahFailureTracker.empty,
    blockReviewRequired: false,
  ),
  isRecording: false,
  isPlaying: false,
  recognizedText: '',
  isEvaluating: false,
);
