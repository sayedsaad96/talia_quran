import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/surah_names.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/locale_number_formatter.dart';
import '../../domain/certificate_verse.dart';
import '../../domain/entities/certificate_award.dart';
import 'certificate_palette.dart';

export 'certificate_palette.dart';

/// The fixed landscape canvas used by previews, PNG exports, and PDFs.
const certificateCanvasSize = Size(1536, 1024);
const certificateAssetPath = 'assets/images/certificate.png';
const certificateLogoAssetPath = 'assets/images/logo.png';

/// The handwritten mark printed above the signature line.
const certificateSignatureText = 'Talia';

/// Copy which can be supplied to an off-tree screenshot renderer.
class CertificateTemplateCopy {
  const CertificateTemplateCopy({
    required this.titleJuz,
    required this.titleSurah,
    required this.titleHalfQuran,
    required this.titleFullQuran,
    required this.titleKhatmah,
    required this.recipientIntro,
    required this.memorizedAction,
    required this.readingAction,
    required this.dateLabel,
    required this.signatureLabel,
    required this.verificationLabel,
    required this.dedicationLabel,
    required this.blessing,
    required this.verseReference,
    required this.juzLabel,
    required this.surahLabel,
    required this.halfQuranLabel,
    required this.fullQuranLabel,
    required this.khatmahLabel,
  });

  final String Function(String juz) titleJuz;
  final String Function(String surahName) titleSurah;
  final String titleHalfQuran;
  final String titleFullQuran;
  final String titleKhatmah;
  final String recipientIntro;
  final String memorizedAction;
  final String readingAction;
  final String dateLabel;
  final String signatureLabel;
  final String verificationLabel;
  final String dedicationLabel;
  final String blessing;
  final String Function(String surahName, String ayahNumber) verseReference;
  final String juzLabel;
  final String surahLabel;
  final String halfQuranLabel;
  final String fullQuranLabel;
  final String khatmahLabel;

  factory CertificateTemplateCopy.forLanguage(String languageCode) {
    final locale = Locale(
      languageCode.toLowerCase().startsWith('ar') ? 'ar' : 'en',
    );
    return CertificateTemplateCopy.fromLocalizations(
      lookupAppLocalizations(locale),
    );
  }

  factory CertificateTemplateCopy.fromLocalizations(AppLocalizations l10n) =>
      CertificateTemplateCopy(
        titleJuz: l10n.certificateTitleJuz,
        titleSurah: l10n.certificateTitleSurahNamed,
        titleHalfQuran: l10n.certificateTitleHalfQuran,
        titleFullQuran: l10n.certificateTitleFullQuran,
        titleKhatmah: l10n.certificateTitleKhatmah,
        recipientIntro: l10n.certificateTemplateRecipientIntro,
        memorizedAction: l10n.certificateTemplateMemorizedAction,
        readingAction: l10n.certificateTemplateReadingAction,
        dateLabel: l10n.certificateTemplateDate,
        signatureLabel: l10n.certificateTemplateSignature,
        verificationLabel: l10n.certificateTemplateVerification,
        dedicationLabel: l10n.certificateTemplateDedication,
        blessing: l10n.certificateTemplateBlessing,
        verseReference: (surahName, ayahNumber) =>
            l10n.certificateTemplateVerseReference(ayahNumber, surahName),
        juzLabel: l10n.certificateTemplateJuz,
        surahLabel: l10n.certificateTemplateSurah,
        halfQuranLabel: l10n.certificateTemplateHalfQuran,
        fullQuranLabel: l10n.certificateTemplateFullQuran,
        khatmahLabel: l10n.certificateTemplateKhatmah,
      );
}

/// Renders the bundled certificate artwork. One template is intentionally used
/// for the screen preview, saved PNG, shared PNG, and PDF.
class CertificateWidget extends StatelessWidget {
  const CertificateWidget({
    super.key,
    required this.userName,
    required this.award,
    required this.completionDate,
    this.languageCode = 'ar',
    this.copy,
    this.styleType = CertificateStyleType.classicParchment,
  });

  final String userName;
  final CertificateAward award;
  final DateTime completionDate;
  final String languageCode;
  final CertificateTemplateCopy? copy;

  /// Retained so existing callers compile; artwork is no longer configurable.
  final CertificateStyleType styleType;

  bool get _isArabic => languageCode.toLowerCase().startsWith('ar');
  CertificateTemplateCopy get _copy =>
      copy ?? CertificateTemplateCopy.forLanguage(languageCode);

  String get _title => switch (award.type) {
    CertificateType.juz => _copy.titleJuz(_juzNumber),
    CertificateType.surah => _copy.titleSurah(_surahName),
    CertificateType.halfQuran => _copy.titleHalfQuran,
    CertificateType.fullQuran => _copy.titleFullQuran,
    CertificateType.khatmahReading => _copy.titleKhatmah,
  };

