import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/achievement_service.dart';

enum CertificateStyleType {
  classicParchment,
  emeraldRoyal,
  pearlGold;

  String get displayName {
    switch (this) {
      case CertificateStyleType.classicParchment:
        return 'الرق الذهبي';
      case CertificateStyleType.emeraldRoyal:
        return 'الزمرد الملكي';
      case CertificateStyleType.pearlGold:
        return 'اللؤلؤ الفاخر';
    }
  }
}

class CertificateStyleTheme {
  final CertificateStyleType type;
  final List<Color> bgGradient;
  final Color borderColor;
  final Color innerBorderColor;
  final Color primaryText;
  final Color secondaryText;
  final Color accentGold;
  final Color badgeBg;
  final Color badgeText;
  final Color sealBg;
  final Color sealGold;
  final bool isDark;

  const CertificateStyleTheme({
    required this.type,
    required this.bgGradient,
    required this.borderColor,
    required this.innerBorderColor,
    required this.primaryText,
    required this.secondaryText,
    required this.accentGold,
    required this.badgeBg,
    required this.badgeText,
    required this.sealBg,
    required this.sealGold,
    required this.isDark,
  });

  static const CertificateStyleTheme classicParchment = CertificateStyleTheme(
    type: CertificateStyleType.classicParchment,
    bgGradient: [Color(0xFFF9F6ED), Color(0xFFF2ECE0)],
    borderColor: Color(0xFFC09B4E),
    innerBorderColor: Color(0x660D251C),
    primaryText: Color(0xFF0D251C),
    secondaryText: Color(0xCC0D251C),
    accentGold: Color(0xFFC09B4E),
    badgeBg: Color(0xFF0D251C),
    badgeText: Color(0xFFF7F4EA),
    sealBg: Color(0xFFF7F4EA),
    sealGold: Color(0xFFC09B4E),
    isDark: false,
  );

  static const CertificateStyleTheme emeraldRoyal = CertificateStyleTheme(
    type: CertificateStyleType.emeraldRoyal,
    bgGradient: [Color(0xFF041F1A), Color(0xFF0A2B24), Color(0xFF041613)],
    borderColor: Color(0xFFE5C158),
    innerBorderColor: Color(0x66E5C158),
    primaryText: Color(0xFFFAF7F0),
    secondaryText: Color(0xCCD5E0DC),
    accentGold: Color(0xFFE5C158),
    badgeBg: Color(0xFFE5C158),
    badgeText: Color(0xFF041F1A),
    sealBg: Color(0xFF0A2B24),
    sealGold: Color(0xFFE5C158),
    isDark: true,
  );

  static const CertificateStyleTheme pearlGold = CertificateStyleTheme(
    type: CertificateStyleType.pearlGold,
    bgGradient: [Color(0xFFFFFFFF), Color(0xFFFAF7F2)],
    borderColor: Color(0xFFD4AF37),
    innerBorderColor: Color(0x40D4AF37),
    primaryText: Color(0xFF1F2927),
    secondaryText: Color(0xCC5A6663),
    accentGold: Color(0xFFB8860B),
    badgeBg: Color(0xFF1A6B5A),
    badgeText: Color(0xFFFFFFFF),
    sealBg: Color(0xFFFFFFFF),
    sealGold: Color(0xFFD4AF37),
    isDark: false,
  );

  static CertificateStyleTheme get(CertificateStyleType type) {
    switch (type) {
      case CertificateStyleType.classicParchment:
        return classicParchment;
      case CertificateStyleType.emeraldRoyal:
        return emeraldRoyal;
      case CertificateStyleType.pearlGold:
        return pearlGold;
    }
  }
}

// ─── Painter للزخارف والإطارات الإسلامية الناصعة Vector ─────────────────
class CertificateFramePainter extends CustomPainter {
  const CertificateFramePainter({required this.theme});
  final CertificateStyleTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final outerBorderPaint = Paint()
      ..color = theme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final innerBorderPaint = Paint()
      ..color = theme.innerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 1. Outer & Inner Frame Lines
    const margin = 12.0;
    final outerRect = Rect.fromLTWH(margin, margin, size.width - margin * 2, size.height - margin * 2);
    final innerRect = Rect.fromLTWH(margin + 6, margin + 6, size.width - (margin + 6) * 2, size.height - (margin + 6) * 2);

    canvas.drawRRect(RRect.fromRectAndRadius(outerRect, const Radius.circular(8)), outerBorderPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(innerRect, const Radius.circular(6)), innerBorderPaint);

