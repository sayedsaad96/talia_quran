import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/home/presentation/widgets/home_unified_progress.dart';

void main() {
  group('HomeUnifiedProgress.memorizedPercent', () {
    String percent(int memorized) =>
        HomeUnifiedProgress.memorizedPercent(memorized, 6236);

    test('nothing memorized reads 0', () {
      expect(percent(0), '0');
      expect(HomeUnifiedProgress.memorizedPercent(3, 0), '0');
    });

    test('a few ayahs never round down to 0', () {
      expect(percent(1), '<0.1');
      expect(percent(6), '<0.1');
    });

    test('below 10% shows one decimal, never rounded up', () {
      expect(percent(7), '0.1');
      expect(percent(156), '2.5');
      expect(percent(623), '9.9');
    });

    test('from 10% shows whole numbers, never rounded up', () {
      expect(percent(624), '10');
      expect(percent(6235), '99');
      expect(percent(6236), '100');
    });
  });
}
