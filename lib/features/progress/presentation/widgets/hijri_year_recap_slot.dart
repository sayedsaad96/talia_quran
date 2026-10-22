import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubits/hijri_year_recap_cubit.dart';
import 'hijri_year_recap_card.dart';

/// Gates construction before the recap Cubit can read account-owned data.
class HijriYearRecapSlot extends StatelessWidget {
  const HijriYearRecapSlot({
    super.key,
    required this.enabled,
    required this.isAdult,
    this.padding = EdgeInsets.zero,
  });

  /// Spacing around the card. Applied only while the card is visible so a
  /// hidden recap leaves no blank gap.
  final EdgeInsetsGeometry padding;

  final bool enabled;
  final bool isAdult;

  @override
  Widget build(BuildContext context) {
    if (!enabled || !isAdult) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) =>
          getIt<HijriYearRecapCubit>()..load(enabled: true, isAdult: true),
      child: BlocBuilder<HijriYearRecapCubit, HijriYearRecapState>(
        builder: (context, state) => state.recap == null
            ? const SizedBox.shrink()
            : Padding(
                padding: padding,
                child: HijriYearRecapCard(
                  recap: state.recap!,
                  onDismiss: context.read<HijriYearRecapCubit>().dismiss,
                ),
              ),
      ),
    );
  }
}
