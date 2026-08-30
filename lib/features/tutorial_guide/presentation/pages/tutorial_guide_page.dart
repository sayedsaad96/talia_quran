import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../tutorial_guide_mapper.dart';
import '../widgets/tutorial_guide_quick_start_card.dart';
import '../widgets/tutorial_guide_section_card.dart';

class TutorialGuidePage extends StatefulWidget {
  const TutorialGuidePage({super.key});

  @override
  State<TutorialGuidePage> createState() => _TutorialGuidePageState();
}

class _TutorialGuidePageState extends State<TutorialGuidePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  late final List<TutorialGuideSection> _allSections;
  late final List<String> _categories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _allSections = TutorialGuideMapper(context.l10n).mapAll();
    _categories = [
      context.l10n.all,
      ..._allSections.map((s) => s.category).toSet(),
    ];
  }

  List<TutorialGuideSection> get _filteredSections {
    final selected = _selectedCategory ?? context.l10n.all;
    return _allSections.where((section) {
      final categoryMatches =
          selected == context.l10n.all || section.category == selected;
      return categoryMatches && section.matches(_query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final sections = _filteredSections;

    return Directionality(
      textDirection: context.textDirection,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context, isDark),
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const TutorialGuideQuickStartCard(),
                  const SizedBox(height: AppSpacing.md),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CategoryChips(
                    categories: _categories,
                    selected: _selectedCategory ?? context.l10n.all,
                    onSelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (sections.isEmpty)
                    const _EmptyGuideSearch()
                  else
                    ...List.generate(sections.length, (index) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.sm,
                        ),
                        child: TutorialGuideSectionCard(
                          section: sections[index],
                          initiallyExpanded:
                              _query.trim().isNotEmpty && index == 0,
                        ),
                      );
                    }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    final titleText = context.l10n.tutorialGuideTitle;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        icon: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_forward_rounded
              : Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        title: Text(
          titleText,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: context.isArabic ? 'Amiri' : null,
            fontSize: 20,
          ),
        ),
        background: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.heroGradientDark
                      : AppColors.heroGradientLight,
                ),
              ),
            ),
            // Background ambient pattern
            Positioned(
              right: -30,
              top: -20,
              child: Icon(
                Icons.menu_book_rounded,
                size: 180,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            PositionedDirectional(
              start: AppSpacing.pagePadding,
              top: 74,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مركز المعرفة وشرح مزايا تالية',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      _AppBarBadge(
                        icon: Icons.topic_rounded,
                        label: '12 موضوعاً',
                      ),
                      SizedBox(width: 6),
                      _AppBarBadge(
                        icon: Icons.auto_awesome_rounded,
                        label: '80+ نصيحة وشرح',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarBadge extends StatelessWidget {
  const _AppBarBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textDirection: context.textDirection,
      decoration: InputDecoration(
        hintText: 'ابحث عن ميزة أو خطوة استخدام...',
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
          fontSize: 13,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clearSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onSelected(category),
            selectedColor: primary,
            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            side: BorderSide(
              color: isSelected
                  ? primary
                  : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            labelStyle: AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyGuideSearch extends StatelessWidget {
  const _EmptyGuideSearch();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final primary = isDark ? AppColors.primaryLight : AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: primary, size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'لا توجد نتائج مطابقة',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'جرّب كلمة أقصر مثل: القرآن، الحفظ، الأذكار، الإشعارات.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
