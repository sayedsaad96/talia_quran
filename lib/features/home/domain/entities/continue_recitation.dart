import 'package:equatable/equatable.dart';

enum ContinueRecitationUnit { ayahs, pages }

class ContinueRecitation extends Equatable {
  const ContinueRecitation({
    required this.surahName,
    required this.current,
    required this.total,
    required this.percent,
    required this.route,
    required this.unit,
    this.startAyah,
    this.endAyah,
    this.versePreview,
    this.surahId,
  });

  final String surahName;
  final int? surahId;
  final int? startAyah;
  final int? endAyah;
  final int current;
  final int total;
  final double percent;
  final String route;
  final ContinueRecitationUnit unit;
  final String? versePreview;

  @override
  List<Object?> get props => [
    surahName,
    startAyah,
    endAyah,
    current,
    total,
    percent,
    route,
    unit,
    versePreview,
    surahId,
  ];
}
