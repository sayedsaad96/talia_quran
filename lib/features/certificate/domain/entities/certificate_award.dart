/// Domain entity — certificate earned by the user for completing a Juz,
/// Surah, half Quran, or full Quran memorization.
///
/// Lives in the certificate feature domain layer so that presentation
/// and service layers can import it without coupling to AchievementService.
library;

import 'package:equatable/equatable.dart';

enum CertificateType { juz, surah, halfQuran, fullQuran }

class CertificateAward extends Equatable {
  const CertificateAward({
    required this.id,
    required this.titleAr,
    required this.type,
    required this.earnedAt,
    this.juzNumber,
    this.surahId,
    this.surahNameAr,
    this.surahNameEn,
  });

  final String id;
  final String titleAr;
  final CertificateType type;
  final DateTime earnedAt;
  final int? juzNumber;
  final int? surahId;
  final String? surahNameAr;
  final String? surahNameEn;

  String get verificationCode {
    final prefix = switch (type) {
      CertificateType.juz => 'J${juzNumber ?? 1}',
      CertificateType.surah => 'S${surahId ?? 1}',
      CertificateType.halfQuran => 'HQ',
      CertificateType.fullQuran => 'FQ',
    };
    final hash = (id.hashCode.abs() % 9000 + 1000).toString();
    return 'TL-${earnedAt.year}-$prefix-$hash';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titleAr': titleAr,
    'type': type.name,
    'earnedAt': earnedAt.toIso8601String(),
    'juzNumber': juzNumber,
    'surahId': surahId,
    'surahNameAr': surahNameAr,
    'surahNameEn': surahNameEn,
  };

  factory CertificateAward.fromJson(Map<String, dynamic> json) =>
      CertificateAward(
        id: json['id'] as String,
        titleAr: json['titleAr'] as String,
        type: CertificateType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => CertificateType.juz,
        ),
        earnedAt: DateTime.parse(json['earnedAt'] as String),
        juzNumber: json['juzNumber'] as int?,
        surahId: json['surahId'] as int?,
        surahNameAr: json['surahNameAr'] as String?,
        surahNameEn: json['surahNameEn'] as String?,
      );

  @override
  List<Object?> get props => [
    id,
    titleAr,
    type,
    earnedAt,
    juzNumber,
    surahId,
    surahNameAr,
    surahNameEn,
  ];
}
