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
    final isAchievement = data.category == SocialShareCategory.achievement ||
        data.category == SocialShareCategory.progress;

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.backgroundGradient,
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: theme.borderColor, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: theme.accentColor.withValues(alpha: 0.15),
              blurRadius: 18,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // ─── 1. Background Islamic Geometric Pattern ──────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _IslamicPatternPainter(
                    color: theme.patternColor,
                  ),
                ),
              ),

              // ─── 2. Ambient Radial Glow Header ────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.5),
                      radius: 0.85,
                      colors: [
                        theme.glowColor,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ─── 3. Islamic Mihrab Arch Silhouette Overlay ─────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _MihrabArchPainter(
                    color: theme.accentColor.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ─── 4. Corner Ornaments (Top & Bottom) ───────────────────────
              Positioned(
                top: 12,
                left: 12,
                child: _CornerDecorator(color: theme.accentColor),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Transform.scale(
                  scaleX: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Transform.scale(
                  scaleY: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Transform.scale(
                  scaleX: -1,
                  scaleY: -1,
                  child: _CornerDecorator(color: theme.accentColor),
                ),
              ),

              // ─── 5. Main Card Content Body ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Section (Branding & Logo)
                    _CardHeader(theme: theme, badgeText: data.badgeText, categoryIcon: data.category.icon),

                    // Middle Section (Golden Achievement Medal + Card Container)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBackground.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.borderColor.withValues(alpha: 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Illuminated Golden Medal Emblem for Achievements
                                if (isAchievement) ...[
                                  _GoldenAchievementMedal(theme: theme),
                                  const SizedBox(height: AppSpacing.sm),
                                ],

                                // Bismillah for Quran Ayah shares
                                if (data.category == SocialShareCategory.quranAyah) ...[
                                  Text(
                                    '﴿ بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ ﴾',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.displaySmall.copyWith(
                                      color: theme.accentColor.withValues(alpha: 0.95),
                                      fontSize: 16,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                ],

                                // Title (e.g., الصفحة الأولى / إنجاز جديد)
                                if (data.title != null && data.title!.isNotEmpty) ...[
                                  Text(
                                    data.title!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.headlineMedium.copyWith(
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isAchievement ? 20 : 18,
                                      fontFamily: 'Amiri',
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                ],

                                // Main Content (e.g. اقرأ أول صفحة من القرآن)
                                Text(
                                  data.content,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: AppTypography.displaySmall.copyWith(
                                    color: theme.textPrimary,
                                    fontSize: data.content.length > 180
                                        ? 14
                                        : (data.content.length > 90 ? 16 : 19),
                                    height: 1.75,
                                    fontFamily: 'Amiri',
                                    fontWeight: isAchievement ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),

                                // Subtitle / Reference
                                if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Divider(
                                    color: theme.borderColor.withValues(alpha: 0.35),
                                    indent: 48,
                                    endIndent: 48,
                                  ),
                                  Text(
                                    data.subtitle!,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer Section (User Name Tag & App Signature)
                    _CardFooter(theme: theme, userName: data.userName),
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

/// Header with Talia App branding and category badge
class _CardHeader extends StatelessWidget {
  final SocialShareTheme theme;
  final String badgeText;
  final IconData categoryIcon;

  const _CardHeader({
    required this.theme,
    required this.badgeText,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  color: theme.accentColor.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_icon_padded.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.accentColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تالية',
                  style: AppTypography.displaySmall.copyWith(
                    color: theme.accentColor,
                    fontSize: 20,
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
                Text(
                  'رفيقك في رحلة القرآن',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.textSecondary.withValues(alpha: 0.85),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: theme.badgeBackground,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                categoryIcon,
                size: 13,
                color: theme.badgeTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: AppTypography.labelSmall.copyWith(
                  color: theme.badgeTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 3D Illuminated Golden Medal Emblem Widget for Achievements
class _GoldenAchievementMedal extends StatelessWidget {
  final SocialShareTheme theme;

  const _GoldenAchievementMedal({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accentColor,
            theme.borderColor,
            const Color(0xFF8B6508),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.45),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.cardBackground,
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.workspace_premium_rounded,
          color: theme.accentColor,
          size: 32,
        ),
      ),
    );
  }
}

/// Card Footer showing user name & Quran signature
class _CardFooter extends StatelessWidget {
  final SocialShareTheme theme;
  final String? userName;

  const _CardFooter({required this.theme, this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userName != null && userName!.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 13,
                color: theme.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                'رحلة $userName مع القرآن',
                style: AppTypography.labelSmall.copyWith(
                  color: theme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
                size: 12,
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
        const SizedBox(height: 4),
        Text(
          'تمت المشاركة عبر تطبيق تالية للقرآن الكريم',
          style: AppTypography.labelSmall.copyWith(
            color: theme.textSecondary.withValues(alpha: 0.75),
            fontSize: 9.5,
          ),
        ),
      ],
    );
  }
}

/// Corner Decorator Painter
class _CornerDecorator extends StatelessWidget {
  final Color color;

  const _CornerDecorator({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
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
      ..color = color.withValues(alpha: 0.75)
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

    const sizeStep = 54.0;
    for (double x = 0; x < size.width + sizeStep; x += sizeStep) {
      for (double y = 0; y < size.height + sizeStep; y += sizeStep) {
        _drawOctagram(canvas, Offset(x, y), sizeStep * 0.35, paint);
      }
    }
  }

  void _drawOctagram(Canvas canvas, Offset center, double radius, Paint paint) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRect(rect, paint);

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

/// Islamic Mihrab Arch Silhouette Painter for Top Card Overlay
class _MihrabArchPainter extends CustomPainter {
  final Color color;

  _MihrabArchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final topMargin = size.height * 0.08;
    final archWidth = size.width * 0.75;
    final archHeight = size.height * 0.22;
    final left = (size.width - archWidth) / 2;
    final right = left + archWidth;

    path.moveTo(left, topMargin + archHeight);
    path.lineTo(left, topMargin + archHeight * 0.4);
    path.cubicTo(
      left,
      topMargin,
      size.width / 2 - archWidth * 0.2,
      topMargin,
      size.width / 2,
      topMargin - 6,
    );
    path.cubicTo(
      size.width / 2 + archWidth * 0.2,
      topMargin,
      right,
      topMargin,
      right,
      topMargin + archHeight * 0.4,
    );
    path.lineTo(right, topMargin + archHeight);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MihrabArchPainter oldDelegate) =>
      oldDelegate.color != color;
}
