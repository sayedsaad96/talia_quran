import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/locale_number_formatter.dart';

class PracticePassageDialog extends StatefulWidget {
  const PracticePassageDialog({super.key, required this.surahAyahCount});

  final int surahAyahCount;

  @override
  State<PracticePassageDialog> createState() => _PracticePassageDialogState();
}

class _PracticePassageDialogState extends State<PracticePassageDialog> {
  String _startText = '1';
  String _countText = '1';
  String? _error;

  void _submit() {
    final start = int.tryParse(LocaleNumberFormatter.western(_startText));
    final count = int.tryParse(LocaleNumberFormatter.western(_countText));
    if (start == null ||
        count == null ||
        start < 1 ||
        count < 1 ||
        start > widget.surahAyahCount ||
        start + count - 1 > widget.surahAyahCount) {
      setState(() => _error = context.l10n.practicePassageInvalid);
      return;
    }
    Navigator.pop(context, (startAyah: start, ayahCount: count));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.practiceChoosePassage),
    content: SingleChildScrollView(child: _fields()),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        key: const Key('practice_start_selected'),
        onPressed: _submit,
        child: Text(context.l10n.startMemorizing),
      ),
    ],
  );

  Widget _fields() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(context.l10n.practicePassageFieldsHint),
      const SizedBox(height: AppSpacing.md),
      TextFormField(
        key: const Key('practice_start_ayah'),
        initialValue: context.numText(1),
        onChanged: (value) => _startText = value,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: context.l10n.practiceStartAyah,
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        key: const Key('practice_ayah_count'),
        initialValue: context.numText(1),
        onChanged: (value) => _countText = value,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: context.l10n.practiceAyahCount),
      ),
    ],
  );
}
