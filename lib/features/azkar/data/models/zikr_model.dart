import '../../domain/entities/azkar_entities.dart';

class ZikrModel extends Zikr {
  const ZikrModel({
    required super.id,
    required super.text,
    required super.transliteration,
    required super.translation,
    required super.totalCount,
    required super.category,
    super.reference,
    super.subcategory,
    super.citation,
    super.sourceType,
    super.authenticityGrade,
    super.tier,
    super.reviewStatus,
    super.datasetVersion = 'unversioned',
  });

  factory ZikrModel.fromJson(
    Map<String, dynamic> json,
    AzkarCategory category,
  ) {
    final id = _requiredString(json, 'id');
    final text = _requiredString(json, 'text');
    final citation = _requiredString(json, 'citation');
    final sourceType = _requiredString(json, 'sourceType');
    final datasetVersion = _requiredString(json, 'datasetVersion');
    final count = json['count'];
    if (count is! int || count < 1) {
      throw const FormatException('count must be an integer of at least 1');
    }
    if (!const {'quran', 'hadith', 'dhikr', 'dua'}.contains(sourceType)) {
      throw FormatException('Unsupported sourceType: $sourceType');
    }
    if (datasetVersion == 'unversioned') {
      throw const FormatException('datasetVersion must identify a review set');
    }

    final reviewStatus = ContentReviewStatus.values.firstWhereOrNull(
      (status) => status.name == json['reviewStatus'],
    );
    if (reviewStatus != ContentReviewStatus.approved) {
      throw const FormatException('Only approved records may be released');
    }

    final tier = DuaTier.values.firstWhereOrNull(
      (value) => value.name == json['tier'],
    );
    if (json['tier'] != null && tier == null) {
      throw const FormatException('Unsupported tier');
    }

    final authenticityGrade = AuthenticityGrade.values.firstWhereOrNull(
      (grade) => grade.name == json['authenticityGrade'],
    );
    if (json['authenticityGrade'] != null && authenticityGrade == null) {
      throw const FormatException('Unsupported authenticityGrade');
    }

    return ZikrModel(
      id: id,
      text: text,
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      totalCount: count,
      category: category,
      reference: json['reference'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      citation: citation,
      sourceType: sourceType,
      authenticityGrade: authenticityGrade,
      tier: tier,
      datasetVersion: datasetVersion,
      reviewStatus: ContentReviewStatus.approved,
    );
  }
}

String _requiredString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
