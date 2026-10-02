import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/quran_entities.dart';
import '../../../memorization_plus/presentation/theme/kids_theme.dart';
import '../../../memorization_plus/presentation/widgets/kids_loading_widget.dart';
import '../../../memorization_plus/presentation/widgets/kids_talia_companion.dart';
import '../cubits/quran_audio_player_cubit.dart';
import '../cubits/quran_page_cubit.dart';
import '../widgets/app_quran_page_view.dart';
import '../widgets/quran_page_font_guard.dart';

/// Page of [ayahNumber] in [surahId], or null when the ayah does not exist.
int? _pageOfAyah(int? surahId, int? ayahNumber) {
  if (surahId == null || surahId < 1 || surahId > 114) return null;
  if (ayahNumber == null || ayahNumber < 1) return null;
  try {
    return qcf.getPageNumber(surahId, ayahNumber);
  } catch (_) {
    return null;
  }
}

/// K26 — what the kids Mushaf marks: the ayah being recited while audio is
/// active, otherwise the child's mission ayah (so there is one highlight at
/// a time).
@visibleForTesting
List<qcf.HighlightVerse> kidsReaderHighlights({
  required QuranAudioPlayerState audio,
  int? missionSurahId,
  int? missionAyah,
  required Color color,
}) {
  if (audio.hasActiveAudio &&
      audio.currentSurahId != null &&
      audio.currentAyahNumber != null &&
      audio.currentPageNumber != null) {
    return [
      qcf.HighlightVerse(
        surah: audio.currentSurahId!,
        verseNumber: audio.currentAyahNumber!,
        page: audio.currentPageNumber!,
        color: color.withValues(alpha: 0.24),
      ),
    ];
  }
  final missionPage = _pageOfAyah(missionSurahId, missionAyah);
  if (missionPage == null) return const [];
  return [
    qcf.HighlightVerse(
      surah: missionSurahId!,
      verseNumber: missionAyah!,
      page: missionPage,
      color: color.withValues(alpha: 0.14),
    ),
  ];
}

/// K26 — the kids Mushaf's use of the shared Quran player: one ayah on a
/// long press, the page from the footer button, and a stop on leaving so a
/// recitation the reader started never runs on into a memorization session.
@visibleForTesting
class KidsReaderAudioController {
  KidsReaderAudioController(this._audio);

  final QuranAudioPlayerCubit _audio;
  bool _started = false;

  Future<void> playAyah(int surahId, int ayahNumber) {
    _started = true;
    return _audio.playAyah(surahId, ayahNumber);
  }

  /// Plays [pageNumber]; the player pauses or resumes it when it is the page
  /// already playing.
  Future<void> togglePage(int pageNumber) {
    _started = true;
    return _audio.playPage(pageNumber);
  }

  Future<void> stopIfStarted() async {
    if (!_started || !_audio.state.hasActiveAudio) return;
    await _audio.stop();
  }
}

class KidsQuranReaderPage extends StatefulWidget {
  const KidsQuranReaderPage({
    super.key,
    this.surahId,
    this.pageNumber,
    this.ayahNumber,
  });

  final int? surahId;
  final int? pageNumber;

  /// K26 — the mission ayah: the reader opens on its page and marks it.
  final int? ayahNumber;

  @override
  State<KidsQuranReaderPage> createState() => _KidsQuranReaderPageState();
}

class _KidsQuranReaderPageState extends State<KidsQuranReaderPage> {
  late final QuranPageCubit _quranPageCubit;
  late final PageController _pageController;
  late final QuranAudioPlayerCubit _audio;
  late final KidsReaderAudioController _audioController;
  late int _currentPageNumber;
  QuranPageDetail? _currentDetail;

  int _normalizePageNumber(int pageNumber) => pageNumber.clamp(1, 604);

  @override
  void initState() {
    super.initState();
    _audio = getIt<QuranAudioPlayerCubit>();
    _audioController = KidsReaderAudioController(_audio);
    final initialPage =
        widget.pageNumber ??
        _pageOfAyah(widget.surahId, widget.ayahNumber) ??
        _pageForSurah(widget.surahId);
    _currentPageNumber = _normalizePageNumber(initialPage);
    _pageController = PageController(initialPage: _currentPageNumber - 1);
    _quranPageCubit = getIt<QuranPageCubit>();
    unawaited(_quranPageCubit.loadPage(_currentPageNumber));
    // Lazy-load QCF fonts for the current page and nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(_currentPageNumber, radius: 8));
  }

  int _pageForSurah(int? surahId) {
    if (surahId == null || surahId < 1 || surahId > 114) return 604;
    return qcf.getPageNumber(surahId, 1);
  }

  @override
  void dispose() {
    unawaited(_audioController.stopIfStarted());
    _pageController.dispose();
    _quranPageCubit.close();
    super.dispose();
  }

