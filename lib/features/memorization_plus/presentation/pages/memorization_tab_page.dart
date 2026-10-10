import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../cubits/memorization_tab_cubit.dart';
import 'memorization_hub_page.dart';
import 'plan_details_page.dart';

class MemorizationTabPage extends StatelessWidget {
  const MemorizationTabPage({super.key, this.cubitOverride});
  final MemorizationTabCubit? cubitOverride;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => (cubitOverride ?? getIt<MemorizationTabCubit>())..load(),
    child: BlocBuilder<MemorizationTabCubit, MemorizationTabState>(
      builder: (context, state) => switch (state) {
        MemorizationTabLoaded(:final showPlan) when showPlan =>
          const PlanDetailsPage(),
        MemorizationTabError() => ErrorStateWidget(
          message: context.l10n.errorOccurred,
          onRetry: () => context.read<MemorizationTabCubit>().load(),
        ),
        MemorizationTabLoading() => const LoadingWidget(),
        MemorizationTabLoaded() => const MemorizationHubPage(),
      },
    ),
  );
}
