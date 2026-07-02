import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_insights_report.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/migration_readiness_usecase.dart';

void main() {
  late MigrationReadinessUsecase usecase;

  setUp(() {
    usecase = const MigrationReadinessUsecase();
  });

  group('MigrationReadinessUsecase', () {
    test('Insufficient Data (<100 records)', () {
      final result = usecase.analyze(
        agreementScore: 0.95,
        totalRecords: 99,
        analyticsConfidence: AnalyticsConfidence.high,
      );
      expect(result.readinessLevel, MigrationReadinessLevel.insufficientData);
      expect(result.readinessScore, 0.95);
    });

    test('Insufficient Data (AnalyticsConfidence.low gate)', () {
      final result = usecase.analyze(
        agreementScore: 0.99,
        totalRecords: 5000,
        analyticsConfidence: AnalyticsConfidence.low,
      );
      expect(result.readinessLevel, MigrationReadinessLevel.insufficientData);
    });

    test('High Readiness (Score >= 0.85)', () {
      final result = usecase.analyze(
        agreementScore: 0.85,
        totalRecords: 100,
        analyticsConfidence: AnalyticsConfidence.medium,
      );
      expect(result.readinessLevel, MigrationReadinessLevel.high);
    });

    test('Medium Readiness (0.70 <= Score < 0.85)', () {
      final result1 = usecase.analyze(
        agreementScore: 0.849,
        totalRecords: 150,
        analyticsConfidence: AnalyticsConfidence.medium,
      );
      expect(result1.readinessLevel, MigrationReadinessLevel.medium);

      final result2 = usecase.analyze(
        agreementScore: 0.70,
        totalRecords: 1000,
        analyticsConfidence: AnalyticsConfidence.high,
      );
      expect(result2.readinessLevel, MigrationReadinessLevel.medium);
    });

    test('Low Readiness (Score < 0.70)', () {
      final result = usecase.analyze(
        agreementScore: 0.69,
        totalRecords: 150,
        analyticsConfidence: AnalyticsConfidence.medium,
      );
      expect(result.readinessLevel, MigrationReadinessLevel.low);
    });
  });
}
