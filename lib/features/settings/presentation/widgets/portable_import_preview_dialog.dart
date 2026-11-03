import 'package:flutter/material.dart';

import '../../../../core/backup/portable_signed_in_import.dart';
import '../../../../core/extensions/context_extensions.dart';

/// Null cancels; a confirmed false imports bookmarks without the checkpoint.
class PortableImportPreviewDialog extends StatefulWidget {
  const PortableImportPreviewDialog({super.key, required this.preview});

  final BookmarkImportPreview preview;

  @override
  State<PortableImportPreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<PortableImportPreviewDialog> {
  bool _importCheckpoint = false;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.backupPortablePreview),
    content: _content(context),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _importCheckpoint),
        child: Text(context.l10n.backupPortableConfirm),
      ),
    ],
  );

  Widget _content(BuildContext context) {
    final preview = widget.preview;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(context.l10n.protectionImportScope),
          Text(
            context.l10n.backupPortableSummary(
              preview.additions.length,
              preview.existing.length,
              preview.deletedConflicts.length,
              preview.invalid.length,
            ),
          ),
          if (preview.checkpoint != null) ...[
            Text(
              '${context.l10n.protectionCheckpoint}: '
              '${preview.currentCheckpoint?.pageNumber ?? '—'}',
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${context.l10n.backupPortableCheckpoint} '
                '(${preview.checkpoint!.pageNumber})',
              ),
              value: _importCheckpoint,
              onChanged: (value) =>
                  setState(() => _importCheckpoint = value ?? false),
            ),
          ],
        ],
      ),
    );
  }
}
