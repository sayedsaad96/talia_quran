import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';
import 'package:talia_quran/features/certificate/domain/certificate_verse.dart';
import 'package:talia_quran/features/certificate/domain/entities/certificate_award.dart';
import 'package:talia_quran/features/certificate/presentation/widgets/certificate_widget.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_history_entry.dart';

void main() {
  group('CertificateType.khatmahReading', () {
    test('khatmah honorific agrees with the recipient gender', () {
      KhatmahHistoryEntry entry(KhatmahDedication d) => KhatmahHistoryEntry(
        id: 'h',
        khatmahNumber: 1,
        title: 't',
        startDate: DateTime(2026, 1, 1),
        completedDate: DateTime(2026, 2, 1),
        totalDays: 32,
        dedication: d,
        certificateId: 'khatmah-h',
      );
      expect(
        entry(
          const KhatmahDedication(
            isDedicated: true,
            recipientName: 'فاطمة',
            condition: DedicationCondition.deceased,
            recipientGender: DedicationGender.female,
          ),
        ).certificate!.dedication,
        'فاطمة (رحمها الله)',
      );
      expect(
        entry(
          const KhatmahDedication(
            isDedicated: true,
            recipientName: 'أحمد',
            condition: DedicationCondition.alive,
            recipientGender: DedicationGender.male,
          ),
        ).certificate!.dedication,
        'أحمد (حفظه الله)',
      );
      expect(
        entry(
          const KhatmahDedication(
            isDedicated: true,
            recipientName: 'سعاد',
            condition: DedicationCondition.sick,
          ),
        ).certificate!.dedication,
        'سعاد',
      );
    });

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

    test(
      'serializes and deserializes JSON roundtrip correctly with dedication',
      () {
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
      },
    );

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

    testWidgets(
      'CertificateWidget displays Khatmah recitation title, action text, and dedication',
      (tester) async {
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
        expect(
          find.text('شهادة إتمام ختمة تلاوة القرآن الكريم'),
          findsOneWidget,
        );
        expect(
          find.text('تشهد منصة تالية لتحفيظ القرآن الكريم بأن'),
          findsOneWidget,
        );
        expect(find.text('﴿ ${CertificateVerse.text} ﴾'), findsOneWidget);
        expect(find.text('(الإسراء: ٩)'), findsOneWidget);
        expect(
          find.text(
            'نسأل الله تعالى أن يجعل القرآن الكريم ربيع قلبه\nونور صدره ورفيق دربه في الدنيا والآخرة.',
          ),
          findsOneWidget,
        );
        expect(find.text(certificateSignatureText), findsOneWidget);
        expect(find.text('التوقيع'), findsOneWidget);
        expect(find.text('قد أتم بنجاح تلاوة'), findsOneWidget);
        expect(find.text('قد أتم بنجاح حفظ'), findsNothing);
        expect(find.text('ختمة القرآن الكريم كاملاً'), findsOneWidget);
        expect(find.text('إهداء إلى: والدي (رحمه الله)'), findsOneWidget);
        expect(find.text('وسام ختم القرآن'), findsNothing);
      },
    );

    testWidgets(
      'CertificateWidget shapes its completion date for the app locale',
      (tester) async {
        final award = CertificateAward(
          id: 'certificate-date-locale',
          titleAr: 'شهادة',
          type: CertificateType.juz,
          earnedAt: DateTime(2026, 9, 2),
          juzNumber: 1,
        );

        Future<void> pumpCertificate(String languageCode) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: CertificateWidget(
                  userName: 'سيد سعد',
                  award: award,
                  completionDate: award.earnedAt,
                  languageCode: languageCode,
                ),
              ),
            ),
          ),
        );

        await pumpCertificate('ar');
        expect(find.text('٢٠٢٦/٠٩/٠٢'), findsOneWidget);
        expect(
          find.text('كود التوثيق: ${award.verificationCode}'),
          findsOneWidget,
        );

        await pumpCertificate('en');
        expect(find.text('2026/09/02'), findsOneWidget);
      },
    );

    testWidgets('uses the bundled template and distinguishes every award type', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(375, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final awards = <CertificateAward>[
        CertificateAward(
          id: 'j',
          titleAr: 'j',
          type: CertificateType.juz,
          earnedAt: DateTime(2026, 9, 2),
          juzNumber: 30,
        ),
        CertificateAward(
          id: 's',
          titleAr: 's',
          type: CertificateType.surah,
          earnedAt: DateTime(2026, 9, 2),
          surahId: 114,
        ),
        CertificateAward(
          id: 'h',
          titleAr: 'h',
          type: CertificateType.halfQuran,
          earnedAt: DateTime(2026, 9, 2),
        ),
        CertificateAward(
          id: 'f',
          titleAr: 'f',
          type: CertificateType.fullQuran,
          earnedAt: DateTime(2026, 9, 2),
        ),
        CertificateAward(
          id: 'r',
          titleAr: 'r',
          type: CertificateType.khatmahReading,
          earnedAt: DateTime(2026, 9, 2),
        ),
      ];
      const expectedArabic = [
        'الجزء الثلاثون',
        'سورة الناس',
        'نصف القرآن الكريم',
        'القرآن الكريم كاملاً',
        'ختمة القرآن الكريم كاملاً',
      ];
      const expectedTitles = [
        'شهادة حفظ الجزء الثلاثون',
        'شهادة حفظ سورة الناس',
        'شهادة حفظ نصف القرآن الكريم',
        'شهادة ختم القرآن الكريم كاملاً',
        'شهادة إتمام ختمة تلاوة القرآن الكريم',
      ];

      for (var index = 0; index < awards.length; index++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: CertificateWidget(
                    userName:
                        'اسم طويل جداً للتأكد من عدم قص بيانات الشهادة عند المعاينة الضيقة',
                    award: awards[index],
                    completionDate: awards[index].earnedAt,
                    languageCode: 'ar',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(expectedArabic[index]), findsOneWidget);
        expect(find.text(expectedTitles[index]), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == certificateAssetPath,
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CertificateWidget(
                userName: 'Long English certificate recipient name',
                award: awards.last,
                completionDate: awards.last.earnedAt,
                languageCode: 'en',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('A complete Quran recitation'), findsOneWidget);
      expect(find.text('has successfully completed reading'), findsOneWidget);
    });

    testWidgets('renders a PNG from the actual bundled certificate asset', (
      tester,
    ) async {
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              key: captureKey,
              width: 900,
              child: const _CertificateRenderFixture(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = captureKey.currentContext!;
      late Uint8List png;
      late Uint8List exportPng;
      late ui.Image rendered;
      late ui.Image exportImage;
      late ui.Image template;
      late int renderedPixel;
      late int templatePixel;
      await tester.runAsync(() async {
        await precacheImage(const AssetImage(certificateAssetPath), context);
        png = await ScreenshotController().captureFromWidget(
          const _CertificateRenderFixture(),
          context: context,
          targetSize: certificateCanvasSize,
          pixelRatio: 1,
          delay: Duration.zero,
        );
        exportPng = await ScreenshotController().captureFromWidget(
          const _CertificateRenderFixture(),
          context: context,
          targetSize: certificateCanvasSize,
          pixelRatio: 3,
          delay: Duration.zero,
        );
        rendered = await _decodePng(png);
        exportImage = await _decodePng(exportPng);
        template = await _decodePng(
          (await rootBundle.load(certificateAssetPath)).buffer.asUint8List(),
        );
        renderedPixel = await _pixelAt(rendered, 30, 30);
        templatePixel = await _pixelAt(template, 30, 30);
      });
      addTearDown(rendered.dispose);
      addTearDown(exportImage.dispose);
      addTearDown(template.dispose);
      expect(exportImage.width, certificateCanvasSize.width * 3);
      expect(exportImage.height, certificateCanvasSize.height * 3);
      expect(renderedPixel, templatePixel);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<ui.Image> _decodePng(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

Future<int> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) throw StateError('Could not read rendered PNG pixels.');
  return data.getUint32((y * image.width + x) * 4, Endian.big);
}

class _CertificateRenderFixture extends StatelessWidget {
  const _CertificateRenderFixture();

  @override
  Widget build(BuildContext context) => CertificateWidget(
    userName: 'سيد سعد',
    award: CertificateAward(
      id: 'render-certificate',
      titleAr: 'شهادة',
      type: CertificateType.khatmahReading,
      earnedAt: DateTime(2026, 9, 2),
      dedication: 'إهداء طويل للاختبار لا ينبغي فقد أي جزء منه',
    ),
    completionDate: DateTime(2026, 9, 2),
  );
}