    // 2. Corner Ornaments (Custom Geometric Arches)
    _drawCornerOrnament(canvas, const Offset(14, 14), 0, size.width * 0.15);
    _drawCornerOrnament(canvas, Offset(size.width - margin - 2, margin + 2), math.pi / 2, size.width * 0.15);
    _drawCornerOrnament(canvas, Offset(margin + 2, size.height - margin - 2), -math.pi / 2, size.width * 0.15);
    _drawCornerOrnament(canvas, Offset(size.width - margin - 2, size.height - margin - 2), math.pi, size.width * 0.15);
  }

  void _drawCornerOrnament(Canvas canvas, Offset corner, double rotation, double ornamentSize) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = theme.accentGold.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 3; i++) {
      final rect = Rect.fromLTWH(4.0 * i, 4.0 * i, ornamentSize - 8.0 * i, ornamentSize - 8.0 * i);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(3.0 * i)), paint);
    }

    final dotPaint = Paint()
      ..color = theme.accentGold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ornamentSize * 0.3, ornamentSize * 0.3), 2.5, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CertificateFramePainter old) => old.theme.type != theme.type;
}

// ─── Certificate Widget ───────────────────────────────────────────────────
class CertificateWidget extends StatelessWidget {
  const CertificateWidget({
    super.key,
    required this.userName,
    required this.award,
    required this.completionDate,
    this.styleType = CertificateStyleType.classicParchment,
  });

  final String userName;
  final CertificateAward award;
  final DateTime completionDate;
  final CertificateStyleType styleType;

  CertificateStyleTheme get theme => CertificateStyleTheme.get(styleType);

  String get _arabicJuzNumber {
    if (award.juzNumber == null) return '';
    final juzNumber = award.juzNumber!;
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
    return juzNumber <= 30 ? arabic[juzNumber] : juzNumber.toString();
  }

  String get _achievementText {
    switch (award.type) {
      case CertificateType.juz:
        return 'الجزء $_arabicJuzNumber';
      case CertificateType.surah:
        return 'سورة ${award.surahNameAr ?? ""}';
      case CertificateType.halfQuran:
        return 'نصف القرآن الكريم';
      case CertificateType.fullQuran:
        return 'القرآن الكريم كاملاً';
      case CertificateType.khatmahReading:
        return 'ختمة القرآن الكريم كاملاً';
    }
  }

  String get _certificateTitle {
    switch (award.type) {
      case CertificateType.juz:
        return 'شهادة حفظ جزء من القرآن';
      case CertificateType.surah:
        return 'شهادة حفظ سورة من القرآن';
      case CertificateType.halfQuran:
        return 'شهادة حفظ نصف القرآن الكريم';
      case CertificateType.fullQuran:
        return 'شهادة ختم القرآن الكريم كاملاً';
      case CertificateType.khatmahReading:
        return 'شهادة ختم تلاوة القرآن الكريم';
    }
  }

  String get _formattedDate {
    return '${completionDate.year}/${completionDate.month.toString().padLeft(2, '0')}/${completionDate.day.toString().padLeft(2, '0')}';
  }

