import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'social_share_model.dart';
import 'social_share_theme.dart';

class SocialShareCard extends StatelessWidget {
  final SocialShareData data;
  final SocialShareTheme theme;
  final double width;

  const SocialShareCard({
    super.key,
    required this.data,
    required this.theme,
    this.width = 380,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background Islamic Pattern Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _IslamicPatternPainter(
                  color: theme.patternColor,
                ),
              ),
            ),

            // Top Corner Decorator (Left & Right)
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

            // Main Content Body
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Branding Header
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
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.auto_awesome,
                              color: theme.accentColor,
                              size: 24,
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

                  const SizedBox(height: AppSpacing.md),

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

                  const SizedBox(height: AppSpacing.lg),

                  // Title (If Any)
                  if (data.title != null && data.title!.isNotEmpty) ...[
                    Text(
                      data.title!,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: theme.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Middle Card Content Frame
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: theme.cardBackground.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.borderColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Decorative Top Bismillah or Ornament if Quran/Dua
                        if (data.category == SocialShareCategory.quranAyah) ...[
                          Text(
                            '﴿ بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيمِ ﴾',
                            textAlign: TextAlign.center,
                            style: AppTypography.displaySmall.copyWith(
                              color: theme.accentColor.withValues(alpha: 0.9),
                              fontSize: 16,
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
                                ? 16
                                : (data.content.length > 100 ? 18 : 22),
                            height: 1.8,
                          ),
                        ),

                        // Subtitle / Source / Verse Ref
                        if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Divider(
                            color: theme.borderColor.withValues(alpha: 0.3),
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

                  // Optional User Name Tag
                  if (data.userName != null && data.userName!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
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
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Footer Divider & App Slogan
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

                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    'تمت المشاركة عبر تطبيق تالية للقرآن الكريم',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      size: const Size(20, 20),
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
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _IslamicPatternPainter extends CustomPainter {
  final Color color;

  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        canvas.drawCircle(Offset(x, y), step * 0.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
