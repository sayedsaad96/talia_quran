import '../presentation/cubits/good_impact_cubit.dart';

/// Refreshes only after an eligible app resume; the cubit owns throttling.
class GoodImpactIndicatorController {
  const GoodImpactIndicatorController(this.cubit);
  final GoodImpactCubit cubit;
  Future<void> onResume() => cubit.refresh();
}
