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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_audio_player_cubit.dart';
import '../cubits/quran_page_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../services/quran_read_confirmation_gate.dart';
import '../../data/services/quran_warmup_service.dart';
import '../widgets/app_quran_page_view.dart';
import '../widgets/ayah_options_sheet.dart';
import '../widgets/long_press_hint_banner.dart';
import '../widgets/quick_navigation_sheet.dart';
import '../widgets/quran_page_font_guard.dart';
import '../widgets/reader_docked_audio_bar.dart';
import '../widgets/reader_footer.dart';
import '../widgets/reader_overflow_sheet.dart';
import '../widgets/reader_top_bar.dart';
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

  // ValueNotifiers prevent full-Scaffold rebuilds when only page number or
  // simple UI flags change. Only the specific ValueListenableBuilder widgets
  // that depend on them will rebuild.
  final _currentPageNotifier = ValueNotifier<int>(1);
  final _isFocusModeNotifier = ValueNotifier<bool>(false);
  final _showLongPressHintNotifier = ValueNotifier<bool>(false);
  final _showReadConfirmedNotifier = ValueNotifier<bool>(false);

  // Keep these for internal logic that doesn't need to trigger UI rebuild.
  int? _currentPageNumber;
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
    unawaited(getIt<BookmarkService>().ensureLoaded());
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
    _currentPageNotifier.dispose();
    _isFocusModeNotifier.dispose();
    _showLongPressHintNotifier.dispose();
    _showReadConfirmedNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _khatmahCubit?.refreshDate();
  }

  void _openAtPage(int pageNumber) {
    _currentPageNumber = pageNumber;
    _currentPageNotifier.value = pageNumber;
    if (_pageController == null) {
      _pageController = PageController(initialPage: pageNumber - 1);
    } else if (_pageController!.hasClients) {
      final currentPos = (_pageController!.page ?? 0).round() + 1;
      if ((currentPos - pageNumber).abs() == 1) {
        unawaited(
          _pageController!.animateToPage(
            pageNumber - 1,
            duration: const Duration(milliseconds: 300),
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
      _showLongPressHintNotifier.value = true;
    }
  }

  void _dismissLongPressHint() {
    unawaited(getIt<SharedPreferences>().setBool(_longPressHintKey, true));
    _showLongPressHintNotifier.value = false;
  }

  void _showReadConfirmed() {
    _readConfirmedFeedbackTimer?.cancel();
    _showReadConfirmedNotifier.value = true;
    _readConfirmedFeedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _showReadConfirmedNotifier.value = false;
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
        child: AyahOptionsSheet(
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

  /// Opens the Quick Navigation sheet. The last-read position is resolved
  /// from the same restorable location source as Continue Reading.
  void _openQuickNav(BuildContext context, int currentPage) {
    HapticFeedback.selectionClick();
    int? lastPage;
    try {
      lastPage = QuranWarmupService.parsePageFromLocation(
        getIt<AppSessionService>().getLastRestorableLocation(),
      );
    } catch (_) {
      lastPage = null;
    }
    QuickNavigationSheet.show(
      context,
      currentPage: _normalizePageNumber(currentPage),
      lastPage: lastPage,
      onGoToPage: (page) => _openAtPage(_normalizePageNumber(page)),
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
    // Primary guidance color (not gold): routine reader chrome uses primary
    // per DESIGN.md; gold stays reserved for achievement surfaces.
    final accent = isDark ? AppColors.primaryLight : AppColors.primary;

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

            // Audio highlights — isolated BlocBuilder so only the PageView
            // highlights list changes, not the full Scaffold.
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
                          color: accent.withValues(alpha: 0.24),
                        ),
                      ]
                    : _highlights;

                return Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: bg,
                  body: SafeArea(
                    child: Stack(
                      children: [
                        // ── Main Page View ─────────────────────────────────
                        ValueListenableBuilder<bool>(
                          valueListenable: _isFocusModeNotifier,
                          builder: (context, isFocusMode, _) {
                            return Listener(
                              behavior: HitTestBehavior.translucent,
                              onPointerDown: (_) => _registerPageInteraction(
                                pageNumber,
                                context,
                              ),
                              onPointerSignal: (_) => _registerPageInteraction(
                                pageNumber,
                                context,
                              ),
                              child: AppQuranPageView(
                                pageController: _pageController!,
                                highlights: currentHighlights,
                                isDarkMode: isDark,
                                isTajweed: true,
                                pageBackgroundColor: bg,
                                onPageChanged: (page) {
                                  HapticFeedback.selectionClick();
                                  // Only update notifier — no setState = no
                                  // Scaffold rebuild during page turn animation.
                                  _currentPageNumber = page;
                                  _currentPageNotifier.value = page;
                                  _saveCurrentPage(page);
                                  _registerPageInteraction(page, context);
                                  _loadPage(page);
                                  unawaited(
                                    qcf.QcfFontLoader.preloadPages(
                                      page,
                                      radius: 8,
                                    ),
                                  );
                                },
                                onLongPress: (
                                  surahNumber,
                                  verseNumber,
                                  details,
                                ) => _showAyahOptions(
                                  context,
                                  surahNumber,
                                  verseNumber,
                                  details,
                                ),
                                topBar: isFocusMode
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
                                          ReaderTopBar(
                                            surahName:
                                                firstSurah?.nameAr ?? '',
                                            juzNumber: juzNumber,
                                            pageNumber: pageNumber,
                                            primary: accent,
                                            bg: bg,
                                            onBack: () {
                                              if (context.canPop()) {
                                                context.pop();
                                              } else {
                                                context.go('/');
                                              }
                                            },
                                            onOpenMenu: () =>
                                                ReaderOverflowSheet.show(
                                              context,
                                              onEnterFocus: () {
                                                HapticFeedback
                                                    .selectionClick();
                                                _isFocusModeNotifier.value =
                                                    true;
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                bottomBar: ValueListenableBuilder<bool>(
                                  valueListenable: _showReadConfirmedNotifier,
                                  builder: (context, showReadConfirmed, _) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const ReaderDockedAudioBar(),
                                        if (!isFocusMode)
                                          ReaderFooter(
                                            pageNumber: pageNumber,
                                            hizbNumber:
                                                MushafHizbHelper.getHizb(
                                              pageNumber,
                                            ),
                                            accent: accent,
                                            bg: bg,
                                            showReadConfirmed:
                                                showReadConfirmed,
                                            onPageTap: () => _openQuickNav(
                                              context,
                                              pageNumber,
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),

                        // ── Focus mode exit button ─────────────────────────
                        ValueListenableBuilder<bool>(
                          valueListenable: _isFocusModeNotifier,
                          builder: (context, isFocusMode, _) {
                            if (!isFocusMode) return const SizedBox.shrink();
                            return PositionedDirectional(
                              top: 16,
                              end: 16,
                              child: IconButton(
                                tooltip: context.l10n.exitFocusMode,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  _isFocusModeNotifier.value = false;
                                },
                                icon: const Icon(
                                  Icons.fullscreen_exit_rounded,
                                ),
                                style: IconButton.styleFrom(
                                  foregroundColor: accent,
                                  backgroundColor: bg.withValues(alpha: 0.92),
                                  minimumSize: const Size(48, 48),
                                  side: BorderSide(
                                    color: accent.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // ── Long press hint banner ─────────────────────────
                        ValueListenableBuilder<bool>(
                          valueListenable: _showLongPressHintNotifier,
                          builder: (context, show, _) {
                            if (!show) return const SizedBox.shrink();
                            return PositionedDirectional(
                              top: 54,
                              start: AppSpacing.md,
                              end: AppSpacing.md,
                              child: LongPressHintBanner(
                                accent: accent,
                                bg: bg,
                                onDismiss: _dismissLongPressHint,
                              ),
                            );
                          },
                        ),
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
