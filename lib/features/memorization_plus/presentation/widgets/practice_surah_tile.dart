import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';

class PracticeSurahTile extends StatefulWidget {
  const PracticeSurahTile({
    super.key,
    required this.surah,
    required this.isDark,
    required this.primary,
  });

  final Surah surah;
  final bool isDark;
  final Color primary;

  @override
  State<PracticeSurahTile> createState() => _PracticeSurahTileState();
}

class _PracticeSurahTileState extends State<PracticeSurahTile> {
  /// Guards the async route lookup so a double tap never opens two sessions.
  bool _opening = false;

  Surah get surah => widget.surah;
  bool get isDark => widget.isDark;
  Color get primary => widget.primary;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final route = await MemorizationNavigationResolver(
        getIt<MemorizationPlusRepository>(),
      ).practiceSurahSessionLocation(surah.id, surahAyahCount: surah.ayahCount);
      if (!mounted) return;
      await context.push(route);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.card;
    final border = context.tokens.divider;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: _opening ? null : _open,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  '${surah.id}',
                  style: AppTypography.labelMedium.copyWith(color: primary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.isArabic ? surah.nameAr : surah.nameEn,
                    style: context.isArabic
                        ? AppTypography.surahTitle.copyWith(
                            color: primary,
                            fontSize: 18,
                          )
                        : AppTypography.titleMedium.copyWith(
                            color: context.tokens.textPrimary,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.countAyahs(
                      surah.ayahCount,
                      context.numText(surah.ayahCount),
                    ),
                    style: AppTypography.bodySmall.copyWith(
                      color: context.tokens.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (_opening)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary,
                ),
              )
            else
              Icon(
                context.isArabic
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: context.tokens.textHint,
              ),
          ],
        ),
      ),
    );
  }
}
