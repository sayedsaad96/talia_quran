import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';

/// Asks whether memorization progress made as a guest should move to the
/// signed-in account. Resolves to true only when the user chooses to import.
Future<bool> showGuestImportDialog(BuildContext context) async {
  final l10n = context.l10n;
  final shouldImport = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.guestImportTitle),
      content: Text(l10n.guestImportBody),
      actions: [
        TextButton(
          key: const Key('guest_import_later_button'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.guestImportLater),
        ),
        FilledButton(
          key: const Key('guest_import_confirm_button'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.guestImportConfirm),
        ),
      ],
    ),
  );
  return shouldImport == true;
}
