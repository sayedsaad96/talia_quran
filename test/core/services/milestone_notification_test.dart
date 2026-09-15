import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/milestone_notification.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';

CertificateAward _award({
  required CertificateType type,
  String? id,
  int? juzNumber,
  int? surahId,
  String? surahNameAr,
  String? surahNameEn,
}) =>
    CertificateAward(
      id: id ?? 'cert_test',
      titleAr: 'شهادة',
      type: type,
      earnedAt: DateTime.utc(2026, 1, 1),
      juzNumber: juzNumber,
      surahId: surahId,
      surahNameAr: surahNameAr,
      surahNameEn: surahNameEn,
    );

void main() {
  group('mapCertificateAwardToMilestone', () {
    test('maps a juz award to the juz milestone with its juz number', () {
      final data = mapCertificateAwardToMilestone(
        _award(type: CertificateType.juz, juzNumber: 7),
      );
      expect(data, isNotNull);
      expect(data!.type, MilestoneNotificationType.juz);
      expect(data.juzNumber, 7);
      expect(data.surahName, isNull);
    });

    test('recovers the juz number from the award id when the field is null', () {
      final data = mapCertificateAwardToMilestone(
        _award(type: CertificateType.juz, id: 'cert_juz_12'),
      );
      expect(data, isNotNull);
      expect(data!.type, MilestoneNotificationType.juz);
      expect(data.juzNumber, 12);
    });

    test('returns null for a juz award with no derivable juz number', () {
      expect(
        mapCertificateAwardToMilestone(_award(type: CertificateType.juz)),
        isNull,
      );
    });

    test('maps a surah award to the surah milestone with its name', () {
      final data = mapCertificateAwardToMilestone(
        _award(
          type: CertificateType.surah,
          surahId: 18,
          surahNameAr: 'الكهف',
          surahNameEn: 'Al-Kahf',
        ),
      );
      expect(data, isNotNull);
      expect(data!.type, MilestoneNotificationType.surah);
      expect(data.surahName, 'Al-Kahf');
    });

    test('falls back to the Arabic surah name when no English name exists', () {
      final data = mapCertificateAwardToMilestone(
        _award(type: CertificateType.surah, surahNameAr: 'الكهف'),
      );
      expect(data, isNotNull);
      expect(data!.surahName, 'الكهف');
    });

    test('returns null for a surah award with no derivable name', () {
      expect(
        mapCertificateAwardToMilestone(_award(type: CertificateType.surah)),
        isNull,
      );
    });

    test('maps a khatmah reading award to the khatmah milestone', () {
      final data = mapCertificateAwardToMilestone(
        _award(type: CertificateType.khatmahReading),
      );
      expect(data, isNotNull);
      expect(data!.type, MilestoneNotificationType.khatmah);
    });

    test('maps a full Quran award to the khatmah milestone', () {
      final data = mapCertificateAwardToMilestone(
        _award(type: CertificateType.fullQuran),
      );
      expect(data, isNotNull);
      expect(data!.type, MilestoneNotificationType.khatmah);
    });

    test('skips half-Quran awards — no reliable milestone type', () {
      expect(
        mapCertificateAwardToMilestone(_award(type: CertificateType.halfQuran)),
        isNull,
      );
    });
  });

  group('fire helpers', () {
    test('fireCertificateMilestone is a safe no-op on unsupported platforms',
        () async {
      // On the test VM (not Android/iOS) the fire path returns early without
      // touching getIt or the notification plugin.
      await fireCertificateMilestone(
        _award(type: CertificateType.juz, juzNumber: 1),
      );
    });

    test('fireKhatmahMilestone is a safe no-op on unsupported platforms',
        () async {
      await fireKhatmahMilestone();
    });
  });
}
