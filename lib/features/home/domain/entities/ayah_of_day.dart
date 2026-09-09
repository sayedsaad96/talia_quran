import 'package:equatable/equatable.dart';

class AyahOfDay extends Equatable {
  const AyahOfDay({
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    required this.surahNameAr,
    required this.surahNameEn,
    required this.pageNumber,
  });

  final int surahId;
  final int ayahNumber;
  final String text;
  final String surahNameAr;
  final String surahNameEn;
  final int pageNumber;

  @override
  List<Object?> get props => [surahId, ayahNumber, text, pageNumber];
}

class DailyAyahRef {
  const DailyAyahRef({required this.surahId, required this.ayahNumber});
  final int surahId;
  final int ayahNumber;
}
