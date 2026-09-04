import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../domain/entities/khatmah_plan.dart';
import '../../domain/entities/khatmah_scheduling_engine.dart';

class KhatmahProgressGauge extends StatelessWidget {
  const KhatmahProgressGauge({
    super.key,
    required this.plan,
    this.size = 200.0,
  });

  final KhatmahPlan plan;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isArabic = context.isArabic;
    final percent = (plan.progressPercentage * 100)
        .clamp(0, 100)
        .toStringAsFixed(1);
    final completedPages = isArabic
        ? MushafHizbHelper.toArabicNumber(plan.completedPagesCount)
        : plan.completedPagesCount.toString();
    final totalPages = isArabic
        ? MushafHizbHelper.toArabicNumber(KhatmahSchedulingEngine.totalPages)
        : KhatmahSchedulingEngine.totalPages.toString();
    final remainingPages = isArabic
        ? MushafHizbHelper.toArabicNumber(plan.remainingPages)
        : plan.remainingPages.toString();

    final dateStr =
        '${plan.expectedEndDate.year}/${plan.expectedEndDate.month.toString().padLeft(2, '0')}/${plan.expectedEndDate.day.toString().padLeft(2, '0')}';
    final formattedDate = isArabic ? _toArabicDigits(dateStr) : dateStr;
    final expectedCompletionLabel = context.l10n.khatmahEstCompletion(
      formattedDate,
    );
    final progressValue = context.l10n.khatmahProgressValue(
      completedPages,
      totalPages,
      percent,
    );

    return Semantics(
      label: context.l10n.khatmahProgress,
      value: '$progressValue. $expectedCompletionLabel',
      excludeSemantics: true,
      child: Container(
        key: const Key('khatmah_progress_gauge'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: math.max(
                size,
                MediaQuery.textScalerOf(context).scale(140),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Custom arc gauge painter
                  CustomPaint(
                    size: Size(size, size),
                    painter: _GaugePainter(
                      progress: plan.progressPercentage.clamp(0.0, 1.0),
                      trackColor: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      progressColor: AppColors.gold,
                      progressEndColor: AppColors.goldLight,
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        key: const Key('khatmah_progress_percentage'),
                        style: AppTypography.headlineMedium.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedPages / $totalPages',
                        key: const Key('khatmah_progress_pages_count'),
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.khatmahPagesLeft(
                          (remainingPages).toString(),
                        ),
                        key: const Key('khatmah_progress_remaining_pages'),
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    expectedCompletionLabel,
                    key: const Key('khatmah_progress_end_date'),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _toArabicDigits(String input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.replaceAllMapped(
      RegExp(r'\d'),
      (m) => digits[int.parse(m.group(0)!)],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.progressEndColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color progressEndColor;

  static const double _startAngle = 0.75 * math.pi; // 135 deg
  static const double _sweepAngle = 1.5 * math.pi; // 270 deg

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 24) / 2;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      trackPaint,
    );

    if (progress > 0) {
      final activeSweep = _sweepAngle * progress;
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: [progressColor, progressEndColor],
          tileMode: TileMode.clamp,
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        activeSweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.progressEndColor != progressEndColor;
  }
}
