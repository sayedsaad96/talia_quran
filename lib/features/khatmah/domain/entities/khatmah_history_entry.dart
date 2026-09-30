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
  CertificateAward? get certificate {
    if (certificateId != 'khatmah-$id') return null;
    String? dedicationStr;
    if (dedication != null &&
        dedication!.isDedicated &&
        dedication!.recipientName != null &&
        dedication!.recipientName!.trim().isNotEmpty) {
      final name = dedication!.recipientName!.trim();
      // An unknown gender gets no honorific rather than a masculine guess.
      final gender = dedication!.effectiveGender;
      final female = gender == DedicationGender.female;
      final suffix = gender == null
          ? ''
          : switch (dedication!.condition) {
              DedicationCondition.alive =>
                female ? ' (حفظها الله)' : ' (حفظه الله)',
              DedicationCondition.deceased =>
                female ? ' (رحمها الله)' : ' (رحمه الله)',
              DedicationCondition.sick =>
                female ? ' (شفاها الله)' : ' (شفاه الله)',
              null => '',
            };
      if (suffix.isNotEmpty && !name.contains('الله')) {
        dedicationStr = '$name$suffix';
      } else {
        dedicationStr = name;
      }
    }
    return CertificateAward(
      id: certificateId!,
      titleAr: CertificateType.khatmahReading.titleAr,
      titleEn: CertificateType.khatmahReading.titleEn,
      type: CertificateType.khatmahReading,
      earnedAt: completedDate,
      dedication: dedicationStr,
    );
  }

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
