import 'package:equatable/equatable.dart';
import 'khatmah_dedication.dart';
import '../../../certificate/domain/entities/certificate_award.dart';

class KhatmahHistoryEntry extends Equatable {
  const KhatmahHistoryEntry({
    required this.id,
    required this.khatmahNumber,
    required this.title,
    required this.startDate,
    required this.completedDate,
    required this.totalDays,
    this.dedication,
    this.certificateId,
  });

  final String id;
  final int khatmahNumber;
  final String title;
  final DateTime startDate;
  final DateTime completedDate;
  final int totalDays;
  final KhatmahDedication? dedication;
  final String? certificateId;

  /// Local issuance lives in the durable archive, never in cloud award lists.
  CertificateAward? get certificate => certificateId == 'khatmah-$id'
      ? CertificateAward(
          id: certificateId!,
          titleAr: CertificateType.khatmahReading.titleAr,
          titleEn: CertificateType.khatmahReading.titleEn,
          type: CertificateType.khatmahReading,
          earnedAt: completedDate,
        )
      : null;

  @override
  List<Object?> get props => [
    id,
    khatmahNumber,
    title,
    startDate,
    completedDate,
    totalDays,
    dedication,
    certificateId,
  ];
}
