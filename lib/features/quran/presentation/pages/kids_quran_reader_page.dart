import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/services/quran_page_order_policy.dart';
import '../../../memorization_plus/data/datasources/kids_reading_receipt_store.dart';
import '../../../memorization_plus/domain/services/kids_daily_missions.dart';
import '../../../memorization_plus/presentation/theme/kids_theme.dart';
import '../../../memorization_plus/presentation/widgets/kids_chunky_button.dart';
import '../../../memorization_plus/presentation/widgets/kids_loading_widget.dart';
import '../../../memorization_plus/presentation/widgets/kids_motion_scope.dart';
import '../../../memorization_plus/presentation/widgets/kids_talia_companion.dart';
import '../cubits/quran_audio_player_cubit.dart';
import '../cubits/quran_page_cubit.dart';
import '../widgets/app_quran_page_view.dart';
import '../widgets/quran_page_font_guard.dart';

import '../../../../core/utils/locale_number_formatter.dart';

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

/// True only when [state] holds the loaded detail of exactly [pageNumber].
@visibleForTesting
bool kidsReaderPageIsLoaded(QuranPageState state, int pageNumber) =>
    state is QuranPageLoaded && state.detail.pageNumber == pageNumber;

/// Guards a confirmation against a delayed detail from a previous page turn.
@visibleForTesting
bool kidsReaderCanConfirmPage(
  QuranPageState state, {
  required int currentPageNumber,
  required int pageNumber,
}) =>
    pageNumber == currentPageNumber &&
    kidsReaderPageIsLoaded(state, currentPageNumber);

/// Plan 2 — the child's explicit «قرأت هذه الصفحة» confirmation. Opening a
/// page or playing audio never confirms; only [confirm] does, and only when
/// both the reading log ([confirmRead]) and the day's receipt store accept it.
@visibleForTesting
class KidsReaderConfirmation extends ChangeNotifier {
  KidsReaderConfirmation({
    required Future<bool> Function(int pageNumber) confirmRead,
    required KidsReadingReceiptStore store,
    DateTime Function()? clock,
    this.toastDuration = const Duration(seconds: 2),
  }) : _confirmRead = confirmRead,
       _store = store,
       _clock = clock ?? DateTime.now;

  final Future<bool> Function(int pageNumber) _confirmRead;
  final KidsReadingReceiptStore _store;
  final DateTime Function() _clock;
  final Duration toastDuration;

  final Set<int> _confirmed = <int>{};
  final Set<int> _inFlight = <int>{};
  Timer? _toastTimer;
  bool _showToast = false;
  bool _disposed = false;

  /// True for [toastDuration] after a successful confirmation.
  bool get showToast => _showToast;

  bool isConfirmed(int pageNumber) => _confirmed.contains(pageNumber);

  /// Pages already confirmed today (e.g. before the app was reopened).
  Future<void> loadToday() async {
    try {
      final pages = await _store.pagesOn(kidsDayKey(_clock()));
      if (_disposed) return;
      _confirmed.addAll(pages);
      notifyListeners();
    } catch (error, stack) {
      TaliaLogger.w('Kids reader: could not load today pages', error, stack);
    }
  }

