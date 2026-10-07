// lib/core/widgets/closing_moment.dart
//
// Talia's shared "closing moment" (لحظة الختام) building blocks.
// Used by session-ending flows (memorization completion, khatmah wird
// completion, …) to close with serenity instead of promotional noise.

import 'package:flutter/material.dart';

import '../../features/quran/domain/repositories/quran_repository.dart';
import '../constants/app_spacing.dart';
import '../di/injection.dart';
import '../extensions/context_extensions.dart';
import '../icons/talia_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'memorization_ayah_display.dart';

/// The serene heart of a closing moment: an ayah of tranquility and a quiet
/// summary of the session's impact, rendered before any statistics.
class ClosingMomentAyahCard extends StatelessWidget {
  const ClosingMomentAyahCard({super.key, required this.summary});

  /// Ar-Ra'd 13:28, shown in full from the canonical corpus: Quran text is
  /// never typed into UI copy (Islamic content sources policy).
  static const closingSurahId = 13;
  static const closingAyahNumber = 28;

  static Future<String?>? _closingAyahText;

  @visibleForTesting
  static void resetCacheForTest() => _closingAyahText = null;

  static Future<String?> _loadClosingAyah() async {
    if (!getIt.isRegistered<QuranRepository>()) return null;
    final result = await getIt<QuranRepository>().getSurahDetail(
      closingSurahId,
    );
    return result.fold(
      (_) => null,
      (detail) => detail.ayahs
          .where((ayah) => ayah.numberInSurah == closingAyahNumber)
          .firstOrNull
          ?.text
          .replaceAll('﻿', '')
          .trim(),
    );
  }

  /// Loads once; a failed read is retried on the next closing moment.
  static Future<String?> _closingAyah() {
    final cached = _closingAyahText;
    if (cached != null) return cached;
    final future = _loadClosingAyah().catchError((Object _) => null);
    _closingAyahText = future;
    future.then((text) {
      if (text == null && identical(_closingAyahText, future)) {
        _closingAyahText = null;
      }
    });
    return future;
  }

  /// Pre-localized, caller-specific summary line (e.g. ayahs memorized or
  /// khatmah wird page range).
  final String summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final cardBg = context.tokens.card;
    final cardBorder = context.tokens.divider;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? cardBorder
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          const Icon(TaliaIcons.moon, color: AppColors.gold, size: 28),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.closingMomentLabel,
            style: AppTypography.labelLarge.copyWith(
              color: textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Fails closed: without the canonical text no ayah is shown.
          FutureBuilder<String?>(
            future: _closingAyah(),
            builder: (context, snapshot) {
              final text = snapshot.data;
              if (text == null || text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: MemorizationAyahDisplay(
                    key: const Key('closing_moment_ayah'),
                    text: text,
                    surahId: closingSurahId,
                    ayahNumber: closingAyahNumber,
                    textColor: textPrimary,
                    decorationColor: AppColors.gold.withValues(alpha: 0.5),
                    referenceColor: AppColors.gold,
                  ),
                ),
              );
            },
          ),
          Text(
            summary,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Opens the serene closing-dua bottom sheet shared by all closing moments.
Future<void> showClosingDuaSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.tokens.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusLg),
      ),
    ),
    builder: (sheetContext) {
      final sheetL10n = sheetContext.l10n;
      final sheetIsDark = sheetContext.isDark;
      final sheetTextPrimary = sheetIsDark
          ? AppColors.darkTextPrimary
          : AppColors.lightTextPrimary;
      final sheetTextSecondary = sheetIsDark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(TaliaIcons.dua, color: AppColors.gold, size: 32),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetL10n.closingDua,
                key: const Key('closing_dua_text'),
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  fontFamily: 'Amiri',
                  color: sheetTextPrimary,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                sheetL10n.closingDuaAmen,
                key: const Key('closing_dua_amen'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: sheetTextSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  sheetL10n.closingMomentLabel,
                  style: AppTypography.bodyMedium.copyWith(
                    color: sheetTextSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
