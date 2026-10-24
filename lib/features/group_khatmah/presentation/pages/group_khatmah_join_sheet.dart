import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../cubits/group_khatmah_cubit.dart';
import '../group_khatmah_messages.dart';

class GroupKhatmahJoinSheet extends StatefulWidget {
  const GroupKhatmahJoinSheet({
    super.key,
    required this.cubit,
    required this.isCreate,
  });

  final GroupKhatmahCubit cubit;
  final bool isCreate;

  @override
  State<GroupKhatmahJoinSheet> createState() => _GroupKhatmahJoinSheetState();
}

class _GroupKhatmahJoinSheetState extends State<GroupKhatmahJoinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _first.dispose();
    _name.dispose();
    super.dispose();
  }

  bool _validLabel(String value, int min, int max) {
    final trimmed = value.trim();
    return trimmed.runes.length >= min &&
        trimmed.runes.length <= max &&
        !RegExp(
          r'[\x00-\x1F\x7F-\x9F\u202A-\u202E\u2066-\u2069]',
        ).hasMatch(trimmed);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final first = _first.text.trim();
    final name = _name.text.trim();
    final success = widget.isCreate
        ? await widget.cubit.create(first, name)
        : await widget.cubit.join(first.toUpperCase(), name);
    if (success && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isCreate
                      ? l10n.groupKhatmahCreate
                      : l10n.groupKhatmahJoin,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ..._fields(l10n),
                const SizedBox(height: 16),
                _submitActions(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _submitActions(AppLocalizations l10n) =>
      BlocBuilder<GroupKhatmahCubit, GroupKhatmahState>(
        bloc: widget.cubit,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorCode != null)
              Text(
                localizedGroupKhatmahError(l10n, state.errorCode!),
                key: const Key('group-khatmah-sheet-error'),
              ),
            FilledButton(
              key: const Key('group-khatmah-submit'),
              onPressed: state.busy ? null : _submit,
              child: Text(
                widget.isCreate
                    ? l10n.groupKhatmahCreate
                    : l10n.groupKhatmahJoin,
              ),
            ),
          ],
        ),
      );

  List<Widget> _fields(AppLocalizations l10n) => [
    TextFormField(
      key: const Key('group-khatmah-first-input'),
      controller: _first,
      textCapitalization: widget.isCreate
          ? TextCapitalization.sentences
          : TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: widget.isCreate
            ? l10n.groupKhatmahGroupTitle
            : l10n.groupKhatmahInviteCode,
      ),
      validator: (value) {
        final text = (value ?? '').trim();
        if (widget.isCreate) {
          return _validLabel(text, 1, 80)
              ? null
              : l10n.groupKhatmahInvalidTitle;
        }
        return RegExp(
              r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$',
            ).hasMatch(text.toUpperCase())
            ? null
            : l10n.groupKhatmahInvalidCode;
      },
    ),
    const SizedBox(height: 12),
    TextFormField(
      key: const Key('group-khatmah-name-input'),
      controller: _name,
      decoration: InputDecoration(labelText: l10n.groupKhatmahDisplayName),
      validator: (value) =>
          _validLabel(value ?? '', 2, 24) ? null : l10n.groupKhatmahInvalidName,
    ),
  ];
}
