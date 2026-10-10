import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class PlanDetailsSection extends StatelessWidget {
  const PlanDetailsSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    color: context.tokens.card,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    ),
  );
}

class PlanDetailsRow extends StatelessWidget {
  const PlanDetailsRow({
    super.key,
    required this.label,
    required this.value,
    this.valueKey,
  });
  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          key: valueKey,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    ),
  );
}
