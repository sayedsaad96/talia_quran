import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/kids_journey_path_definition.dart';

/// Three-way choice of the child's memorization path. Callers show it only
/// while the Quran journey flag is on.
class KidsJourneyPathSelector extends StatelessWidget {
  const KidsJourneyPathSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final KidsJourneyPathId value;
  final ValueChanged<KidsJourneyPathId> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = {
      KidsJourneyPathId.juzAmmaAdventure: l10n.kidsJourneyPathAdventure,
      KidsJourneyPathId.quranFromNas: l10n.kidsJourneyPathFromNas,
      KidsJourneyPathId.quranFromFatiha: l10n.kidsJourneyPathFromFatiha,
    };
    return RadioGroup<KidsJourneyPathId>(
      groupValue: value,
      onChanged: (id) {
        if (id != null) onChanged(id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.kidsJourneyPathTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final id in KidsJourneyPathId.values)
            RadioListTile<KidsJourneyPathId>(
              key: Key('kids_journey_path_${id.storageValue}'),
              contentPadding: EdgeInsets.zero,
              value: id,
              title: Text(labels[id]!),
            ),
        ],
      ),
    );
  }
}
