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
    AzkarCategory category, {
    String datasetVersion = 'unversioned',
  }) {
    return ZikrModel(
      id: json['id'] as String,
      text: json['text'] as String,
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      totalCount: json['count'] as int? ?? 1,
      category: category,
      reference: json['reference'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      citation: json['citation'] as String?,
      sourceType: json['sourceType'] as String?,
      authenticityGrade: AuthenticityGrade.values.firstWhereOrNull(
        (g) => g.name == json['authenticityGrade'],
      ),
      tier: DuaTier.values.firstWhereOrNull((t) => t.name == json['tier']),
      datasetVersion:
          json['datasetVersion'] as String? ?? datasetVersion,
      reviewStatus: ContentReviewStatus.values.firstWhereOrNull(
            (s) => s.name == json['reviewStatus'],
          ) ??
          ContentReviewStatus.pendingReview,
    );
  }
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
