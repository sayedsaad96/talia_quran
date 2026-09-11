import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/quran_continuous_player_service.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/quran_audio_player_cubit.dart';
import '../cubits/surah_list_cubit.dart';
import '../../domain/entities/juz_summary.dart';
import '../../domain/entities/quran_entities.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/juz_grid_view.dart';
import '../widgets/reciter_selector_sheet.dart';
import 'bookmarks_page.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SurahListCubit>()..loadSurahs(),
      child: const _QuranView(),
    );
  }
}

class _QuranView extends StatefulWidget {
  const _QuranView();
  @override
  State<_QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<_QuranView>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late TabController _tabCtrl;
  int _tabIndex = 0;
  String _query = '';

  /// Surah revelation-type filter for the Surahs tab only. Null means all.
  /// Kept as view-local display filtering — no Cubit change.
  String? _surahType;

  List<Surah>? _summarySource;
  List<JuzSummary>? _summaries;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabCtrl.removeListener(_onTabChanged);
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.index != _tabIndex) {
      setState(() => _tabIndex = _tabCtrl.index);
    }
  }

  /// Routes the search text to the active tab: Surahs tab filters through
  /// the Cubit, Juz/Bookmarks tabs filter locally in their views.
  void _onSearchChanged(String q) {
    if (q != _query) {
      setState(() => _query = q);
    }
    if (_tabIndex == 0 && mounted) {
      context.read<SurahListCubit>().search(q);
    }
  }

  /// Shared Juz metadata, memoized across rebuilds (same surah list
  /// reference → same summaries). Shared with the reader Quick Navigation.
  List<JuzSummary> _juzSummaries(List<Surah> surahs) {
    if (!identical(_summarySource, surahs) || _summaries == null) {
      _summarySource = surahs;
      _summaries = JuzSummaries.fromSurahs(surahs);
    }
    return _summaries!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          _buildAppBar(context, isDark),
        ],
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                0,
              ),
              child: ContinueReadingCard(),
            ),
            if (_tabIndex == 0) _buildTypeFilter(context, isDark),
            Expanded(
              child: BlocBuilder<SurahListCubit, SurahListState>(
                builder: (context, state) {
                  if (state is SurahListLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.pagePadding),
                      child: ShimmerList(itemCount: 10, height: 72),
                    );
                  }
                  if (state is SurahListError) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () =>
                          context.read<SurahListCubit>().loadSurahs(),
                    );
                  }
                  if (state is SurahListLoaded) {
                    return TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _SurahListView(
                          surahs: state.filtered,
                          typeFilter: _surahType,
                        ),
                        JuzGridView(
                          summaries: _juzSummaries(state.surahs),
                          query: _tabIndex == 1 ? _query : '',
                        ),
                        BookmarksTab(
                          query: _tabIndex == 2 ? _query : '',
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilter(BuildContext context, bool isDark) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final hint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final options = <String?>[
      null,
      'meccan',
      'medinan',
    ];
    String labelFor(String? type) {
      return switch (type) {
        'meccan' => context.l10n.meccan,
        'medinan' => context.l10n.medinan,
        _ => context.l10n.all,
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        0,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final type in options)
              ChoiceChip(
                label: Text(labelFor(type)),
                selected: _surahType == type,
                onSelected: (_) => setState(() => _surahType = type),
                selectedColor: primary.withValues(alpha: 0.14),
                backgroundColor: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                labelStyle: AppTypography.labelMedium.copyWith(
                  color: _surahType == type ? primary : hint,
                  fontWeight: _surahType == type
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                side: BorderSide(
                  color: _surahType == type
                      ? primary.withValues(alpha: 0.5)
                      : (isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider),
                ),
                showCheckmark: false,
              ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final bottomHeight = 96 + ((textScale - 1) * 32);

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.heroGradientDark
              : AppColors.heroGradientLight,
        ),
      ),
      title: Text(
        context.l10n.quran,
        style: AppTypography.displaySmall.copyWith(
          color: Colors.white,
          fontSize: 22,
        ),
      ),
      actions: [
        ValueListenableBuilder<QuranReciter>(
          valueListenable: reciterService.currentReciter,
          builder: (context, reciter, _) {
            final name = context.isArabic ? reciter.nameAr : reciter.nameEn;
            return Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: TextButton.icon(
                onPressed: () => ReciterSelectorSheet.show(context),
                icon: const Icon(Icons.record_voice_over_rounded, size: 18),
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  textStyle: AppTypography.labelMedium,
                ),
              ),
            );
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight),
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                ),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                ),
              ),
              TabBar(
                controller: _tabCtrl,
                labelColor: primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
                labelStyle: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                indicatorColor: primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2.5,
                tabs: [
                  Tab(text: context.l10n.surahs),
                  Tab(text: context.l10n.juz),
                  Tab(text: context.l10n.bookmark),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final hasTextNow = widget.controller.text.isNotEmpty;
    if (hasTextNow != _hasText) {
      setState(() => _hasText = hasTextNow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.searchSurah,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              size: 20,
            ),
            suffixIcon: _hasText
                ? IconButton(
                    tooltip: context.l10n.clearSearch,
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.darkTextHint
                          : AppColors.lightTextHint,
                      size: 18,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahListView extends StatelessWidget {
  const _SurahListView({required this.surahs, this.typeFilter});
  final List<Surah> surahs;

  /// View-local revelation-type filter ('meccan' | 'medinan' | null for all).
  final String? typeFilter;

  @override
  Widget build(BuildContext context) {
    final visible = typeFilter == null
        ? surahs
        : surahs
              .where(
                (s) => typeFilter == 'meccan' ? s.isMeccan : !s.isMeccan,
              )
              .toList();
    if (visible.isEmpty) {
      return EmptyStateWidget(
        message: context.l10n.noData,
        icon: Icons.search_off_rounded,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        120,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _SurahTile(surah: visible[i], index: i),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.index});
  final Surah surah;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push('/quran/surah/${surah.id}'),
        splashColor: primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: border, width: 0.6),
          ),
          child: Row(
            children: [
              // Circular Number Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: AppTypography.labelMedium.copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name and meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.isArabic ? surah.nameAr : surah.nameEn,
                      style: context.isArabic
                          ? AppTypography.surahTitle.copyWith(
                              color: primary,
                              fontSize: 22,
                              height: 1.2,
                            )
                          : AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: surah.isMeccan ? 'مكية' : 'مدنية',
                          isMeccan: surah.isMeccan,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${surah.ayahCount} ${context.l10n.ayahs}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Quick Play Surah Button
              BlocBuilder<QuranAudioPlayerCubit, QuranAudioPlayerState>(
                builder: (context, audioState) {
                  final isCurrentSurah =
                      audioState.scope == PlayScope.surah &&
                      audioState.currentSurahId == surah.id &&
                      audioState.hasActiveAudio;
                  final isPlaying = isCurrentSurah && audioState.isPlaying;
                  final isLoading = isCurrentSurah && audioState.isLoading;

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: IconButton(
                      icon: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: primary,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : (isCurrentSurah
                                        ? Icons.play_circle_fill_rounded
                                        : Icons.play_circle_outline_rounded),
                              size: 26,
                              color: isCurrentSurah
                                  ? primary
                                  : (isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary),
                            ),
                      tooltip: isPlaying
                          ? (context.isArabic ? 'إيقاف مؤقت' : 'Pause')
                          : (context.isArabic
                                ? 'استماع للسورة'
                                : 'Listen to Surah'),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        context.read<QuranAudioPlayerCubit>().playSurah(
                          surah.id,
                        );
                      },
                    ),
                  );
                },
              ),
              Icon(
                context.isArabic
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isMeccan,
    required this.isDark,
  });

  final String label;
  final bool isMeccan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chipColor = isMeccan
        ? (isDark ? AppColors.primaryLight : AppColors.primary)
        : (isDark ? AppColors.success : AppColors.primaryDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: chipColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
