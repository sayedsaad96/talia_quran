import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/azkar_entities.dart';
import '../cubits/azkar_cubit.dart';

class GeneralAzkarPage extends StatelessWidget {
  const GeneralAzkarPage({super.key, this.category = AzkarCategory.general});

  final AzkarCategory category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AzkarCubit>()..load(category),
      child: _GeneralAzkarView(category: category),
    );
  }
}

class _GeneralAzkarView extends StatefulWidget {
  const _GeneralAzkarView({required this.category});

  final AzkarCategory category;

  @override
  State<_GeneralAzkarView> createState() => _GeneralAzkarViewState();
}

class _GeneralAzkarViewState extends State<_GeneralAzkarView> {
  String _selectedSubcategory = '';

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
    // Extract unique subcategories
    final allSubcategories = state.sessions
        .map((s) => s.zikr.subcategory)
        .where((sub) => sub.isNotEmpty)
        .toSet()
        .toList();

    final tabs = ['', ...allSubcategories];

    // Filter sessions
    final filteredSessions = _selectedSubcategory.isEmpty
        ? state.sessions
        : state.sessions
              .where((s) => s.zikr.subcategory == _selectedSubcategory)
              .toList();

    return CustomScrollView(
      slivers: [
        _buildAppBar(context, isDark),
        if (allSubcategories.isNotEmpty)
          SliverToBoxAdapter(child: _buildCategoriesFilter(tabs, isDark)),
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
                child: _ZikrCard(zikr: session.zikr, isDark: isDark)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                    .slideY(begin: 0.1, end: 0),
              );
            }, childCount: filteredSessions.length),
          ),
        ),
      ],
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
          return GestureDetector(
            onTap: () => setState(() => _selectedSubcategory = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                  color: selected
                      ? primary
                      : (isDark
                            ? AppColors.darkCard
                            : Colors.white),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: selected
                        ? primary
                        : (isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider),
                    width: selected ? 0 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  tab.isEmpty ? context.l10n.all : tab,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    final isDuas = widget.category == AzkarCategory.duas;

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
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
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDuas
                        ? const [Color(0xFF881337), Color(0xFF3F0717)]
                        : const [Color(0xFF1A6B5A), Color(0xFF0D362D)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDuas
                        ? const [Color(0xFFE11D48), Color(0xFF881337)]
                        : const [Color(0xFF1A6B5A), Color(0xFF0F4A3E)],
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
  const _ZikrCard({required this.zikr, required this.isDark});

  final Zikr zikr;
  final bool isDark;

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
                child: Text(
                  zikr.text,
                  style: AppTypography.azkarText.copyWith(
                    color: textPrimary,
                    fontSize: 22,
                    height: 1.8,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
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
                    IconButton(
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
                      icon: Icon(
                        Icons.share_rounded,
                        color: primary,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        final data = SocialShareData(
                          content: zikr.text.trim(),
                          subtitle: zikr.reference.trim(),
                          category: SocialShareCategory.azkar,
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
