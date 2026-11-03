import 'package:flutter/material.dart';
import '../../../../core/backup/portable_signed_in_import.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'portable_import_preview_dialog.dart';

/// A separate additive path: this widget can never call the full restorer.
class PortableBackupImportButton extends StatefulWidget {
  const PortableBackupImportButton({
    super.key,
    required this.importer,
    required this.pickFile,
    required this.guardianGate,
    required this.signedIn,
    this.afterImport,
  });
  final PortableSignedInImporter importer;
  final Future<List<int>?> Function() pickFile;
  final Future<bool> Function(BuildContext) guardianGate;
  final bool Function() signedIn;
  final VoidCallback? afterImport;
  @override
  State<PortableBackupImportButton> createState() => _PortableImportState();
}

class _PortableImportState extends State<PortableBackupImportButton> {
  bool _busy = false;
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _import() async {
    if (_busy || !widget.signedIn()) return;
    setState(() => _busy = true);
    try {
      final bytes = await widget.pickFile();
      if (bytes == null || !mounted || !widget.signedIn()) return;
      final preview = await widget.importer.previewFile(bytes);
      if (!mounted || !widget.signedIn()) return;
      final importCheckpoint = await showDialog<bool>(
        context: context,
        builder: (_) => PortableImportPreviewDialog(preview: preview),
      );
      if (importCheckpoint == null || !mounted || !widget.signedIn()) return;
      if (!await widget.guardianGate(context) ||
          !mounted ||
          !widget.signedIn()) {
        return;
      }
      final result = await widget.importer.apply(
        preview,
        importCheckpoint: importCheckpoint,
      );
      if (!mounted) return;
      _message(
        result is BookmarksOnlyCheckpointFailed
            ? context.l10n.backupPortablePartial(result.bookmarksAdded)
            : context.l10n.backupDone,
      );
      widget.afterImport?.call();
    } on StalePortableImportException {
      if (mounted) _message(context.l10n.backupPortableStale);
    } catch (_) {
      if (mounted) _message(context.l10n.backupErrorInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _busy ? null : _import,
    child: Text(context.l10n.backupPortableImport),
  );
}
