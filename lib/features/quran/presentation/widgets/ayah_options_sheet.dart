import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/quran_ayah_display_text.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/bookmark_entry.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_audio_player_cubit.dart';
import 'reciter_selector_sheet.dart';

/// Ayah long-press options sheet of the adult Mushaf reader.
///
/// Moved verbatim from `QuranReaderPage` (`_AyahOptionsSheet` + `_OptionBtn`)
/// as a behavior-preserving refactor. All audio/bookmark/share behavior is
/// unchanged.
class AyahOptionsSheet extends StatefulWidget {
  const AyahOptionsSheet({
    super.key,
    required this.ayah,
    required this.surahName,
    required this.onInteraction,
  });

  final Ayah ayah;
  final String surahName;
  final VoidCallback onInteraction;

  @override
  State<AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<AyahOptionsSheet> {
  Future<void> _playAyah() async {
    widget.onInteraction();
    final cubit = context.read<QuranAudioPlayerCubit>();
    if (cubit.state.scope == PlayScope.singleAyah &&
        cubit.state.isPlaying &&
        cubit.state.currentSurahId == widget.ayah.surahId &&
        cubit.state.currentAyahNumber == widget.ayah.numberInSurah) {
      await cubit.pause();
    } else {
      await cubit.playAyah(widget.ayah.surahId, widget.ayah.numberInSurah);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();
    final displayedAyahText = QuranAyahDisplayText.withVerseBrackets(
      widget.ayah.text,
      ayahNumber: widget.ayah.numberInSurah,
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                context.l10n.surahAyahFormat(
                  widget.surahName,
                  widget.ayah.numberInSurah,
                ),
                style: AppTypography.titleMedium.copyWith(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Full Ayah Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: primary.withValues(alpha: 0.15)),
                ),
                child: Text(
                  displayedAyahText,
                  style: AppTypography.quranMedium,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Reciter Selector Button
              ValueListenableBuilder<QuranReciter>(
                valueListenable: reciterService.currentReciter,
                builder: (context, reciter, _) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: () => ReciterSelectorSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.record_voice_over_rounded,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.isArabic
                                  ? reciter.nameAr
                                  : reciter.nameEn,
                              style: AppTypography.bodySmall.copyWith(
                                color: primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
                    builder: (context, audioState) {
                      final isPlayingThisAyah =
                          audioState.scope == PlayScope.singleAyah &&
                          audioState.isPlaying &&
                          audioState.currentSurahId == widget.ayah.surahId &&
                          audioState.currentAyahNumber ==
                              widget.ayah.numberInSurah;
                      final isBufferingThisAyah =
                          audioState.scope == PlayScope.singleAyah &&
                          audioState.isLoading &&
                          audioState.currentSurahId == widget.ayah.surahId &&
                          audioState.currentAyahNumber ==
                              widget.ayah.numberInSurah;

                      return AyahOptionButton(
                        icon: isBufferingThisAyah
                            ? Icons.hourglass_top_rounded
                            : (isPlayingThisAyah
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill_rounded),
                        label: isPlayingThisAyah
                            ? context.l10n.pause
                            : context.l10n.play,
                        color: primary,
                        onTap: _playAyah,
                      );
                    },
                  ),
                  AyahOptionButton(
                    icon: Icons.copy_rounded,
                    label: context.l10n.copy,
                    color: primary,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: displayedAyahText),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.copied)),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                  AyahOptionButton(
                    icon: Icons.bookmark_rounded,
                    label: context.l10n.bookmark,
                    color: primary,
                    onTap: () async {
                      final bookmarkService = getIt<BookmarkService>();
                      final entry = BookmarkEntry(
                        surahId: widget.ayah.surahId,
                        surahName: widget.surahName,
                        ayahNumber: widget.ayah.numberInSurah,
                        ayahText: widget.ayah.text,
                        savedAt: DateTime.now().toUtc(),
                      );
                      final isAdded = await bookmarkService.toggle(entry);
                      if (isAdded) {
                        unawaited(HapticFeedback.mediumImpact());
                      }
                      if (context.mounted) {
                        final navigator = Navigator.of(context);
                        final message = isAdded
                            ? context.l10n.bookmarkAdded
                            : context.l10n.bookmarkRemoved;
                        final undoLabel = context.l10n.undo;
                        navigator.pop();
                        context.showAutoDismissSnackBar(
                          message,
                          action: SnackBarAction(
                            label: undoLabel,
                            onPressed: () {
                              unawaited(bookmarkService.toggle(entry));
                            },
                          ),
                        );
                      }
                    },
                  ),
                  AyahOptionButton(
                    icon: Icons.share_rounded,
                    label: context.l10n.share,
                    color: primary,
                    onTap: () {
                      Navigator.pop(context);
                      final data = SocialShareData.quranAyah(
                        ayah: widget.ayah,
                        surahName: widget.surahName,
                      );
                      SocialShareSheet.show(context, data);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class AyahOptionButton extends StatelessWidget {
  const AyahOptionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
