import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../home/presentation/cubits/home_cubit.dart';
import '../../../home/presentation/theme/home_skin.dart';
import '../../adult_journey_feature_flags.dart';
import '../adult_journey_context_adapter.dart';
import '../cubits/adult_journey_cubit.dart';
import '../cubits/adult_journey_state.dart';
import 'adult_journey_setup_invite_card.dart';
import 'adult_journey_setup_sheet.dart';
import 'adult_today_budget_card.dart';

/// The single sliver Home mounts for the adult-journey overlay. It renders
/// nothing (and builds no cubit) unless personalization is on, and nothing
/// until a confirmed adult's preferences have loaded.
class AdultJourneyHomeSlot extends StatelessWidget {
  const AdultJourneyHomeSlot({super.key});

  static bool get _enabled =>
      getIt.isRegistered<AdultJourneyFlags>() &&
      getIt.isRegistered<AdultJourneyCubit>() &&
      getIt<AdultJourneyFlags>().isEnabled(AdultJourneyFeature.personalization);

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return BlocProvider<AdultJourneyCubit>(
      create: (_) => getIt<AdultJourneyCubit>(),
      child: const _SlotBody(),
    );
  }
}

class _SlotBody extends StatefulWidget {
  const _SlotBody();

  @override
  State<_SlotBody> createState() => _SlotBodyState();
}

class _SlotBodyState extends State<_SlotBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _feed(context.read<HomeCubit>().state);
    });
  }

  void _feed(HomeState home) {
    if (home is! HomeLoaded) return;
    context.read<AdultJourneyCubit>().refreshContext(
      buildAdultJourneyContext(
        state: home,
        ownerId: getIt<RecordOwnerProvider>().currentOwnerId,
        now: DateTime.now(),
      ),
    );
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
    if (!showInvite && !state.todayBudgetEnabled) {
      return const SizedBox.shrink();
    }
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
          if (showInvite)
            AdultJourneySetupInviteCard(
              skin: skin,
              onPersonalize: () => showAdultJourneySetupSheet(context, cubit),
              onLater: cubit.snoozeSetup,
            ),
          if (showInvite && state.todayBudgetEnabled)
            const SizedBox(height: AppSpacing.md),
          if (state.todayBudgetEnabled)
            AdultTodayBudgetCard(state: state, skin: skin),
        ],
      ),
    );
  }
}
