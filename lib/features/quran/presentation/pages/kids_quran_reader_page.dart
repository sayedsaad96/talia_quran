import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_page_cubit.dart';

class KidsQuranReaderPage extends StatefulWidget {
  const KidsQuranReaderPage({super.key, this.surahId, this.pageNumber});

  final int? surahId;
  final int? pageNumber;

  @override
  State<KidsQuranReaderPage> createState() => _KidsQuranReaderPageState();
}

class _KidsQuranReaderPageState extends State<KidsQuranReaderPage> {
  late final QuranPageCubit _quranPageCubit;
  late final PageController _pageController;
  late int _currentPageNumber;
  QuranPageDetail? _currentDetail;

  int _normalizePageNumber(int pageNumber) => pageNumber.clamp(1, 604);

  @override
  void initState() {
    super.initState();
    final initialPage = widget.pageNumber ?? _pageForSurah(widget.surahId);
    _currentPageNumber = _normalizePageNumber(initialPage);
    _pageController = PageController(initialPage: _currentPageNumber - 1);
    _quranPageCubit = getIt<QuranPageCubit>();
    unawaited(_quranPageCubit.loadPage(_currentPageNumber));
    // Lazy-load QCF fonts for the current page and nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(_currentPageNumber, radius: 3));
  }

  int _pageForSurah(int? surahId) {
    if (surahId == null || surahId < 1 || surahId > 114) return 604;
    return qcf.getPageNumber(surahId, 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _quranPageCubit.close();
    super.dispose();
  }

  void _loadPage(int pageNumber) {
    _currentPageNumber = _normalizePageNumber(pageNumber);
    unawaited(_quranPageCubit.loadPage(_currentPageNumber));
    // Lazy-load QCF fonts for nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(_currentPageNumber, radius: 3));
  }

  void _goBackToKidsHome(BuildContext context) {
    final query = widget.surahId == null
        ? ''
        : '?${Uri(queryParameters: {'surahId': '${widget.surahId}'}).query}';
    context.go('${AppRoutes.memorizationPlusKidsHome}$query');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _quranPageCubit,
      child: BlocBuilder<QuranPageCubit, QuranPageState>(
        builder: (context, state) {
          if (state is QuranPageLoaded) {
            _currentDetail = state.detail;
          }

          final detail = state is QuranPageLoaded
              ? state.detail
              : _currentDetail;
          if (detail == null && state is QuranPageLoading) {
            return const Scaffold(body: Center(child: LoadingWidget()));
          }
          if (detail == null && state is QuranPageError) {
            return Scaffold(
              body: ErrorStateWidget(
                message: state.message,
                onRetry: () => _loadPage(_currentPageNumber),
              ),
            );
          }

          final surahName = detail?.surahs.firstOrNull == null
              ? null
              : context.isArabic
              ? detail!.surahs.first.nameAr
              : detail!.surahs.first.nameEn;

          return KidsQuranReaderContent(
            pageController: _pageController,
            pageNumber: detail?.pageNumber ?? _currentPageNumber,
            surahName: surahName,
            onBack: () => _goBackToKidsHome(context),
            onPageChanged: _loadPage,
          );
        },
      ),
    );
  }
}

@visibleForTesting
class KidsQuranReaderContent extends StatelessWidget {
  const KidsQuranReaderContent({
    super.key,
    required this.pageNumber,
    required this.onBack,
    this.pageController,
    this.surahName,
    this.onPageChanged,
    this.reader,
  });

  final PageController? pageController;
  final int pageNumber;
  final String? surahName;
  final VoidCallback onBack;
  final ValueChanged<int>? onPageChanged;
  final Widget? reader;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFFDF5E6);
    final accent = isDark ? KidsQuranColors.goldDark : KidsQuranColors.gold;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _KidsQuranHeader(
              title: context.l10n.kidsQuranTitle,
              subtitle: context.l10n.kidsQuranSubtitle,
              surahName: surahName,
              accent: accent,
              bg: bg,
              onBack: onBack,
            ),
            Expanded(
              child:
                  reader ??
                  qcf.QuranPageView(
                    pageController: pageController!,
                    highlights: const <qcf.HighlightVerse>[],
                    isDarkMode: isDark,
                    isTajweed: true,
                    pageBackgroundColor: bg,
                    onPageChanged: onPageChanged,
                  ),
            ),
            _KidsQuranFooter(pageNumber: pageNumber, accent: accent, bg: bg),
          ],
        ),
      ),
    );
  }
}

class KidsQuranColors {
  const KidsQuranColors._();

  static const gold = Color(0xFFB08930);
  static const goldDark = Color(0xFFC8A55B);
}

class _KidsQuranHeader extends StatelessWidget {
  const _KidsQuranHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.bg,
    required this.onBack,
    this.surahName,
  });

  final String title;
  final String subtitle;
  final String? surahName;
  final Color accent;
  final Color bg;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: context.l10n.kidsQuranBackToHome,
            icon: Icon(
              context.isArabic
                  ? Icons.arrow_forward_rounded
                  : Icons.arrow_back_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded, color: accent, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  surahName == null ? subtitle : '$surahName • $subtitle',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: accent.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsQuranFooter extends StatelessWidget {
  const _KidsQuranFooter({
    required this.pageNumber,
    required this.accent,
    required this.bg,
  });

  final int pageNumber;
  final Color accent;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.swipe_rounded, color: accent, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              context.l10n.kidsQuranSwipeHint,
              style: AppTypography.labelSmall.copyWith(color: accent),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              border: Border.all(color: accent.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              context.l10n.kidsQuranPageLabel(pageNumber),
              style: AppTypography.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
