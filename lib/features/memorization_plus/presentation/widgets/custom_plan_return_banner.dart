import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/talia_icons.dart';

class CustomPlanReturnBanner extends StatelessWidget {
  const CustomPlanReturnBanner({
    super.key,
    required this.planName,
    required this.onReturn,
  });
  final String planName;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.customPlanSelectedTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(planName),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('custom_plan_return_selected'),
            onPressed: onReturn,
            icon: const Icon(TaliaIcons.chevronForward),
            label: Text(context.l10n.customPlanReturnSelected),
          ),
        ],
      ),
    ),
  );
}
