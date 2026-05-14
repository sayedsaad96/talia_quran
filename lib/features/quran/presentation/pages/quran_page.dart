import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/surah_list_cubit.dart';
import '../../domain/entities/quran_entities.dart';
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
              // ARCH-003 FIX: Always show TabBarView so Juz and Bookmarks tabs
              // remain accessible even when surah search returns no results.
              return TabBarView(
                controller: _tabCtrl,
                children: [
                  state.filtered.isEmpty
                      ? EmptyStateWidget(
                          message: context.l10n.noData,
                          icon: Icons.search_off_rounded,
                        )
                      : _SurahListView(surahs: state.filtered),
                  _JuzGridView(surahs: state.surahs), // Not affected by search
                  const BookmarksTab(), // Not affected by search
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

    return SliverAppBar(
      expandedHeight: 180,
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
                AppSpacing.xl,
                AppSpacing.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.quran,
                    style: AppTypography.displaySmall.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.03),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.totalSurahsAyahs(6236, 114),
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                  const SizedBox(height: AppSpacing.md),
                  _SearchBar(controller: _searchCtrl),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: primary,
            unselectedLabelColor: isDark
                ? AppColors.darkTextHint
                : AppColors.lightTextHint,
            labelStyle: AppTypography.labelLarge,
            indicatorColor: primary,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 2,
            tabs: [
              Tab(text: context.l10n.surahs),
              Tab(text: context.l10n.juz),
              Tab(text: context.l10n.bookmark),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: TextField(
          controller: controller,
          onChanged: (q) => context.read<SurahListCubit>().search(q),
          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          decoration: InputDecoration(
            hintText: context.l10n.searchSurah,
            hintStyle: AppTypography.bodyMedium.copyWith(color: Colors.white60),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Colors.white60,
              size: 20,
            ),
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
        120, // Bottom padding to prevent cutoff by nav bar
      ),
      itemCount: surahs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push('/quran/surah/${surah.id}'),
        splashColor: primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: AppTypography.labelMedium.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.isArabic ? surah.nameAr : surah.nameEn,
                      style: context.isArabic
                          ? AppTypography.surahTitle.copyWith(
                              color: primary,
                              fontSize: 20,
                            )
                          : AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Chip(
                          label: context.isArabic
                              ? surah.isMeccan
                                    ? context.l10n.meccan
                                    : context.l10n.medinan
                              : surah.isMeccan
                              ? context.l10n.meccan
                              : context.l10n.medinan,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${surah.ayahCount} ${context.l10n.ayahs}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextHint
                                : AppColors.lightTextHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.02, end: 0);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
      ),
    );
  }
}

class _JuzGridView extends StatelessWidget {
  const _JuzGridView({required this.surahs});
  final List<Surah> surahs;

  // BUG-004 FIX: Correct start pages verified from quran.json
  // Juz 7 was 122 → should be 121; Juz 11 was 202 → should be 201
  static const List<int> _juzStartPages = [
    1, 22, 42, 62, 82, 102,
    121, // Juz 7 ← was 122
    142, 162, 182,
    201, // Juz 11 ← was 202
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Changed to 2 columns for better text fitting
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2, // Rectangular card
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
                    color: primary.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
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
                                fontWeight: FontWeight.w700,
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
            )
            .animate()
            .fadeIn(duration: 200.ms, delay: (i * 20).ms)
            .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
      },
    );
  }
}
