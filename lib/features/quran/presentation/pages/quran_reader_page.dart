import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart' as qcf;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/app_session_service.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/services/audio_lifecycle_manager.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/bookmark_entry.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_page_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../services/quran_read_confirmation_gate.dart';
import '../widgets/app_quran_page_view.dart';
import '../widgets/quran_page_font_guard.dart';
import '../widgets/reciter_selector_sheet.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key, this.surahId, this.pageNumber});

  final int? surahId;
  final int? pageNumber;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _highlights = const <qcf.HighlightVerse>[];

  late final QuranPageCubit _quranPageCubit;
  PageController? _pageController;
  SurahDetailCubit? _surahDetailCubit;
  Timer? _readTimer;
  Timer? _readConfirmedFeedbackTimer;
  QuranPageDetail? _currentDetail;
  int? _currentPageNumber;
  bool _showLongPressHint = false;
  bool _showReadConfirmedFeedback = false;
  bool _isFocusMode = false;

  final QuranReadConfirmationGate _readConfirmationGate =
      QuranReadConfirmationGate();
  static const _longPressHintKey = 'quran_long_press_hint_seen';

  int _normalizePageNumber(int pageNumber) => pageNumber.clamp(1, 604);

  @override
  void initState() {
    super.initState();
    _quranPageCubit = getIt<QuranPageCubit>();

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
    if (widget.pageNumber != null && widget.pageNumber != oldWidget.pageNumber) {
      _openAtPage(_normalizePageNumber(widget.pageNumber!));
    }
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    _readConfirmedFeedbackTimer?.cancel();
    _pageController?.dispose();
    _surahDetailCubit?.close();
    _quranPageCubit.close();
    super.dispose();
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
    unawaited(qcf.QcfFontLoader.preloadPages(pageNumber, radius: 3));
  }


  void _saveCurrentPage(int pageNumber) {
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
    unawaited(context.read<QuranPageCubit>().confirmRead(pageNumber));
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
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AyahOptionsSheet(
        ayah: ayah,
        surahName: qcf.getSurahNameArabic(surahNumber),
        onInteraction: () {
          if (_currentPageNumber != null) {
            _registerPageInteraction(_currentPageNumber!, context);
          }
        },
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
    final gold = isDark ? AppColors.goldLight : AppColors.goldDark;

    return BlocProvider.value(
      value: _quranPageCubit,
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
                      highlights: _highlights,
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
                        unawaited(qcf.QcfFontLoader.preloadPages(page, radius: 3));
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
                          : _MushafTopBar(
                              surahName: firstSurah?.nameAr ?? '',
                              juzNumber: juzNumber,
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
                      bottomBar: _isFocusMode
                          ? null
                          : _MushafFooter(
                              pageNumber: pageNumber,
                              hizbNumber: MushafHizbHelper.getHizb(pageNumber),
                              gold: gold,
                              bg: bg,
                              showReadConfirmed: _showReadConfirmedFeedback,
                            ),
                    ),
                  ),
                  if (_isFocusMode)
                    PositionedDirectional(
                      top: 16,
                      end: 16,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isFocusMode = false);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: gold.withValues(alpha: 0.5)),
                          ),
                          child: Icon(Icons.fullscreen_exit_rounded, color: gold, size: 22),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MushafTopBar extends StatelessWidget {
  const _MushafTopBar({
    required this.surahName,
    required this.juzNumber,
    required this.gold,
    required this.bg,
    required this.onClose,
    this.onToggleFocus,
  });

  final String surahName;
  final int juzNumber;
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
          bottom: BorderSide(
            color: gold.withValues(alpha: 0.15),
            width: 0.8,
          ),
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
              GestureDetector(
                onTap: () => ReciterSelectorSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.record_voice_over_rounded, color: gold, size: 16),
                ),
              ),
              if (onToggleFocus != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onToggleFocus,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.fullscreen_rounded, color: gold, size: 16),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, color: gold, size: 15),
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
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'الحزب ${MushafHizbHelper.toArabicNumber(hizbNumber)}',
            style: AppTypography.bodySmall.copyWith(
              fontFamily: 'Amiri',
              fontSize: 13,
              color: gold,
              height: 1.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              border: Border.all(color: gold.withValues(alpha: 0.6), width: 1),
              borderRadius: BorderRadius.circular(20),
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
          AnimatedOpacity(
            opacity: showReadConfirmed ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  context.l10n.readPageConfirmed,
                  style: AppTypography.titleSmall.copyWith(
                    fontFamily: 'Amiri',
                    color: gold,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
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
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    AudioLifecycleManager.instance.register(_player);
  }

  @override
  void dispose() {
    AudioLifecycleManager.instance.unregister(_player);
    _playerSub?.cancel();
    unawaited(
      _player.dispose().catchError((Object error, StackTrace stack) {
        TaliaLogger.w('Ayah options player dispose failed', error, stack);
      }),
    );
    super.dispose();
  }

  Future<void> _playAyah() async {
    if (_isPlaying) {
      try {
        await _player.pause();
      } catch (error, stack) {
        TaliaLogger.w('Ayah audio pause failed', error, stack);
      }
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    try {
      widget.onInteraction();
      setState(() => _isPlaying = true);
      final reciter = getIt<QuranReciterService>().currentReciter.value;
      final source = await AudioCacheService.instance.getAudioSource(
        widget.ayah.surahId,
        widget.ayah.numberInSurah,
        reciter: reciter,
      );
      await AudioCacheService.playFromSource(_player, source);
      unawaited(_playerSub?.cancel() ?? Future.value());
      _playerSub = _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlaying = false);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.v2AudioPlaybackFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();

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
                'سورة ${widget.surahName} • الآية ${widget.ayah.numberInSurah}',
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
                  border: Border.all(
                    color: primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Text(
                  widget.ayah.text.trim(),
                  style: AppTypography.azkarText.copyWith(
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Reciter Selector Button
              ValueListenableBuilder<QuranReciter>(
                valueListenable: reciterService.currentReciter,
                builder: (context, reciter, _) {
                  return InkWell(
                    onTap: () => ReciterSelectorSheet.show(context),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic_rounded, size: 14, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            context.isArabic ? reciter.nameAr : reciter.nameEn,
                            style: AppTypography.bodySmall.copyWith(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.swap_horiz_rounded, size: 14, color: primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OptionBtn(
                    icon: _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill_rounded,
                    label: _isPlaying ? context.l10n.pause : context.l10n.play,
                    color: primary,
                    onTap: _playAyah,
                  ),
                  _OptionBtn(
                    icon: Icons.copy_rounded,
                    label: context.l10n.copy,
                    color: Colors.blue,
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.ayah.text),
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
                    color: AppColors.warning,
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
                    color: AppColors.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelMedium.copyWith(color: color)),
        ],
      ),
    );
  }
}
