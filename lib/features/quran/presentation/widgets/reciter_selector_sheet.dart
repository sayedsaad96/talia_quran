import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../cubits/quran_audio_player_cubit.dart';

class ReciterSelectorSheet extends StatelessWidget {
  const ReciterSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const ReciterSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.tokens.surface;
    final primary = context.tokens.accent;
    final reciterService = getIt<QuranReciterService>();

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(TaliaIcons.recite, color: primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.l10n.selectReciter,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<QuranReciter>(
              valueListenable: reciterService.currentReciter,
              builder: (context, current, _) {
                return Column(
                  children: QuranReciter.values.map((reciter) {
                    final isSelected = reciter == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isSelected
                            ? primary.withValues(alpha: 0.08)
                            : context.tokens.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? primary
                                : context.tokens.divider,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            reciterService.setReciter(reciter);
                            // Apply to ongoing recitation immediately; when
                            // nothing is playing this is a no-op and the
                            // preference takes effect on the next playback.
                            getIt<QuranAudioPlayerCubit>().changeReciter(
                              reciter,
                            );
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary
                                  : primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? TaliaIcons.check : TaliaIcons.mic,
                              color: isSelected ? Colors.white : primary,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            context.isArabic ? reciter.nameAr : reciter.nameEn,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? primary
                                  : context.tokens.textPrimary,
                            ),
                          ),
                          trailing: isSelected
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd,
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.reciterActiveChip,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
