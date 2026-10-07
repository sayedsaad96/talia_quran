import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/talia_icons.dart';
import '../utils/locale_number_formatter.dart';
import '../utils/locale_numeric_input_formatter.dart';

/// Flutter's built-in time input parses only ASCII digits. Keep its dial and
/// provide localized editable fields through the same dialog result.
Future<TimeOfDay?> showLocaleTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TransitionBuilder? builder,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  initialEntryMode: TimePickerEntryMode.dialOnly,
  builder: (dialogContext, child) {
    final picker = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child!,
        TextButton.icon(
          icon: const Icon(TaliaIcons.keyboard),
          label: Text(
            MaterialLocalizations.of(dialogContext).inputTimeModeButtonLabel,
          ),
          onPressed: () async {
            final selected = await showDialog<TimeOfDay>(
              context: dialogContext,
              builder: (_) => _NumericTimeDialog(initialTime: initialTime),
            );
            if (selected != null && dialogContext.mounted) {
              Navigator.of(dialogContext).pop(selected);
            }
          },
        ),
      ],
    );
    final centered = Center(child: picker);
    return builder?.call(dialogContext, centered) ?? centered;
  },
);

class _NumericTimeDialog extends StatefulWidget {
  const _NumericTimeDialog({required this.initialTime});
  final TimeOfDay initialTime;

  @override
  State<_NumericTimeDialog> createState() => _NumericTimeDialogState();
}

class _NumericTimeDialogState extends State<_NumericTimeDialog> {
  final _form = GlobalKey<FormState>();
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  String? _language;
  late DayPeriod _period = widget.initialTime.period;

  bool get _use24 => MediaQuery.alwaysUse24HourFormatOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_language == null) {
      final hour = _use24
          ? widget.initialTime.hour
          : widget.initialTime.hourOfPeriod;
      _hour.text = '${!_use24 && hour == 0 ? 12 : hour}';
      _minute.text = widget.initialTime.minute.toString().padLeft(2, '0');
    }
    _language = language;
    for (final controller in [_hour, _minute]) {
      controller.value = controller.value.copyWith(
        text: LocaleNumberFormatter.format(controller.text, language),
      );
    }
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  int? _parse(String? digits) =>
      int.tryParse(LocaleNumberFormatter.western(digits ?? ''));

  Widget _field(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) {
    final material = MaterialLocalizations.of(context);
    return Expanded(
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
          LengthLimitingTextInputFormatter(2),
          LocaleNumericInputFormatter(_language!),
        ],
        validator: (digits) {
          final number = _parse(digits);
          return number == null || number < min || number > max
              ? material.invalidTimeLabel
              : null;
        },
      ),
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    var hour = _parse(_hour.text)!;
    if (!_use24) hour = hour % 12 + (_period == DayPeriod.pm ? 12 : 0);
    Navigator.of(
      context,
    ).pop(TimeOfDay(hour: hour, minute: _parse(_minute.text)!));
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(material.timePickerInputHelpText),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _field(
                  _hour,
                  material.timePickerHourLabel,
                  _use24 ? 0 : 1,
                  _use24 ? 23 : 12,
                ),
                const SizedBox(width: 16),
                _field(_minute, material.timePickerMinuteLabel, 0, 59),
              ],
            ),
            if (!_use24)
              DropdownButton<DayPeriod>(
                value: _period,
                items: [
                  DropdownMenuItem(
                    value: DayPeriod.am,
                    child: Text(material.anteMeridiemAbbreviation),
                  ),
                  DropdownMenuItem(
                    value: DayPeriod.pm,
                    child: Text(material.postMeridiemAbbreviation),
                  ),
                ],
                onChanged: (period) => setState(() => _period = period!),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        TextButton(onPressed: _submit, child: Text(material.okButtonLabel)),
      ],
    );
  }
}