  String get _achievementText => switch (award.type) {
    CertificateType.juz => '${_copy.juzLabel} $_juzNumber',
    CertificateType.surah => '${_copy.surahLabel} $_surahName',
    CertificateType.halfQuran => _copy.halfQuranLabel,
    CertificateType.fullQuran => _copy.fullQuranLabel,
    CertificateType.khatmahReading => _copy.khatmahLabel,
  };

  String get _juzNumber {
    const arabic = [
      '',
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
      'العشرون',
      'الحادي والعشرون',
      'الثاني والعشرون',
      'الثالث والعشرون',
      'الرابع والعشرون',
      'الخامس والعشرون',
      'السادس والعشرون',
      'السابع والعشرون',
      'الثامن والعشرون',
      'التاسع والعشرون',
      'الثلاثون',
    ];
    final number = award.juzNumber;
    if (!_isArabic) return '${number ?? ''}';
    return number != null && number > 0 && number < arabic.length
        ? arabic[number]
        : '${number ?? ''}';
  }

  String get _surahName {
    if (_isArabic) return award.surahNameAr ?? SurahNames.nameAr(award.surahId);
    return award.surahNameEn ??
        award.surahNameAr ??
        SurahNames.nameEn(award.surahId);
  }

  String get _verseReference => _copy.verseReference(
    _isArabic
        ? SurahNames.nameAr(CertificateVerse.surahId)
        : SurahNames.nameEn(CertificateVerse.surahId),
    LocaleNumberFormatter.format(
      '${CertificateVerse.ayahNumber}',
      languageCode,
    ),
  );

  String get _formattedDate => LocaleNumberFormatter.format(
    '${completionDate.year}/${completionDate.month.toString().padLeft(2, '0')}/${completionDate.day.toString().padLeft(2, '0')}',
    languageCode,
  );

