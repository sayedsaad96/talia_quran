import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../domain/entities/juz_summary.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';

/// Quick navigation sheet for the adult reader (presentation only).
///
/// The footer page indicator opens this sheet instead of hosting a permanent
/// 1–604 slider. Sections: last read position, go-to-page (field + scrubber),
/// surah jump (from the loaded surah list), juz jump (shared [JuzSummary]
/// metadata). Navigation itself stays in the reader page via [onGoToPage].
class QuickNavigationSheet extends StatefulWidget {
  const QuickNavigationSheet({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onGoToPage,
    this.summaries = const [],
  });

  final int currentPage;

  /// Shared Juz metadata. When empty, the Juz section loads the real surah
  /// list and derives the same summaries itself.
  final List<JuzSummary> summaries;
  final int? lastPage;
  final ValueChanged<int> onGoToPage;

  static Future<void> show(
    BuildContext context, {
    required int currentPage,
    required int? lastPage,
    required ValueChanged<int> onGoToPage,
    List<JuzSummary> summaries = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QuickNavigationSheet(
        currentPage: currentPage,
        summaries: summaries,
        lastPage: lastPage,
        onGoToPage: onGoToPage,
      ),
    );
  }

  @override
  State<QuickNavigationSheet> createState() => _QuickNavigationSheetState();
}

class _QuickNavigationSheetState extends State<QuickNavigationSheet> {
  late final TextEditingController _pageCtrl;
  late final TextEditingController _surahFilterCtrl;
  late double _sliderValue;
  String _surahQuery = '';

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.currentPage.toDouble();
    _pageCtrl = TextEditingController(text: '${widget.currentPage}');
    _surahFilterCtrl = TextEditingController();
    _surahFilterCtrl.addListener(() {
      if (mounted) setState(() => _surahQuery = _surahFilterCtrl.text);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _surahFilterCtrl.dispose();
    super.dispose();
  }

  void _go(int page) {
    final target = page.clamp(1, 604);
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    widget.onGoToPage(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final hint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  context.l10n.quickNavTitle,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      if (widget.lastPage != null &&
                          widget.lastPage != widget.currentPage)
                        _LastReadTile(
                          page: widget.lastPage!,
                          primary: primary,
                          onTap: () => _go(widget.lastPage!),
                        ),
                      _SectionTitle(
                        label:
                            '${context.l10n.page} ${widget.currentPage} / 604',
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _pageCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: context.l10n.quickNavPageHint,
                                hintStyle: AppTypography.bodySmall.copyWith(
                                  color: hint,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm + 4,
                                ),
                              ),
                              onSubmitted: (value) {
                                final page = int.tryParse(value);
                                if (page != null) _go(page);
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          FilledButton(
                            onPressed: () {
                              final page = int.tryParse(_pageCtrl.text);
                              if (page != null) _go(page);
                            },
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(64, 48),
                            ),
                            child: Text(context.l10n.quickNavGo),
                          ),
                        ],
                      ),
                      Slider(
                        value: _sliderValue,
                        min: 1,
                        max: 604,
                        divisions: 603,
                        label: '${_sliderValue.round()}',
                        onChanged: (value) =>
                            setState(() => _sliderValue = value),
                        onChangeEnd: (value) => _go(value.round()),
                      ),
                      _SectionTitle(label: context.l10n.surahs),
                      TextField(
                        controller: _surahFilterCtrl,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchSurah,
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: hint,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SurahJumpList(
                        query: _surahQuery,
                        primary: primary,
                        onTap: (surah) => _go(surah.page),
                      ),
                      _SectionTitle(label: context.l10n.juz),
                      _JuzJumpGrid(
                        summaries: widget.summaries,
                        onTap: (summary) => _go(summary.startPage),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        label,
        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _LastReadTile extends StatelessWidget {
  const _LastReadTile({
    required this.page,
    required this.primary,
    required this.onTap,
  });

  final int page;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${context.l10n.continueReading} • ${context.l10n.page} $page',
                    style: AppTypography.labelLarge.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(context.forwardChevron, size: 18, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahJumpList extends StatelessWidget {
  const _SurahJumpList({
    required this.query,
    required this.primary,
    required this.onTap,
  });

  final String query;
  final Color primary;
  final ValueChanged<Surah> onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<QuranRepository>().getSurahs(),
      builder: (context, snapshot) {
        final result = snapshot.data?.fold((_) => null, (s) => s);
        if (result == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final q = ArabicNormalizer.normalize(query.trim());
        final visible = q.isEmpty
            ? result
            : result.where((surah) {
                if (surah.id.toString() == query.trim()) return true;
                if (ArabicNormalizer.normalize(surah.nameAr).contains(q)) {
                  return true;
                }
                return surah.nameEn.toLowerCase().contains(
                  query.trim().toLowerCase(),
                );
              }).toList();
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final surah = visible[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              leading: Text(
                '${surah.id}',
                style: AppTypography.labelMedium.copyWith(color: primary),
              ),
              title: Text(
                context.isArabic ? surah.nameAr : surah.nameEn,
                style: AppTypography.titleSmall,
              ),
              trailing: Text(
                '${context.l10n.page} ${surah.page}',
                style: AppTypography.labelSmall.copyWith(color: primary),
              ),
              onTap: () => onTap(surah),
            );
          },
        );
      },
    );
  }
}

class _JuzJumpGrid extends StatelessWidget {
  const _JuzJumpGrid({required this.summaries, required this.onTap});

  final List<JuzSummary> summaries;
  final ValueChanged<JuzSummary> onTap;

  @override
  Widget build(BuildContext context) {
    if (summaries.isNotEmpty) {
      return _Grid(list: summaries, onTap: onTap);
    }
    // Derive the same shared summaries from the real surah list.
    return FutureBuilder(
      future: getIt<QuranRepository>().getSurahs(),
      builder: (context, snapshot) {
        final surahs = snapshot.data?.fold((_) => null, (s) => s);
        if (surahs == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _Grid(
          list: JuzSummaries.fromSurahs(surahs),
          onTap: onTap,
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.list, required this.onTap});

  final List<JuzSummary> list;
  final ValueChanged<JuzSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        mainAxisExtent: 44,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final summary = list[index];
        return Material(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: () => onTap(summary),
            child: Center(
              child: Text(
                '${summary.juzNumber}',
                style: AppTypography.labelLarge.copyWith(
                  color: primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
