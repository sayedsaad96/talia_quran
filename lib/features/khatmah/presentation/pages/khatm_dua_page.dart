import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/khatmah_dedication.dart';
import '../cubits/khatm_dua_cubit.dart';
import '../khatmah_localizations.dart';

class KhatmDuaPage extends StatefulWidget {
  const KhatmDuaPage({super.key, this.cubit, this.dedication});

  final KhatmDuaCubit? cubit;
  final KhatmahDedication? dedication;

  @override
  State<KhatmDuaPage> createState() => _KhatmDuaPageState();
}

class _KhatmDuaPageState extends State<KhatmDuaPage> {
  late final KhatmDuaCubit _cubit;
  bool _createdOwnCubit = false;

  @override
  void initState() {
    super.initState();
    if (widget.cubit != null) {
      _cubit = widget.cubit!;
    } else {
      try {
        _cubit = context.read<KhatmDuaCubit>();
      } catch (_) {
        _cubit = getIt<KhatmDuaCubit>();
        _createdOwnCubit = true;
      }
    }

    if (_cubit.state is KhatmDuaInitial) {
      _cubit.load();
    }
  }

  @override
  void dispose() {
    if (_createdOwnCubit) {
      _cubit.close();
    }
    super.dispose();
  }

  void _copyDua(
    String arabicText,
    String? dedicationInsert, [
    String? supplicationInsert,
  ]) {
    final buffer = StringBuffer();
    buffer.writeln(arabicText);
    if (dedicationInsert != null && dedicationInsert.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(context.l10n.khatmahDedicationOfReward);
      buffer.writeln(dedicationInsert);
    }
    if (supplicationInsert != null && supplicationInsert.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(supplicationInsert);
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.khatmahDuACopiedToClipboard,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final gold = isDark ? AppColors.goldLight : AppColors.gold;
    final bg = context.tokens.background;
    final cardBg = context.tokens.card;
    final border = context.tokens.divider;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          context.l10n.khatmahDuAKhatmAlQuran,
          style: AppTypography.titleMedium,
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const Key('khatm_dua_decrease_font'),
                tooltip: context.l10n.khatmahDecreaseFontSize,
                icon: const Icon(TaliaIcons.textDecrease),
                onPressed: () => _cubit.decreaseFontSize(),
              ),
              IconButton(
                key: const Key('khatm_dua_increase_font'),
                tooltip: context.l10n.khatmahIncreaseFontSize,
                icon: const Icon(TaliaIcons.textIncrease),
                onPressed: () => _cubit.increaseFontSize(),
              ),
              BlocBuilder<KhatmDuaCubit, KhatmDuaState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state is! KhatmDuaLoaded) {
                    return const SizedBox.shrink();
                  }
                  final dedicationInsert =
                      (widget.dedication != null &&
                          widget.dedication!.isDedicated)
                      ? context.l10n.khatmahDedicatedTo(
                          widget.dedication!.recipientName ?? '',
                        )
                      : null;
                  final supplicationInsert =
                      (widget.dedication != null &&
                          widget.dedication!.isDedicated &&
                          widget.dedication!.condition != null)
                      ? state.data.getDedicationInsert(
                          widget.dedication!.condition!,
                          widget.dedication!.effectiveGender,
                          widget.dedication!.recipientName,
                        )
                      : null;

                  return IconButton(
                    key: const Key('khatm_dua_copy_button'),
                    tooltip: context.l10n.khatmahCopyDuA,
                    icon: const Icon(TaliaIcons.copy),
                    onPressed: () => _copyDua(
                      state.data.arabicText,
                      dedicationInsert,
                      supplicationInsert,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<KhatmDuaCubit, KhatmDuaState>(
        bloc: _cubit,
        builder: (context, state) {
          if (state is KhatmDuaLoading || state is KhatmDuaInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is KhatmDuaError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      TaliaIcons.error,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      context.l10n.khatmahDuaLoadError,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => _cubit.load(),
                      child: Text(context.l10n.khatmahRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is KhatmDuaLoaded) {
            final data = state.data;
            final fontScale = state.fontScale;
            // Dedication line and supplication insert share one size.
            final insertFontSize = 18.0 * fontScale;
            final hasDedication =
                widget.dedication != null && widget.dedication!.isDedicated;
            final dedicationInsert = hasDedication
                ? context.l10n.khatmahDedicatedTo(
                    widget.dedication!.recipientName ?? '',
                  )
                : null;
            final supplicationInsert =
                (hasDedication && widget.dedication!.condition != null)
                ? data.getDedicationInsert(
                    widget.dedication!.condition!,
                    widget.dedication!.effectiveGender,
                    widget.dedication!.recipientName,
                  )
                : '';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source attribution & Tier Guidance Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(TaliaIcons.mushaf, size: 20, color: gold),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                context.l10n.khatmahSuggestedDua,
                                style: AppTypography.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                  border: Border.all(
                                    color: gold.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  context.l10n.khatmahGeneralGuidance,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: gold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          data.isApproved
                              ? data.sourceNote
                              : context.l10n.khatmahDuaPendingReview,
                          style: AppTypography.bodySmall.copyWith(
                            color: context.tokens.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Main Du'a Text Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      data.arabicText,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Noto_Naskh_Arabic',
                        fontSize: 20.0 * fontScale,
                        height: 2.2,
                        fontWeight: FontWeight.w500,
                        color: context.tokens.textPrimary,
                      ),
                    ),
                  ),

                  // Dedication Supplication Section (if dedicated)
                  if (hasDedication && dedicationInsert != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      key: const Key('khatm_dua_dedication_card'),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.khatmahDedicationOfReward,
                            style: AppTypography.titleMedium.copyWith(
                              color: gold,
                            ),
                          ),
                          if (widget.dedication!.relationship != null)
                            Text(
                              localizedKhatmahRelationship(
                                context,
                                widget.dedication!.relationship,
                              ),
                            ),
                          if (widget.dedication!.condition != null)
                            Text(
                              localizedKhatmahCondition(
                                context,
                                widget.dedication!.condition,
                              ),
                            ),
                          if (widget.dedication!.customNote?.isNotEmpty == true)
                            Text(
                              context.l10n.khatmahUserNote(
                                widget.dedication!.customNote!,
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            dedicationInsert,
                            textAlign: TextAlign.center,
                            textDirection: context.textDirection,
                            style: TextStyle(
                              fontFamily: 'Noto_Naskh_Arabic',
                              fontSize: insertFontSize,
                              height: 2.0,
                              fontWeight: FontWeight.w600,
                              color: context.tokens.textPrimary,
                            ),
                          ),
                          if (supplicationInsert.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Divider(color: gold.withValues(alpha: 0.3)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              supplicationInsert,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Noto_Naskh_Arabic',
                                fontSize: insertFontSize,
                                height: 2.2,
                                fontWeight: FontWeight.w500,
                                color: context.tokens.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
