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
    this.enabled = true,
  });

  final KidsChildPolicy policy;
  final ValueChanged<KidsChildPolicy> onChanged;

  /// False while a save is in flight: every control is inert.
  final bool enabled;

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
            onChanged: enabled
                ? (value) => onChanged(policy.copyWith(reduceMotion: value))
                : null,
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
            onSelectionChanged: enabled
                ? (selection) {
                    if (selection.isEmpty) return;
                    onChanged(
                      policy.copyWith(maxDailySuggestions: selection.first),
                    );
                  }
                : null,
          ),
          SwitchListTile(
            key: const ValueKey('kids-policy-home-missions'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.kidsPolicyHomeMissions),
            value: policy.homeMissionsEnabled,
            onChanged: enabled
                ? (value) =>
                      onChanged(policy.copyWith(homeMissionsEnabled: value))
                : null,
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
              onChanged: enabled
                  ? (minutes) {
                      if (minutes == null ||
                          minutes == policy.sessionGoalMinutes) {
                        return;
                      }
                      onChanged(policy.copyWith(sessionGoalMinutes: minutes));
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// [KidsPolicyControls] that disables itself while [onSave] runs, so a
/// rapid second edit cannot send a CAS with the same (now stale) version.
class KidsPolicyEditor extends StatefulWidget {
  const KidsPolicyEditor({
    super.key,
    required this.policy,
    required this.onSave,
  });

  final KidsChildPolicy policy;
  final Future<void> Function(KidsChildPolicy policy) onSave;

  @override
  State<KidsPolicyEditor> createState() => _KidsPolicyEditorState();
}

class _KidsPolicyEditorState extends State<KidsPolicyEditor> {
  bool _saving = false;

  Future<void> _save(KidsChildPolicy policy) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(policy);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => KidsPolicyControls(
    policy: widget.policy,
    enabled: !_saving,
    onChanged: _save,
  );
}
