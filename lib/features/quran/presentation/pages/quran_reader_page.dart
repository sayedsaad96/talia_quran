import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/utils/quran_ayah_display_text.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/bookmark_entry.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_audio_player_cubit.dart';
import '../cubits/quran_page_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../services/quran_read_confirmation_gate.dart';
import '../widgets/app_quran_page_view.dart';
import '../widgets/quran_floating_audio_player.dart';
import '../widgets/quran_page_font_guard.dart';
import '../widgets/reciter_selector_sheet.dart';
import '../../../khatmah/domain/entities/khatmah_plan.dart';
import '../../../khatmah/domain/entities/khatmah_reading_result.dart';
import '../../../khatmah/presentation/cubits/khatmah_cubit.dart';
import '../../../khatmah/presentation/widgets/khatmah_reader_session_bar.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({
    super.key,
    this.surahId,
    this.pageNumber,
    this.readerMode = QuranReaderMode.free,
    this.khatmahCubit,
  });

  final int? surahId;
  final int? pageNumber;
  final QuranReaderMode readerMode;
  final KhatmahCubit? khatmahCubit;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _highlights = const <qcf.HighlightVerse>[];

  late final QuranPageCubit _quranPageCubit;
  KhatmahCubit? _khatmahCubit;
  PageController? _pageController;
  SurahDetailCubit? _surahDetailCubit;
  Timer? _readTimer;
  Timer? _readConfirmedFeedbackTimer;
  StreamSubscription<KhatmahState>? _khatmahSubscription;
  QuranPageDetail? _currentDetail;
  int? _currentPageNumber;
  bool _showLongPressHint = false;
  bool _showReadConfirmedFeedback = false;
  bool _isFocusMode = false;
  bool _hasNavigatedToCompletion = false;

  final QuranReadConfirmationGate _readConfirmationGate =
      QuranReadConfirmationGate();
  static const _longPressHintKey = 'quran_long_press_hint_seen';

  int _normalizePageNumber(int pageNumber) => pageNumber.clamp(1, 604);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quranPageCubit = getIt<QuranPageCubit>();

    if (widget.readerMode == QuranReaderMode.khatmah) {
      if (widget.khatmahCubit != null) {
        _khatmahCubit = widget.khatmahCubit;
      } else {
        try {
          if (getIt.isRegistered<KhatmahCubit>()) {
            _khatmahCubit = getIt<KhatmahCubit>()..load();
          }
        } catch (_) {}
      }
    }

    _khatmahCubit?.watchCalendar();
    _khatmahSubscription = _khatmahCubit?.stream.listen((state) {
      if (mounted) {
        _handleKhatmahState(context, state);
      }
    });

    if (widget.pageNumber != null) {
      final initialPage = _normalizePageNumber(widget.pageNumber!);
      _openAtPage(initialPage);
    } else if (widget.surahId != null) {
      _surahDetailCubit = getIt<SurahDetailCubit>()..loadSurah(widget.surahId!);
    }
    unawaited(_loadLongPressHintState());
  }

  @override
  void didUpdateWidget(QuranReaderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageNumber != null &&
        widget.pageNumber != oldWidget.pageNumber) {
      _openAtPage(_normalizePageNumber(widget.pageNumber!));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _khatmahCubit?.unwatchCalendar();
    _readTimer?.cancel();
    _readConfirmedFeedbackTimer?.cancel();
    _khatmahSubscription?.cancel();
    _pageController?.dispose();
    _surahDetailCubit?.close();
    _quranPageCubit.close();
    if (widget.khatmahCubit == null) {
      _khatmahCubit?.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _khatmahCubit?.refreshDate();
  }

  void _openAtPage(int pageNumber) {
    _currentPageNumber = pageNumber;
    if (_pageController == null) {
      _pageController = PageController(initialPage: pageNumber - 1);
    } else if (_pageController!.hasClients) {
      final currentPos = (_pageController!.page ?? 0).round() + 1;
      if ((currentPos - pageNumber).abs() == 1) {
        unawaited(
          _pageController!.animateToPage(
            pageNumber - 1,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _pageController!.jumpToPage(pageNumber - 1);
      }
    }
    _saveCurrentPage(pageNumber);
    _loadPage(pageNumber);
    // Lazy-load QCF fonts for the current page and nearby pages.
    unawaited(qcf.QcfFontLoader.preloadPages(pageNumber, radius: 8));
  }

  void _saveCurrentPage(int pageNumber) {
    if (widget.readerMode == QuranReaderMode.khatmah) return;
    unawaited(
      getIt<AppSessionService>().saveLocation(
        '/quran/page/${_normalizePageNumber(pageNumber)}',
      ),
    );
  }

  Future<void> _loadLongPressHintState() async {
    final seen = getIt<SharedPreferences>().getBool(_longPressHintKey) ?? false;
    if (!seen && mounted) {
      setState(() => _showLongPressHint = true);
    }
  }

  void _dismissLongPressHint() {
    unawaited(getIt<SharedPreferences>().setBool(_longPressHintKey, true));
    if (mounted) {
      setState(() => _showLongPressHint = false);
    }
  }

  void _showReadConfirmed() {
    _readConfirmedFeedbackTimer?.cancel();
    if (mounted) {
      setState(() => _showReadConfirmedFeedback = true);
    }
    _readConfirmedFeedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showReadConfirmedFeedback = false);
      }
    });
  }

  void _loadPage(int pageNumber) {
    _readTimer?.cancel();
    _readTimer = null;
    unawaited(_quranPageCubit.loadPage(pageNumber));
  }

  void _registerPageInteraction(int pageNumber, BuildContext context) {
    final normalizedPage = _normalizePageNumber(pageNumber);
    _readConfirmationGate.registerInteraction(normalizedPage);
    _confirmReadIfReady(normalizedPage, context);
  }

  void _confirmReadIfReady(int pageNumber, BuildContext context) {
    if (!mounted || !context.mounted || _currentPageNumber != pageNumber) {
      return;
    }
    if (!_readConfirmationGate.shouldConfirm(pageNumber)) {
      return;
    }
    _readConfirmationGate.markPending(pageNumber);
    unawaited(_confirmThenRecordKhatmah(pageNumber));
  }

  Future<void> _confirmThenRecordKhatmah(int pageNumber) async {
    final confirmed = await _quranPageCubit.confirmRead(pageNumber);
    if (!confirmed) return;
    if (widget.readerMode == QuranReaderMode.khatmah) {
      await _khatmahCubit?.recordDigitalPage(pageNumber);
    }
  }

  void _handleKhatmahState(BuildContext context, KhatmahState state) {
    if (state is KhatmahProgressFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.khatmahUnableToSaveKhatmahProgress),
          action: SnackBarAction(
            label: context.l10n.khatmahRetry,
            onPressed: () => _khatmahCubit?.retryLastProgress(),
          ),
        ),
      );
      return;
    }
    if (state is KhatmahCompleted && !_hasNavigatedToCompletion) {
      _hasNavigatedToCompletion = true;
      context.go(
        AppRoutes.khatmahCompletion,
        extra: KhatmahReadingResult(
          plan: state.plan,
          historyEntry: state.historyEntry,
          newlyCompletedPages: state.newlyCompletedPages,
        ),
      );
    }
  }

  void _startReadTimer(QuranPageDetail detail, BuildContext context) {
    final pageNumber = detail.pageNumber;
    if (_currentPageNumber != pageNumber ||
        _readConfirmationGate.hasConfirmed(pageNumber) ||
        _readTimer != null) {
      return;
    }

    final totalChars = detail.ayahs.fold<int>(
      0,
      (sum, ayah) => sum + ayah.text.length,
    );
    final requiredSeconds = (totalChars / 20).ceil().clamp(5, 60);

    _readTimer = Timer(Duration(seconds: requiredSeconds), () {
      _readTimer = null;
      if (!mounted || !context.mounted || _currentPageNumber != pageNumber) {
        return;
      }
      _readConfirmationGate.registerTimerElapsed(pageNumber);
      _confirmReadIfReady(pageNumber, context);
    });
  }

  Ayah _resolveAyah(int surahNumber, int verseNumber) {
    final detail = _currentDetail;
    if (detail != null) {
      for (final ayah in detail.ayahs) {
        if (ayah.surahId == surahNumber && ayah.numberInSurah == verseNumber) {
          return ayah;
        }
      }
    }

    return Ayah(
      number: 0,
      surahId: surahNumber,
      text: qcf.getVerse(surahNumber, verseNumber),
      numberInSurah: verseNumber,
      juz: qcf.getJuzNumber(surahNumber, verseNumber),
      page: qcf.getPageNumber(surahNumber, verseNumber),
    );
  }

  void _showAyahOptions(
    BuildContext context,
    int surahNumber,
    int verseNumber,
    LongPressStartDetails _,
  ) {
    HapticFeedback.lightImpact();
    if (_currentPageNumber != null) {
      _registerPageInteraction(_currentPageNumber!, context);
    }
    final ayah = _resolveAyah(surahNumber, verseNumber);
    final audioCubit = context.read<QuranAudioPlayerCubit>();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: audioCubit,
        child: _AyahOptionsSheet(
          ayah: ayah,
          surahName: qcf.getSurahNameArabic(surahNumber),
          onInteraction: () {
            if (_currentPageNumber != null) {
              _registerPageInteraction(_currentPageNumber!, context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.surahId != null && _surahDetailCubit != null) {
      return BlocProvider.value(
        value: _surahDetailCubit!,
        child: Scaffold(
          backgroundColor: context.isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: BlocConsumer<SurahDetailCubit, SurahDetailState>(
            listener: (context, state) {
              if (state is SurahDetailLoaded && _pageController == null) {
                final initialPage = _normalizePageNumber(
                  state.detail.surah.page,
                );
                setState(() => _openAtPage(initialPage));
              }
            },
            builder: (context, state) {
              if (state is SurahDetailLoading) {
                return QuranPageSkeletonLoader(isDark: context.isDark);
              }
              if (state is SurahDetailError) {
                return ErrorStateWidget(
                  message: state.message,
                  onRetry: () => context.read<SurahDetailCubit>().loadSurah(
                    widget.surahId!,
                  ),
                );
              }
              if (state is SurahDetailLoaded && _pageController != null) {
                return _buildMushafReader(context);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    if (_pageController != null) return _buildMushafReader(context);
    return const SizedBox.shrink();
  }

  Widget _buildMushafReader(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? AppColors.parchmentDark : AppColors.parchmentLight;
    final gold = isDark ? AppColors.primaryLight : AppColors.primary;

    final content = BlocProvider.value(
      value: _quranPageCubit,
      child: BlocListener<QuranAudioPlayerCubit, QuranAudioPlayerState>(
        listener: (context, audioState) {
          if (audioState.currentPageNumber != null &&
              audioState.hasActiveAudio &&
              audioState.currentPageNumber != _currentPageNumber) {
            _openAtPage(audioState.currentPageNumber!);
          }
        },
        child: BlocConsumer<QuranPageCubit, QuranPageState>(
          listener: (context, state) {
            if (state is QuranPageLoaded) {
              _currentDetail = state.detail;
              if (state.isReadConfirmed) {
                final isNewlyConfirmed = _readConfirmationGate.markConfirmed(
                  state.detail.pageNumber,
                );
                _readTimer?.cancel();
                _readTimer = null;
                if (isNewlyConfirmed) {
                  _showReadConfirmed();
                }
              } else {
                _startReadTimer(state.detail, context);
              }

              if (state.readConfirmationError != null) {
                _readConfirmationGate.clearPending(state.detail.pageNumber);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.readConfirmationError!)),
                );
              }
            }
          },
          builder: (context, state) {
            final detail = state is QuranPageLoaded
                ? state.detail
                : _currentDetail;
            if (detail == null && state is QuranPageLoading) {
              return QuranPageSkeletonLoader(isDark: context.isDark);
            }
            if (detail == null && state is QuranPageError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => _loadPage(_currentPageNumber ?? 1),
              );
            }

            final firstAyah = detail?.ayahs.firstOrNull;
            final firstSurah = firstAyah == null
                ? null
                : detail!.surahs
                          .where((surah) => surah.id == firstAyah.surahId)
                          .firstOrNull ??
                      detail.surahs.firstOrNull;
            final juzNumber = firstAyah?.juz ?? firstSurah?.juz ?? 1;
            final pageNumber = detail?.pageNumber ?? _currentPageNumber ?? 1;

            return BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
              builder: (context, audioState) {
                final isAudioActive =
                    audioState.hasActiveAudio &&
                    audioState.currentSurahId != null &&
                    audioState.currentAyahNumber != null &&
                    audioState.currentPageNumber != null;

                final currentHighlights = isAudioActive
                    ? [
                        qcf.HighlightVerse(
                          surah: audioState.currentSurahId!,
                          verseNumber: audioState.currentAyahNumber!,
                          page: audioState.currentPageNumber!,
                          color: gold.withValues(alpha: 0.24),
                        ),
                      ]
                    : _highlights;

                return Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: bg,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) =>
                              _registerPageInteraction(pageNumber, context),
                          onPointerSignal: (_) =>
                              _registerPageInteraction(pageNumber, context),
                          child: AppQuranPageView(
                            pageController: _pageController!,
                            highlights: currentHighlights,
                            isDarkMode: isDark,
                            isTajweed: true,
                            pageBackgroundColor: bg,
                            onPageChanged: (page) {
                              HapticFeedback.selectionClick();
                              setState(() => _currentPageNumber = page);
                              _saveCurrentPage(page);
                              _registerPageInteraction(page, context);
                              _loadPage(page);
                              // Lazy-load QCF fonts for nearby pages.
                              unawaited(
                                qcf.QcfFontLoader.preloadPages(page, radius: 8),
                              );
                            },
                            onLongPress: (surahNumber, verseNumber, details) =>
                                _showAyahOptions(
                                  context,
                                  surahNumber,
                                  verseNumber,
                                  details,
                                ),
                            topBar: _isFocusMode
                                ? null
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (widget.readerMode ==
                                          QuranReaderMode.khatmah)
                                        KhatmahReaderSessionBar(
                                          cubit: _khatmahCubit,
                                          currentPage: pageNumber,
                                        ),
                                      _MushafTopBar(
                                        surahName: firstSurah?.nameAr ?? '',
                                        juzNumber: juzNumber,
                                        pageNumber: pageNumber,
                                        gold: gold,
                                        bg: bg,
                                        onToggleFocus: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isFocusMode = true);
                                        },
                                        onClose: () {
                                          if (context.canPop()) {
                                            context.pop();
                                          } else {
                                            context.go('/');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                            bottomBar: _isFocusMode
                                ? null
                                : _MushafFooter(
                                    pageNumber: pageNumber,
                                    hizbNumber: MushafHizbHelper.getHizb(
                                      pageNumber,
                                    ),
                                    gold: gold,
                                    bg: bg,
                                    showReadConfirmed:
                                        _showReadConfirmedFeedback,
                                  ),
                          ),
                        ),
                        if (_isFocusMode)
                          PositionedDirectional(
                            top: 16,
                            end: 16,
                            child: IconButton(
                              tooltip: context.l10n.exitFocusMode,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() => _isFocusMode = false);
                              },
                              icon: const Icon(Icons.fullscreen_exit_rounded),
                              style: IconButton.styleFrom(
                                foregroundColor: gold,
                                backgroundColor: bg.withValues(alpha: 0.92),
                                minimumSize: const Size(48, 48),
                                side: BorderSide(
                                  color: gold.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ),
                        if (_showLongPressHint)
                          PositionedDirectional(
                            top: 54,
                            start: AppSpacing.md,
                            end: AppSpacing.md,
                            child: _LongPressHintBanner(
                              gold: gold,
                              bg: bg,
                              onDismiss: _dismissLongPressHint,
                            ),
                          ),
                        const QuranFloatingAudioPlayer(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    if (_khatmahCubit != null) {
      return BlocProvider.value(value: _khatmahCubit!, child: content);
    }
    return content;
  }
}

class _MushafTopBar extends StatelessWidget {
  const _MushafTopBar({
    required this.surahName,
    required this.juzNumber,
    required this.pageNumber,
    required this.gold,
    required this.bg,
    required this.onClose,
    this.onToggleFocus,
  });

  final String surahName;
  final int juzNumber;
  final int pageNumber;
  final Color gold;
  final Color bg;
  final VoidCallback onClose;
  final VoidCallback? onToggleFocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: BorderSide(color: gold.withValues(alpha: 0.15), width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_outlined, color: gold, size: 16),
              const SizedBox(width: 4),
              Text(
                'الجزء ${MushafHizbHelper.getJuzName(juzNumber)}',
                style: AppTypography.bodyMedium.copyWith(
                  fontFamily: 'Amiri',
                  color: gold,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                surahName,
                style: AppTypography.quranHeader.copyWith(
                  color: gold,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
                builder: (context, audioState) {
                  final isPlayingThisPage =
                      audioState.scope == PlayScope.page &&
                      audioState.currentPageNumber == pageNumber &&
                      audioState.hasActiveAudio;
                  final isPlaying = isPlayingThisPage && audioState.isPlaying;
                  final isLoading = isPlayingThisPage && audioState.isLoading;

                  return IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      context.read<QuranAudioPlayerCubit>().playPage(
                        pageNumber,
                      );
                    },
                    tooltip: isPlaying
                        ? (context.isArabic
                              ? 'إيقاف التلاوة'
                              : 'Pause Recitation')
                        : (context.isArabic ? 'تلاوة الصفحة' : 'Play Page'),
                    icon: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: gold,
                            ),
                          )
                        : Icon(
                            isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : (isPlayingThisPage
                                      ? Icons.play_circle_fill_rounded
                                      : Icons.play_circle_outline_rounded),
                          ),
                    color: gold,
                    style: IconButton.styleFrom(
                      backgroundColor: gold.withValues(
                        alpha: isPlayingThisPage ? 0.22 : 0.1,
                      ),
                      minimumSize: const Size(48, 48),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: () => ReciterSelectorSheet.show(context),
                tooltip: context.l10n.selectReciter,
                icon: const Icon(Icons.record_voice_over_rounded),
                color: gold,
                style: IconButton.styleFrom(
                  backgroundColor: gold.withValues(alpha: 0.1),
                  minimumSize: const Size(48, 48),
                ),
              ),
              if (onToggleFocus != null) ...[
                IconButton(
                  onPressed: onToggleFocus,
                  tooltip: context.l10n.enterFocusMode,
                  icon: const Icon(Icons.fullscreen_rounded),
                  color: gold,
                  style: IconButton.styleFrom(
                    backgroundColor: gold.withValues(alpha: 0.1),
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
              IconButton(
                onPressed: onClose,
                tooltip: context.l10n.closeReader,
                icon: const Icon(Icons.close_rounded),
                color: gold,
                style: IconButton.styleFrom(
                  backgroundColor: gold.withValues(alpha: 0.1),
                  minimumSize: const Size(48, 48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MushafFooter extends StatelessWidget {
  const _MushafFooter({
    required this.pageNumber,
    required this.hizbNumber,
    required this.gold,
    required this.bg,
    required this.showReadConfirmed,
  });

  final int pageNumber;
  final int hizbNumber;
  final Color gold;
  final Color bg;
  final bool showReadConfirmed;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              context.l10n.hizbNumberLabel(
                MushafHizbHelper.toArabicNumber(hizbNumber),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                fontFamily: 'Amiri',
                fontSize: 13,
                color: gold,
                height: 1.5,
              ),
            ),
          ),
          Semantics(
            label: '${context.l10n.page} $pageNumber',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.itemGap,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.1),
                border: Border.all(color: gold.withValues(alpha: 0.45)),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                MushafHizbHelper.toArabicNumber(pageNumber),
                style: AppTypography.titleMedium.copyWith(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  color: gold,
                  height: 1.4,
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: showReadConfirmed ? 1 : 0,
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: gold, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        context.l10n.readPageConfirmed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontFamily: 'Amiri',
                          color: gold,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LongPressHintBanner extends StatelessWidget {
  const _LongPressHintBanner({
    required this.gold,
    required this.bg,
    required this.onDismiss,
  });

  final Color gold;
  final Color bg;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      elevation: 4,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: gold.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.touch_app_rounded, color: gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.quranLongPressHint,
                style: AppTypography.bodySmall.copyWith(
                  fontFamily: 'Amiri',
                  color: gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close_rounded, color: gold, size: 18),
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.close,
            ),
          ],
        ),
      ),
    );
  }
}

class _AyahOptionsSheet extends StatefulWidget {
  const _AyahOptionsSheet({
    required this.ayah,
    required this.surahName,
    required this.onInteraction,
  });

  final Ayah ayah;
  final String surahName;
  final VoidCallback onInteraction;

  @override
  State<_AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<_AyahOptionsSheet> {
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

                      return _OptionBtn(
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
                  _OptionBtn(
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
                  _OptionBtn(
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
                      final wasBookmarked = bookmarkService.isBookmarked(
                        entry.surahId,
                        entry.ayahNumber,
                      );
                      await bookmarkService.toggle(entry);
                      if (!wasBookmarked) {
                        unawaited(HapticFeedback.mediumImpact());
                      }
                      if (context.mounted) {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        final message = wasBookmarked
                            ? context.l10n.bookmarkRemoved
                            : context.l10n.bookmarkAdded;
                        final undoLabel = context.l10n.undo;
                        navigator.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(message),
                            action: SnackBarAction(
                              label: undoLabel,
                              onPressed: () {
                                unawaited(bookmarkService.toggle(entry));
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _OptionBtn(
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

class _OptionBtn extends StatelessWidget {
  const _OptionBtn({
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
