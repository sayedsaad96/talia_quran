import 'dart:convert';

const _sourceTypes = {'quran', 'hadith', 'dhikr', 'dua'};
const _tiers = {'essential', 'recommended', 'supplementary'};
const _grades = {'sahih', 'hasan', 'daif', 'mawquf'};

/// Extracts notification text from records that satisfy the release contract.
/// Invalid or unapproved records are ignored so religious notifications fail
/// closed even if the bundled asset is accidentally malformed.
List<String> extractApprovedAzkarTexts(
  String source, {
  required String category,
}) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) return const [];
  final records = decoded[category];
  if (records is! List<dynamic>) return const [];

  final approvedRecords = <Map<String, dynamic>>[];
  for (final record in records) {
    if (record is Map<String, dynamic> && _isApprovedReleaseRecord(record)) {
      approvedRecords.add(record);
    }
  }

  final idCounts = _approvedIdCounts(decoded);
  return List.unmodifiable([
    for (final record in approvedRecords)
      if (idCounts[record['id']] == 1) record['text'] as String,
  ]);
}

Map<String, int> _approvedIdCounts(Map<String, dynamic> source) {
  final counts = <String, int>{};
  for (final records in source.values) {
    if (records is! List<dynamic>) continue;
    for (final record in records) {
      if (record is Map<String, dynamic> && _isApprovedReleaseRecord(record)) {
        final id = record['id'] as String;
        counts.update(id, (count) => count + 1, ifAbsent: () => 1);
      }
    }
  }
  return counts;
}

bool _isApprovedReleaseRecord(Map<String, dynamic> record) {
  if (record['reviewStatus'] != 'approved') return false;
  if (!_hasText(record, 'id') ||
      !_hasText(record, 'text') ||
      !_hasText(record, 'citation') ||
      !_hasText(record, 'datasetVersion')) {
    return false;
  }
  if (record['datasetVersion'] == 'unversioned') return false;

  final count = record['count'];
  if (count is! int || count < 1) return false;

  final sourceType = record['sourceType'];
  if (sourceType is! String || !_sourceTypes.contains(sourceType)) return false;
  if (!_tiers.contains(record['tier'])) return false;

  final grade = record['authenticityGrade'];
  if (sourceType != 'quran' && !_grades.contains(grade)) return false;
  return grade == null || _grades.contains(grade);
}

bool _hasText(Map<String, dynamic> record, String field) {
  final value = record[field];
  return value is String && value.trim().isNotEmpty;
}
