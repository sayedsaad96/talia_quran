import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/fallback_pop_scope.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/entities/plan_details.dart';
import '../cubits/plan_details_cubit.dart';
import '../widgets/plan_details_progress.dart';
import '../widgets/plan_details_reviews.dart';
import '../widgets/plan_details_settings.dart';

class PlanDetailsPage extends StatelessWidget {
  const PlanDetailsPage({super.key, this.cubitOverride});
  final PlanDetailsCubit? cubitOverride;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => (cubitOverride ?? getIt<PlanDetailsCubit>())..load(),
    child: const _PlanDetailsView(),
  );
}

class _PlanDetailsView extends StatefulWidget {
  const _PlanDetailsView();

  @override
  State<_PlanDetailsView> createState() => _PlanDetailsViewState();
}

class _PlanDetailsViewState extends State<_PlanDetailsView> {
  bool _openingSession = false;

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) await context.read<PlanDetailsCubit>().load();
  }

  Future<void> _start() async {
    if (_openingSession) return;
    setState(() => _openingSession = true);
    try {
      final route = await context.read<PlanDetailsCubit>().sessionLocation();
      if (mounted &&
          route != null &&
          route.startsWith(AppRoutes.memorizationV2Session)) {
        await _open(route);
      }
    } finally {
      if (mounted) setState(() => _openingSession = false);
    }
  }

  void _back() {
    context.go(AppRoutes.memorizationPlusCustomPlan);
  }

  @override
  Widget build(BuildContext context) => FallbackPopScope(
    fallbackLocation: AppRoutes.memorizationPlusCustomPlan,
    child: Scaffold(
      backgroundColor: context.tokens.background,
      appBar: AppBar(
        title: Text(context.l10n.planDetailsTitle),
        leading: IconButton(
          onPressed: _back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const BackButtonIcon(),
        ),
      ),
      body: BlocBuilder<PlanDetailsCubit, PlanDetailsState>(
        builder: (context, state) => switch (state) {
          PlanDetailsLoading() => const LoadingWidget(),
          PlanDetailsError() => ErrorStateWidget(
            message: context.l10n.errorOccurred,
            onRetry: context.read<PlanDetailsCubit>().load,
          ),
          PlanDetailsEmpty() => EmptyStateWidget(
            icon: TaliaIcons.calendarEdit,
            message: context.l10n.dailyPlanNoPlanTitle,
            actionLabel: context.l10n.dailyPlanCreatePlanAction,
            onAction: () => _open(
              '${AppRoutes.memorizationPlusCustomPlan}?returnToPlanDetails=true',
            ),
          ),
          PlanDetailsLoaded(:final details) => _body(details),
        },
      ),
    ),
  );

  Widget _body(PlanDetails details) => RefreshIndicator(
    onRefresh: context.read<PlanDetailsCubit>().load,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                details.plan.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(context.l10n.planDetailsSubtitle),
              const SizedBox(height: AppSpacing.md),
              _actions(details),
              const SizedBox(height: AppSpacing.md),
              PlanDetailsProgress(details: details),
              PlanDetailsToday(details: details),
              PlanDetailsReviews(details: details),
              PlanDetailsSettings(plan: details.plan),
              PlanDetailsSurahs(details: details),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _actions(PlanDetails details) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton.icon(
        key: const Key('plan_details_start_session'),
        onPressed: details.canStartSession && !_openingSession ? _start : null,
        icon: const Icon(TaliaIcons.play),
        label: Text(context.l10n.planDetailsStartSession),
      ),
      const SizedBox(height: AppSpacing.sm),
      _secondaryActions(),
    ],
  );

  Widget _secondaryActions() => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      OutlinedButton.icon(
        key: const Key('plan_details_daily'),
        onPressed: () => _open(AppRoutes.memorizationPlusDailyPlan),
        icon: const Icon(TaliaIcons.checklist),
        label: Text(context.l10n.dailyPlanHeaderTitle),
      ),
      TextButton.icon(
        key: const Key('plan_details_edit'),
        onPressed: () => _open(
          '${AppRoutes.memorizationPlusCustomPlan}?returnToPlanDetails=true',
        ),
        icon: const Icon(TaliaIcons.edit),
        label: Text(context.l10n.planDetailsEdit),
      ),
      TextButton.icon(
        key: const Key('plan_details_exit'),
        onPressed: _back,
        icon: const Icon(TaliaIcons.settingsSmart),
        label: Text(context.l10n.planDetailsExitToSetup),
      ),
      TextButton(
        key: const Key('plan_details_other_options'),
        onPressed: () => _open(AppRoutes.memorizationOptions),
        child: Text(context.l10n.planDetailsOtherOptions),
      ),
    ],
  );
}