  void _loadPage(int pageNumber) {
    _currentPageNumber = _normalizePageNumber(pageNumber);
    unawaited(_quranPageCubit.loadPage(_currentPageNumber));
    // Lazy-load QCF fonts for nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(_currentPageNumber, radius: 8));
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
            return Scaffold(
              body: QuranPageSkeletonLoader(isDark: context.isDark),
            );
          }
          if (detail == null && state is QuranPageError) {
            return Scaffold(
              // The kids reader keeps the dark night-sky look regardless of
              // the app brightness — keep the error screen on it too.
              backgroundColor: KidsTheme.nightSkyDark,
              body: KidsErrorWidget(
                onRetry: () => _loadPage(_currentPageNumber),
              ),
            );
          }

          final surahName = detail?.surahs.firstOrNull == null
              ? null
              : context.isArabic
              ? detail!.surahs.first.nameAr
              : detail!.surahs.first.nameEn;

          final pageNumber = detail?.pageNumber ?? _currentPageNumber;
          final accent = KidsQuranReaderContent.accentFor(context);
          return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
            bloc: _audio,
            builder: (context, audio) => KidsQuranReaderContent(
              pageController: _pageController,
              pageNumber: pageNumber,
              surahName: surahName,
              onBack: () => _goBackToKidsHome(context),
              onPageChanged: _loadPage,
              highlights: kidsReaderHighlights(
                audio: audio,
                missionSurahId: widget.surahId,
                missionAyah: widget.ayahNumber,
                color: accent,
              ),
              onAyahLongPress: (surahId, ayahNumber) =>
                  unawaited(_audioController.playAyah(surahId, ayahNumber)),
              isPagePlaying:
                  audio.isPlaying &&
                  audio.scope == PlayScope.page &&
                  audio.currentPageNumber == pageNumber,
              onTogglePageAudio: () =>
                  unawaited(_audioController.togglePage(pageNumber)),
            ),
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
    this.highlights = const [],
    this.onAyahLongPress,
    this.isPagePlaying = false,
    this.onTogglePageAudio,
  });

  final PageController? pageController;
  final int pageNumber;
  final String? surahName;
  final VoidCallback onBack;
  final ValueChanged<int>? onPageChanged;
  final Widget? reader;

  /// K26 — the mission ayah, or the ayah being recited.
  final List<qcf.HighlightVerse> highlights;

  /// K26 — a long press recites that ayah.
  final void Function(int surahId, int ayahNumber)? onAyahLongPress;

  /// K26 — this page is being recited; the footer button pauses it.
  final bool isPagePlaying;

  /// K26 — plays or pauses the page (null hides the button).
  final VoidCallback? onTogglePageAudio;

  /// Keeps the Quran surface calm and parchment-based, while using the same
  /// kids-path accent family for navigation, page metadata and highlights.
  static Color accentFor(BuildContext context) =>
      context.isDark ? KidsTheme.goldLight : KidsTheme.forestGreen;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? AppColors.parchmentDark : AppColors.parchmentLight;
    final accent = accentFor(context);

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
                  AppQuranPageView(
                    pageController: pageController!,
                    highlights: highlights,
                    isDarkMode: isDark,
                    isTajweed: true,
                    pageBackgroundColor: bg,
                    onPageChanged: onPageChanged,
                    onLongPress: onAyahLongPress == null
                        ? null
                        : (surahId, ayahNumber, _) =>
                              onAyahLongPress!(surahId, ayahNumber),
                  ),
            ),
            _KidsQuranFooter(
              pageNumber: pageNumber,
              accent: accent,
              bg: bg,
              isPagePlaying: isPagePlaying,
              onTogglePageAudio: onTogglePageAudio,
            ),
          ],
        ),
      ),
    );
  }
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
            // Mirrors itself under RTL: it points right in Arabic.
            icon: Icon(Icons.arrow_back_rounded, color: accent),
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
          // Static, decorative Talia (N2): never animates beside the Mushaf.
          Image.asset(
            KidsTaliaPose.readingQuran.asset,
            height: 40,
            excludeFromSemantics: true,
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
    this.isPagePlaying = false,
    this.onTogglePageAudio,
  });

  final int pageNumber;
  final Color accent;
  final Color bg;
  final bool isPagePlaying;
  final VoidCallback? onTogglePageAudio;

  @override
  Widget build(BuildContext context) {
    final onToggle = onTogglePageAudio;
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // K26: the long press is the way to hear one ayah, so the tip
              // stays on screen instead of hiding in a first-run coach mark.
              Icon(Icons.touch_app_rounded, color: accent, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.kidsQuranLongPressHint,
                  style: AppTypography.labelSmall.copyWith(color: accent),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
          if (onToggle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const ValueKey('kids-quran-page-audio'),
              onPressed: onToggle,
              icon: Icon(
                isPagePlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                isPagePlaying
                    ? context.l10n.kidsQuranPausePage
                    : context.l10n.kidsQuranListenPage,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: bg,
                minimumSize: const Size.fromHeight(52),
                shape: const RoundedRectangleBorder(
                  borderRadius: KidsTheme.buttonRadius,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
