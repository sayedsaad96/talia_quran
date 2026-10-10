import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/kids_session_policy.dart';

class KidsHouseSizeSelector extends StatefulWidget {
  const KidsHouseSizeSelector({
    super.key,
    required this.current,
    required this.onSave,
  });
  final int? current;
  final Future<bool> Function(int? count) onSave;

  @override
  State<KidsHouseSizeSelector> createState() => _KidsHouseSizeSelectorState();
}

class _KidsHouseSizeSelectorState extends State<KidsHouseSizeSelector> {
  bool _saving = false;
  bool _failed = false;
  late int _selected = sanitizeKidsAyahsPerHouse(widget.current) ?? 0;

  Future<void> _save(int? selection) async {
    if (selection == null || _saving || selection == _selected) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      final saved = await widget.onSave(selection == 0 ? null : selection);
      if (mounted) {
        setState(() {
          if (saved) _selected = selection;
          _failed = !saved;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.l10n.kidsHouseSizeTitle,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(context.l10n.kidsHouseSizeHint),
      DropdownButton<int>(
        key: const Key('kids_house_size'),
        isExpanded: true,
        value: _selected,
        items: [
          DropdownMenuItem(
            value: 0,
            child: Text(context.l10n.kidsSessionGoalAgeDefault),
          ),
          for (var count = 1; count <= 10; count++)
            DropdownMenuItem(value: count, child: Text(context.numText(count))),
        ],
        onChanged: _saving ? null : _save,
      ),
      if (_saving) const LinearProgressIndicator(),
      if (_failed) Text(context.l10n.errorOccurred),
    ],
  );
}
