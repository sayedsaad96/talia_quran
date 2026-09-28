import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/v2/listen_budget.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/core/memorization/v2/session_state.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

/// A6 — long block reviews must not be cut off by a fixed listening window.
void main() {
  // Neutral fixture text (not Quran): 60 words per ayah.
  final longAyahText = List.filled(60, 'كلمة').join(' ');

  V2SessionState state(V2SessionPhase phase, {int ayahs = 5}) =>
      V2SessionState.initial(
        surahId: 2,
        blockAyahs: [
          for (var i = 1; i <= ayahs; i++)
            Ayah(number: i, surahId: 2, text: longAyahText, numberInSurah: i),
        ],
        blockReviewRequired: true,
      ).copyWith(phase: phase);

  test('a long block review listens long enough for every ayah', () {
    final budget = V2ListenBudget.forState(state(V2SessionPhase.blockReview));

    // 300 words at a generous pace needs well over the old implicit window.
    expect(budget.listenFor.inSeconds, greaterThanOrEqualTo(250));
    expect(budget.pauseFor, const Duration(seconds: 8));
  });

  test('a single ayah keeps a short pause window', () {
    final budget = V2ListenBudget.forState(state(V2SessionPhase.reciting));

    expect(budget.pauseFor, const Duration(seconds: 5));
    expect(budget.listenFor.inSeconds, inInclusiveRange(30, 300));
  });

  test('the window is bounded', () {
    final huge = V2ListenBudget.forState(
      state(V2SessionPhase.blockReview, ayahs: 20),
    );
    expect(huge.listenFor, const Duration(seconds: 300));
  });
}
