import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/talia_app_bar.dart';
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
  List<TutorialGuideSection> _allSections = const [];
  List<String> _categories = const [];

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
    final sections = _filteredSections;

    return Directionality(
      textDirection: context.textDirection,
      child: Scaffold(
        backgroundColor: context.tokens.background,
        body: CustomScrollView(
          slivers: [
            _buildAppBar(context),
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

  SliverAppBar _buildAppBar(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final tipCount = _allSections.fold<int>(
      0,
      (sum, s) => sum + s.steps.length + s.tips.length + s.notes.length,
    );

    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: tokens.background,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      leading: const TaliaBackButton(
        fallbackLocation: AppRoutes.settings,
        color: Colors.white,
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.pagePadding,
          0,
          AppSpacing.pagePadding,
          AppSpacing.md,
        ),
        title: Text(
          l10n.tutorialGuideTitle,
          style: AppTypography.headlineMedium.copyWith(
            color: Colors.white,
            fontFamily: context.isArabic ? 'Amiri' : null,
          ),
        ),
        background: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: tokens.heroGradient,
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
                    l10n.tutorialGuideHeroSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _AppBarBadge(
                        icon: Icons.topic_rounded,
                        label: l10n.tutorialGuideTopicsCount(
                          _allSections.length,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _AppBarBadge(
                        icon: Icons.auto_awesome_rounded,
                        label: l10n.tutorialGuideTipsCount(tipCount),
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
    final tokens = context.tokens;
    final primary = tokens.accent;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textDirection: context.textDirection,
      decoration: InputDecoration(
        hintText: context.l10n.tutorialGuideSearchHint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: tokens.textHint),
        prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.clearSearch,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: tokens.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: tokens.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          borderSide: BorderSide(color: tokens.divider),
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
    final tokens = context.tokens;
    final primary = tokens.accent;

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
            backgroundColor: tokens.card,
            side: BorderSide(color: isSelected ? primary : tokens.divider),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            labelStyle: AppTypography.labelMedium.copyWith(
              color: isSelected ? Colors.white : tokens.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: tokens.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, color: tokens.accent, size: 44),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.tutorialGuideNoResults,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.tutorialGuideNoResultsHint,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
