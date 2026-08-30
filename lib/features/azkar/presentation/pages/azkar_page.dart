import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key});

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late Future<Map<AzkarCategory, int>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
  }

  Future<Map<AzkarCategory, int>> _loadCounts() async {
    final repo = getIt<AzkarRepository>();
    final results = await Future.wait(
      AzkarCategory.values.map((category) => repo.getAzkar(category)),
    );
    final counts = <AzkarCategory, int>{};
    var failures = 0;
    for (var i = 0; i < AzkarCategory.values.length; i++) {
      results[i].fold(
        (_) => failures++,
        (list) => counts[AzkarCategory.values[i]] = list.length,
      );
    }
    if (counts.isEmpty && failures > 0) {
      throw Exception('azkar counts unavailable');
    }
    return counts;
  }

  void _retry() {
    setState(() => _countsFuture = _loadCounts());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: FutureBuilder<Map<AzkarCategory, int>>(
        future: _countsFuture,
        builder: (context, snapshot) {
          final counts = snapshot.data;
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context, isDark),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.lg,
                      AppSpacing.pagePadding,
                      120, // Prevent cutoff by bottom nav
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        ...snapshot.hasError
                            ? [
                                SizedBox(
                                  height: 320,
                                  child: ErrorStateWidget(
                                    message: context.localizedCubitMessage(
                                      CubitMessageCodes.errorCache,
                                    ),
                                    onRetry: _retry,
                                  ),
                                ),
                              ]
                            : _buildCategoryItems(context, counts, isDark),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCategoryItems(
    BuildContext context,
    Map<AzkarCategory, int>? counts,
    bool isDark,
  ) {
    if (counts == null) {
      return const [SizedBox(height: 180, child: LoadingWidget())];
    }

    final items = <Widget>[];
    void addCard(Widget card) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(height: AppSpacing.md));
      }
      items.add(card);
    }

    final morningCount = counts[AzkarCategory.morning] ?? 0;
    if (morningCount > 0) {
      addCard(
        _AzkarCategoryCard(
          title: context.l10n.morningAzkar,
          subtitle: context.l10n.zikrCount(morningCount),
          icon: Icons.wb_sunny_rounded,
          gradientColors: const [AppColors.primaryLight, AppColors.primaryDark],
          route: 'morning',
          isDark: isDark,
        ),
      );
    }

    final eveningCount = counts[AzkarCategory.evening] ?? 0;
    if (eveningCount > 0) {
      addCard(
        _AzkarCategoryCard(
          title: context.l10n.eveningAzkar,
          subtitle: context.l10n.zikrCount(eveningCount),
          icon: Icons.nightlight_round,
          gradientColors: const [AppColors.primary, AppColors.primaryDark],
          route: 'evening',
          isDark: isDark,
        ),
      );
    }

    final generalCount = counts[AzkarCategory.general] ?? 0;
    if (generalCount > 0) {
      addCard(
        _AzkarCategoryCard(
          title: context.l10n.generalAzkar,
          subtitle: context.l10n.azkarCount(generalCount),
          icon: Icons.spa_rounded,
          gradientColors: const [AppColors.ambientTeal, Color(0xFF0F4A3E)],
          route: 'general',
          isDark: isDark,
        ),
      );
    }

    final duaCount = counts[AzkarCategory.duas] ?? 0;
    if (duaCount > 0) {
      addCard(
        _AzkarCategoryCard(
          title: context.l10n.duas,
          subtitle: context.l10n.duaCount(duaCount),
          icon: Icons.volunteer_activism_rounded,
          gradientColors: const [AppColors.inkDeep, AppColors.primaryDark],
          route: 'duas',
          isDark: isDark,
        ),
      );
    }

    if (items.isEmpty) {
      return [
        EmptyStateWidget(
          key: const ValueKey('azkar-content-under-review'),
          message: context.l10n.azkarContentUnderReview,
          icon: Icons.pending_actions_rounded,
        ),
      ];
    }
    items.add(const SizedBox(height: AppSpacing.xl));
    return items;
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
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
          child: Stack(
            children: [
              PositionedDirectional(
                end: -40,
                top: -20,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 200,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.lg,
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.azkar,
                        style: AppTypography.displaySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          context.l10n.azkarSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AzkarCategoryCard extends StatefulWidget {
  const _AzkarCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.route,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
  final bool isDark;

  @override
  State<_AzkarCategoryCard> createState() => _AzkarCategoryCardState();
}

class _AzkarCategoryCardState extends State<_AzkarCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          context.push('/azkar/${widget.route}');
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOutCubic,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors[0].withValues(alpha: 0.4),
                  blurRadius: _isPressed ? 10 : 20,
                  offset: Offset(0, _isPressed ? 4 : 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background pattern/icon
                PositionedDirectional(
                  end: -20,
                  bottom: -20,
                  child: Icon(
                    widget.icon,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      // Icon Container with Glassmorphism feel
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: context.isArabic ? 'Amiri' : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull,
                                ),
                              ),
                              child: Text(
                                widget.subtitle,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Directionality.of(context) == TextDirection.rtl
                              ? Icons.arrow_back_ios_new_rounded
                              : Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
