import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
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

@visibleForTesting
String kidsMissionLocation(KidsNextMission mission) =>
    '${AppRoutes.memorizationPlusKids}?surahId=${mission.surahId}'
    '&ayahNumber=${mission.startAyah}&missionType=${mission.type.name}';

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
            onHomeTap: () => context.go(AppRoutes.home),
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
    final mission = state.nextMission;
    if (mission == null) {
      await context.push(
        '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
      );
    } else {
      await context.push(kidsMissionLocation(mission));
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
    required this.onHomeTap,
    required this.onMushafTap,
    required this.onJourneyTap,
    required this.onMissionTap,
    this.childName,
    this.onRefresh,
    this.onPathSettingsTap,
  });

  final KidsJourneyLoaded state;
  final VoidCallback onHomeTap;
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
          onHomeTap: onHomeTap,
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
                      const SizedBox(height: AppSpacing.xl),
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

class _KidsHomeBottomNav extends StatelessWidget {
  const _KidsHomeBottomNav({
    required this.onHomeTap,
    required this.onMushafTap,
    required this.onJourneyTap,
    required this.onMissionTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onMushafTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onMissionTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return NavigationBar(
      key: const ValueKey('kids-home-bottom-nav'),
      selectedIndex: 0,
      backgroundColor: KidsTheme.nightSkyMid,
      indicatorColor: KidsTheme.goldStar.withValues(alpha: 0.18),
      labelBehavior: isCompact
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            onHomeTap();
          case 1:
            onMushafTap();
          case 2:
            onJourneyTap();
          case 3:
            onMissionTap();
        }
      },
      destinations: [
        NavigationDestination(
          key: const ValueKey('kids-home-nav-home'),
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: context.l10n.home,
        ),
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