  Future<void> confirm(int pageNumber) async {
    if (_confirmed.contains(pageNumber) || !_inFlight.add(pageNumber)) return;
    try {
      if (!await _confirmRead(pageNumber)) return;
      await _store.recordPage(pageNumber);
      if (_disposed) return;
      _confirmed.add(pageNumber);
      _showToast = true;
      _toastTimer?.cancel();
      _toastTimer = Timer(toastDuration, () {
        _showToast = false;
        if (!_disposed) notifyListeners();
      });
      notifyListeners();
    } catch (error, stack) {
      TaliaLogger.e('Kids reader: page confirmation failed', error, stack);
    } finally {
      _inFlight.remove(pageNumber);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _toastTimer?.cancel();
    super.dispose();
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
  KidsReaderConfirmation? _confirmation;

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
    _pageController = PageController(
      initialPage: QuranPageOrderPolicy.kidsFatihahFirstReverse
          .indexForCanonicalPage(_currentPageNumber),
    );
    _quranPageCubit = getIt<QuranPageCubit>();
    unawaited(_quranPageCubit.loadPage(_currentPageNumber));
    // Lazy-load QCF fonts for the current page and nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(_currentPageNumber, radius: 8));
    // The receipt store backs the confirm button; without it the button stays
    // hidden rather than confirming something that is not recorded.
    if (getIt.isRegistered<KidsReadingReceiptStore>()) {
      _confirmation = KidsReaderConfirmation(
        confirmRead: (page) async {
          // The cubit is shared: never record a receipt for a page other than
          // the reader's current canonical page and loaded detail.
          final state = _quranPageCubit.state;
          if (!kidsReaderCanConfirmPage(
            state,
            currentPageNumber: _currentPageNumber,
            pageNumber: page,
          )) {
            return false;
          }
          return _quranPageCubit.confirmKidsRead(page);
        },
        store: getIt<KidsReadingReceiptStore>(),
      );
      unawaited(_confirmation!.loadToday());
    }
  }

  int _pageForSurah(int? surahId) {
    if (surahId == null || surahId < 1 || surahId > 114) return 1;
    return qcf.getPageNumber(surahId, 1);
  }

  @override
  void dispose() {
    unawaited(_audioController.stopIfStarted());
    _confirmation?.dispose();
    _pageController.dispose();
    _quranPageCubit.close();
    super.dispose();
  }

  void _loadPage(int pageNumber) {
    if (!mounted) return;
    setState(() => _currentPageNumber = _normalizePageNumber(pageNumber));
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
    return KidsMotionScope(
      child: BlocProvider.value(
        value: _quranPageCubit,
        child: BlocBuilder<QuranPageCubit, QuranPageState>(
          builder: (context, state) {
            if (state is QuranPageLoaded &&
                state.detail.pageNumber == _currentPageNumber) {
              _currentDetail = state.detail;
            }

            final detail = _currentDetail?.pageNumber == _currentPageNumber
                ? _currentDetail
                : null;
            if (_currentDetail == null && state is QuranPageLoading) {
              return Scaffold(
                body: QuranPageSkeletonLoader(isDark: context.isDark),
              );
            }
            if (_currentDetail == null && state is QuranPageError) {
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

            final pageNumber = _currentPageNumber;
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
                confirmation: kidsReaderPageIsLoaded(state, _currentPageNumber)
                    ? _confirmation
                    : null,
                isAudioPlaying: audio.isPlaying,
              ),
            );
          },
        ),
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
    this.confirmation,
    this.isAudioPlaying = false,
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

  /// Plan 2 — «قرأت هذه الصفحة» (null hides the button).
  final KidsReaderConfirmation? confirmation;

  /// Any recitation is playing: playback never earns the confirm button.
  final bool isAudioPlaying;

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
                    pageOrder: QuranPageOrderPolicy.kidsFatihahFirstReverse,
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
              confirmation: confirmation,
              isAudioPlaying: isAudioPlaying,
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
            icon: TaliaIcon(TaliaKidsIcons.arrowBack, color: accent),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TaliaIcon(TaliaKidsIcons.reading, color: accent, size: 18),
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

/// One compact control area under the Mushaf, so the page keeps most of the
/// screen: the long-press tip with the page number, then «قرأت هذه الصفحة»
/// and «استمع للصفحة» side by side.
class _KidsQuranFooter extends StatelessWidget {
  const _KidsQuranFooter({
    required this.pageNumber,
    required this.accent,
    required this.bg,
    this.isPagePlaying = false,
    this.onTogglePageAudio,
    this.confirmation,
    this.isAudioPlaying = false,
  });

  /// Shared by both buttons so the row stays one even height.
  static const double buttonHeight = 48;

  final int pageNumber;
  final Color accent;
  final Color bg;
  final bool isPagePlaying;
  final VoidCallback? onTogglePageAudio;
  final KidsReaderConfirmation? confirmation;
  final bool isAudioPlaying;

  @override
  Widget build(BuildContext context) {
    final confirmation = this.confirmation;
    if (confirmation == null) {
      return _layout(context, confirmSlot: null, showToast: false);
    }
    return ListenableBuilder(
      listenable: confirmation,
      builder: (context, _) {
        final confirmed = confirmation.isConfirmed(pageNumber);
        final showToast = confirmed && confirmation.showToast;
        final Widget? confirmSlot;
        if (confirmed) {
          // While Talia congratulates above, listening gets the whole row.
          confirmSlot = showToast ? null : _confirmedChip(context);
        } else if (isAudioPlaying) {
          // Playback never earns the confirm button.
          confirmSlot = null;
        } else {
          confirmSlot = KidsChunkyButton(
            key: const ValueKey('kids-reader-confirm-page'),
            label: context.l10n.kidsReaderConfirmPage,
            icon: TaliaKidsIcons.check,
            tone: KidsButtonTone.green,
            height: buttonHeight,
            compact: true,
            onPressed: () => unawaited(confirmation.confirm(pageNumber)),
          );
        }
        return _layout(context, confirmSlot: confirmSlot, showToast: showToast);
      },
    );
  }

  Widget _layout(
    BuildContext context, {
    required Widget? confirmSlot,
    required bool showToast,
  }) {
    final onToggle = onTogglePageAudio;
    final listen = onToggle == null
        ? null
        : KidsChunkyButton(
            key: const ValueKey('kids-quran-page-audio'),
            label: isPagePlaying
                ? context.l10n.kidsQuranPausePage
                : context.l10n.kidsQuranListenPage,
            icon: isPagePlaying ? TaliaKidsIcons.pause : TaliaKidsIcons.play,
            tone: KidsButtonTone.gold,
            height: buttonHeight,
            compact: true,
            onPressed: onToggle,
          );
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
          if (showToast)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Center(
                child: KidsTaliaCompanion(
                  pose: KidsTaliaPose.happy,
                  message: context.l10n.kidsReaderPageConfirmed,
                  animate: false,
                  height: 64,
                ),
              ),
            ),
          _hintRow(context),
          if (confirmSlot != null || listen != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (confirmSlot != null)
                  Expanded(child: Center(child: confirmSlot)),
                if (confirmSlot != null && listen != null)
                  const SizedBox(width: AppSpacing.sm),
                if (listen != null) Expanded(child: listen),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _hintRow(BuildContext context) {
    return Row(
      children: [
        // K26: the long press is the way to hear one ayah, so the tip stays
        // on screen instead of hiding in a first-run coach mark.
        TaliaIcon(TaliaKidsIcons.tap, color: accent, size: 16),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            context.l10n.kidsQuranLongPressHint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(color: accent),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            context.l10n.kidsQuranPageLabel(
              LocaleNumberFormatter.format(
                pageNumber.toString(),
                context.l10n.localeName,
              ),
            ),
            style: AppTypography.labelSmall.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _confirmedChip(BuildContext context) {
    return Container(
      key: const ValueKey('kids-reader-page-confirmed'),
      constraints: const BoxConstraints(minHeight: buttonHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TaliaIcon(TaliaKidsIcons.checkCircleFilled, color: accent, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              context.l10n.kidsReaderPageConfirmed,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
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