  bool get _isFullOrHalf =>
      award.type == CertificateType.fullQuran ||
      award.type == CertificateType.halfQuran ||
      award.type == CertificateType.khatmahReading;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 1.414,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.bgGradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ─── إطار الزخرفة المتجهي Vector ───────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: CertificateFramePainter(theme: theme),
                  ),
                ),

                // ─── وسام ختم القرآن العائم (إذا كان ختم أو نصف) ────────
                if (_isFullOrHalf)
                  Positioned(
                    top: 24,
                    left: 28,
                    child: _RoyalRibbonBadge(theme: theme),
                  ),

                // ─── كود التوثيق المرجعي ─────────────────────────────
                Positioned(
                  bottom: 18,
                  right: 28,
                  child: Text(
                    'كود التوثيق: ${award.verificationCode}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 10,
                      color: theme.secondaryText.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ─── المحتوى الرئيسي ─────────────────────────────────
                Positioned.fill(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.68,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ─── اللوجو (أعلى) ───────────────────
                              Image.asset(
                                'assets/images/logo_new.png',
                                width: 48,
                                height: 68,
                                cacheWidth: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.menu_book_rounded,
                                  color: theme.accentGold,
                                  size: 70,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ─── عنوان الشهادة ────────────────────
                              Text(
                                _certificateTitle,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryText,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ─── سطر الشهادة مع خطوط الزخرفة ─────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildDecorativeLine(theme.accentGold),
                                  const SizedBox(width: 12),
                                  Text(
                                    'تشهد منصة تالية لتحفيظ القرآن الكريم بأن',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 18,
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildDecorativeLine(theme.accentGold),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // ─── اسم الطالب مع زخرفة جانبية ──────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildOrnamentIcon(theme.accentGold),
                                  const SizedBox(width: 16),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: theme.accentGold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildOrnamentIcon(theme.accentGold),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'قد أتم بنجاح حفظ',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 19,
                                  color: theme.secondaryText,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ─── بادج الإنجاز ─────────────────────
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.badgeBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: theme.accentGold.withValues(alpha: 0.5), width: 1),
                                ),
                                child: Text(
                                  _achievementText,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.badgeText,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              const SizedBox(height: 20),

                              // ─── التاريخ والختم ─────────────────
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // التاريخ (يمين)
                                  Column(
                                    children: [
                                      Text(
                                        _formattedDate,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: theme.primaryText,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Amiri',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: 90,
                                        height: 1,
                                        color: theme.primaryText.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'التاريخ',
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 14,
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 180),

                                  // ختم التطبيق الرسمى (يسار)
                                  _AppSeal(
                                    size: 104,
                                    theme: theme,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeLine(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        Container(width: 50, height: 1, color: color),
      ],
    );
  }

  Widget _buildOrnamentIcon(Color color) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

/// Royal Ribbon Badge for Full Quran / Half Quran completion
class _RoyalRibbonBadge extends StatelessWidget {
  final CertificateStyleTheme theme;
  const _RoyalRibbonBadge({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.accentGold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.accentGold.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'وسام ختم القرآن',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: theme.badgeBg,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSeal extends StatelessWidget {
  const _AppSeal({
    required this.size,
    required this.theme,
  });

  final double size;
  final CertificateStyleTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.sealBg,
              boxShadow: [
                BoxShadow(
                  color: theme.sealGold.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _AppSealPainter(
              darkGreen: theme.primaryText,
              goldAccent: theme.sealGold,
              bgBeige: theme.sealBg,
            ),
          ),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.badgeBg,
              border: Border.all(color: theme.sealGold, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                color: theme.sealGold,
                size: size * 0.16,
              ),
              const SizedBox(height: 2),
              Text(
                'تالية القرآن',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: size * 0.13,
                  fontWeight: FontWeight.bold,
                  color: theme.sealGold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppSealPainter extends CustomPainter {
  const _AppSealPainter({
    required this.darkGreen,
    required this.goldAccent,
    required this.bgBeige,
  });

  final Color darkGreen;
  final Color goldAccent;
  final Color bgBeige;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final outerPath = Path();
    const int petals = 32;
    for (var i = 0; i < petals * 2; i++) {
      final angle = (math.pi * 2 * i) / (petals * 2);
      final r = i.isEven ? radius : radius - 3.5;
      final p = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        outerPath.moveTo(p.dx, p.dy);
      } else {
        outerPath.lineTo(p.dx, p.dy);
      }
    }
    outerPath.close();

    canvas.drawPath(
      outerPath,
      Paint()
        ..color = goldAccent
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      outerPath,
      Paint()
        ..color = darkGreen.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    canvas.drawCircle(center, radius - 5, Paint()..color = bgBeige);
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = darkGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    final starRadius = radius - 12;
    final rectWidth = starRadius * math.sqrt(2);

    final goldStroke = Paint()
      ..color = goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final greenStroke = Paint()
      ..color = darkGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * math.pi / 4);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: rectWidth,
        height: rectWidth,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = goldAccent.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(rect, goldStroke);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: rectWidth - 6,
          height: rectWidth - 6,
        ),
        greenStroke,
      );
      canvas.restore();
    }

    for (var i = 0; i < 8; i++) {
      final angle = (math.pi * 2 * i) / 8;
      final p = Offset(
        center.dx + math.cos(angle) * (starRadius + 2.5),
        center.dy + math.sin(angle) * (starRadius + 2.5),
      );
      canvas.drawCircle(
        p,
        3.0,
        Paint()
          ..color = bgBeige
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        p,
        3.0,
        Paint()
          ..color = goldAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        p,
        1.2,
        Paint()
          ..color = darkGreen
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_AppSealPainter oldDelegate) {
    return oldDelegate.darkGreen != darkGreen ||
        oldDelegate.goldAccent != goldAccent ||
        oldDelegate.bgBeige != bgBeige;
  }
}
