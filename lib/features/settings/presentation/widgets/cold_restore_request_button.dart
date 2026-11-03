import 'package:flutter/material.dart';

import '../../../../core/backup/restore_request_store.dart';
import '../../../../core/l10n/app_localizations.dart';

class ColdRestoreRequestButton extends StatefulWidget {
  const ColdRestoreRequestButton({super.key, required this.requests});
  final RestoreRequestStore requests;
  @override
  State<ColdRestoreRequestButton> createState() =>
      _ColdRestoreRequestButtonState();
}

class _ColdRestoreRequestButtonState extends State<ColdRestoreRequestButton> {
  bool _busy = false;
  Future<void> _schedule() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      await widget.requests.schedule();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupMaintenanceTitle),
          content: Text(l10n.backupMaintenanceRestart),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.backupConfirm),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupErrorProtection)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _busy ? null : _schedule,
    child: Text(AppLocalizations.of(context).backupMaintenanceSchedule),
  );
}
