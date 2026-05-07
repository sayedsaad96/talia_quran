import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/achievement_service.dart';

// ─── Painter للزخارف الإسلامية ───────────────────────────────────────────
class IslamicOrnamentPainter extends CustomPainter {
  const IslamicOrnamentPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    _drawCornerOrnament(canvas, paint, Offset.zero, 0, size.width * 0.22);
    _drawCornerOrnament(
      canvas,
      paint,
      Offset(size.width, 0),
      math.pi / 2,
      size.width * 0.22,
    );
    _drawCornerOrnament(
      canvas,
      paint,
      Offset(0, size.height),
      -math.pi / 2,
      size.width * 0.22,
    );
    _drawCornerOrnament(
      canvas,
      paint,
      Offset(size.width, size.height),
      math.pi,
      size.width * 0.22,
    );
  }

  void _drawCornerOrnament(
    Canvas canvas,
    Paint paint,
    Offset corner,
    double rotation,
    double size,
  ) {
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(rotation);
    for (int i = 1; i <= 3; i++) {
      final rect = Rect.fromLTWH(
        8.0 * i,
        8.0 * i,
        size - 16.0 * i,
        size - 16.0 * i,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(4.0 * i)),
        paint,
      );
    }
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(10 + i * 6.0, size),
        Offset(size, 10 + i * 6.0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(IslamicOrnamentPainter old) => old.color != color;
}

// ─── Certificate Widget ───────────────────────────────────────────────────
class CertificateWidget extends StatelessWidget {
  const CertificateWidget({
    super.key,
    required this.userName,
    required this.award,
    required this.completionDate,
  });

  final String userName;
  final CertificateAward award;
  final DateTime completionDate;

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
    }
  }

  String get _formattedDate {
    return '${completionDate.year}/${completionDate.month.toString().padLeft(2, '0')}/${completionDate.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF0D251C);
    const goldAccent = Color(0xFFC09B4E);
    const bgBeige = Color(0xFFF7F4EA);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 1.414,
        child: Container(
          decoration: BoxDecoration(
            color: bgBeige,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ─── الخلفية ──────────────────────────────────────────
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/certificate.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: goldAccent, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const CustomPaint(
                          painter: IslamicOrnamentPainter(color: goldAccent),
                        ),
                      );
                    },
                  ),
                ),

                // ─── المحتوى الرئيسي ─────────────────────────────────
                Positioned.fill(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.65, // لضبط المساحة المركزية
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ─── اللوجو (أعلى) ───────────────────
                                Image.asset(
                                  'assets/images/logo.png',
                                  width: 50,
                                  height: 70,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.menu_book_rounded,
                                    color: darkGreen,
                                    size: 50,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ─── عنوان الشهادة ────────────────────
                                Text(
                                  _certificateTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ─── سطر الشهادة مع خطوط الزخرفة ─────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildDecorativeLine(goldAccent),
                                    const SizedBox(width: 12),
                                    Text(
                                      'تشهد منصة تالية لتحفيظ القرآن الكريم بأن',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 18,
                                        color: darkGreen.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildDecorativeLine(goldAccent),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // ─── اسم الطالب مع زخرفة جانبية ──────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildOrnamentIcon(goldAccent),
                                    const SizedBox(width: 16),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: goldAccent,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildOrnamentIcon(goldAccent),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'قد أتم بنجاح حفظ',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 20,
                                    color: darkGreen.withValues(alpha: 0.8),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // ─── بادج الإنجاز ─────────────────────
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: darkGreen,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    _achievementText,
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: bgBeige,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // ─── آية قرآنية ───────────────────────
                                const Text(
                                  '﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 26,
                                    color: darkGreen,
                                  ),
                                ),
                                Text(
                                  '(الإسراء: 9)',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 14,
                                    color: darkGreen.withValues(alpha: 0.6),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'نسأل الله تعالى أن يجعل القرآن الكريم ربيع قلبه\nونور صدره ورفيق دربه في الدنيا والآخرة.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 18,
                                    color: darkGreen.withValues(alpha: 0.8),
                                    height: 1.6,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // ─── التوقيع والتاريخ ─────────────────
                                // في الاتجاه RTL: أول عنصر يظهر على اليمين (التوقيع)، وثاني عنصر على اليسار (التاريخ)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // التوقيع (يمين)
                                    Column(
                                      children: [
                                        const Text(
                                          ' Talia',
                                          style: TextStyle(
                                            fontFamily: 'MrsSaintDelafield',
                                            fontSize: 48,
                                            fontWeight: FontWeight.w700,
                                            color: darkGreen,
                                            height: 0.8,
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 2,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 90,
                                          height: 1,
                                          color: darkGreen.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التوقيع',
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 14,
                                            color: darkGreen.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(width: 200),

                                    // التاريخ (يسار)
                                    Column(
                                      children: [
                                        Text(
                                          _formattedDate,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: darkGreen,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Amiri',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 90,
                                          height: 1,
                                          color: darkGreen.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التاريخ',
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 14,
                                            color: darkGreen.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
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
        Container(width: 60, height: 1, color: color),
      ],
    );
  }

  Widget _buildOrnamentIcon(Color color) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // المربع الأول
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          // المربع الثاني مائل بزاوية 45 درجة لتكوين نجمة إسلامية (ثمانية)
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 1.5),
              ),
            ),
          ),
          // نقطة في المنتصف
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
