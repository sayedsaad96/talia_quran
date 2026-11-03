import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/backup/backup_file_format.dart';
import '../../../../core/backup/backup_file_picker.dart';
import '../../../../core/backup/backup_restorer.dart';
import '../../../../core/backup/restore_maintenance_session.dart';
import '../../../../core/l10n/app_localizations.dart';

/// A separate root app; the normal providers and router do not exist here.
class RestoreMaintenanceApp extends StatefulWidget {
  const RestoreMaintenanceApp({
    super.key,
    required this.open,
    required this.resume,
  });
  final Future<RestoreMaintenanceSession> Function() open;
  final Future<void> Function(RestoreMaintenanceSession) resume;
  @override
  State<RestoreMaintenanceApp> createState() => _RestoreMaintenanceAppState();
}

class _RestoreMaintenanceAppState extends State<RestoreMaintenanceApp> {
  late Future<RestoreMaintenanceSession> _session = _open();
  Future<RestoreMaintenanceSession> _open() {
    final future = Future<RestoreMaintenanceSession>.sync(widget.open);
    // A fast failure may arrive between setState and FutureBuilder's next
    // subscription. Observe it immediately; the builder still shows its error.
    future.ignore();
    return future;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FutureBuilder<RestoreMaintenanceSession>(
      future: _session,
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        if (snapshot.hasData) {
          return _RestoreMaintenancePage(
            session: snapshot.data!,
            resume: widget.resume,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.backupMaintenanceTitle)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.backupErrorRecoveryBlocked,
                          textAlign: TextAlign.center,
                        ),
                        FilledButton(
                          onPressed: () => setState(() {
                            _session = _open();
                          }),
                          child: Text(l10n.retryLabel),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    ),
  );
}

class RestoreAdmissionBusyApp extends StatelessWidget {
  const RestoreAdmissionBusyApp({super.key, required this.retry});
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      l10n.backupMaintenanceBusy,
                      textAlign: TextAlign.center,
                    ),
                    FilledButton(
                      onPressed: retry,
                      child: Text(l10n.retryLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _RestoreMaintenancePage extends StatefulWidget {
  const _RestoreMaintenancePage({required this.session, required this.resume});
  final RestoreMaintenanceSession session;
  final Future<void> Function(RestoreMaintenanceSession) resume;
  @override
  State<_RestoreMaintenancePage> createState() =>
      _RestoreMaintenancePageState();
}

class _RestoreMaintenancePageState extends State<_RestoreMaintenancePage> {
  bool _busy = false;
  String? _message;
  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await work();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).backupErrorProtection,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.backupConfirmTitle),
            content: Text(l10n.backupConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.backupConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _verifyPin() async {
    if (!await widget.session.pin.requiresPin()) return true;
    if (!mounted) return false;
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupMaintenancePin),
        content: TextField(
          controller: controller,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.backupMaintenancePin),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.backupConfirm),
          ),
        ],
      ),
    );
    // Dialog route disposal finishes after the pop animation.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (value == null) return false;
    final verified = await widget.session.verifyPin(value);
    if (!verified && mounted) {
      setState(() => _message = l10n.backupMaintenancePinRejected);
    }
    return verified;
  }

  Future<void> _restore() => _run(() async {
    final l10n = AppLocalizations.of(context);
    if (!await widget.session.canReplace) {
      setState(() => _message = l10n.backupMaintenanceUnavailable);
      return;
    }
    final id = await widget.session.requests.pendingId();
    if (id == null) {
      setState(() => _message = l10n.backupMaintenanceFinished);
      return;
    }
    final bytes = await readPickedBackup(await FilePicker.pickFile());
    if (bytes == null || !mounted) return;
    final decoded = decodeBackup(bytes);
    if (decoded.payload == null) {
      setState(() => _message = l10n.backupErrorInvalid);
      return;
    }
    if (!await _confirm() || !mounted || !await _verifyPin() || !mounted) {
      return;
    }
    final result = await widget.session.restore(id, decoded.payload!);
    if (!mounted) return;
    setState(
      () => _message = switch (result) {
        BackupRestoreResult.restored => l10n.backupDone,
        BackupRestoreResult.invalidSections => l10n.backupErrorInvalid,
        BackupRestoreResult.recoveryBlocked => l10n.backupErrorRecoveryBlocked,
        _ => l10n.backupErrorProtection,
      },
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.backupMaintenanceTitle),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.backupMaintenanceBody),
              const SizedBox(height: 20),
              if (_message != null)
                Semantics(liveRegion: true, child: Text(_message!)),
              if (_busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _busy ? null : _restore,
                child: Text(l10n.backupImport),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => widget.resume(widget.session)),
                child: Text(l10n.backupMaintenanceContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
