import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/kids_encouragement.dart';
import 'encouragement_labels.dart';

class ChildEncouragementCard extends StatelessWidget {
  const ChildEncouragementCard({
    super.key,
    required this.encouragement,
    required this.onDone,
  });
  final KidsEncouragement encouragement;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.encouragementInboxTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Image.asset(
            encouragement.sticker.assetPath,
            width: 80,
            height: 80,
            semanticLabel: encouragementStickerLabel(
              context.l10n,
              encouragement.sticker,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            encouragementMessageLabel(context.l10n, encouragement.message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            key: const ValueKey('encouragement-done'),
            onPressed: onDone,
            child: Text(context.l10n.encouragementDone),
          ),
        ],
      ),
    ),
  );
}
