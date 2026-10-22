import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/l10n/localization_helpers.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/memorization_entities.dart';

/// What the guardian wrote: the gift title and, optionally, the surah whose
/// completion opens it.
class GuardianPromiseDraft {
  const GuardianPromiseDraft(this.title, this.milestoneSurahId);

  final String title;
  final int? milestoneSurahId;
}

/// Add-gift dialog for the child on this device: a free promise text (at most
/// [ParentReward.titleMaxLength] characters), a few neutral examples and an
/// optional "when a surah is completed" condition. [surahIds] are the surahs
/// the child can choose from; empty hides the condition.
class GuardianPromiseDialog extends StatefulWidget {
  const GuardianPromiseDialog({super.key, required this.surahIds});

  final List<int> surahIds;

  @override
  State<GuardianPromiseDialog> createState() => _GuardianPromiseDialogState();
}

class _GuardianPromiseDialogState extends State<GuardianPromiseDialog> {
  final _controller = TextEditingController();
  int? _surahId;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = context.l10n.fieldRequired);
      return;
    }
    Navigator.pop(context, GuardianPromiseDraft(title, _surahId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final examples = [
      l10n.promiseExample1,
      l10n.promiseExample2,
      l10n.promiseExample3,
    ];
    return AlertDialog(
      title: Text(l10n.parentDashboardRemoteRewardTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: ParentReward.titleMaxLength,
              decoration: InputDecoration(
                hintText: l10n.parentDashboardRewardHint,
                errorText: _errorText,
                counterText: '',
              ),
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final example in examples)
                  ActionChip(
                    label: Text(example),
                    onPressed: () => setState(() {
                      _controller.text = example;
                      _errorText = null;
                    }),
                  ),
              ],
            ),
            if (widget.surahIds.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<int?>(
                key: const ValueKey('guardian-promise-surah'),
                initialValue: _surahId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.promiseLinkSurah),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(l10n.promiseNoCondition),
                  ),
                  for (final id in widget.surahIds)
                    DropdownMenuItem<int?>(
                      value: id,
                      child: Text(context.localizedSurahName(id)),
                    ),
                ],
                onChanged: (value) => setState(() => _surahId = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('guardian-promise-save'),
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
