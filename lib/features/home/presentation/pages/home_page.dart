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
import '../../domain/services/home_primary_action_resolver.dart';
import '../theme/home_skin.dart';
import '../widgets/glass_panel.dart';
import '../widgets/home_activity_feed.dart';
import '../widgets/home_ayah_of_day.dart';
import '../widgets/home_background.dart';
import '../widgets/home_micro_review_card.dart';
import '../widgets/home_continue_card.dart';
import '../widgets/home_contextual_slot.dart';
import '../widgets/home_first_run.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/home_night_header.dart';
import '../widgets/home_parent_children.dart';
import '../widgets/home_start_khatmah_card.dart';
import '../widgets/home_unified_progress.dart';
import '../widgets/next_best_action_card.dart';
import '../widgets/resume_session_card.dart';
import '../widgets/staggered_fade_slide.dart';

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
class HomeLoadedView extends StatefulWidget {
  const HomeLoadedView({
    super.key,
    required this.state,
    required this.skin,
  });

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  State<HomeLoadedView> createState() => _HomeLoadedViewState();
}

class _HomeLoadedViewState extends State<HomeLoadedView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.skin.isDark;
    final journeyEnabled =
        JourneyFeatureFlags.unifiedJourneyEnabled && widget.state.unifiedJourneyEnabled;
    return RefreshIndicator(
      color: widget.skin.accent,
      onRefresh: () => context.read<HomeCubit>().load(),
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final offset = _scrollController.hasClients
                    ? _scrollController.offset
                    : 0.0;
                return HomeNightHeader(
                  state: widget.state,
                  skin: widget.skin,
                  parallaxOffset: offset,
                );
              },
            ),
          ),
          if (widget.state.isRefreshing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (widget.state.isFirstRun)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.md,
                  AppSpacing.pagePadding,
                  0,
                ),
                child: GlassPanel(
                  skin: widget.skin,
                  child: HomeFirstRun(skin: widget.skin),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: StaggeredFadeSlide(
                delay: const Duration(milliseconds: 0),
                child: _PrimaryAction(state: widget.state, skin: widget.skin),
              ),
            ),
            if (journeyEnabled &&
                widget.state.continueRecitation == null &&
                const HomePrimaryActionResolver().resolve(
                      unifiedJourneyEnabled: journeyEnabled,
                      hasContinueRecitation: false,
                      heroPriority: widget.state.heroAction?.priority,
                    ) ==
                    HomePrimaryActionKind.journeyHero)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeStartKhatmahCard(skin: widget.skin, isDark: isDark),
                ),
              ),
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: widget.state.activeSlot != null
                    ? Padding(
                        key: ValueKey(widget.state.activeSlot!.kind),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pagePadding,
                          AppSpacing.md,
                          AppSpacing.pagePadding,
                          0,
                        ),
                        child: HomeContextualSlot(state: widget.state, skin: widget.skin),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_slot')),
              ),
            ),
            if (widget.state.familyChildren.isNotEmpty)
              SliverToBoxAdapter(
                child: StaggeredFadeSlide(
                  delay: const Duration(milliseconds: 160),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.md,
                      AppSpacing.pagePadding,
                      0,
                    ),
                    child: HomeParentChildren(
                      children: widget.state.familyChildren,
                      skin: widget.skin,
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: StaggeredFadeSlide(
                delay: const Duration(milliseconds: 240),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeUnifiedProgress(state: widget.state, skin: widget.skin),
                ),
              ),
            ),
            // "لمحة مراجعة": quiet surprise-recall ayah; renders nothing for
            // users without memorized ayahs.
            SliverToBoxAdapter(
              child: StaggeredFadeSlide(
                delay: const Duration(milliseconds: 280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeMicroReviewCard(skin: widget.skin),
                ),
              ),
            ),
            if (widget.state.ayahOfDay != null)
              SliverToBoxAdapter(
                child: StaggeredFadeSlide(
                  delay: const Duration(milliseconds: 320),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pagePadding,
                      AppSpacing.md,
                      AppSpacing.pagePadding,
                      0,
                    ),
                    child: HomeAyahOfDayCard(
                      ayah: widget.state.ayahOfDay!,
                      skin: widget.skin,
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: StaggeredFadeSlide(
                delay: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pagePadding,
                    AppSpacing.md,
                    AppSpacing.pagePadding,
                    0,
                  ),
                  child: HomeActivityFeed(state: widget.state, skin: widget.skin),
                ),
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
                  color: widget.skin.textSecondary,
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
  const _PrimaryAction({required this.state, required this.skin});

  final HomeLoaded state;
  final HomeSkin skin;

  @override
  Widget build(BuildContext context) {
    final isDark = skin.isDark;
    final journeyEnabled =
        JourneyFeatureFlags.unifiedJourneyEnabled && state.unifiedJourneyEnabled;
    const resolver = HomePrimaryActionResolver();
    final kind = resolver.resolve(
      unifiedJourneyEnabled: journeyEnabled,
      hasContinueRecitation: state.continueRecitation != null,
      heroPriority: state.heroAction?.priority,
    );
    Widget child;
    if (kind == HomePrimaryActionKind.khatmahContinue) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeContinueCard(recitation: state.continueRecitation!, skin: skin),
          if (resolver.shouldShowUrgentJourneyBelowKhatmah(
            unifiedJourneyEnabled: journeyEnabled,
            hasContinueRecitation: true,
            heroAction: state.heroAction,
          )) ...[
            const SizedBox(height: AppSpacing.md),
            _JourneyHeroAction(state: state, isDark: isDark),
          ],
        ],
      );
    } else if (kind == HomePrimaryActionKind.startKhatmah &&
        journeyEnabled) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeStartKhatmahCard(skin: skin, isDark: isDark),
          if (state.heroAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            _JourneyHeroAction(state: state, isDark: isDark),
          ],
        ],
      );
    } else {
      // Interim (Tasks 1-3): preserves today's rendering exactly.
      // Task 5 replaces the startKhatmah case with HomeStartKhatmahCard
      // and adds the invitation below the journey hero (plan step 3.4).
      if (journeyEnabled &&
          state.heroAction != null) {
        child = _JourneyHeroAction(state: state, isDark: isDark);
      } else if (state.lastRestorableLocation != null) {
        child = ResumeSessionCard(
          location: state.lastRestorableLocation!,
          skin: skin,
        );
      } else {
        child = NextBestActionCard(
          state: state,
          isKids: state.isKids,
          skin: skin,
        );
      }
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

class _JourneyHeroAction extends StatelessWidget {
  const _JourneyHeroAction({required this.state, required this.isDark});

  final HomeLoaded state;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final action = state.heroAction!;
    final data = const UnifiedJourneyActionMapper().map(context, action);
    return HomeHeroSection(
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
  }
}
