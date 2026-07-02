import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/leech_analysis_usecase.dart';

void main() {
  late LeechAnalysisUsecase usecase;
  late DateTime now;

  setUp(() {
    usecase = const LeechAnalysisUsecase();
    now = DateTime(2026, 1, 1).toUtc();
  });

  AyahReviewRecord createRecord({
    int lapses = 0,
  }) {
    return AyahReviewRecord(
      surahId: 1,
      ayahNumber: 1,
      strengthLevel: 1,
      intervalDays: 1,
      lastReviewedAt: now,
      nextReviewDate: now,
      totalReviews: 1,
      lastRating: PerformanceRating.excellent,
      lapses: lapses,
    );
  }

  group('LeechAnalysisUsecase', () {
    test('Empty list returns all zeros', () {
      final result = usecase.analyze([]);
      expect(result.totalLeeches, 0);
      expect(result.percentageOfLeeches, 0.0);
      expect(result.averageLapses, 0.0);
    });

    test('Identifies leeches correctly (lapses >= 8)', () {
      final records = [
        createRecord(lapses: 0),
        createRecord(lapses: 7),
        createRecord(lapses: 8), // Leech
        createRecord(lapses: 12), // Leech
      ];

      final result = usecase.analyze(records);
      expect(result.totalLeeches, 2);
      expect(result.percentageOfLeeches, 0.5); // 2 out of 4
      expect(result.averageLapses, (8 + 12) / 2); // 10.0
    });

    test('No leeches in dataset', () {
      final records = [
        createRecord(lapses: 1),
        createRecord(lapses: 2),
      ];

      final result = usecase.analyze(records);
      expect(result.totalLeeches, 0);
      expect(result.percentageOfLeeches, 0.0);
      expect(result.averageLapses, 0.0);
    });

    test('All leeches in dataset', () {
      final records = [
        createRecord(lapses: 10),
        createRecord(lapses: 20),
      ];

      final result = usecase.analyze(records);
      expect(result.totalLeeches, 2);
      expect(result.percentageOfLeeches, 1.0);
      expect(result.averageLapses, 15.0);
    });
  });
}
