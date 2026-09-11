import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/services/quran_warmup_service.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';

/// "Continue Reading" card shown above the Quran list tabs.
///
/// The page number is resolved synchronously from the real last restorable
/// reading position ([AppSessionService.getLastRestorableLocation]), never
/// from the last opened screen. Surah/ayah context is enriched
/// asynchronously from [QuranRepository.getQuranPage]; while loading (or on
/// error) a compact page-only card is shown. When there is no saved position
/// (first run) nothing is rendered.
class ContinueReadingCard extends StatefulWidget {
  const ContinueReadingCard({super.key});

  @override
  State<ContinueReadingCard> createState() => _ContinueReadingCardState();
}

class _ContinueReadingCardState extends State<ContinueReadingCard> {
  int? _page;
  Future<QuranPageDetail?>? _detailFuture;

  @override
  void initState() {
    super.initState();
    _page = _resolveLastPage();
    if (_page != null) {
      final page = _page!;
      _detailFuture = getIt<QuranRepository>()
          .getQuranPage(page)
          .then((result) => result.fold((_) => null, (detail) => detail));
    }
  }

  int? _resolveLastPage() {
    try {
      return QuranWarmupService.parsePageFromLocation(
        getIt<AppSessionService>().getLastRestorableLocation(),
      );
    } catch (_) {
      return null;
    }
  }

  void _resume(int page) {
    HapticFeedback.selectionClick();
    context.push('/quran/page/$page');
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page == null) return const SizedBox.shrink();

    return FutureBuilder<QuranPageDetail?>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        final surah = detail?.surahs.firstOrNull;
        final subtitle = surah == null
            ? '${context.l10n.page} $page'
            : context.isArabic
                ? '${surah.nameAr} • ${context.l10n.page} $page'
                : '${surah.nameEn} • ${context.l10n.page} $page';
        return _CardBody(
          page: page,
          subtitle: subtitle,
          onTap: () => _resume(page),
        );
      },
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.page,
    required this.subtitle,
    required this.onTap,
  });

  final int page;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final label =
        '${context.l10n.continueReading}، $subtitle';

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: primary.withValues(alpha: 0.35),
                width: 1,
              ),
              color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    color: primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.continueReading,
                        style: AppTypography.labelLarge.copyWith(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  context.forwardChevron,
                  size: 18,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
