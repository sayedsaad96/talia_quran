import '../../domain/entities/quran_entities.dart';

class SurahModel extends Surah {
  const SurahModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.ayahCount,
    required super.juz,
    required super.type,
    required super.page,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      id: json['id'] as int,
      nameAr: json['nameAr'] as String,
      nameEn: json['nameEn'] as String,
      ayahCount: json['ayahCount'] as int,
      juz: json['juz'] as int,
      type: json['type'] as String,
      page: json['page'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'ayahCount': ayahCount,
    'juz': juz,
    'type': type,
    'page': page,
  };
}
