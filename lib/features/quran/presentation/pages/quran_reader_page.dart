import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/quran_entities.dart';
import '../cubits/surah_detail_cubit.dart';
import '../cubits/quran_page_cubit.dart';
import '../../data/datasources/bookmark_service.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key, this.surahId, this.pageNumber});
  final int? surahId;
  final int? pageNumber;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  PageController? _pageController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.pageNumber != null) {
      _pageController = PageController(initialPage: widget.pageNumber! - 1);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized && widget.surahId != null) {
      return BlocProvider(
        create: (_) => getIt<SurahDetailCubit>()..loadSurah(widget.surahId!),
        child: Scaffold(
          backgroundColor: context.isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: BlocConsumer<SurahDetailCubit, SurahDetailState>(
            listener: (context, state) {
              if (state is SurahDetailLoaded) {
                setState(() {
                  _pageController = PageController(initialPage: state.detail.surah.page - 1);
                  _isInitialized = true;
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
                  onRetry: () => context.read<SurahDetailCubit>().loadSurah(widget.surahId!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    // Wrap with Directionality to ensure swipe right-to-left
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            itemCount: 604,
            itemBuilder: (context, index) {
              return _QuranPageViewer(pageNumber: index + 1);
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}

class _QuranPageViewer extends StatefulWidget {
  const _QuranPageViewer({required this.pageNumber});
  final int pageNumber;

  @override
  State<_QuranPageViewer> createState() => _QuranPageViewerState();
}

class _QuranPageViewerState extends State<_QuranPageViewer> {
  Timer? _readTimer;
  bool _readConfirmed = false;

  void _startTimerForPage(QuranPageDetail detail, BuildContext context) {
    if (_readTimer != null || _readConfirmed) return;
    
    // Calculate reading time based on characters.
    // Average reading speed: ~20 characters per second for Arabic with Tajweed.
    final totalChars = detail.ayahs.fold<int>(0, (sum, ayah) => sum + ayah.text.length);
    
    // Calculate required seconds (e.g., 600 chars / 20 = 30 seconds)
    int requiredSeconds = (totalChars / 20).ceil();
    
    // Ensure minimum and maximum boundaries
    if (requiredSeconds < 5) requiredSeconds = 5; // minimum 5 seconds
    if (requiredSeconds > 60) requiredSeconds = 60; // cap at 60 seconds

    _readTimer = Timer(Duration(seconds: requiredSeconds), () {
      if (mounted && !_readConfirmed) {
        setState(() => _readConfirmed = true);
        context.read<QuranPageCubit>().confirmRead(widget.pageNumber);
      }
    });
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
        // ARCH-008: Use listener to start timer instead of build()
        listener: (context, state) {
          if (state is QuranPageLoaded) {
            _startTimerForPage(state.detail, context);
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
            return _ContinuousPageText(detail: state.detail);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ContinuousPageText extends StatefulWidget {
  const _ContinuousPageText({required this.detail});
  final QuranPageDetail detail;

  @override
  State<_ContinuousPageText> createState() => _ContinuousPageTextState();
}

class _ContinuousPageTextState extends State<_ContinuousPageText> {
  Timer? _tapTimer;


  void _showAyahOptions(BuildContext context, Ayah ayah) {
    HapticFeedback.lightImpact();
    // Get the real surah name from the detail's surahs list
    final surah = widget.detail.surahs.firstWhere(
      (s) => s.id == ayah.surahId,
      orElse: () => widget.detail.surahs.first,
    );
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AyahOptionsSheet(ayah: ayah, surahName: surah.nameAr),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final chars = number.toString().split('');
    return chars.map((c) => arabicDigits[int.parse(c)]).join();
  }

  void _handleAyahTap(BuildContext context, Ayah ayah) {
    if (_tapTimer?.isActive ?? false) {
      // Double tap detected
      _tapTimer?.cancel();
      HapticFeedback.mediumImpact();
      
      final surah = widget.detail.surahs.firstWhere(
        (s) => s.id == ayah.surahId,
        orElse: () => widget.detail.surahs.first,
      );
      
      getIt<BookmarkService>().toggle(
        BookmarkEntry(
          surahId: ayah.surahId,
          surahName: surah.nameAr,
          ayahNumber: ayah.numberInSurah,
          ayahText: ayah.text,
          savedAt: DateTime.now(),
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.isArabic ? 'تم حفظ العلامة المرجعية' : 'Bookmark saved')),
      );
    } else {
      // Single tap, wait to see if it becomes a double tap
      _tapTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _showAyahOptions(context, ayah);
        }
      });
    }
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final isDark = context.isDark;
    
    // Mushaf specific colors
    final mushafGold = isDark ? const Color(0xFFC8A55B) : const Color(0xFFB08930);
    final mushafBg = isDark ? const Color(0xFF000000) : const Color(0xFFFDFBF7);
    final textColor = isDark ? const Color(0xFFF4F4F4) : const Color(0xFF222222);

    final textStyle = AppTypography.bodyLarge.copyWith(
      fontFamily: 'Amiri',
      fontSize: 24, // Slightly larger base size
      height: 1.85, 
      color: textColor,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          color: mushafBg,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              // Page Header (Juz, Surah, Grid Icon)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: mushafGold.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, color: mushafGold, size: 16),
                        ),
                      ),
                      Text(
                        detail.surahs.firstWhere((s) => s.id == detail.ayahs.first.surahId).nameAr,
                        style: TextStyle(color: mushafGold, fontFamily: 'Amiri', fontSize: 16),
                      ),
                    ],
                  ),
                  Icon(Icons.grid_view_rounded, color: mushafGold, size: 20),
                  Row(
                    children: [
                      Icon(Icons.bookmark_outline_rounded, color: mushafGold, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${context.l10n.juz} ${_toArabicNumber(detail.ayahs.first.juz ?? detail.surahs.firstWhere((s) => s.id == detail.ayahs.first.surahId).juz)}',
                        style: TextStyle(color: mushafGold, fontFamily: 'Amiri', fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Divider under header
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Divider(color: mushafGold.withValues(alpha: 0.3), height: 1, thickness: 1),
              ),
              
              // The actual page content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, boxConstraints) {
                    final contentWidth = boxConstraints.maxWidth; 
                    
                    final spans = <InlineSpan>[];
                    for (int i = 0; i < detail.ayahs.length; i++) {
                      final ayah = detail.ayahs[i];
                      
                      if (ayah.numberInSurah == 1) {
                        final surah = detail.surahs.firstWhere((s) => s.id == ayah.surahId);
                        spans.add(
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: SizedBox(
                              width: contentWidth,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 16),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  border: Border.all(color: mushafGold, width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: mushafGold.withValues(alpha: 0.5), width: 0.5),
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Center(
                                    child: Text(
                                      "\u0633\u0648\u0631\u0629 ${surah.nameAr}",
                                      style: TextStyle(color: mushafGold, fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                        if (ayah.surahId != 1 && ayah.surahId != 9) {
                          spans.add(
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: SizedBox(
                                width: contentWidth,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
                                      style: textStyle.copyWith(fontSize: 22, color: textColor),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      // Clean up ayah text (remove prepended Bismillah if it exists, since we already display it centered)
                      String ayahText = ayah.text;
                      if (ayah.numberInSurah == 1 && ayah.surahId != 1 && ayah.surahId != 9) {
                        final normalized = ayahText
                            .replaceAll(RegExp(r'\p{M}', unicode: true), '')
                            .replaceAll('ٱ', 'ا');
                        if (normalized.startsWith('بسم الله الرحمن الرحيم')) {
                          final parts = ayahText.split(' ');
                          if (parts.length >= 4) {
                            ayahText = parts.sublist(4).join(' ');
                          }
                        }
                      }

                      spans.add(
                        TextSpan(
                          text: ayahText,
                          style: textStyle,
                          recognizer: TapGestureRecognizer()..onTap = () => _handleAyahTap(context, ayah),
                        ),
                      );
                      spans.add(
                        TextSpan(
                          text: ' ﴿${_toArabicNumber(ayah.numberInSurah)}﴾ ',
                          style: textStyle.copyWith(
                            color: mushafGold,
                            fontSize: textStyle.fontSize! * 0.85,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () => _handleAyahTap(context, ayah),
                        ),
                      );
                    }

                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: contentWidth,
                        ),
                        child: Text.rich(
                          TextSpan(children: spans),
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );
                  }
                ),
              ),
              
              // Page Footer (Page Number)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: mushafGold.withValues(alpha: 0.1),
                        border: Border.all(color: mushafGold, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _toArabicNumber(detail.pageNumber),
                        style: TextStyle(color: mushafGold, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _AyahOptionsSheet extends StatefulWidget {
  const _AyahOptionsSheet({required this.ayah, required this.surahName});
  final Ayah ayah;
  final String surahName;

  @override
  State<_AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends State<_AyahOptionsSheet> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
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
      final audioSource = await AudioCacheService.instance.getAudioSource(
        widget.ayah.surahId,
        widget.ayah.numberInSurah,
      );
      await _player.setUrl(audioSource);
      await _player.play();
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
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
                  icon: _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill_rounded,
                  label: _isPlaying ? (context.isArabic ? 'إيقاف' : 'Pause') : context.l10n.play,
                  color: primary,
                  onTap: _playAyah,
                ),
                _OptionBtn(
                  icon: Icons.copy_rounded,
                  label: context.l10n.copy,
                  color: Colors.blue,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: widget.ayah.text));
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
                  onTap: () {
                    getIt<BookmarkService>().toggle(
                      BookmarkEntry(
                        surahId: widget.ayah.surahId,
                        surahName: widget.surahName,
                        ayahNumber: widget.ayah.numberInSurah,
                        ayahText: widget.ayah.text,
                        savedAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.isArabic ? 'تم حفظ العلامة المرجعية' : 'Bookmark saved')),
                    );
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
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