  @override
  Widget build(BuildContext context) {
    final textDirection = _isArabic ? TextDirection.rtl : TextDirection.ltr;
    return MediaQuery.withNoTextScaling(
      child: Directionality(
        textDirection: textDirection,
        child: AspectRatio(
          aspectRatio:
              certificateCanvasSize.width / certificateCanvasSize.height,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Image(
                  image: AssetImage(certificateAssetPath),
                  fit: BoxFit.fill,
                ),
                _CertificateContent(
                  copy: _copy,
                  title: _title,
                  userName: userName,
                  achievementText: _achievementText,
                  actionText: award.type == CertificateType.khatmahReading
                      ? _copy.readingAction
                      : _copy.memorizedAction,
                  verseReference: _verseReference,
                  dedication: award.dedication?.trim(),
                  formattedDate: _formattedDate,
                  verificationCode: award.verificationCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _ink = Color(0xff173c37);
const _gold = Color(0xffa8802f);
const _goldLine = Color(0xffc9a45c);
const _muted = Color(0xff6b5a3c);
const _pillText = Color(0xfff7ecd2);

/// Lays the copy over the artwork. Positions are fractions of the canvas, so
/// the preview and the 3x export match exactly; every band shrinks its text
/// rather than overflow into the artwork.
class _CertificateContent extends StatelessWidget {
  const _CertificateContent({
    required this.copy,
    required this.title,
    required this.userName,
    required this.achievementText,
    required this.actionText,
    required this.verseReference,
    required this.dedication,
    required this.formattedDate,
    required this.verificationCode,
  });

  final CertificateTemplateCopy copy;
  final String title;
  final String userName;
  final String achievementText;
  final String actionText;
  final String verseReference;
  final String? dedication;
  final String formattedDate;
  final String verificationCode;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      final s = width / certificateCanvasSize.width;
      final hasDedication = dedication?.isNotEmpty ?? false;

      // The parchment between the window artwork and the seal spans roughly
      // 0.31–0.69 of the width around the arch at 0.5.
      Widget band({
        double cx = .5,
        required double cy,
        required double w,
        required double h,
        required Widget child,
      }) => Positioned(
        left: (cx - w / 2) * width,
        top: (cy - h / 2) * height,
        width: w * width,
        height: h * height,
        child: Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: child),
        ),
      );

      Text text(
        String value,
        double size, {
        FontWeight? weight,
        Color color = _ink,
        String? fontFamily,
      }) => Text(
        value,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: fontFamily ?? 'Amiri',
          fontSize: size * s,
          fontWeight: weight,
          color: color,
          height: 1.25,
        ),
      );

      return Stack(
        children: [
          band(
            cy: .118,
            w: .08,
            h: .095,
            child: Image.asset(
              certificateLogoAssetPath,
              width: 96 * s,
              height: 96 * s,
            ),
          ),
          band(
            cy: .215,
            w: .38,
            h: .075,
            child: text(title, 52, weight: FontWeight.bold),
          ),
          band(
            cy: .292,
            w: .38,
            h: .045,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GoldRule(length: 120 * s, scale: s, dotAtStart: true),
                SizedBox(width: 14 * s),
                text(copy.recipientIntro, 26, color: _muted),
                SizedBox(width: 14 * s),
                _GoldRule(length: 120 * s, scale: s, dotAtStart: false),
              ],
            ),
          ),
          band(
            cy: .378,
            w: .38,
            h: .08,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Rosette(size: 30 * s),
                SizedBox(width: 22 * s),
                text(userName, 56, weight: FontWeight.bold, color: _gold),
                SizedBox(width: 22 * s),
                _Rosette(size: 30 * s),
              ],
            ),
          ),
          band(
            cy: .458,
            w: .38,
            h: .045,
            child: text(actionText, 27, color: _muted),
          ),
          band(
            cy: .532,
            w: .38,
            h: .075,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 44 * s,
                vertical: 8 * s,
              ),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(26 * s),
                border: Border.all(color: _goldLine, width: 1.5 * s),
              ),
              child: text(
                achievementText,
                34,
                weight: FontWeight.bold,
                color: _pillText,
              ),
            ),
          ),
          band(
            cy: .621,
            w: .38,
            h: .062,
            // Quran text is always laid out right-to-left, whatever the
            // certificate language, so the ornate brackets face inward.
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: text(
                '﴿ ${CertificateVerse.text} ﴾',
                36,
                weight: FontWeight.bold,
              ),
            ),
          ),
          band(
            cy: .671,
            w: .2,
            h: .03,
            child: text(verseReference, 18, color: _muted),
          ),
          band(
            cy: .738,
            w: .38,
            h: .085,
            child: SizedBox(
              width: .38 * width,
              child: Text(
                copy.blessing,
                maxLines: 3,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 24 * s,
                  color: _ink,
                  height: 1.45,
                ),
              ),
            ),
          ),
          if (hasDedication)
            band(
              cy: .806,
              w: .38,
              h: .032,
              child: text(
                '${copy.dedicationLabel}: $dedication',
                20,
                color: _gold,
              ),
            ),
          ..._signatureColumn(
            cx: .385,
            value: text(formattedDate, 24, weight: FontWeight.bold),
            label: copy.dateLabel,
            band: band,
            text: text,
            width: width,
            height: height,
            s: s,
          ),
          ..._signatureColumn(
            cx: .615,
            value: text(
              certificateSignatureText,
              68,
              weight: FontWeight.bold,
              fontFamily: 'MrsSaintDelafield',
            ),
            label: copy.signatureLabel,
            band: band,
            text: text,
            width: width,
            height: height,
            s: s,
          ),
          band(
            cy: .938,
            w: .16,
            h: .022,
            child: text(
              '${copy.verificationLabel}: $verificationCode',
              15,
              color: _muted,
            ),
          ),
        ],
      );
    },
  );

  /// A value over a gold rule with its caption beneath, as on paper forms.
  List<Widget> _signatureColumn({
    required double cx,
    required Widget value,
    required String label,
    required Widget Function({
      double cx,
      required double cy,
      required double w,
      required double h,
      required Widget child,
    })
    band,
    required Text Function(
      String value,
      double size, {
      FontWeight? weight,
      Color color,
      String? fontFamily,
    })
    text,
    required double width,
    required double height,
    required double s,
  }) => [
    band(cx: cx, cy: .853, w: .14, h: .06, child: value),
    Positioned(
      left: (cx - .055) * width,
      top: .888 * height,
      width: .11 * width,
      height: 1.4 * s,
      child: const ColoredBox(color: _goldLine),
    ),
    band(
      cx: cx,
      cy: .912,
      w: .14,
      h: .03,
      child: text(label, 19, color: _muted),
    ),
  ];
}

/// A thin gold line ending in a small diamond, framing the intro line.
class _GoldRule extends StatelessWidget {
  const _GoldRule({
    required this.length,
    required this.scale,
    required this.dotAtStart,
  });

  final double length;
  final double scale;
  final bool dotAtStart;

  @override
  Widget build(BuildContext context) {
    final dot = Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: 6 * scale, height: 6 * scale, color: _goldLine),
    );
    final line = Container(
      width: length,
      height: 1.5 * scale,
      color: _goldLine,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dotAtStart ? [dot, line] : [line, dot],
    );
  }
}

/// The eight-point gold ornament flanking the recipient's name.
class _Rosette extends StatelessWidget {
  const _Rosette({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _RosettePainter());
}

class _RosettePainter extends CustomPainter {
  const _RosettePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * .12;
    final fill = Paint()..color = _gold;

    final star = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? radius * .95 : radius * .62;
      final angle = i * math.pi / 8 - math.pi / 2;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * r;
      i == 0
          ? star.moveTo(point.dx, point.dy)
          : star.lineTo(point.dx, point.dy);
    }
    star.close();
    canvas
      ..drawPath(star, stroke)
      ..drawCircle(center, radius * .38, stroke)
      ..drawCircle(center, radius * .16, fill);
  }

  @override
  bool shouldRepaint(_RosettePainter oldDelegate) => false;
}
