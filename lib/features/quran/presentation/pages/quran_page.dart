import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/services/quran_reciter.dart';
import '../../../../core/services/quran_reciter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/surah_list_cubit.dart';
import '../../domain/entities/quran_entities.dart';
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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
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
        body: BlocBuilder<SurahListCubit, SurahListState>(
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
                onRetry: () => context.read<SurahListCubit>().loadSurahs(),
              );
            }
            if (state is SurahListLoaded) {
              return TabBarView(
                controller: _tabCtrl,
                children: [
                  state.filtered.isEmpty
                      ? EmptyStateWidget(
                          message: context.l10n.noData,
                          icon: Icons.search_off_rounded,
                        )
                      : _SurahListView(surahs: state.filtered),
                  _JuzGridView(surahs: state.surahs),
                  const BookmarksTab(),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    final reciterService = getIt<QuranReciterService>();

    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      snap: false,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: Column(
                children: [
                  // Top Row: Reciter selector button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.quran,
                        style: AppTypography.displaySmall.copyWith(
                          color: Colors.white,
                          fontFamily: 'Amiri',
                          fontSize: 26,
                        ),
                      ),
                      ValueListenableBuilder<QuranReciter>(
                        valueListenable: reciterService.currentReciter,
                        builder: (context, reciter, _) {
                          return GestureDetector(
                            onTap: () => ReciterSelectorSheet.show(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.record_voice_over_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.isArabic ? reciter.nameAr : reciter.nameEn,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ).animate().fadeIn(duration: 200.ms),
                  const Spacer(),
                  // Stats pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatItem(label: context.isArabic ? 'سورة' : 'Surah', value: '114'),
                        const _StatDivider(),
                        _StatItem(label: context.isArabic ? 'آية' : 'Ayah', value: '6,236'),
                        const _StatDivider(),
                        _StatItem(label: context.isArabic ? 'جزء' : 'Juz', value: '30'),
                      ],
                    ),
                  ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(104),
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
                child: _SearchBar(controller: _searchCtrl),
              ),
              TabBar(
                controller: _tabCtrl,
                labelColor: primary,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextHint
                    : AppColors.lightTextHint,
                labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
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

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white24,
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

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
          onChanged: (q) => context.read<SurahListCubit>().search(q),
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
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                      size: 18,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      context.read<SurahListCubit>().search('');
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
  const _SurahListView({required this.surahs});
  final List<Surah> surahs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        120,
      ),
      itemCount: surahs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _SurahTile(surah: surahs[i], index: i),
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.02, end: 0);
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
        ? (isDark ? const Color(0xFFC8A55B) : const Color(0xFFB08930))
        : (isDark ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20));

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

class _JuzGridView extends StatelessWidget {
  const _JuzGridView({required this.surahs});
  final List<Surah> surahs;

  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102,
    121,
    142, 162, 182,
    201,
    222, 242, 262, 282, 302, 322, 342, 362, 382,
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        AppSpacing.pagePadding,
        120,
      ),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
      ),
      itemCount: 30,
      itemBuilder: (context, i) {
        final initialPage = _juzStartPages[i];

        return GestureDetector(
          onTap: () => context.push('/quran/page/$initialPage'),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: primary.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(AppSpacing.radiusLg),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.juz,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.localizedJuzName(i + 1),
                          style: AppTypography.titleMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms, delay: (i * 15).ms).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
