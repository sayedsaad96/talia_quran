import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/learning_launch_context.dart';
import 'package:talia_quran/core/memorization/v2/ayah_failure_tracker.dart';
import 'package:talia_quran/core/memorization/v2/hint_usage.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/v2_session_page.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  testWidgets('discard action clears the session before leaving', (
    tester,
  ) async {
    final cubit = _ExitTestCubit(_activeState());
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: FilledButton(
              onPressed: () => context.push('/session'),
              child: const Text('Open session'),
            ),
          ),
        ),
        GoRoute(
          path: '/session',
          builder: (_, _) => V2SessionPage(
            surahId: 1,
            startAyah: 1,
            blockSize: 1,
            cubitOverride: cubit,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('Open session'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save & leave'), findsOneWidget);
    expect(find.text('Discard session'), findsOneWidget);

    await tester.tap(find.text('Discard session'));
    await tester.pumpAndSettle();

    expect(cubit.discardCalls, 1);
    expect(find.text('Open session'), findsOneWidget);
  });
}

MSActive _activeState() => const MSActive(
  sessionState: V2SessionState(
    surahId: 1,
    blockAyahs: [
      Ayah(
        surahId: 1,
        numberInSurah: 1,
        number: 1,
        juz: 1,
        page: 1,
        text: 'Ayah 1',
      ),
    ],
    currentAyahIndex: 0,
    phase: V2SessionPhase.learning,
    passedAyahNumbers: {},
    hintTracker: V2HintTracker.empty,
    failureTracker: V2AyahFailureTracker.empty,
    blockReviewRequired: true,
  ),
  isRecording: false,
  isPlaying: false,
  recognizedText: '',
  isEvaluating: false,
);

class _ExitTestCubit extends Cubit<MemorizationSessionState>
    implements MemorizationSessionCubit {
  _ExitTestCubit(super.initialState);

  int discardCalls = 0;

  @override
  Future<void> startSession({
    required int surahId,
    required int startAyah,
    int blockSize = 5,
    LearningLaunchContext? launchContext,
  }) async {}

  @override
  Future<bool> discardSession() async {
    discardCalls += 1;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
