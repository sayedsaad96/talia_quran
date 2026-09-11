import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/azkar_preferences_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../cubits/azkar_cubit.dart';
import '../widgets/font_scale_selector_sheet.dart';

class GeneralAzkarPage extends StatelessWidget {
  const GeneralAzkarPage({
    super.key,
    this.category = AzkarCategory.general,
    this.prefsStore,
  });

  final AzkarCategory category;
  final AzkarPreferencesStore? prefsStore;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AzkarCubit>()..load(category),
      child: _GeneralAzkarView(
        category: category,
        prefsStore: prefsStore,
      ),
    );
  }
}

class _GeneralAzkarView extends StatefulWidget {
  const _GeneralAzkarView({
    required this.category,
    this.prefsStore,
  });

  final AzkarCategory category;
  final AzkarPreferencesStore? prefsStore;

  @override
  State<_GeneralAzkarView> createState() => _GeneralAzkarViewState();
}

class _GeneralAzkarViewState extends State<_GeneralAzkarView> {
  static const String _favoritesTabKey = '__favorites__';

  late final AzkarPreferencesStore _prefsStore;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubcategory = '';

  @override
  void initState() {
    super.initState();
    _prefsStore = widget.prefsStore ??
        (getIt.isRegistered<AzkarPreferencesStore>()
            ? getIt<AzkarPreferencesStore>()
            : AzkarPreferencesStore());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: BlocBuilder<AzkarCubit, AzkarState>(
        builder: (context, state) {
          if (state is AzkarLoading) {
            return const Center(child: LoadingWidget());
          }
          if (state is AzkarError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () => context.read<AzkarCubit>().load(widget.category),
            );
          }
          if (state is AzkarLoaded) {
            return _buildContent(context, state, isDark);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AzkarLoaded state, bool isDark) {
    if (state.sessions.isEmpty) {
      return CustomScrollView(
        slivers: [
          _buildAppBar(context, isDark),
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateWidget(
              key: const ValueKey('azkar-content-under-review'),
              message: context.l10n.azkarContentUnderReview,
              icon: Icons.pending_actions_rounded,
            ),
          ),
        ],
      );
    }

    // Extract unique subcategories and normalize on-the-fly
    final uniqueSubcategories = state.sessions
        .map((s) {
          final sub = s.zikr.subcategory;
          return sub == 'أدعية قرآنية' ? 'أدعية من القرآن' : sub;
        })
        .where((sub) => sub.isNotEmpty)
        .toSet()
        .toList();

    final tabs = ['', _favoritesTabKey, ...uniqueSubcategories];

    // Filter sessions by tab and normalized search query
    final isFavoritesTab = _selectedSubcategory == _favoritesTabKey;
    final normalizedQuery = ArabicNormalizer.normalize(_searchQuery.trim());

    final filteredSessions = state.sessions.where((s) {
      if (isFavoritesTab) {
        if (!_prefsStore.isFavorite(s.zikr.id)) return false;
      } else if (_selectedSubcategory.isNotEmpty) {
        final rawSub = s.zikr.subcategory;
        final mappedSub =
            rawSub == 'أدعية قرآنية' ? 'أدعية من القرآن' : rawSub;
        if (mappedSub != _selectedSubcategory &&
            rawSub != _selectedSubcategory) {
          return false;
        }
      }

      if (normalizedQuery.isEmpty) return true;

      final textNorm = ArabicNormalizer.normalize(s.zikr.text);
      final refNorm = ArabicNormalizer.normalize(s.zikr.reference);
      final subNorm = ArabicNormalizer.normalize(s.zikr.subcategory);

      return textNorm.contains(normalizedQuery) ||
          refNorm.contains(normalizedQuery) ||
          subNorm.contains(normalizedQuery);
    }).toList();

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, isDark),
        SliverToBoxAdapter(child: _buildSearchBar(context, isDark)),
        SliverToBoxAdapter(child: _buildCategoriesFilter(tabs, isDark)),
        if (filteredSessions.isEmpty)
          _buildEmptyResults(isFavoritesTab, isDark)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final session = filteredSessions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ZikrCard(
                    zikr: session.zikr,
                    isDark: isDark,
                    prefsStore: _prefsStore,
                  ),
                );
              }, childCount: filteredSessions.length),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.xs,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'ابحث في الأدعية والأذكار...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  key: const ValueKey('search-suffix-clear'),
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesFilter(List<String> tabs, bool isDark) {
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final tab = tabs[i];
          final selected = _selectedSubcategory == tab;
          final isFavTab = tab == _favoritesTabKey;

          Widget labelWidget;
          if (tab.isEmpty) {
            labelWidget = Text(context.l10n.all);
          } else if (isFavTab) {
            labelWidget = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.goldLight : AppColors.goldDark),
                ),
                const SizedBox(width: 4),
                const Text('المفضلة'),
              ],
            );
          } else {
            labelWidget = Text(tab);
          }

          return ChoiceChip(
            label: labelWidget,
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _selectedSubcategory = tab),
            selectedColor: primary,
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            side: BorderSide(
              color: selected
                  ? primary
                  : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
            labelStyle: AppTypography.labelMedium.copyWith(
              color: selected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyResults(bool isFavoritesTab, bool isDark) {
    if (isFavoritesTab) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bookmark_border_rounded,
                  size: 56,
                  color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد أدعية في المفضلة',
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اضغط على علامة الإشارة المرجعية بجانب أي دعاء لحفظه هنا',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد نتائج مطابقة',
                style: AppTypography.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'لم نجد أي أدعية تطابق بحثك',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('clear-search-button'),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('مسح البحث'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    final isDuas = widget.category == AzkarCategory.duas;

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: const BackButtonIcon(),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
      ),
      actions: [
        IconButton(
          tooltip: context.l10n.fontSize,
          icon: const Icon(Icons.format_size_rounded),
          color: Colors.white,
          onPressed: () => FontScaleSelectorSheet.show(
            context,
            store: _prefsStore,
            isDark: isDark,
          ),
        ),
      ],
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
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primaryDark],
                  ),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isDuas ? context.l10n.duas : context.l10n.generalAzkar,
                    style: AppTypography.headlineLarge.copyWith(
                      color: Colors.white,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDuas
                        ? context.l10n.duasSubtitle
                        : context.l10n.generalAzkarSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
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

class _ZikrCard extends StatelessWidget {
  const _ZikrCard({
    required this.zikr,
    required this.isDark,
    required this.prefsStore,
  });

  final Zikr zikr;
  final bool isDark;
  final AzkarPreferencesStore prefsStore;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            top: -10,
            child: Icon(
              Icons.format_quote_rounded,
              size: 80,
              color: primary.withValues(alpha: 0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: ValueListenableBuilder<double>(
                  valueListenable: prefsStore.fontScaleListenable,
                  builder: (context, fontScale, _) {
                    return Text(
                      zikr.text,
                      style: AppTypography.azkarText.copyWith(
                        color: textPrimary,
                        fontSize: 22.0 * fontScale,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),
              Divider(color: border, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (zikr.reference.isNotEmpty)
                      Expanded(
                        child: Text(
                          zikr.reference,
                          style: AppTypography.labelMedium.copyWith(
                            color: textSecondary,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    ValueListenableBuilder<Set<String>>(
                      valueListenable: prefsStore.favoritesListenable,
                      builder: (context, favorites, _) {
                        final isFav = favorites.contains(zikr.id);
                        return IconButton(
                          key: ValueKey('bookmark-${zikr.id}'),
                          tooltip: isFav
                              ? 'إزالة من المفضلة'
                              : 'إضافة إلى المفضلة',
                          icon: Icon(
                            isFav
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isFav
                                ? (isDark
                                    ? AppColors.goldLight
                                    : AppColors.goldDark)
                                : textSecondary.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            prefsStore.toggleFavorite(zikr.id);
                          },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: context.l10n.copy,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: textSecondary.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: zikr.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.l10n.zikrCopied)),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: context.l10n.share,
                      icon: Icon(Icons.share_rounded, color: primary, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final data = SocialShareData.dua(
                          zikr: zikr,
                          isDua: false,
                        );
                        SocialShareSheet.show(context, data);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
