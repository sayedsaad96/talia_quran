import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/gestures.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/bookmark_service.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/quran_page_cubit.dart';
import '../cubits/surah_detail_cubit.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// QuranReaderPage — Entry Point (unchanged architecture)
// ═══════════════════════════════════════════════════════════════════════════════

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key, this.surahId, this.pageNumber});
  final int? surahId;
  final int? pageNumber;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  PageController? _pageController;
  SurahDetailCubit? _surahDetailCubit;
  int? _currentPageNumber;

  int _normalizePageNumber(int pageNumber) => pageNumber.clamp(1, 604);

  @override
  void initState() {
    super.initState();
    if (widget.pageNumber != null) {
      _currentPageNumber = _normalizePageNumber(widget.pageNumber!);
      _pageController = PageController(initialPage: _currentPageNumber! - 1);
    } else if (widget.surahId != null) {
      _surahDetailCubit = getIt<SurahDetailCubit>()..loadSurah(widget.surahId!);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _surahDetailCubit?.close();
    super.dispose();
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
                setState(() {
                  _currentPageNumber = initialPage;
                  _pageController = PageController(
                    initialPage: initialPage - 1,
                  );
                });
              }
            },
            builder: (context, state) {
              if (state is SurahDetailLoading) {
                return const Center(child: CircularProgressIndicator());
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
                return _buildPageView(context);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    if (_pageController != null) return _buildPageView(context);
    return const SizedBox.shrink();
  }

  Widget _buildPageView(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 604,
            onPageChanged: (index) {
              setState(() => _currentPageNumber = index + 1);
            },
            itemBuilder: (context, index) {
              final pageNumber = index + 1;
              return _QuranPageViewer(
                pageNumber: pageNumber,
                isCurrentPage: _currentPageNumber == pageNumber,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _QuranPageViewer — Loads page data + read timer
// ═══════════════════════════════════════════════════════════════════════════════

class _QuranPageViewer extends StatefulWidget {
  const _QuranPageViewer({
    required this.pageNumber,
    required this.isCurrentPage,
  });
  final int pageNumber;
  final bool isCurrentPage;

  @override
  State<_QuranPageViewer> createState() => _QuranPageViewerState();
}

class _QuranPageViewerState extends State<_QuranPageViewer> {
  Timer? _readTimer;
  bool _readConfirmed = false;

  void _startReadTimer(QuranPageDetail detail, BuildContext context) {
    if (!widget.isCurrentPage || _readTimer != null || _readConfirmed) return;
    final totalChars = detail.ayahs.fold<int>(
      0,
      (sum, a) => sum + a.text.length,
    );
    final requiredSeconds = (totalChars / 20).ceil().clamp(5, 60);
    _readTimer = Timer(Duration(seconds: requiredSeconds), () {
      _readTimer = null;
      if (mounted &&
          context.mounted &&
          widget.isCurrentPage &&
          !_readConfirmed) {
        unawaited(
          context.read<QuranPageCubit>().confirmRead(widget.pageNumber),
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant _QuranPageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isCurrentPage && _readTimer != null) {
      _readTimer?.cancel();
      _readTimer = null;
    }
  }

  @override
  void dispose() {
    _readTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<QuranPageCubit>()..loadPage(widget.pageNumber),
      child: BlocConsumer<QuranPageCubit, QuranPageState>(
        listener: (context, state) {
          if (state is QuranPageLoaded) {
            if (state.isReadConfirmed) {
              _readConfirmed = true;
              _readTimer?.cancel();
              _readTimer = null;
            } else {
              _startReadTimer(state.detail, context);
            }

            if (state.readConfirmationError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.readConfirmationError!)),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is QuranPageLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is QuranPageError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<QuranPageCubit>().loadPage(widget.pageNumber),
            );
          }
          if (state is QuranPageLoaded) {
            _startReadTimer(state.detail, context);
            return _MushafPageContent(detail: state.detail);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MushafPageContent — Core Mushaf UI using QcfPage
// ═══════════════════════════════════════════════════════════════════════════════

class _MushafPageContent extends StatefulWidget {
  const _MushafPageContent({required this.detail});
  final QuranPageDetail detail;

  @override
  State<_MushafPageContent> createState() => _MushafPageContentState();
}

class _MushafPageContentState extends State<_MushafPageContent> {
  Timer? _tapTimer;
  final List<TapGestureRecognizer> _recognizers = [];

  QuranPageDetail get detail => widget.detail;

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _showAyahOptions(BuildContext context, Ayah ayah) {
    HapticFeedback.lightImpact();
    final surah = detail.surahs.cast<Surah>().firstWhere(
      (s) => s.id == ayah.surahId,
      orElse: () => detail.surahs.first,
    );
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AyahOptionsSheet(ayah: ayah, surahName: surah.nameAr),
    );
  }

  Future<void> _handleAyahTap(BuildContext context, Ayah ayah) async {
    if (_tapTimer?.isActive ?? false) {
      // Double tap → bookmark
      _tapTimer?.cancel();
      unawaited(HapticFeedback.mediumImpact());
      final surah = detail.surahs.cast<Surah>().firstWhere(
        (s) => s.id == ayah.surahId,
        orElse: () => detail.surahs.first,
      );
      await getIt<BookmarkService>().toggle(
        BookmarkEntry(
          surahId: ayah.surahId,
          surahName: surah.nameAr,
          ayahNumber: ayah.numberInSurah,
          ayahText: ayah.text,
          savedAt: DateTime.now(),
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.isArabic ? 'تم حفظ العلامة المرجعية' : 'Bookmark saved',
            ),
          ),
        );
      }
    } else {
      // Single tap → wait for possible double tap
      _tapTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) _showAyahOptions(context, ayah);
      });
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _disposeRecognizers();
    super.dispose();
  }

  // ── Quran Text Builder ────────────────────────────────────────────────────────

  static const _basmala = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  String _stripBasmala(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith(_basmala)) {
      return trimmed.substring(_basmala.length).trim();
    }
    final normalized = trimmed
        .replaceAll(RegExp(r'\p{M}', unicode: true), '')
        .replaceAll('ٱ', 'ا');
    if (normalized.startsWith('بسم الله الرحمن الرحيم')) {
      final parts = trimmed.split(' ');
      if (parts.length >= 4) {
        return parts.sublist(4).join(' ');
      }
    }
    return trimmed;
  }

  List<InlineSpan> _buildQuranSpans(
    Color gold,
    Color textColor,
    double baseFontSize,
    Color bg,
  ) {
    _disposeRecognizers();
    final spans = <InlineSpan>[];

    for (int i = 0; i < detail.ayahs.length; i++) {
      final ayah = detail.ayahs[i];

      // If it's the first ayah of a surah, add Surah Banner and Basmala
      if (ayah.numberInSurah == 1) {
        final surah = detail.surahs.cast<Surah>().firstWhere(
          (s) => s.id == ayah.surahId,
          orElse: () => detail.surahs.first,
        );

        // Add Surah Banner
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _SurahBannerWidget(surah: surah, gold: gold, bg: bg),
          ),
        );

        // Add Basmala if not Al-Fatihah or At-Tawbah
        if (ayah.surahId != 1 && ayah.surahId != 9) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Center(
                  child: Text(
                    'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: baseFontSize * 0.9,
                      color: gold,
                      height: 2.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }

      // Add the actual Ayah text
      String ayahText = ayah.text;

      if (ayah.numberInSurah == 1 && ayah.surahId != 1 && ayah.surahId != 9) {
        ayahText = _stripBasmala(ayahText);
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => _handleAyahTap(context, ayah);
      _recognizers.add(recognizer);

      spans.add(
        TextSpan(
          text: ayahText,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: baseFontSize,
            color: textColor,
            height: 2.2,
          ),
          recognizer: recognizer,
        ),
      );

      // Add Ayah Number
      final numRecognizer = TapGestureRecognizer()
        ..onTap = () => _handleAyahTap(context, ayah);
      _recognizers.add(numRecognizer);

      spans.add(
        TextSpan(
          text:
              ' \u06DD${MushafHizbHelper.toArabicNumber(ayah.numberInSurah)} ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: baseFontSize * 0.8,
            color: gold,
            height: 2.2,
          ),
          recognizer: numRecognizer,
        ),
      );
    }

    return spans;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final gold = isDark ? const Color(0xFFC8A55B) : const Color(0xFFB08930);
    final bg = isDark ? const Color(0xFF0D1117) : const Color(0xFFFDF5E6);
    final textColor = isDark
        ? const Color(0xFFF2EFE9)
        : const Color(0xFF1A1209);

    // Responsive font size based on screen width
    final sw = context.screenWidth;
    final baseFontSize = sw < 360
        ? 20.0
        : sw < 400
        ? 22.0
        : sw < 480
        ? 24.0
        : 28.0;

    final firstAyah = detail.ayahs.first;
    final firstSurah = detail.surahs.cast<Surah>().firstWhere(
      (s) => s.id == firstAyah.surahId,
      orElse: () => detail.surahs.first,
    );
    final juzNumber = firstAyah.juz ?? firstSurah.juz;
    final hizbNumber = MushafHizbHelper.getHizb(detail.pageNumber);

    return Container(
      color: bg,
      child: Column(
        children: [
          // ── Header Row ────────────────────────────────────────────────────────
          _MushafTopBar(
            surahName: firstSurah.nameAr,
            juzNumber: juzNumber,
            gold: gold,
            bg: bg,
            onClose: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),

          Divider(color: gold.withValues(alpha: 0.35), height: 1, thickness: 1),

          // ── Quran Text ────────────────────────────────────────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCenteredPage =
                    detail.pageNumber == 1 || detail.pageNumber == 2;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24, // subtract padding
                    ),
                    alignment: isCenteredPage
                        ? Alignment.center
                        : Alignment.topCenter,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: isCenteredPage
                          ? Alignment.center
                          : Alignment.topCenter,
                      child: SizedBox(
                        width: constraints.maxWidth > 600
                            ? 600
                            : constraints.maxWidth - 32,
                        child: Text.rich(
                          TextSpan(
                            children: _buildQuranSpans(
                              gold,
                              textColor,
                              baseFontSize,
                              bg,
                            ),
                          ),
                          textAlign: isCenteredPage
                              ? TextAlign.center
                              : TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(color: gold.withValues(alpha: 0.35), height: 1, thickness: 1),

          // ── Footer Row ────────────────────────────────────────────────────────
          _MushafFooter(
            pageNumber: detail.pageNumber,
            hizbNumber: hizbNumber,
            gold: gold,
            bg: bg,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MushafTopBar — Header: surah name | decorative icon | juz
// ═══════════════════════════════════════════════════════════════════════════════

class _MushafTopBar extends StatelessWidget {
  const _MushafTopBar({
    required this.surahName,
    required this.juzNumber,
    required this.gold,
    required this.bg,
    required this.onClose,
  });

  final String surahName;
  final int juzNumber;
  final Color gold;
  final Color bg;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ── Left: Juz info ────────────────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bookmark_outlined, color: gold, size: 16),
              const SizedBox(width: 4),
              Text(
                'الجزء ${MushafHizbHelper.getJuzName(juzNumber)}',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: gold,
                  height: 1.5,
                ),
              ),
            ],
          ),

          // ── Center: Decorative icon ───────────────────────────────────────
          Icon(Icons.grid_view_rounded, color: gold, size: 18),

          // ── Right: Surah name + close button ─────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                surahName,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: gold,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
              ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// _SurahBannerWidget — Decorative Surah title (used in customHeaderBuilder)
// ═══════════════════════════════════════════════════════════════════════════════

class _SurahBannerWidget extends StatelessWidget {
  const _SurahBannerWidget({
    required this.surah,
    required this.gold,
    required this.bg,
  });

  final Surah surah;
  final Color gold;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: gold, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: gold.withValues(alpha: 0.45), width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'سُورَةُ ${surah.nameAr}',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: gold,
                  height: 1.6,
                ),
              ),
              Text(
                '${surah.isMeccan ? 'مَكِّيَّة' : 'مَدَنِيَّة'}  •  ${MushafHizbHelper.toArabicNumber(surah.ayahCount)} آيَة',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  color: gold.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MushafFooter — Page number + Hizb info
// ═══════════════════════════════════════════════════════════════════════════════

class _MushafFooter extends StatelessWidget {
  const _MushafFooter({
    required this.pageNumber,
    required this.hizbNumber,
    required this.gold,
    required this.bg,
  });

  final int pageNumber;
  final int hizbNumber;
  final Color gold;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hizb info
          Text(
            'الحزب ${MushafHizbHelper.toArabicNumber(hizbNumber)}',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              color: gold,
              height: 1.5,
            ),
          ),

          // Center: Page number in decorative pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.1),
              border: Border.all(color: gold.withValues(alpha: 0.6), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              MushafHizbHelper.toArabicNumber(pageNumber),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: gold,
                height: 1.4,
              ),
            ),
          ),

          // Right: spacing mirror
          const SizedBox(width: 60),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _AyahOptionsSheet — Bottom sheet for ayah actions (play / copy / bookmark)
// ═══════════════════════════════════════════════════════════════════════════════

class _AyahOptionsSheet extends StatefulWidget {
  const _AyahOptionsSheet({required this.ayah, required this.surahName});
  final Ayah ayah;
  final String surahName;

  @override
  State<_AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<_AyahOptionsSheet> {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _playerSub;
  bool _isPlaying = false;

  @override
  void dispose() {
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAyah() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      setState(() => _isPlaying = true);
      final url = await AudioCacheService.instance.getAudioSource(
        widget.ayah.surahId,
        widget.ayah.numberInSurah,
      );
      await _player.setUrl(url);
      await _player.play();
      unawaited(_playerSub?.cancel() ?? Future.value());
      _playerSub = _player.playerStateStream.listen((ps) {
        if (ps.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

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
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Text(
                '${context.l10n.ayahs} ${widget.ayah.numberInSurah}',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OptionBtn(
                    icon: _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill_rounded,
                    label: _isPlaying
                        ? (context.isArabic ? 'إيقاف' : 'Pause')
                        : context.l10n.play,
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
                    color: Colors.orange,
                    onTap: () async {
                      await getIt<BookmarkService>().toggle(
                        BookmarkEntry(
                          surahId: widget.ayah.surahId,
                          surahName: widget.surahName,
                          ayahNumber: widget.ayah.numberInSurah,
                          ayahText: widget.ayah.text,
                          savedAt: DateTime.now(),
                        ),
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.isArabic
                                  ? 'تم حفظ العلامة المرجعية'
                                  : 'Bookmark saved',
                            ),
                          ),
                        );
                      }
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

// ═══════════════════════════════════════════════════════════════════════════════
// _OptionBtn — Action button used in _AyahOptionsSheet
// ═══════════════════════════════════════════════════════════════════════════════

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
