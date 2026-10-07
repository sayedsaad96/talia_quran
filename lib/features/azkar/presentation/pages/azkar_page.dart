import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/l10n/cubit_message_codes.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../data/datasources/azkar_completion_store.dart';
import '../../data/datasources/azkar_preferences_store.dart';
import '../../data/datasources/smart_wird_progress_store.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/services/azkar_period_resolver.dart';
import '../../domain/services/azkar_time_context.dart';
import '../cubits/azkar_hub_cubit.dart';
import '../widgets/free_tasbeeh_sheet.dart';

import '../../../../core/utils/locale_number_formatter.dart';

class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key, this.currentTime});

  /// Optional injected date-time to explicitly drive morning/evening context in tests.
  final DateTime? currentTime;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AzkarHubCubit(
        getIt<AzkarRepository>(),
        getIt<AzkarCompletionStore>(),
        getIt<AzkarPreferencesStore>(),
        smartWirdStore: getIt<SmartWirdProgressStore>(),
        windowSource: getIt.isRegistered<AzkarPrayerWindowSource>()
            ? getIt<AzkarPrayerWindowSource>()
            : null,
      )..load(currentTime),
      child: const _AzkarHubView(),
    );
  }
}

class _AzkarHubView extends StatelessWidget {
  const _AzkarHubView();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: BlocBuilder<AzkarHubCubit, AzkarHubState>(
        builder: (context, state) {
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
                        ...switch (state.status) {
                          AzkarHubStatus.loading => const [
                            SizedBox(height: 180, child: LoadingWidget()),
                          ],
                          AzkarHubStatus.error => [
                            SizedBox(
                              height: 320,
                              child: ErrorStateWidget(
                                message: context.localizedCubitMessage(
                                  CubitMessageCodes.errorCache,
                                ),
                                onRetry: () =>
                                    context.read<AzkarHubCubit>().load(),
                              ),
                            ),
                          ],
                          AzkarHubStatus.ready => _buildContent(
                            context,
                            state,
                            isDark,
                          ),
                        },
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
    AzkarHubState state,
    bool isDark,
  ) {
    final counts = state.counts;
    final morningCount = counts[AzkarCategory.morning] ?? 0;
    final eveningCount = counts[AzkarCategory.evening] ?? 0;
    final generalCount = counts[AzkarCategory.general] ?? 0;
    final duaCount = counts[AzkarCategory.duas] ?? 0;

    // Strict religious safety gate: if no approved records exist, fail closed.
    if (state.allEmpty) {
      return [
        EmptyStateWidget(
          key: const ValueKey('azkar-content-under-review'),
          message: context.l10n.azkarContentUnderReview,
          icon: TaliaIcons.pending,
        ),
      ];
    }

    final items = <Widget>[];

    // 1. Contextual Hero Card
    final heroCategory = switch (state.period) {
      AzkarPeriod.morning when morningCount > 0 => AzkarCategory.morning,
      AzkarPeriod.evening when eveningCount > 0 => AzkarCategory.evening,
      _ =>
        morningCount > 0
            ? AzkarCategory.morning
            : (eveningCount > 0 ? AzkarCategory.evening : null),
    };

    if (heroCategory != null) {
      final isMorningHero = heroCategory == AzkarCategory.morning;
      final heroCount = isMorningHero ? morningCount : eveningCount;
      final isAllDone = state.completion[heroCategory] ?? false;

      items.add(
        _ContextualHeroCard(
          key: const ValueKey('azkar-hero-card'),
          title: isMorningHero
              ? context.l10n.morningAzkar
              : context.l10n.eveningAzkar,
          subtitle: isAllDone
              ? context.l10n.azkarWirdCompletedToday
              : (isMorningHero
                    ? context.l10n.azkarMorningHeroSubtitle
                    : context.l10n.azkarEveningHeroSubtitle),
          countText: context.l10n.zikrCount(context.numText(heroCount)),
          isDone: isAllDone,
          icon: isMorningHero ? TaliaIcons.sun : TaliaIcons.moon,
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
          subtitle: context.l10n.zikrCount(context.numText(morningCount)),
          icon: TaliaIcons.sun,
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
          subtitle: context.l10n.zikrCount(context.numText(eveningCount)),
          icon: TaliaIcons.moon,
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
          subtitle: context.l10n.duaCount(context.numText(duaCount)),
          icon: TaliaIcons.dua,
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
          subtitle: context.l10n.azkarCount(context.numText(generalCount)),
          icon: TaliaIcons.azkar,
          accentColor: AppColors.ambientTeal,
          route: 'general',
          isDark: isDark,
        ),
      );
    }

    // Smart Wird card — subtitle reflects the live daily state.
    final smartWirdSubtitle = state.smartWirdCompletedToday
        ? context.l10n.azkarSmartWirdDone(
            LocaleNumberFormatter.format(
              (state.smartWirdSessionCountToday).toString(),
              context.l10n.localeName,
            ),
          )
        : context.l10n.azkarSmartWirdSubtitle;
    bentoCards.add(
      _BentoGridCard(
        key: const ValueKey('azkar-card-smart-wird'),
        title: context.l10n.azkarSmartWird,
        subtitle: smartWirdSubtitle,
        icon: TaliaIcons.sparkle,
        accentColor: AppColors.success,
        route: 'smart',
        isDark: isDark,
      ),
    );

    // Free Tasbeeh card
    bentoCards.add(
      _BentoGridCard(
        key: const ValueKey('azkar-card-tasbeeh'),
        title: context.l10n.azkarFreeTasbeeh,
        subtitle: context.l10n.azkarFreeTasbeehSubtitle,
        icon: TaliaIcons.tap,
        accentColor: AppColors.goldDark,
        onTap: () async {
          await FreeTasbeehSheet.show(context, isDark: isDark);
          if (context.mounted) {
            context.read<AzkarHubCubit>().refreshTasbeehTally();
          }
        },
        isDark: isDark,
      ),
    );

    // Section Header
    items.add(
      Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(
          context.l10n.azkarSectionsAndServices,
          style: AppTypography.titleMedium.copyWith(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.w700,
            color: context.tokens.textPrimary,
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
      backgroundColor: context.tokens.background,
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
                  TaliaIcons.prayer,
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXl,
                            ),
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
                              isDone
                                  ? context.l10n.azkarReviewWird
                                  : context.l10n.azkarStartWirdNow,
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? TaliaIcons.arrowBack
                                  : TaliaIcons.arrowForward,
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
    final surfaceColor = context.tokens.card;
    final borderColor = context.tokens.divider;
    final textColor = context.tokens.textPrimary;
    final subColor = context.tokens.textSecondary;

    return InkWell(
      onTap: onTap ?? () => context.push('/azkar/$route'),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                      ? TaliaIcons.chevronBack
                      : TaliaIcons.chevronForward,
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
                  style: AppTypography.labelSmall.copyWith(color: subColor),
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
