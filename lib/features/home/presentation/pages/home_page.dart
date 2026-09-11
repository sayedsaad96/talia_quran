import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/journey/journey_feature_flags.dart';
import '../../../../core/journey/unified_journey_action_mapper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/social_share/social_share_model.dart';
import '../../../../core/widgets/social_share/social_share_sheet.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../streak/presentation/cubits/streak_cubit.dart';
import '../cubits/home_cubit.dart';
import '../theme/home_skin.dart';
import '../widgets/glass_panel.dart';
import '../widgets/home_activity_feed.dart';
import '../widgets/home_action_tiles.dart';
import '../widgets/home_ayah_of_day.dart';
import '../widgets/home_background.dart';
import '../widgets/home_continue_card.dart';
import '../widgets/home_contextual_slot.dart';
import '../widgets/home_daily_challenge_card.dart';
import '../widgets/home_first_run.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_night_header.dart';
import '../widgets/home_parent_children.dart';
import '../widgets/home_quick_access.dart';
import '../widgets/next_best_action_card.dart';
import '../widgets/resume_session_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.requestDailyAyahShare = false});

  final bool requestDailyAyahShare;

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _wasInBackground = false;
  late final HomeCubit _homeCubit;
  late final StreakCubit _streakCubit;
  StreamSubscription<HomeState>? _homeSubscription;
  bool _shareDailyAyahWhenReady = false;
  bool _isOpeningDailyAyahShare = false;

  @override
  void initState() {
    super.initState();
    _homeCubit = getIt<HomeCubit>();
    _homeSubscription = _homeCubit.stream.listen(_onHomeStateChanged);
    _shareDailyAyahWhenReady = widget.requestDailyAyahShare;
    _homeCubit.load();
    _streakCubit = getIt<StreakCubit>()..loadStreak();
    WidgetsBinding.instance.addObserver(this);
    AppRouter.router.routerDelegate.addListener(_onRouteChanged);
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final location =
        AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (location == AppRoutes.home) {
      _reloadProgress();
    }
  }

  @override
  void dispose() {
    _homeSubscription?.cancel();
    AppRouter.router.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    _homeCubit.close();
    _streakCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestDailyAyahShare && !oldWidget.requestDailyAyahShare) {
      _shareDailyAyahWhenReady = true;
      _reloadProgress();
    }
  }

  void _onHomeStateChanged(HomeState state) {
    if (!_shareDailyAyahWhenReady || _isOpeningDailyAyahShare) return;
    if (state is! HomeLoaded || state.isRefreshing || state.ayahOfDay == null) {
      return;
    }
    _shareDailyAyahWhenReady = false;
    _isOpeningDailyAyahShare = true;
    final ayah = state.ayahOfDay!;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final surahName = context.isArabic ? ayah.surahNameAr : ayah.surahNameEn;
      try {
        await SocialShareSheet.show(
          context,
          SocialShareData.quranVerse(
            ayahText: ayah.text,
            surahName: surahName,
            ayahNumber: ayah.ayahNumber,
          ),
        );
      } finally {
        _isOpeningDailyAyahShare = false;
        if (mounted) AppRouter.router.go(AppRoutes.home);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasInBackground = true;
    }
    if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _reloadProgress();
    }
  }

  void _reloadProgress() {
    if (!mounted) return;
    _homeCubit.load();
    _streakCubit.loadStreak();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _homeCubit),
        BlocProvider.value(value: _streakCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, _) => const _HomeView(),
      ),
    );
  }
}
class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final skin = HomeSkin.forBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: skin.scaffold,
      body: HomeBackground(
        skin: skin,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return const HomeSkeletonLoader();
            }
            if (state is HomeError) {
              return ErrorStateWidget(
                message: state.message,
                onRetry: () => context.read<HomeCubit>().load(),
              );
            }
            if (state is HomeLoaded) {
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: HomeLoadedView(state: state, skin: skin),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
class HomeLoadedView extends StatelessWidget {
  const HomeLoadedView({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final isDark = skin.isDark;
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return RefreshIndicator(
      color: skin.accent,
      onRefresh: () => context.read<HomeCubit>().load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HomeNightHeader(state: state, skin: skin),
          ),
          if (state.isRefreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (state.isFirstRun)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: GlassPanel(
                  skin: skin,
                  child: HomeFirstRun(isDark: isDark),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: state.continueRecitation != null
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pagePadding,
                        AppSpacing.md,
                        AppSpacing.pagePadding,
                        0,
                      ),
                      child: HomeContinueCard(
                        recitation: state.continueRecitation!,
                        skin: skin,
                      ),
                    )
                  : _PrimaryAction(state: state, isDark: isDark),
            ),
            if (state.activeSlot != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeContextualSlot(state: state, skin: skin),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: HomeActionTiles(state: state, skin: skin),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked =
                        constraints.maxWidth < 520 || textScale > 1.3;
                    final challenge = HomeDailyChallengeCard(
                      state: state,
                      skin: skin,
                    );
                    final journey = HomeJourneyRingCard(
                      state: state,
                      skin: skin,
                    );
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          journey,
                          const SizedBox(height: AppSpacing.md),
                          challenge,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: challenge),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: journey),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (state.ayahOfDay != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeAyahOfDayCard(
                    ayah: state.ayahOfDay!,
                    skin: skin,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: HomeActivityFeed(state: state, skin: skin),
              ),
            ),
            if (state.familyChildren.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeParentChildren(
                    children: state.familyChildren,
                    skin: skin,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: HomeQuickAccess(state: state, skin: skin),
              ),
            ),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.lg,
                AppSpacing.pagePadding,
                0,
              ),
              child: Text(
                context.l10n.homeFooterTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: skin.textSecondary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.paddingOf(context).bottom +
                  AppSpacing.xxl +
                  AppSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.state, required this.isDark});
  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (JourneyFeatureFlags.unifiedJourneyEnabled && state.heroAction != null) {
      final action = state.heroAction!;
      final data = const UnifiedJourneyActionMapper().map(context, action);
      child = HomeHeroSection(
        data: data,
        isDark: isDark,
        minutes: state.heroMinutes,
        onTap: () => context.push(action.route),
        onMore: state.alternativeActions.length > 1
            ? () => showHomeAlternativesSheet(
                context,
                actions: state.alternativeActions.skip(1).toList(),
                isDark: isDark,
              )
            : null,
      );
    } else if (state.lastRestorableLocation != null) {
      child = ResumeSessionCard(
        location: state.lastRestorableLocation!,
        isDark: isDark,
        isKids: state.isKids,
      );
    } else {
      child = NextBestActionCard(
        state: state,
        isDark: isDark,
        isKids: state.isKids,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: child,
    );
  }
}
