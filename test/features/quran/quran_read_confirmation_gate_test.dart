import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/services/quran_read_confirmation_gate.dart';

void main() {
  group('QuranReadConfirmationGate', () {
    test('open page and do nothing is not counted', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.shouldConfirm(1), isFalse);
    });

    test('timer elapsed without interaction is not counted', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.registerTimerElapsed(1), isFalse);
      expect(gate.shouldConfirm(1), isFalse);
    });

    test('interaction then timer elapsed is counted', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.registerInteraction(1), isFalse);
      expect(gate.registerTimerElapsed(1), isTrue);
    });

    test('timer elapsed then navigation interaction is counted once', () {
      final gate = QuranReadConfirmationGate();

      expect(gate.registerTimerElapsed(2), isFalse);
      expect(gate.registerInteraction(2), isTrue);
      gate.markPending(2);
      expect(gate.shouldConfirm(2), isFalse);
      expect(gate.markConfirmed(2), isTrue);
      expect(gate.registerInteraction(2), isFalse);
      expect(gate.registerTimerElapsed(2), isFalse);
    });
  });
}
