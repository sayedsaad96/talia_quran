import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/services/quran_read_confirmation_gate.dart';

void main() {
  group('QuranReadConfirmationGate', () {
    test('open page before its reading time is not counted', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.shouldConfirm(1), isFalse);
    });

    test('reading time elapsed is counted without a touch', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.registerTimerElapsed(1), isTrue);
      expect(gate.shouldConfirm(1), isTrue);
    });

    test('a page is counted once', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.registerTimerElapsed(2), isTrue);
      gate.markPending(2);
      expect(gate.shouldConfirm(2), isFalse);
      expect(gate.markConfirmed(2), isTrue);
      expect(gate.registerTimerElapsed(2), isFalse);
      expect(gate.markConfirmed(2), isFalse);
    });
  });

  group('QuranReadConfirmationGate.requiredSeconds', () {
    test('short pages wait at least 5 seconds', () {
      expect(QuranReadConfirmationGate.requiredSeconds(0), 5);
      expect(QuranReadConfirmationGate.requiredSeconds(120), 5);
    });

    test('grows with the page text', () {
      // Al-Fatihah (page 1) and the opening of Al-Baqarah (page 2).
      expect(QuranReadConfirmationGate.requiredSeconds(286), 8);
      expect(QuranReadConfirmationGate.requiredSeconds(385), 10);
    });

    test('a full mushaf page waits at most 25 seconds', () {
      expect(QuranReadConfirmationGate.requiredSeconds(1213), 25);
      expect(QuranReadConfirmationGate.requiredSeconds(5000), 25);
    });
  });

  test('a released pending page can be confirmed again (B4)', () {
    final gate = QuranReadConfirmationGate();
    gate.registerTimerElapsed(7);
    gate.markPending(7);
    expect(gate.shouldConfirm(7), isFalse);

    gate.clearPending(7);

    expect(gate.shouldConfirm(7), isTrue);
  });
}
