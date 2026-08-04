import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'social_share_model.dart';
import 'social_share_theme.dart';

class SocialShareCard extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final double width;
  final SocialShareFormat format;

  const SocialShareCard({
    super.key,
    required this.data,
    required this.theme,
    this.width = 380,
    this.format = SocialShareFormat.portrait,
  });

  double get _aspectRatio {
    switch (format) {
      case SocialShareFormat.square:
        return 1.0;
      case SocialShareFormat.portrait:
        return 0.8; // 4:5
      case SocialShareFormat.story:
        return 0.5625; // 9:16
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: theme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Background Islamic Pattern Overlay (Geometric Octagram)
              Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicPatternPainter(
                    color: theme.patternColor,
                  ),
                ),
              ),

              // Ambient Inner Radial Glow
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.6),
                      radius: 0.8,
                      colors: [
                        theme.glowColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Top Corner Decorators (Left & Right)
              Positioned(
                top: 14,
                left: 14,
                child: _CornerDecorator(color: theme.accentColor),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Transform.scale(
                  scaleX: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                child: Transform.scale(
                  scaleY: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),
              Positioned(
                bottom: 14,
                right: 14,
                child: Transform.scale(
                  scaleX: -1,
                  scaleY: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),

              // Main Content Body
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Section (Branding & Category Badge)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.accentColor.withValues(alpha: 0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo_icon_padded.png',
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.auto_awesome,
                                    color: theme.accentColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تالية',
                                  style: AppTypography.displaySmall.copyWith(
                                    color: theme.accentColor,
                                    fontSize: 22,
                                    height: 1.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'رفيقك في رحلة القرآن',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: theme.textSecondary.withValues(alpha: 0.85),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.badgeBackground,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: theme.accentColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                data.category.icon,
                                size: 14,
                                color: theme.badgeTextColor,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                data.badgeText,
                                style: AppTypography.labelSmall.copyWith(
                                  color: theme.badgeTextColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Middle Card Content Frame
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: theme.cardBackground.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Quran Ayah Decorative Header
                                if (data.category == SocialShareCategory.quranAyah) ...[
                                  Text(
                                    '﴿ بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ ﴾',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.displaySmall.copyWith(
                                      color: theme.accentColor.withValues(alpha: 0.9),
                                      fontSize: 16,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],

                                // Title (If Any)
                                if (data.title != null && data.title!.isNotEmpty) ...[
                                  Text(
                                    data.title!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: data.category == SocialShareCategory.quranAyah ? 'Amiri' : null,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                ],

                                // Main Text Content
                                Text(
                                  data.content,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.displaySmall.copyWith(
                                    color: theme.textPrimary,
                                    fontSize: data.content.length > 200
                                        ? 15
                                        : (data.content.length > 100 ? 17 : 21),
                                    height: 1.8,
                                    fontFamily: (data.category == SocialShareCategory.quranAyah || data.category == SocialShareCategory.dua) ? 'Amiri' : null,
                                  ),
                                ),

                                // Subtitle / Verse Ref / Source
                                if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  Divider(
                                    color: theme.borderColor.withValues(alpha: 0.35),
                                    indent: 40,
                                    endIndent: 40,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    data.subtitle!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer Section (User Name Tag & App Footer)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.userName != null && data.userName!.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: theme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'رحلة ${data.userName}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: theme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      theme.borderColor.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.stars_rounded,
                                size: 14,
                                color: theme.accentColor,
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.borderColor.withValues(alpha: 0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'تمت المشاركة عبر تطبيق تالية للقرآن الكريم',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.textSecondary.withValues(alpha: 0.75),
                            fontSize: 10,
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

class _CornerDecorator extends StatelessWidget {
  final Color color;

  const _CornerDecorator({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _CornerPainter(color: color),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);

    // Corner Accent Dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(4, 4), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Geometric Octagram (Islamic 8-pointed star pattern painter)
class _IslamicPatternPainter extends CustomPainter {
  final Color color;

  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const sizeStep = 60.0;
    for (double x = 0; x < size.width + sizeStep; x += sizeStep) {
      for (double y = 0; y < size.height + sizeStep; y += sizeStep) {
        _drawOctagram(canvas, Offset(x, y), sizeStep * 0.35, paint);
      }
    }
  }

  void _drawOctagram(Canvas canvas, Offset center, double radius, Paint paint) {
    // Square 1
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRect(rect, paint);

    // Square 2 rotated 45 degrees
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * math.pi / 180);
    canvas.drawRect(Rect.fromCircle(center: Offset.zero, radius: radius), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
