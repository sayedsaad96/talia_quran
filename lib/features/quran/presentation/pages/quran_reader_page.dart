import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      child: BlocBuilder<QuranPageCubit, QuranPageState>(
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
            // Start the background timer as soon as the page is loaded
            _startTimerForPage(state.detail, context);
            
            return _ContinuousPageText(detail: state.detail);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ContinuousPageText extends StatelessWidget {
  const _ContinuousPageText({required this.detail});
  final QuranPageDetail detail;

  void _showAyahOptions(BuildContext context, Ayah ayah) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AyahOptionsSheet(ayah: ayah),
    );
  }

  String _toArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final chars = number.toString().split('');
    return chars.map((c) => arabicDigits[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final textStyle = AppTypography.bodyLarge.copyWith(
      fontFamily: 'Amiri',
      fontSize: 26,
      height: 1.8,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );

    final spans = <InlineSpan>[];
    for (int i = 0; i < detail.ayahs.length; i++) {
        final ayah = detail.ayahs[i];
        
        // Show Bismillah if it's the first ayah of ANY Surah (except Tawbah - Surah 9)
        // Wait, for Fatihah (Surah 1) Bismillah is the first Ayah. For others it's not counted but printed.
        // If numberInSurah is 1 and it's not Surah 1 or 9, we usually print Bismillah before it.
        // I will add Surah Header if numberInSurah == 1
        if (ayah.numberInSurah == 1) {
            final surah = detail.surahs.firstWhere((s) => s.id == ayah.surahId);
            spans.add(
                WidgetSpan(
                    child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                            border: Border.all(color: primary.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                            child: Text(
                                "\u0633\u0648\u0631\u0629 ${surah.nameAr}",
                                style: AppTypography.surahTitle.copyWith(color: primary, fontSize: 24),
                            ),
                        ),
                    ),
                ),
            );
            if (ayah.surahId != 1 && ayah.surahId != 9) {
                spans.add(
                    WidgetSpan(
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                    "بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ",
                                    style: textStyle.copyWith(fontSize: 20),
                                ),
                            ),
                        ),
                    ),
                );
            }
        }

        spans.add(
            TextSpan(
              text: ayah.text,
              style: textStyle,
              recognizer: TapGestureRecognizer()..onTap = () => _showAyahOptions(context, ayah),
            ),
        );
        spans.add(
            TextSpan(
              text: ' ﴿${_toArabicNumber(ayah.numberInSurah)}﴾ ',
              style: textStyle.copyWith(
                color: primary,
                fontSize: textStyle.fontSize! * 0.9,
              ),
              recognizer: TapGestureRecognizer()..onTap = () => _showAyahOptions(context, ayah),
            ),
        );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        children: [
            // Page Header (Juz, Surah)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                  Text(
                    '${context.l10n.juz} ${detail.ayahs.first.juz}',
                    style: AppTypography.labelLarge.copyWith(color: primary, fontFamily: 'Amiri'),
                  ),
                  Text(
                    detail.surahs.firstWhere((s) => s.id == detail.ayahs.first.surahId).nameAr,
                    style: AppTypography.labelLarge.copyWith(color: primary, fontFamily: 'Amiri'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text.rich(
                    TextSpan(children: spans),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
            ),
            // Page Footer (Page Number)
            const SizedBox(height: 8),
            Text(
              '${detail.pageNumber}',
              style: AppTypography.labelMedium.copyWith(color: isDark ? Colors.white54 : Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _AyahOptionsSheet extends StatelessWidget {
  const _AyahOptionsSheet({required this.ayah});
  final Ayah ayah;

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
              '${context.l10n.ayahs} ${ayah.numberInSurah}',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OptionBtn(
                  icon: Icons.play_circle_fill_rounded,
                  label: context.l10n.play,
                  color: primary,
                  onTap: () {
                    // Play logic would go here
                    Navigator.pop(context);
                  },
                ),
                _OptionBtn(
                  icon: Icons.copy_rounded,
                  label: context.l10n.copy,
                  color: Colors.blue,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: ayah.text));
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
                    // We need surahName. For now we use generic string or get it if possible.
                    getIt<BookmarkService>().toggle(
                      BookmarkEntry(
                        surahId: ayah.surahId,
                        surahName: "سورة",
                        ayahNumber: ayah.numberInSurah,
                        ayahText: ayah.text,
                        savedAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(context);
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
