import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/kids_child_policy.dart';

/// Session-goal choices offered to the guardian (minutes).
const List<int> kKidsSessionGoalChoices = [6, 8, 10];

/// Dropdown value standing for "no override" (a null session goal: the
/// age-band default). Never a valid goal (goals are 1..60).
const int _kAgeDefaultGoal = 0;

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
    // A null goal is the age-band default, shown as such (never as 6).
    final current = policy.sessionGoalMinutes;
    final goal = current ?? _kAgeDefaultGoal;
    final goalChoices = {
      ...kKidsSessionGoalChoices,
      ?current,
    }.toList()..sort();
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
                DropdownMenuItem(
                  value: _kAgeDefaultGoal,
                  child: Text(
                    l10n.kidsSessionGoalAgeDefault,
                    key: const ValueKey('kids-policy-session-goal-age-default'),
                  ),
                ),
                for (final minutes in goalChoices)
                  DropdownMenuItem(
                    value: minutes,
                    child: Text(l10n.kidsSessionGoalValue(minutes)),
                  ),
              ],
              onChanged: enabled
                  ? (minutes) {
                      if (minutes == null || minutes == goal) return;
                      onChanged(
                        minutes == _kAgeDefaultGoal
                            ? policy.copyWith(clearSessionGoalMinutes: true)
                            : policy.copyWith(sessionGoalMinutes: minutes),
                      );
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
