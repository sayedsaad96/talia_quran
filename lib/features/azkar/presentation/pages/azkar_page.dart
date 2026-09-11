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
import '../../data/datasources/azkar_completion_store.dart';
import '../../data/datasources/azkar_preferences_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/services/azkar_time_context.dart';
import '../widgets/free_tasbeeh_sheet.dart';

class AzkarPage extends StatefulWidget {
  const AzkarPage({super.key, this.currentTime});

  /// Optional injected date-time to explicitly drive morning/evening context in tests.
  final DateTime? currentTime;

  @override
  State<AzkarPage> createState() => _AzkarPageState();
}

class _AzkarPageState extends State<AzkarPage> {
  late Future<Map<AzkarCategory, int>> _countsFuture;
  AzkarCompletionStore? _completionStore;
  late final AzkarPreferencesStore _prefsStore;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();

    _completionStore = getIt.isRegistered<AzkarCompletionStore>()
        ? getIt<AzkarCompletionStore>()
        : null;

    _prefsStore = getIt.isRegistered<AzkarPreferencesStore>()
        ? getIt<AzkarPreferencesStore>()
        : AzkarPreferencesStore();
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
                      AppSpacing.md,
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
                            : _buildContent(context, counts, isDark),
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

  List<Widget> _buildContent(
    BuildContext context,
    Map<AzkarCategory, int>? counts,
    bool isDark,
  ) {
    if (counts == null) {
      return const [SizedBox(height: 180, child: LoadingWidget())];
    }

    final morningCount = counts[AzkarCategory.morning] ?? 0;
    final eveningCount = counts[AzkarCategory.evening] ?? 0;
    final generalCount = counts[AzkarCategory.general] ?? 0;
    final duaCount = counts[AzkarCategory.duas] ?? 0;

    // Strict religious safety gate: if no approved records exist, fail closed
    if (morningCount == 0 &&
        eveningCount == 0 &&
        generalCount == 0 &&
        duaCount == 0) {
      return [
        EmptyStateWidget(
          key: const ValueKey('azkar-content-under-review'),
          message: context.l10n.azkarContentUnderReview,
          icon: Icons.pending_actions_rounded,
        ),
      ];
    }

    final period = AzkarTimeContext.resolvePeriod(widget.currentTime);

    // Pick contextual hero category based on period and availability
    final AzkarCategory? heroCategory = switch (period) {
      AzkarPeriod.morning when morningCount > 0 => AzkarCategory.morning,
      AzkarPeriod.evening when eveningCount > 0 => AzkarCategory.evening,
      _ => morningCount > 0
          ? AzkarCategory.morning
          : (eveningCount > 0 ? AzkarCategory.evening : null),
    };

    final items = <Widget>[];

    // 1. Contextual Hero Card
    if (heroCategory != null) {
      final isMorningHero = heroCategory == AzkarCategory.morning;
      final heroCount = isMorningHero ? morningCount : eveningCount;
      final isAllDone =
          _completionStore?.isCategoryComplete(
            heroCategory,
            widget.currentTime,
          ) ??
          false;

      items.add(
        _ContextualHeroCard(
          key: const ValueKey('azkar-hero-card'),
          title: isMorningHero
              ? context.l10n.morningAzkar
              : context.l10n.eveningAzkar,
          subtitle: isAllDone
              ? 'اكتمل ورد اليوم بنجاح ✨'
              : (isMorningHero
                  ? 'ابدأ يومك بذكر الله وطمأنينة القلب'
                  : 'اختم يومك بالسكينة والاستغفار'),
          countText: context.l10n.zikrCount(heroCount),
          isDone: isAllDone,
          icon: isMorningHero
              ? Icons.wb_sunny_rounded
              : Icons.nightlight_round,
          gradientColors: isMorningHero
              ? const [Color(0xFFE5A642), Color(0xFFC27D16)]
              : const [AppColors.primary, AppColors.primaryDark],
          route: isMorningHero ? 'morning' : 'evening',
          isDark: isDark,
        ),
      );
      items.add(const SizedBox(height: AppSpacing.lg));
    }

    // 2. Bento Grid for Remaining Available Categories + Free Tasbeeh
    final bentoCards = <Widget>[];

    // Other time-based category if available
    if (heroCategory != AzkarCategory.morning && morningCount > 0) {
      bentoCards.add(
        _BentoGridCard(
          title: context.l10n.morningAzkar,
          subtitle: context.l10n.zikrCount(morningCount),
          icon: Icons.wb_sunny_rounded,
          accentColor: const Color(0xFFE5A642),
          route: 'morning',
          isDark: isDark,
        ),
      );
    }

    if (heroCategory != AzkarCategory.evening && eveningCount > 0) {
      bentoCards.add(
        _BentoGridCard(
          title: context.l10n.eveningAzkar,
          subtitle: context.l10n.zikrCount(eveningCount),
          icon: Icons.nightlight_round,
          accentColor: AppColors.primaryLight,
          route: 'evening',
          isDark: isDark,
        ),
      );
    }

    // Duas card
    if (duaCount > 0) {
      bentoCards.add(
        _BentoGridCard(
          title: context.l10n.duas,
          subtitle: context.l10n.duaCount(duaCount),
          icon: Icons.menu_book_rounded,
          accentColor: const Color(0xFF6B46C1),
          route: 'duas',
          isDark: isDark,
        ),
      );
    }

    // General Azkar card
    if (generalCount > 0) {
      bentoCards.add(
        _BentoGridCard(
          title: context.l10n.generalAzkar,
          subtitle: context.l10n.azkarCount(generalCount),
          icon: Icons.spa_rounded,
          accentColor: AppColors.ambientTeal,
          route: 'general',
          isDark: isDark,
        ),
      );
    }

    // Free Tasbeeh card
    bentoCards.add(
      _BentoGridCard(
        key: const ValueKey('azkar-card-tasbeeh'),
        title: 'مسبحة حرة',
        subtitle: 'تسبيح واستغفار حر',
        icon: Icons.touch_app_rounded,
        accentColor: AppColors.goldDark,
        onTap: () => FreeTasbeehSheet.show(
          context,
          store: _prefsStore,
          isDark: isDark,
        ),
        isDark: isDark,
      ),
    );

    // Section Header
    items.add(
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          'الأقسام والخدمات',
          style: AppTypography.titleMedium.copyWith(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ),
    );

    // Render Bento Grid in 2-column rows
    for (var i = 0; i < bentoCards.length; i += 2) {
      final isLastSingle = i + 1 >= bentoCards.length;
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: bentoCards[i]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: isLastSingle
                    ? const SizedBox.shrink()
                    : bentoCards[i + 1],
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  SliverAppBar _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
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
                end: -30,
                top: -15,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        context.l10n.azkar,
                        style: AppTypography.displaySmall.copyWith(
                          color: Colors.white,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.azkarSubtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
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

class _ContextualHeroCard extends StatelessWidget {
  const _ContextualHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.countText,
    required this.isDone,
    required this.icon,
    required this.gradientColors,
    required this.route,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final String countText;
  final bool isDone;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title، $countText',
      child: InkWell(
        onTap: () => context.push('/azkar/$route'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative background glow icon
              PositionedDirectional(
                end: -15,
                bottom: -15,
                child: Icon(
                  icon,
                  size: 130,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'Amiri',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            countText,
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isDone ? 'مراجعة الورد' : 'ابدأ الورد الآن',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Icons.arrow_back_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
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
    );
  }
}

class _BentoGridCard extends StatelessWidget {
  const _BentoGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.route,
    this.onTap,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? route;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final surfaceColor =
        isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return InkWell(
      onTap: onTap ?? () => context.push('/azkar/$route'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.arrow_back_ios_new_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: subColor.withValues(alpha: 0.6),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: textColor,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelSmall.copyWith(
                    color: subColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
