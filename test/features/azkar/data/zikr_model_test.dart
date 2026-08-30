import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

void main() {
  group('ZikrModel release parsing', () {
    test('rejects every record that is not explicitly approved', () {
      for (final status in <String?>[
        null,
        'pendingReview',
        'rejected',
        'approvedWithTypo',
      ]) {
        final record = _validReleaseRecord();
        if (status == null) {
          record.remove('reviewStatus');
        } else {
          record['reviewStatus'] = status;
        }

        expect(
          () => ZikrModel.fromJson(record, AzkarCategory.morning),
          throwsFormatException,
          reason: 'status $status must fail closed',
        );
      }
    });

    test('rejects approved records with incomplete release metadata', () {
      for (final field in <String>[
        'citation',
        'sourceType',
        'datasetVersion',
      ]) {
        final record = _validReleaseRecord()..remove(field);

        expect(
          () => ZikrModel.fromJson(record, AzkarCategory.morning),
          throwsFormatException,
          reason: 'missing $field must fail closed',
        );
      }
    });

    test('preserves an approved record without inventing grade or tier', () {
      final record = _validReleaseRecord()
        ..['sourceType'] = 'hadith'
        ..remove('authenticityGrade')
        ..remove('tier');

      final zikr = ZikrModel.fromJson(record, AzkarCategory.morning);

      expect(zikr.reviewStatus, ContentReviewStatus.approved);
      expect(zikr.authenticityGrade, isNull);
      expect(zikr.tier, isNull);
      expect(zikr.sourceType, 'hadith');
      expect(zikr.citation, 'Quran 2:201');
    });

    test('accepts a complete approved Quran record without a hadith grade', () {
      final zikr = ZikrModel.fromJson(
        _validReleaseRecord(),
        AzkarCategory.morning,
      );

      expect(zikr.reviewStatus, ContentReviewStatus.approved);
      expect(zikr.authenticityGrade, isNull);
      expect(zikr.datasetVersion, 'v1-reviewed-1');
    });
  });
}

Map<String, dynamic> _validReleaseRecord() => <String, dynamic>{
  'id': 'morning-001',
  'text': 'نص معتمد للاختبار',
  'count': 1,
  'citation': 'Quran 2:201',
  'sourceType': 'quran',
  'authenticityGrade': null,
  'tier': 'essential',
  'datasetVersion': 'v1-reviewed-1',
  'reviewStatus': 'approved',
};
