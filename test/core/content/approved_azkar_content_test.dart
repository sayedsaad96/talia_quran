import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/content/approved_azkar_content.dart';

void main() {
  test('extracts only complete approved text without rewriting it', () {
    const approvedText = '  نص معتمد يبقى كما هو  ';
    final source = jsonEncode({
      'duas': [
        _record(id: 'pending', reviewStatus: 'pendingReview'),
        _record(id: 'missing-citation')..remove('citation'),
        _record(id: 'approved', text: approvedText),
      ],
    });

    expect(extractApprovedAzkarTexts(source, category: 'duas'), [approvedText]);
  });

  test('requires a grade for every approved non-Quran source', () {
    final source = jsonEncode({
      'morning': [
        _record(id: 'ungraded', sourceType: 'hadith')
          ..remove('authenticityGrade'),
        _record(id: 'graded', sourceType: 'hadith', authenticityGrade: 'sahih'),
      ],
    });

    expect(extractApprovedAzkarTexts(source, category: 'morning'), [
      'نص graded',
    ]);
  });

  test('does not emit notification text for duplicate stable IDs', () {
    final source = jsonEncode({
      'evening': [
        _record(id: 'duplicate', text: 'النص الأول'),
        _record(id: 'duplicate', text: 'النص الثاني'),
        _record(id: 'unique', text: 'نص فريد'),
      ],
    });

    expect(extractApprovedAzkarTexts(source, category: 'evening'), ['نص فريد']);
  });

  test('fails closed when its stable ID is duplicated in another category', () {
    final source = jsonEncode({
      'morning': [_record(id: 'shared-id', text: 'نص الصباح')],
      'evening': [_record(id: 'shared-id', text: 'نص المساء')],
    });

    expect(extractApprovedAzkarTexts(source, category: 'morning'), isEmpty);
    expect(extractApprovedAzkarTexts(source, category: 'evening'), isEmpty);
  });
}

Map<String, dynamic> _record({
  required String id,
  String? text,
  String reviewStatus = 'approved',
  String sourceType = 'quran',
  String? authenticityGrade,
}) => <String, dynamic>{
  'id': id,
  'text': text ?? 'نص $id',
  'count': 1,
  'citation': 'مرجع $id',
  'sourceType': sourceType,
  'authenticityGrade': authenticityGrade,
  'tier': 'essential',
  'datasetVersion': 'v1-reviewed-1',
  'reviewStatus': reviewStatus,
};
