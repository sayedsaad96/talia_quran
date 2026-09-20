// lib/features/home/presentation/widgets/home_micro_review_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/surah_names.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/memorization/micro_review_picker.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../memorization_plus/domain/entities/ayah_review_record.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../theme/home_skin.dart';
import 'glass_panel.dart';

/// "لمحة مراجعة" (Micro-Review): one quiet ayah from the user's older
/// memorization, hidden until tapped — a 30-second active-recall moment.
///
/// Self-contained: loads its own data via DI and renders nothing when there
/// is nothing to review, so it never disturbs the home layout of new users.
class HomeMicroReviewCard extends StatefulWidget {
  const HomeMicroReviewCard({super.key, required this.skin});

  final HomeSkin skin;

  @override
  State<HomeMicroReviewCard> createState() => _HomeMicroReviewCardState();
}

class _HomeMicroReviewCardState extends State<HomeMicroReviewCard> {
  final MicroReviewPicker _picker = const MicroReviewPicker();
  AyahReviewRecord? _pick;
  bool _revealed = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!getIt.isRegistered<MemorizationPlusRepository>()) {
        if (mounted) setState(() => _loaded = true);
        return;
      }
      final result = await getIt<MemorizationPlusRepository>()
          .getAllReviewRecords();
      final pick = result.fold(
        (_) => null,
        (records) => _picker.pick(records: records, now: DateTime.now()),
      );
      if (!mounted) return;
      setState(() {
        _pick = pick;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Quiet until loaded, invisible when there is nothing to review.
    if (!_loaded || _pick == null) return const SizedBox.shrink();

    final record = _pick!;
    final l10n = context.l10n;
    final skin = widget.skin;
    final surahName = context.isArabic
        ? (SurahNames.arabic[record.surahId] ?? '')
        : (SurahNames.english[record.surahId] ?? '');
    final reference = l10n.microReviewReference(
      surahName,
      record.ayahNumber.toString(),
    );

    return GlassPanel(
      skin: skin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 18, color: skin.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.microReviewTitle,
                style: AppTypography.titleSmall.copyWith(
                  color: skin.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.microReviewQuestion,
            style: AppTypography.bodySmall.copyWith(color: skin.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _revealed
                ? Text(
                    qcf.getVerse(record.surahId, record.ayahNumber),
                    key: const ValueKey('revealed'),
                    textAlign: TextAlign.center,
                    style: AppTypography.headlineSmall.copyWith(
                      fontFamily: 'Amiri',
                      color: skin.textPrimary,
                      height: 2,
                    ),
                  )
                : InkWell(
                    key: const ValueKey('hidden'),
                    onTap: () => setState(() => _revealed = true),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(color: skin.glassBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            reference,
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium.copyWith(
                              color: skin.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.microReviewRevealHint,
                            style: AppTypography.bodySmall.copyWith(
                              color: skin.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  reference,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: skin.textSecondary,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('home_micro_review_recite'),
                onPressed: () => context.push(
                  '${AppRoutes.memorizationV2Session}'
                  '?surahId=${record.surahId}'
                  '&startAyah=${record.ayahNumber}'
                  '&blockSize=5'
                  '&intent=review'
                  '&origin=review',
                ),
                icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                label: Text(l10n.microReviewRecite),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
