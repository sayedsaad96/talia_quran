import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/kids_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/memorization_path_settings_sheet.dart';
import '../widgets/kids_mission_card.dart';
import '../widgets/kids_progress_header.dart';

class KidsGamifiedHomePage extends StatelessWidget {
  const KidsGamifiedHomePage({
    super.key,
    required this.surahId,
    this.childName,
  });

  final int surahId;
  final String? childName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<KidsJourneyCubit>()..load(surahId: surahId),
      child: _KidsGamifiedHomeView(surahId: surahId, childName: childName),
    );
  }
}

@visibleForTesting
String kidsQuranReaderLocation(int surahId) =>
    '${AppRoutes.memorizationPlusKidsQuran}?surahId=$surahId';

class _KidsGamifiedHomeView extends StatelessWidget {
  const _KidsGamifiedHomeView({required this.surahId, this.childName});

  final int surahId;
  final String? childName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KidsTheme.nightSkyDark,
      body: BlocConsumer<KidsJourneyCubit, KidsJourneyState>(
        listener: (context, state) {
          if (state is KidsJourneyLoaded && state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is KidsJourneyInitial || state is KidsJourneyLoading) {
            return const Center(child: LoadingWidget());
          }

          if (state is KidsJourneyError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<KidsJourneyCubit>().load(surahId: surahId),
            );
          }

          if (state is! KidsJourneyLoaded) return const SizedBox.shrink();

          return KidsGamifiedHomeContent(
            state: state,
            childName: childName,
            onRefresh: () =>
                context.read<KidsJourneyCubit>().load(surahId: surahId),
            onMushafTap: () =>
                context.push(kidsQuranReaderLocation(state.surahId)),
            onJourneyTap: () => context.push(
              '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
            ),
            onMissionTap: () => unawaited(_openCurrentMission(context, state)),
            onPathSettingsTap: () =>
                showMemorizationPathSettingsSheet(context, isDark: true),
          );
        },
      ),
    );
  }

  Future<void> _openCurrentMission(
    BuildContext context,
    KidsJourneyLoaded state,
  ) async {
    final stage = state.currentStage;
    if (stage == null) {
      await context.push(
        '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
      );
    } else {
      final startAyah = stage.nextAyahToStart;
      await context.push(
        '${AppRoutes.memorizationPlusKids}?surahId=${stage.surahId}&ayahNumber=$startAyah',
      );
    }

    if (context.mounted) {
      await context.read<KidsJourneyCubit>().load(surahId: state.surahId);
    }
  }
}

@visibleForTesting
class KidsGamifiedHomeContent extends StatelessWidget {
  const KidsGamifiedHomeContent({
    super.key,
    required this.state,
    required this.onMushafTap,
    required this.onJourneyTap,
    required this.onMissionTap,
    this.childName,
    this.onRefresh,
    this.onPathSettingsTap,
  });

  final KidsJourneyLoaded state;
  final VoidCallback onMushafTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onMissionTap;
  final String? childName;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onPathSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: KidsTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: _KidsHomeBottomNav(
          onMushafTap: onMushafTap,
          onJourneyTap: onJourneyTap,
          onMissionTap: onMissionTap,
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: onRefresh ?? () async {},
            child: CustomScrollView(
              key: const PageStorageKey<String>('kids-gamified-home'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      KidsProgressHeader(
                        progress: state.progress,
                        childName: childName,
                        onSettingsTap: onPathSettingsTap,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _KidsStartHerePanel(
                        hasCurrentStage: state.currentStage != null,
                        onStartTap: onMissionTap,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      KidsMissionCard(
                        stage: state.currentStage,
                        surahName:
                            state.surahName ??
                            '${context.l10n.surah} ${state.surahId}',
                        onContinue: onMissionTap,
                      ),
                      const SizedBox(height: 96),
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

class _KidsStartHerePanel extends StatelessWidget {
  const _KidsStartHerePanel({
    required this.hasCurrentStage,
    required this.onStartTap,
  });

  final bool hasCurrentStage;
  final VoidCallback onStartTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: KidsTheme.goldStar.withValues(alpha: 0.18),
        borderRadius: KidsTheme.cardRadius,
        border: Border.all(color: KidsTheme.goldStar.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: KidsTheme.goldStar,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: KidsTheme.nightSkyDark,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.isArabic ? 'ابدأ من هنا' : 'Start here',
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.isArabic
                      ? 'افتح مهمة اليوم ثم اجمع النجوم عند إكمال الآيات.'
                      : 'Open today\'s mission, then collect stars as ayahs are completed.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onStartTap,
            icon: const Icon(Icons.flag_rounded, size: 18),
            label: Text(
              hasCurrentStage
                  ? (context.isArabic ? 'المهمة' : 'Mission')
                  : (context.isArabic ? 'الخريطة' : 'Map'),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: KidsTheme.goldStar,
              foregroundColor: KidsTheme.nightSkyDark,
              textStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KidsHomeBottomNav extends StatelessWidget {
  const _KidsHomeBottomNav({
    required this.onMushafTap,
    required this.onJourneyTap,
    required this.onMissionTap,
  });

  final VoidCallback onMushafTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onMissionTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return NavigationBar(
      key: const ValueKey('kids-home-bottom-nav'),
      selectedIndex: 2,
      backgroundColor: KidsTheme.nightSkyMid,
      indicatorColor: KidsTheme.goldStar.withValues(alpha: 0.18),
      labelBehavior: isCompact
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onMushafTap();
          case 1:
            onJourneyTap();
          case 2:
            onMissionTap();
        }
      },
      destinations: [
        NavigationDestination(
          key: const ValueKey('kids-home-nav-mushaf'),
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book_rounded),
          label: context.l10n.kidsGamifiedMushaf,
        ),
        NavigationDestination(
          key: const ValueKey('kids-home-nav-journey'),
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map_rounded),
          label: context.l10n.kidsGamifiedJourney,
        ),
        NavigationDestination(
          key: const ValueKey('kids-home-nav-missions'),
          icon: const Icon(Icons.flag_outlined),
          selectedIcon: const Icon(Icons.flag_rounded),
          label: context.l10n.kidsGamifiedMissions,
        ),
      ],
    );
  }
}
