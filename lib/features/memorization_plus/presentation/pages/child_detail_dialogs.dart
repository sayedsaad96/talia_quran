part of 'child_detail_page.dart';

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hintText,
    required this.actionLabel,
    this.initialText = '',
  });

  static const int maxLength = 50;

  final String title;
  final String hintText;
  final String actionLabel;
  final String initialText;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return context.l10n.fieldRequired;
    if (trimmed.length > _TextInputDialog.maxLength) {
      return context.l10n.fieldTooLong(
        LocaleNumberFormatter.format(
          (_TextInputDialog.maxLength).toString(),
          context.l10n.localeName,
        ),
      );
    }
    return null;
  }

  void _submit() {
    final error = _validate(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: _TextInputDialog.maxLength,
          decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: _errorText,
            counterText: '',
          ),
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}

typedef _ChildIdentityDraft = ({String nickname, int age});

/// Name + age editor for a linked child, validated with the same
/// [ChildIdentityPolicy] the server enforces.
class _ChildIdentityDialog extends StatefulWidget {
  const _ChildIdentityDialog({required this.initialName, this.initialAge});

  final String initialName;
  final int? initialAge;

  @override
  State<_ChildIdentityDialog> createState() => _ChildIdentityDialogState();
}

class _ChildIdentityDialogState extends State<_ChildIdentityDialog> {
  late final TextEditingController _nameController;
  int? _age;
  String? _nameError;
  String? _ageError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _age = ChildIdentityPolicy.isValidAge(widget.initialAge)
        ? widget.initialAge
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = context.l10n;
    final name = ChildIdentityPolicy.normalizeNickname(_nameController.text);
    final age = _age;
    final ageValid = ChildIdentityPolicy.isValidAge(age);
    setState(() {
      _nameError = name == null
          ? l10n.childErrorNicknameInvalid(
              LocaleNumberFormatter.format(
                (ChildIdentityPolicy.maxNicknameLength).toString(),
                l10n.localeName,
              ),
            )
          : null;
      _ageError = ageValid
          ? null
          : l10n.childErrorAgeInvalid(
              LocaleNumberFormatter.format(
                (ChildIdentityPolicy.minAge).toString(),
                l10n.localeName,
              ),
              LocaleNumberFormatter.format(
                (ChildIdentityPolicy.maxAge).toString(),
                l10n.localeName,
              ),
            );
    });
    if (name == null || age == null || !ageValid) return;
    Navigator.pop<_ChildIdentityDraft>(context, (nickname: name, age: age));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.childEditIdentity),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: ChildIdentityPolicy.maxNicknameLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.l10n.name,
                errorText: _nameError,
                counterText: '',
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<int>(
              initialValue: _age,
              decoration: InputDecoration(
                labelText: context.l10n.age,
                errorText: _ageError,
              ),
              items: [
                for (
                  var age = ChildIdentityPolicy.minAge;
                  age <= ChildIdentityPolicy.maxAge;
                  age++
                )
                  DropdownMenuItem(
                    value: age,
                    child: Text(
                      context.l10n.childAgeYears(
                        age,
                        LocaleNumberFormatter.format(
                          (age).toString(),
                          context.l10n.localeName,
                        ),
                      ),
                    ),
                  ),
              ],
              onChanged: (value) => setState(() {
                _age = value;
                _ageError = null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
      ],
    );
  }
}
