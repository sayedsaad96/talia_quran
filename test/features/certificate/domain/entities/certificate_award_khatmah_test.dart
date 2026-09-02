import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';

void main() {
  group('CertificateType.khatmahReading', () {
    test('contains khatmahReading in CertificateType.values', () {
      expect(CertificateType.values, contains(CertificateType.khatmahReading));
    });

    test('provides Arabic and English display titles / labels', () {
      const type = CertificateType.khatmahReading;
      expect(type.titleAr, contains('ختم'));
      expect(type.titleEn, contains('Khatmah'));
      expect(type.labelAr, type.titleAr);
      expect(type.labelEn, type.titleEn);
    });

    test('generates verification code with prefix KR', () {
      final award = CertificateAward(
        id: 'cert_khatmah_reading_001',
        titleAr: 'شهادة إتمام ختمة القرآن الكريم',
        type: CertificateType.khatmahReading,
        earnedAt: DateTime(2026, 9, 2),
      );

      final code = award.verificationCode;
      expect(code, contains('-KR-'));
      expect(code, startsWith('TL-2026-KR-'));
    });

    test('serializes and deserializes JSON roundtrip correctly', () {
      final earnedAt = DateTime.utc(2026, 9, 2, 12, 0, 0);
      final original = CertificateAward(
        id: 'cert_khatmah_reading_roundtrip',
        titleAr: 'شهادة إتمام ختمة تلاوة القرآن الكريم',
        titleEn: 'Quran Recitation Khatmah Certificate',
        type: CertificateType.khatmahReading,
        earnedAt: earnedAt,
      );

      final json = original.toJson();
      expect(json['type'], 'khatmahReading');
      expect(json['id'], original.id);
      expect(json['titleAr'], original.titleAr);

      final restored = CertificateAward.fromJson(json);
      expect(restored.type, CertificateType.khatmahReading);
      expect(restored.id, original.id);
      expect(restored.titleAr, original.titleAr);
      expect(restored.titleEn, original.titleEn);
      expect(restored.earnedAt, original.earnedAt);
      expect(restored, original);
    });
  });
}
