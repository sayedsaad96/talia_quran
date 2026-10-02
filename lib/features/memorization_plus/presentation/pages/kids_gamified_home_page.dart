import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/memorization_entities.dart';
import '../../domain/navigation/kids_next_mission_resolver.dart';
import '../../domain/services/kids_daily_missions.dart';
import '../../domain/repositories/memorization_plus_repository.dart';
import '../cubits/kids_journey_cubit.dart';
import '../theme/kids_theme.dart';
import '../widgets/kids_daily_mission_tile.dart';
import '../widgets/kids_journey_complete_card.dart';
import '../widgets/kids_day_complete_card.dart';
import '../widgets/kids_welcome_back_card.dart';
import '../widgets/kids_loading_widget.dart';
import '../widgets/memorization_path_settings_sheet.dart';
import '../widgets/kids_mission_card.dart';
import '../widgets/kids_progress_header.dart';
import '../widgets/kids_talia_moments.dart';
import '../widgets/kids_ui.dart';
import '../world/kids_world_palette.dart';

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
      create: (_) =>
          getIt<KidsJourneyCubit>()
            ..load(surahId: surahId, followFrontier: true),
      child: _KidsGamifiedHomeView(surahId: surahId, childName: childName),
    );
  }
}

@visibleForTesting
String kidsQuranReaderLocation(int surahId, {int? ayahNumber}) =>
    '${AppRoutes.memorizationPlusKidsQuran}?surahId=$surahId'
    '${ayahNumber == null ? '' : '&ayahNumber=$ayahNumber'}';

@visibleForTesting
String kidsMissionLocation(KidsNextMission mission) =>
    '${AppRoutes.memorizationPlusKids}?surahId=${mission.surahId}'
    '&ayahNumber=${mission.startAyah}&missionType=${mission.type.name}';

class _KidsGamifiedHomeView extends StatefulWidget {
  const _KidsGamifiedHomeView({required this.surahId, this.childName});

  final int surahId;
  final String? childName;

  @override
  State<_KidsGamifiedHomeView> createState() => _KidsGamifiedHomeViewState();
}

class _KidsGamifiedHomeViewState extends State<_KidsGamifiedHomeView> {
  /// Guards against rapid double taps stacking two copies of the same
  /// destination on top of each other — a very real pattern with children.
  bool _destinationOpen = false;

  /// The nickname entered at kids setup, so the greeting uses the child's
  /// name instead of a generic "memorization hero".
  String? _nickname;

  @override
  void initState() {
    super.initState();
    _nickname = widget.childName;
    if (_nickname == null) unawaited(_loadNickname());
  }

  Future<void> _loadNickname() async {
    try {
      if (!getIt.isRegistered<MemorizationPlusRepository>()) return;
      final result = await getIt<MemorizationPlusRepository>()
          .getParentSettings();
      final nickname = result.fold(
        (_) => null,
        (settings) => settings.localChildNickname,
      );
      if (!mounted || nickname == null || nickname.trim().isEmpty) return;
      setState(() => _nickname = nickname.trim());
    } catch (_) {
      // The generic greeting is a safe fallback.
    }
  }

