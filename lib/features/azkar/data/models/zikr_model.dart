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
  });

  factory ZikrModel.fromJson(
    Map<String, dynamic> json,
    AzkarCategory category,
  ) {
    return ZikrModel(
      id: json['id'] as String,
      text: json['text'] as String,
      transliteration: json['transliteration'] as String? ?? '',
      translation: json['translation'] as String? ?? '',
      totalCount: json['count'] as int? ?? 1,
      category: category,
      reference: json['reference'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
    );
  }
}
