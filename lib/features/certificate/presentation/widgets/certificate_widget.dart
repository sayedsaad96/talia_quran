import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/achievement_service.dart';

// ─── Painter للزخارف الإسلامية ─────────────────────────────────────────────

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

// ─── Certificate Widget ─────────────────────────────────────────────────────

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
      '', 'الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس', 'السادس', 'السابع', 'الثامن', 'التاسع', 'العاشر',
      'الحادي عشر', 'الثاني عشر', 'الثالث عشر', 'الرابع عشر', 'الخامس عشر', 'السادس عشر', 'السابع عشر', 'الثامن عشر', 'التاسع عشر', 'العشرون',
      'الحادي والعشرون', 'الثاني والعشرون', 'الثالث والعشرون', 'الرابع والعشرون', 'الخامس والعشرون', 'السادس والعشرون', 'السابع والعشرون', 'الثامن والعشرون', 'التاسع والعشرون', 'الثلاثون',
    ];
    return juzNumber <= 30 ? arabic[juzNumber] : juzNumber.toString();
  }

  String get _achievementText {
    if (award.type == CertificateType.juz) {
      return 'الجزء $_arabicJuzNumber';
    } else {
      return 'سورة ${award.surahNameAr ?? ""}';
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
        // Landscape A4 roughly
        aspectRatio: 1.414,
        child: Container(
          decoration: BoxDecoration(
            color: bgBeige,
            border: Border.all(color: darkGreen, width: 8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 5,
              )
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: goldAccent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                // Corner decorations
                const Positioned.fill(
                  child: CustomPaint(
                    painter: IslamicOrnamentPainter(color: goldAccent),
                  ),
                ),

                // Main Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        const Column(
                          children: [
                            Icon(Icons.menu_book_rounded, color: darkGreen, size: 32),
                            Text(
                              'تالية\nTalia',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: darkGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Title
                        const Text(
                          'شهادة حفظ القرآن الكريم',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subtitle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_border_rounded, color: goldAccent, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'تشهد منصة تالية لتحفيظ القرآن الكريم بأن',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                color: darkGreen.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star_border_rounded, color: goldAccent, size: 16),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // User name
                        Text(
                          userName,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: goldAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'قد أتم بنجاح حفظ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            color: darkGreen.withValues(alpha: 0.8),
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Badge / Box for achievement
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          decoration: BoxDecoration(
                            color: darkGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _achievementText,
                            style: const TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: bgBeige,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Verse
                        Column(
                          children: [
                            const Text(
                              '﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 20,
                                color: darkGreen,
                              ),
                            ),
                            Text(
                              '(الإسراء: 9)',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 12,
                                color: darkGreen.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Footer prayer
                        Text(
                          'نسأل الله تعالى أن يجعل القرآن الكريم ربيع قلبه\nونور صدره ورفيق دربه في الدنيا والآخرة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 14,
                            color: darkGreen.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Signatures & Date
                Positioned(
                  bottom: 24,
                  left: 40,
                  right: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Signature
                      Column(
                        children: [
                          const Text(
                            'Talia',
                            style: TextStyle(
                              fontFamily: 'Amiri', // Or a cursive font if available
                              fontSize: 24,
                              fontStyle: FontStyle.italic,
                              color: darkGreen,
                            ),
                          ),
                          Container(width: 80, height: 1, color: goldAccent),
                          const SizedBox(height: 4),
                          Text(
                            'التوقيع',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14,
                              color: darkGreen.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      
                      // Date
                      Column(
                        children: [
                          Text(
                            _formattedDate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: darkGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(width: 80, height: 1, color: goldAccent),
                          const SizedBox(height: 4),
                          Text(
                            'التاريخ',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 14,
                              color: darkGreen.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