  Future<void> _openDestination(Future<void> Function() open) async {
    if (_destinationOpen) return;
    _destinationOpen = true;
    try {
      await open();
    } finally {
      if (mounted) {
        _destinationOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahId = widget.surahId;
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
            return const Center(child: KidsLoadingWidget());
          }

          if (state is KidsJourneyError) {
            return KidsErrorWidget(
              onRetry: () => context.read<KidsJourneyCubit>().load(
                surahId: surahId,
                followFrontier: true,
              ),
            );
          }

          if (state is! KidsJourneyLoaded) return const SizedBox.shrink();

          return KidsGamifiedHomeContent(
            state: state,
            childName: _nickname,
            // The home tab is only ever tappable while the home screen is
            // already visible: navigating to the same route would rebuild the
            // page and flash a loading state at the child for no reason.
            onHomeTap: () {},
            onRefresh: () => context.read<KidsJourneyCubit>().load(
              surahId: surahId,
              followFrontier: true,
            ),
            onMushafTap: () => _openDestination(() async {
              if (!context.mounted) return;
              // Open the Mushaf at today's mission ayah, marked (K26).
              final mission = state.nextMission;
              await context.push(
                mission == null
                    ? kidsQuranReaderLocation(state.surahId)
                    : kidsQuranReaderLocation(
                        mission.surahId,
                        ayahNumber: mission.startAyah,
                      ),
              );
            }),
            onJourneyTap: () => _openDestination(() async {
              if (!context.mounted) return;
              await context.push(
                '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
              );
            }),
            onMissionTap: () =>
                _openDestination(() => _openCurrentMission(context, state)),
            onReadingMissionTap: () => _openDestination(() async {
              if (!context.mounted) return;
              await context.push(kidsQuranReaderLocation(state.surahId));
              if (context.mounted) {
                // A confirmed page completes the reading card.
                await context.read<KidsJourneyCubit>().load(
                  surahId: state.surahId,
                  followFrontier: true,
                );
              }
            }),
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
      if (!context.mounted) return;
      await context.push(
        '${AppRoutes.memorizationPlusKidsJourney}?surahId=${state.surahId}',
      );
    } else {
      if (!context.mounted) return;
      await context.push(kidsMissionLocation(mission));
    }

    if (context.mounted) {
      // Re-resolve from the loaded surah: finishing its last ayah moves home
      // on to the surah where the journey continues (K20).
      await context.read<KidsJourneyCubit>().load(
        surahId: state.surahId,
        followFrontier: true,
      );
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
    this.onReadingMissionTap,
  });

  final KidsJourneyLoaded state;
  final VoidCallback onHomeTap;
  final VoidCallback onMushafTap;
  final VoidCallback onJourneyTap;
  final VoidCallback onMissionTap;
  final String? childName;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onPathSettingsTap;

  /// Opens the kids Mushaf for the reading mission card.
  final VoidCallback? onReadingMissionTap;

  @override
  Widget build(BuildContext context) {
    return KidsBackground(
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
                      const SizedBox(height: AppSpacing.md),
                      KidsTaliaMomentCompanion(
                        moment: kidsHomeTaliaMoment(state),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // K33: a warm welcome after a few days away.
                      if (state.isReturningAfterBreak) ...[
                        const KidsWelcomeBackCard(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (state.dailyGoalCap != null) ...[
                        // Today's quota is used up: end the day with praise
                        // instead of a mission the session would refuse (N3).
                        // Checked first: a surah finished on a capped day is
                        // not the end of the journey (K18).
                        KidsDayCompleteCard(dailyGoalCap: state.dailyGoalCap!),
                      ] else if (state.currentStage == null &&
                          state.nextMission == null &&
                          // Real progress separates a finished journey from a
                          // first-time child who has not started yet.
                          state.progress.ayahsCompleted > 0) ...[
                        // No stage and no mission after real progress: the
                        // journey is finished — a real celebration, not a
                        // generic empty state (W2).
                        const KidsJourneyCompleteCard(),
                      ] else ...[
                        KidsMissionCard(
                          stage: state.missionStage,
                          // A mission in another surah never borrows the
                          // loaded surah's name.
                          surahName:
                              state.nextMission != null &&
                                  state.nextMission!.surahId != state.surahId
                              ? state.missionSurahName ??
                                    '${context.l10n.surah} '
                                        '${state.nextMission!.surahId}'
                              : state.surahName ??
                                    '${context.l10n.surah} ${state.surahId}',
                          onContinue: onMissionTap,
                          // A due SRS review or linked stage review is today's
                          // task, so the card says "Ready for review".
                          isReviewMission:
                              state.nextMission?.type ==
                                  KidsMissionType.dueReview ||
                              state.nextMission?.type ==
                                  KidsMissionType.linkedReview,
                          // Describe the ayahs the review really opens (N7).
                          reviewAyahs: state.nextMission?.ayahNumbers,
                        ),
                      ],
                      ..._missionTiles(context),
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

  /// «مهماتي اليوم»: a tile for every mission after the learning card (which
  /// is the existing mission / day-complete card above).
  List<Widget> _missionTiles(BuildContext context) {
    final others = state.dailyMissions
        .where((m) => m.kind != KidsDailyMissionKind.learning)
        .toList(growable: false);
    if (others.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.lg),
      Semantics(
        header: true,
        child: Text(
          context.l10n.kidsDailyMissionsTitle,
          style: AppTypography.titleMedium.copyWith(
            color: KidsWorldPalette.of(context).onScene,
            fontFamily: 'Amiri',
            letterSpacing: 0,
          ),
        ),
      ),
      for (final mission in others) ...[
        const SizedBox(height: AppSpacing.sm),
        KidsDailyMissionTile(
          mission: mission,
          onTap: () => switch (mission.kind) {
            KidsDailyMissionKind.reading => onReadingMissionTap?.call(),
            _ => onMissionTap(),
          },
        ),
      ],
    ];
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
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? KidsTheme.goldLight
              : KidsTheme.shellTextSecondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
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
