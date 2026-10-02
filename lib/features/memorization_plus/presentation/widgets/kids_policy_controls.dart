import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_child_policy.dart';

/// Session-goal choices offered to the guardian (minutes).
const List<int> kKidsSessionGoalChoices = [6, 8, 10];

/// Guardian controls for the kids child policy: reduce motion, missions per
/// day (1..3), home missions and the session goal. Stateless: every change
/// is reported through [onChanged] with the edited policy (same version),
/// and the caller saves it through the dashboard cubit.
class KidsPolicyControls extends StatelessWidget {
  const KidsPolicyControls({
    super.key,
    required this.policy,
    required this.onChanged,
  });

  final KidsChildPolicy policy;
  final ValueChanged<KidsChildPolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final goal = policy.sessionGoalMinutes ?? kKidsSessionGoalChoices.first;
    final goalChoices = {...kKidsSessionGoalChoices, goal}.toList()..sort();
    // Own transparent Material so the tiles' ink shows on a decorated card.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            key: const ValueKey('kids-policy-reduce-motion'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kidsPolicyReduceMotion),
            value: policy.reduceMotion,
            onChanged: (value) =>
                onChanged(policy.copyWith(reduceMotion: value)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              l10n.kidsPolicyMaxSuggestions,
              style: AppTypography.bodyLarge,
            ),
          ),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (
                var count = kKidsMinDailySuggestions;
                count <= kKidsMaxDailySuggestions;
                count++
              )
                ButtonSegment<int>(
                  value: count,
                  label: Text(
                    '$count',
                    key: ValueKey('kids-policy-max-$count'),
                  ),
                ),
            ],
            selected: {
              clampKidsMaxDailySuggestions(policy.maxDailySuggestions),
            },
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              onChanged(policy.copyWith(maxDailySuggestions: selection.first));
            },
          ),
          SwitchListTile(
            key: const ValueKey('kids-policy-home-missions'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kidsPolicyHomeMissions),
            value: policy.homeMissionsEnabled,
            onChanged: (value) =>
                onChanged(policy.copyWith(homeMissionsEnabled: value)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kidsSessionGoalTitle),
            trailing: DropdownButton<int>(
              key: const ValueKey('kids-policy-session-goal'),
              value: goal,
              items: [
                for (final minutes in goalChoices)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(l10n.kidsSessionGoalValue(minutes)),
                  ),
              ],
              onChanged: (minutes) {
                if (minutes == null || minutes == policy.sessionGoalMinutes) {
                  return;
                }
                onChanged(policy.copyWith(sessionGoalMinutes: minutes));
              },
            ),
          ),
        ],
      ),
    );
  }
}
