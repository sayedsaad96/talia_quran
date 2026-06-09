import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/services/audio_cache_service.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/quran_entities.dart';
import '../../data/datasources/bookmark_service.dart';
import '../cubits/surah_detail_cubit.dart';

class SurahDetailPage extends StatelessWidget {
  const SurahDetailPage({super.key, required this.surahId});
  final int surahId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SurahDetailCubit>()..loadSurah(surahId),
      child: const _SurahDetailView(),
    );
  }
}

class _SurahDetailView extends StatefulWidget {
  const _SurahDetailView();
  @override
  State<_SurahDetailView> createState() => _SurahDetailViewState();
}

class _SurahDetailViewState extends State<_SurahDetailView> {
  final _player = AudioPlayer();
  final _bookmarkService = getIt<BookmarkService>();
  int? _playingAyah;
  bool _isPlaying = false;
  double _fontSize = 24.0;
  bool _focusMode = false;
  Set<String> _bookmarkedKeys = {};
  StreamSubscription<PlayerState>? _playerSubscription;

  static const _fontSizeKey = 'quran_font_size';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _loadFontSize();
  }

  void _loadFontSize() {
    final prefs = getIt<SharedPreferences>();
    _fontSize = prefs.getDouble(_fontSizeKey) ?? 24.0;
  }

  void _saveFontSize(double size) {
    getIt<SharedPreferences>().setDouble(_fontSizeKey, size);
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _loadBookmarks() {
    final keys = _bookmarkService.getAll().map((b) => b.key).toSet();
    setState(() => _bookmarkedKeys = keys);
  }

  Future<void> _toggleBookmark(Ayah ayah, String surahName) async {
    try {
      final key = '${ayah.surahId}_${ayah.numberInSurah}';
      // Capture the current state BEFORE the toggle to determine what it will become
      final wasBookmarked = _bookmarkedKeys.contains(key);

      await _bookmarkService.toggle(
        BookmarkEntry(
          surahId: ayah.surahId,
          surahName: surahName,
          ayahNumber: ayah.numberInSurah,
          ayahText: ayah.text,
          savedAt: DateTime.now(),
        ),
      );
      _loadBookmarks();
      if (mounted) {
        // isNowBookmarked is the opposite of what it was before the toggle
        final isNowBookmarked = !wasBookmarked;
        context.showSnackBar(
          isNowBookmarked
              ? context.l10n.bookmarkAdded
              : context.l10n.bookmarkRemoved,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bookmarkSaveError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Plays audio from either a URL or a local file path
  Future<void> _playAudioSource(AudioPlayer player, String source) async {
    try {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await player.setUrl(source);
      } else {
        await player.setFilePath(source);
      }
      await player.play();
    } catch (e, stack) {
      TaliaLogger.w('Audio playback failed', e, stack);
    }
  }

  Future<void> _playAyah(Ayah ayah) async {
    if (_playingAyah == ayah.numberInSurah && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }
    try {
      setState(() {
        _playingAyah = ayah.numberInSurah;
        _isPlaying = true;
      });
      final audioSource = await AudioCacheService.instance.getAudioSource(
        ayah.surahId,
        ayah.numberInSurah,
      );
      await _playAudioSource(_player, audioSource);
      // Cancel previous subscription before creating a new one
      await _playerSubscription?.cancel();
      _playerSubscription = _player.playerStateStream.listen((state) {
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
    final bg = isDark ? AppColors.parchmentDark : AppColors.parchmentLight;

    return Scaffold(
      backgroundColor: bg,
      body: BlocBuilder<SurahDetailCubit, SurahDetailState>(
        builder: (context, state) {
          if (state is SurahDetailLoading) {
            return const Center(child: LoadingWidget());
          }
          if (state is SurahDetailError) {
            return ErrorStateWidget(message: state.message);
          }
          if (state is SurahDetailLoaded) {
            return _buildContent(context, state.detail, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SurahDetail detail, bool isDark) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return CustomScrollView(
      slivers: [
        // ─── App Bar ─────────────────────────────────────────────────────────
        SliverAppBar(
          pinned: true,
          backgroundColor: isDark
              ? AppColors.parchmentDark
              : AppColors.parchmentLight,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              size: 20,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Column(
            children: [
              Text(
                context.isArabic ? detail.surah.nameAr : detail.surah.nameEn,
                style: context.isArabic
                    ? AppTypography.surahTitle.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 18,
                      )
                    : AppTypography.titleLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _focusMode
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                color: primary,
                size: 22,
              ),
              onPressed: () => setState(() => _focusMode = !_focusMode),
              tooltip: 'Focus mode',
            ),
            // Font size
            IconButton(
              icon: Icon(Icons.text_fields_rounded, color: primary, size: 22),
              onPressed: () => _showFontSizeSheet(context),
            ),
          ],
        ),

        // ─── Surah Header ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _SurahHeader(
            surah: detail.surah,
            isDark: isDark,
            primary: primary,
          ),
        ),

        // ─── Basmala ─────────────────────────────────────────────────────────
        if (detail.surah.id != 1 && detail.surah.id != 9)
          SliverToBoxAdapter(
            child: _BasmalaWidget(isDark: isDark, primary: primary),
          ),

        // ─── Ayahs ───────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            120,
          ),
          sliver: SliverToBoxAdapter(
            child: _ContinuousSurahText(
              ayahs: detail.ayahs,
              fontSize: _fontSize,
              playingAyah: _playingAyah,
              isDark: isDark,
              onAyahTapped: (ayah) {
                _showAyahActions(context, ayah, detail.surah.nameAr, isDark);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showAyahActions(
    BuildContext context,
    Ayah ayah,
    String surahName,
    bool isDark,
  ) {
    final bKey = '${ayah.surahId}_${ayah.numberInSurah}';
    final isBookmarked = _bookmarkedKeys.contains(bKey);
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                  ),
                  Text(
                    'آية رقم ${ayah.numberInSurah}',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    leading: Icon(
                      (_playingAyah == ayah.numberInSurah && _isPlaying)
                          ? Icons.pause_circle_rounded
                          : Icons.play_circle_rounded,
                      color: primary,
                    ),
                    title: Text(
                      (_playingAyah == ayah.numberInSurah && _isPlaying)
                          ? context.l10n.pause
                          : context.l10n.play,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    onTap: () {
                      ctx.pop();
                      _playAyah(ayah);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.copy_rounded, color: primary),
                    title: Text(
                      context.l10n.copy,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    onTap: () {
                      ctx.pop();
                      Clipboard.setData(ClipboardData(text: ayah.text));
                      context.showSnackBar(context.l10n.copied);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isBookmarked ? AppColors.gold : primary,
                    ),
                    title: Text(
                      isBookmarked
                          ? 'إزالة العلامة المرجعية'
                          : 'إضافة علامة مرجعية',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    onTap: () {
                      ctx.pop();
                      _toggleBookmark(ayah, surahName);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showFontSizeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (_) => _FontSizeSheet(
        current: _fontSize,
        onChanged: (v) {
          setState(() => _fontSize = v);
          _saveFontSize(v);
        },
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({
    required this.surah,
    required this.isDark,
    required this.primary,
  });

  final Surah surah;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.pagePadding),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: isDark
            ? AppColors.heroGradientDark
            : AppColors.heroGradientLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          Text(
            context.isArabic ? surah.nameAr : surah.nameEn,
            style: AppTypography.displayMedium.copyWith(
              fontFamily: context.isArabic ? 'Amiri' : null,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill(
                label: context.isArabic
                    ? surah.isMeccan
                          ? context.l10n.meccan
                          : context.l10n.medinan
                    : surah.isMeccan
                    ? context.l10n.meccan
                    : context.l10n.medinan,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(label: '${surah.ayahCount} ${context.l10n.ayahs}'),
              const SizedBox(width: AppSpacing.sm),
              _StatPill(label: '${context.l10n.juz} ${surah.juz}'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

class _BasmalaWidget extends StatelessWidget {
  const _BasmalaWidget({required this.isDark, required this.primary});
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.md,
      ),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: AppTypography.quranMedium.copyWith(
            color: primary,
            fontSize: 20,
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ContinuousSurahText extends StatefulWidget {
  const _ContinuousSurahText({
    required this.ayahs,
    required this.fontSize,
    required this.playingAyah,
    required this.isDark,
    required this.onAyahTapped,
  });

  final List<Ayah> ayahs;
  final double fontSize;
  final int? playingAyah;
  final bool isDark;
  final Function(Ayah) onAyahTapped;

  @override
  State<_ContinuousSurahText> createState() => _ContinuousSurahTextState();
}

class _ContinuousSurahTextState extends State<_ContinuousSurahText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  // Convert standard digits to Arabic numerals
  String _toArabicFixed(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(arabicNumbers[int.parse(str[i])]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Dispose old recognizers at the start of each build
    _disposeRecognizers();

    final textColor = widget.isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final primary = widget.isDark ? AppColors.primaryLight : AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: widget.ayahs.map((ayah) {
            final isPlaying = widget.playingAyah == ayah.numberInSurah;

            final recognizer = TapGestureRecognizer()
              ..onTap = () => widget.onAyahTapped(ayah);
            _recognizers.add(recognizer);

            return TextSpan(
              text: '${ayah.text} ﴿${_toArabicFixed(ayah.numberInSurah)}﴾ ',
              style: AppTypography.quranVerse.copyWith(
                fontSize: widget.fontSize,
                color: isPlaying ? primary : textColor,
                backgroundColor: isPlaying
                    ? primary.withValues(alpha: 0.15)
                    : null,
              ),
              recognizer: recognizer,
            );
          }).toList(),
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}

class _FontSizeSheet extends StatefulWidget {
  const _FontSizeSheet({required this.current, required this.onChanged});
  final double current;
  final ValueChanged<double> onChanged;

  @override
  State<_FontSizeSheet> createState() => _FontSizeSheetState();
}

class _FontSizeSheetState extends State<_FontSizeSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.fontSize,
              style: AppTypography.headlineSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: AppTypography.quranMedium.copyWith(
                fontSize: _value,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.lg),
            Slider(
              value: _value,
              min: 16,
              max: 36,
              divisions: 5,
              activeColor: primary,
              onChanged: (v) {
                setState(() => _value = v);
                widget.onChanged(v);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
