import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/certificate/presentation/widgets/certificate_widget.dart';

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

    test('serializes and deserializes JSON roundtrip correctly with dedication', () {
      final earnedAt = DateTime.utc(2026, 9, 2, 12, 0, 0);
      final original = CertificateAward(
        id: 'cert_khatmah_reading_roundtrip',
        titleAr: 'شهادة إتمام ختمة تلاوة القرآن الكريم',
        titleEn: 'Quran Recitation Khatmah Certificate',
        type: CertificateType.khatmahReading,
        earnedAt: earnedAt,
        dedication: 'والدي (رحمه الله)',
      );

      final json = original.toJson();
      expect(json['type'], 'khatmahReading');
      expect(json['id'], original.id);
      expect(json['titleAr'], original.titleAr);
      expect(json['dedication'], 'والدي (رحمه الله)');

      final restored = CertificateAward.fromJson(json);
      expect(restored.type, CertificateType.khatmahReading);
      expect(restored.id, original.id);
      expect(restored.titleAr, original.titleAr);
      expect(restored.titleEn, original.titleEn);
      expect(restored.earnedAt, original.earnedAt);
      expect(restored.dedication, 'والدي (رحمه الله)');
      expect(restored, original);
    });

    test('dedication is included in props for equality comparison', () {
      final earnedAt = DateTime.utc(2026, 9, 2, 12, 0, 0);
      final cert1 = CertificateAward(
        id: 'cert_1',
        titleAr: 'شهادة إتمام ختمة',
        type: CertificateType.khatmahReading,
        earnedAt: earnedAt,
        dedication: 'أمي (حفظها الله)',
      );
      final cert2 = CertificateAward(
        id: 'cert_1',
        titleAr: 'شهادة إتمام ختمة',
        type: CertificateType.khatmahReading,
        earnedAt: earnedAt,
        dedication: 'أبي (رحمه الله)',
      );
      expect(cert1 == cert2, isFalse);
    });

    testWidgets('CertificateWidget displays Khatmah recitation title, action text, and dedication', (tester) async {
      final award = CertificateAward(
        id: 'khatmah-test-1',
        titleAr: 'شهادة إتمام ختمة تلاوة القرآن الكريم',
        titleEn: 'Quran Recitation Khatmah Certificate',
        type: CertificateType.khatmahReading,
        earnedAt: DateTime(2026, 9, 2),
        dedication: 'والدي (رحمه الله)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                height: 600,
                child: CertificateWidget(
                  userName: 'سيد سعد',
                  award: award,
                  completionDate: DateTime(2026, 9, 2),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('سيد سعد'), findsOneWidget);
      expect(find.text('شهادة ختم تلاوة القرآن الكريم'), findsOneWidget);
      expect(find.text('قد أتم بنجاح تلاوة'), findsOneWidget);
      expect(find.text('قد أتم بنجاح حفظ'), findsNothing);
      expect(find.text('ختمة القرآن الكريم كاملاً'), findsOneWidget);
      expect(find.text('إهداء إلى: والدي (رحمه الله)'), findsOneWidget);
      expect(find.text('وسام ختم القرآن'), findsOneWidget);
    });
  });
}
