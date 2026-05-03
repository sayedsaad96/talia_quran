import 'dart:math' as math;
import 'package:flutter/material.dart';

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
    required this.juzNumber,
    required this.completionDate,
  });

  final String userName;
  final int juzNumber;
  final DateTime completionDate;

  String get _arabicJuzNumber {
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

  String get _formattedDate {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'إبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${completionDate.day} ${months[completionDate.month - 1]} ${completionDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    const goldLight = Color(0xFFF5D78E);
    const goldDark = Color(0xFF8B6914);
    const goldAccent = Color(0xFFC9A84C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 1080 / 1350,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2C1810), goldDark, Color(0xFF1A0F08)],
            ),
          ),
          child: Stack(
            children: [
              // Corner ornaments
              const Positioned.fill(
                child: CustomPaint(
                  painter: IslamicOrnamentPainter(color: goldAccent),
                ),
              ),

              // Gold frame
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: goldAccent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Basmala
                    Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: goldLight.withValues(alpha: 0.9),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Divider
                    const _GoldDivider(color: goldAccent),

                    // Title
                    const Text(
                      'شهادة إتمام',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: goldLight,
                        letterSpacing: 2,
                        shadows: [Shadow(color: goldDark, blurRadius: 8)],
                      ),
                    ),

                    Text(
                      'يُشهد بأن',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18,
                        color: goldLight.withValues(alpha: 0.75),
                      ),
                    ),

                    // User name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: goldAccent, width: 1.5),
                          top: BorderSide(color: goldAccent, width: 1.5),
                        ),
                      ),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: goldLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Main text
                    Text(
                      'قد أتمّ بفضل الله وتوفيقه\nحفظ الجزء $_arabicJuzNumber\nمن القرآن الكريم',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        color: goldLight.withValues(alpha: 0.9),
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const _GoldDivider(color: goldAccent),

                    // Date
                    Text(
                      _formattedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: goldLight.withValues(alpha: 0.6),
                        letterSpacing: 1.5,
                      ),
                    ),

                    // Talia logo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book_rounded,
                          color: goldAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تطبيق تالية لحفظ القرآن الكريم',
                          style: TextStyle(
                            fontSize: 12,
                            color: goldAccent.withValues(alpha: 0.7),
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
    );
  }
}

class _GoldDivider extends StatelessWidget {
  const _GoldDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Divider(color: color.withValues(alpha: 0.4))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(Icons.star_rounded, color: color, size: 12),
      ),
      Expanded(child: Divider(color: color.withValues(alpha: 0.4))),
    ],
  );
}
