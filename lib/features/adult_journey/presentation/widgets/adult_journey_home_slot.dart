import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../home/presentation/cubits/home_cubit.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../adult_journey_feature_flags.dart';
import '../adult_journey_context_adapter.dart';
import '../cubits/adult_journey_cubit.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_return_card.dart';
import 'adult_journey_setup_invite_card.dart';
import 'adult_journey_setup_sheet.dart';
import 'adult_today_budget_card.dart';

/// The single sliver Home mounts for the adult-journey overlay. It renders
/// nothing (and builds no cubit) unless personalization is on, and nothing
/// until a confirmed adult's preferences have loaded.
class AdultJourneyHomeSlot extends StatelessWidget {
  const AdultJourneyHomeSlot({super.key, this.isHomeForeground});

  /// Whether Home is what the user sees right now; defaults to
  /// [adultJourneyHomeIsForeground]. Injectable for tests.
  final bool Function(BuildContext context)? isHomeForeground;

  static bool get _enabled =>
      getIt.isRegistered<AdultJourneyFlags>() &&
      getIt.isRegistered<AdultJourneyCubit>() &&
      getIt<AdultJourneyFlags>().isEnabled(AdultJourneyFeature.personalization);

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return BlocProvider<AdultJourneyCubit>(
      create: (_) => getIt<AdultJourneyCubit>(),
      child: _SlotBody(
        isHomeForeground: isHomeForeground ?? adultJourneyHomeIsForeground,
      ),
    );
  }
}

/// Home is in front of the user: the app is resumed, the shell's selected
/// branch is Home (index 0), and Home's route is the top route — not a hidden
/// tab of the `indexedStack` or a page pushed over it (spec §4.3).
bool adultJourneyHomeIsForeground(BuildContext context) {
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
    return false;
  }
  final shell = StatefulNavigationShell.maybeOf(context);
  if (shell != null && shell.currentIndex != 0) return false;
  return _everyEnclosingRouteIsCurrent(context);
}

/// Pages opened from Home (reader, sessions, sheets, dialogs) are pushed on
/// the ROOT navigator, above the shell, so Home's own branch route stays
/// "current" under them. Walk up through every enclosing navigator: Home is
/// in front only if each route on the way is the top of its navigator.
bool _everyEnclosingRouteIsCurrent(BuildContext context) {
  BuildContext? current = context;
  while (current != null) {
    final route = ModalRoute.of(current);
    if (route == null) return true;
    if (!route.isCurrent) return false;
    final navigatorContext = route.navigator?.context;
    if (navigatorContext == null || identical(navigatorContext, current)) {
      return true;
    }
    current = navigatorContext;
  }
  return true;
}

class _SlotBody extends StatefulWidget {
  const _SlotBody({required this.isHomeForeground});

  final bool Function(BuildContext context) isHomeForeground;

  @override
  State<_SlotBody> createState() => _SlotBodyState();
}

/// Feeds each Home load to the cubit and evaluates a visit at exactly two
/// points: after a Home load was applied, when the app resumes, and after any
/// navigation (popping back to Home, switching back to its tab). The
/// foreground check decides; the repository writes at most one visit per
/// local day and owner, so repeated checks cost no writes.
class _SlotBodyState extends State<_SlotBody> with WidgetsBindingObserver {
  Listenable? _routerDelegate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _feed(context.read<HomeCubit>().state);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final delegate = GoRouter.maybeOf(context)?.routerDelegate;
    if (identical(delegate, _routerDelegate)) return;
    _routerDelegate?.removeListener(_onNavigation);
    _routerDelegate = delegate?..addListener(_onNavigation);
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onNavigation);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Routes settle after the frame; check Home's position then.
  void _onNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRecordVisit());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<AdultJourneyCubit>().refreshDay();
    _maybeRecordVisit();
  }

  Future<void> _feed(HomeState home) async {
    if (home is! HomeLoaded) return;
    await context.read<AdultJourneyCubit>().refreshContext(
      buildAdultJourneyContext(
        state: home,
        ownerId: getIt<RecordOwnerProvider>().currentOwnerId,
        now: DateTime.now(),
      ),
    );
    _maybeRecordVisit();
  }

  void _maybeRecordVisit() {
    if (!mounted || !widget.isHomeForeground(context)) return;
    unawaited(context.read<AdultJourneyCubit>().recordHomeVisit());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listener: (_, home) => _feed(home),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, home) =>
            BlocBuilder<AdultJourneyCubit, AdultJourneyState>(
              builder: (context, state) {
                if (home is! HomeLoaded || !state.isVisible) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: _content(context, home, state),
                );
              },
            ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    HomeLoaded home,
    AdultJourneyState state,
  ) {
    final skin = HomeSkin.of(context);
    final cubit = context.read<AdultJourneyCubit>();
    // One welcome card: Home's own first-run card wins over the invite.
    final showInvite = state.setupInviteDue && !home.isFirstRun;
    final cards = <Widget>[
      if (state.returnOffer != null) AdultReturnCard(state: state, skin: skin),
      if (showInvite)
        AdultJourneySetupInviteCard(
          skin: skin,
          onPersonalize: () => showAdultJourneySetupSheet(context, cubit),
          onLater: cubit.snoozeSetup,
          error: state.errorFor(AdultJourneyErrorSource.snooze),
        ),
      if (state.todayBudgetEnabled)
        AdultTodayBudgetCard(state: state, skin: skin),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            card,
          ],
        ],
      ),
    );
  }
}
