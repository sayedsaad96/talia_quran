import '../../domain/entities/quran_entities.dart';

class AyahModel extends Ayah {
  const AyahModel({
    required super.number,
    required super.surahId,
    required super.text,
    required super.numberInSurah,
    super.juz,
    super.page,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      number: json['number'] as int,
      surahId: json['surahId'] as int,
      text: json['text'] as String,
      numberInSurah: json['numberInSurah'] as int,
      juz: json['juz'] as int?,
      page: json['page'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'surahId': surahId,
        'text': text,
        'numberInSurah': numberInSurah,
        'juz': juz,
        'page': page,
      };
}
