import 'dart:convert';

/// Stable position in the review-record delta stream.
///
/// `updated_at` alone is not a total order: rows sharing a timestamp must be
/// disambiguated by their database identity to avoid skipping a page boundary.
class ReviewRecordPullCursor {
  const ReviewRecordPullCursor(this.updatedAt, this.id);

  final DateTime updatedAt;
  final int id;

  static final epoch = ReviewRecordPullCursor(
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    0,
  );

  factory ReviewRecordPullCursor.fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return epoch;
    try {
      if (!raw.startsWith('{')) {
        return ReviewRecordPullCursor(DateTime.parse(raw).toUtc(), 0);
      }
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return ReviewRecordPullCursor(
        DateTime.parse(json['updated_at'] as String).toUtc(),
        _asInt(json['id']) ?? 0,
      );
    } catch (_) {
      return epoch;
    }
  }

  factory ReviewRecordPullCursor.fromCloudRow(Map<String, dynamic> row) {
    final updatedAt = row['updated_at'];
    final id = _asInt(row['id']);
    if (updatedAt is! String || id == null) {
      throw const FormatException('Invalid review-record pull cursor row');
    }
    return ReviewRecordPullCursor(DateTime.parse(updatedAt).toUtc(), id);
  }

  bool isBefore(ReviewRecordPullCursor other) {
    final timestampOrder = updatedAt.toUtc().compareTo(other.updatedAt.toUtc());
    return timestampOrder < 0 || (timestampOrder == 0 && id < other.id);
  }

  String toStorage() =>
      jsonEncode({'updated_at': updatedAt.toUtc().toIso8601String(), 'id': id});

  @override
  bool operator ==(Object other) =>
      other is ReviewRecordPullCursor &&
      updatedAt.toUtc() == other.updatedAt.toUtc() &&
      id == other.id;

  @override
  int get hashCode => Object.hash(updatedAt.toUtc(), id);

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
