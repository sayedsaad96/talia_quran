import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2_session_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  group('V2 block review UI', () {
    testWidgets('pending screen starts block review through the cubit', (
      tester,
    ) async {
      final cubit = _FakeMemorizationSessionCubit(
        _activeState(phase: V2SessionPhase.blockReviewPending),
      );

      await tester.pumpWidget(
        _TestApp(
          cubit: cubit,
          child: V2BlockReviewPendingPage(state: cubit.state as MSActive),
        ),
      );

      expect(find.text('Block review'), findsOneWidget);
      expect(find.text('Start Block Review'), findsOneWidget);
      expect(find.text('Session complete'), findsNothing);

      await tester.tap(find.text('Start Block Review'));
      await tester.pump();

      expect(cubit.startBlockReviewCalls, 1);
    });

    testWidgets(
      'block review screen hides target ayah text and records via STT',
      (tester) async {
        final cubit = _FakeMemorizationSessionCubit(
          _activeState(phase: V2SessionPhase.blockReview),
        );

        await tester.pumpWidget(
          _TestApp(
            cubit: cubit,
            child: V2BlockReviewPage(state: cubit.state as MSActive),
          ),
        );

        expect(find.text('Recite the full block'), findsOneWidget);
        expect(find.text('Ayahs 1-2'), findsOneWidget);
        expect(find.textContaining('الحمد'), findsNothing);
        expect(find.textContaining('الرحمن'), findsNothing);

        await tester.tap(find.text('Start recording'));
        await tester.pump();

        expect(cubit.startRecordingCalls, 1);
      },
    );
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
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }
}

class _FakeMemorizationSessionCubit extends Cubit<MemorizationSessionState>
    implements MemorizationSessionCubit {
  _FakeMemorizationSessionCubit(super.initialState);

  int startBlockReviewCalls = 0;
  int startRecordingCalls = 0;
  int stopRecordingCalls = 0;

  @override
  Future<void> startBlockReview() async {
    startBlockReviewCalls += 1;
  }

  @override
  Future<void> startRecording() async {
    startRecordingCalls += 1;
  }

  @override
  Future<void> stopRecording() async {
    stopRecordingCalls += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MSActive _activeState({required V2SessionPhase phase}) {
  return MSActive(
    sessionState: V2SessionState(
      surahId: 1,
      blockAyahs: const [
        Ayah(
          number: 1,
          surahId: 1,
          text: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
          numberInSurah: 1,
        ),
        Ayah(
          number: 2,
          surahId: 1,
          text: 'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          numberInSurah: 2,
        ),
      ],
      currentAyahIndex: 0,
      phase: phase,
      passedAyahNumbers: const {1, 2},
      hintTracker: V2HintTracker.empty,
      failureTracker: V2AyahFailureTracker.empty,
      blockReviewRequired: true,
    ),
    isRecording: false,
    isPlaying: false,
    recognizedText: '',
    isEvaluating: false,
  );
}
