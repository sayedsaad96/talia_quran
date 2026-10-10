import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../quran/domain/entities/quran_entities.dart';
import '../../domain/navigation/memorization_navigation_resolver.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import 'practice_passage_dialog.dart';

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
  bool _navigating = false;

  Surah get surah => widget.surah;
  bool get isDark => widget.isDark;
  Color get primary => widget.primary;

  Future<void> _open() async {
    if (_opening || _navigating) return;
    setState(() => _opening = true);
    try {
      final selection = await _choosePassage();
      if (selection == null || !mounted) return;
      final route =
          await MemorizationNavigationResolver(
            getIt<MemorizationPlusRepository>(),
          ).practiceSurahSessionLocation(
            surah.id,
            surahAyahCount: surah.ayahCount,
            startAyah: selection.startAyah,
            ayahCount: selection.ayahCount,
          );
      if (!mounted) return;
      setState(() => _opening = false);
      _navigating = true;
      try {
        await context.push(route);
      } finally {
        _navigating = false;
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<({int startAyah, int ayahCount})?> _choosePassage() async {
    final choice = await showDialog<_PracticePassageChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.practicePassageTitle),
        content: Text(context.l10n.practicePassageMessage),
        actionsOverflowDirection: VerticalDirection.up,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          OutlinedButton(
            key: const Key('practice_choose_split'),
            onPressed: () =>
                Navigator.pop(dialogContext, _PracticePassageChoice.split),
            child: Text(context.l10n.practiceChoosePassage),
          ),
          FilledButton(
            key: const Key('practice_choose_whole'),
            onPressed: () =>
                Navigator.pop(dialogContext, _PracticePassageChoice.whole),
            child: Text(context.l10n.practiceWholeSurah),
          ),
        ],
      ),
    );
    if (choice == _PracticePassageChoice.whole) {
      return (startAyah: 1, ayahCount: surah.ayahCount);
    }
    if (choice != _PracticePassageChoice.split || !mounted) return null;
    return _chooseSplitPassage();
  }

  Future<({int startAyah, int ayahCount})?> _chooseSplitPassage() =>
      showDialog<({int startAyah, int ayahCount})>(
        context: context,
        builder: (_) => PracticePassageDialog(surahAyahCount: surah.ayahCount),
      );

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
                  context.numText(surah.id),
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
                    ? TaliaIcons.chevronBack
                    : TaliaIcons.chevronForward,
                size: 14,
                color: context.tokens.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

enum _PracticePassageChoice { whole, split }
