import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/backup/backup_after_restore.dart';
import '../../../../core/backup/backup_collector.dart';
import '../../../../core/backup/backup_file_format.dart';
import '../../../../core/backup/backup_restorer.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/identity/record_owner_provider.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/talia_logger.dart';
import '../../../memorization_plus/domain/repositories/memorization_plus_repository.dart';
import '../../../memorization_plus/presentation/widgets/guardian_pin_dialog.dart';
import '../widgets/settings_subpage_scaffold.dart';

/// Which message a failed backup step maps to.
enum BackupErrorKind { invalid, newer, corrupt }

@visibleForTesting
BackupErrorKind backupDecodeErrorKind(BackupDecodeError error) =>
    switch (error) {
      BackupDecodeError.notGzip ||
      BackupDecodeError.notJson ||
      BackupDecodeError.wrongFormat ||
      BackupDecodeError.malformedSections => BackupErrorKind.invalid,
      BackupDecodeError.checksumMismatch => BackupErrorKind.corrupt,
      BackupDecodeError.newerVersion => BackupErrorKind.newer,
    };

/// Writes the backup bytes to a temporary file and offers it for sharing.
typedef BackupFileExporter =
    Future<void> Function(String fileName, List<int> bytes);

/// Lets the user pick a backup file; null when cancelled. Throws
/// [BackupFileTooLarge] for a file no valid backup can be.
typedef BackupFilePicker = Future<List<int>?> Function();

/// Asks for the guardian PIN when this device has one; false cancels.
typedef BackupGuardianGate = Future<bool> Function(BuildContext context);

/// The picked file is larger than [kBackupMaxBytes].
class BackupFileTooLarge implements Exception {
  const BackupFileTooLarge();
}

/// Writes [bytes] to [fileName] in [dir], hands the path to [share], and
/// deletes the file afterwards (best effort) whether sharing succeeded or not.
@visibleForTesting
Future<void> shareBackupFileFrom(
  Directory dir,
  String fileName,
  List<int> bytes,
  Future<void> Function(String path) share,
) async {
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  try {
    await share(file.path);
  } finally {
    try {
      if (await file.exists()) await file.delete();
    } catch (e, st) {
      TaliaLogger.w('Backup temp file cleanup failed', e, st);
    }
  }
}

Future<void> _shareBackupFile(String fileName, List<int> bytes) async =>
    shareBackupFileFrom(
      await getTemporaryDirectory(),
      fileName,
      bytes,
      (path) => SharePlus.instance.share(ShareParams(files: [XFile(path)])),
    );

/// The picked file's bytes, or null when nothing was picked. The size is
/// checked before reading, so an oversized file is never loaded.
@visibleForTesting
Future<List<int>?> readPickedBackup(PlatformFile? picked) async {
  if (picked == null) return null;
  final size = picked.lengthSync() ?? await picked.length();
  if (size != null && size > kBackupMaxBytes) throw const BackupFileTooLarge();
  return picked.readAsBytes();
}

Future<List<int>?> _pickBackupFile() async =>
    readPickedBackup(await FilePicker.pickFile());

/// With a parent PIN on this device (or unreadable parent settings) the
/// guardian must enter it; a PIN is never created here.
Future<bool> _guardianPinGate(BuildContext context) async {
  final hasPin = (await getIt<MemorizationPlusRepository>().getParentSettings())
      .fold((_) => true, (settings) => settings.hasPin);
  if (!hasPin) return true;
  if (!context.mounted) return false;
  return ensureGuardianPin(
    context,
    confirmLabel: context.l10n.backupConfirm,
    allowCreate: false,
  );
}

/// Export and restore of the local backup file. Restore replaces this
/// device's data and is offered only without a cloud account.
class BackupPage extends StatefulWidget {
  const BackupPage({
    super.key,
    this.isSignedIn,
    this.collect,
    this.restore,
    this.pickFile,
    this.exportFile,
    this.guardianGate,
    this.afterRestore,
  });

  final bool Function()? isSignedIn;
  final Future<BackupPayload> Function(DateTime now)? collect;
  final Future<BackupRestoreResult> Function(BackupPayload payload)? restore;
  final BackupFilePicker? pickFile;
  final BackupFileExporter? exportFile;
  final BackupGuardianGate? guardianGate;
  final Future<void> Function()? afterRestore;

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;

  bool get _signedIn =>
      (widget.isSignedIn ?? () => getIt<RecordOwnerProvider>().isSignedIn)();

  String _message(AppLocalizations l10n, BackupErrorKind kind) =>
      switch (kind) {
        BackupErrorKind.invalid => l10n.backupErrorInvalid,
        BackupErrorKind.newer => l10n.backupErrorNewer,
        BackupErrorKind.corrupt => l10n.backupErrorCorrupt,
      };

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    if (_busy) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final collect = widget.collect ?? getIt<BackupCollector>().collect;
      final payload = await collect(now);
      final bytes = encodeBackup(payload);
      await (widget.exportFile ?? _shareBackupFile)(backupFileName(now), bytes);
    } catch (e, st) {
      TaliaLogger.w('Backup export failed', e, st);
      _snack(l10n.errorUnknownMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    if (_busy || _signedIn) return;
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final List<int>? bytes;
      try {
        bytes = await (widget.pickFile ?? _pickBackupFile)();
      } on BackupFileTooLarge {
        _snack(l10n.backupErrorInvalid);
        return;
      }
      if (bytes == null) return;
      final decoded = decodeBackup(bytes);
      final payload = decoded.payload;
      if (payload == null) {
        final kind = backupDecodeErrorKind(
          decoded.error ?? BackupDecodeError.wrongFormat,
        );
        _snack(_message(l10n, kind));
        return;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.backupConfirmTitle),
          content: Text(l10n.backupConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.backupConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      // An account may have been signed into while the dialog was open.
      if (_signedIn) {
        _snack(l10n.backupImportSignedIn);
        return;
      }
      final gate = widget.guardianGate ?? _guardianPinGate;
      if (!await gate(context) || !mounted || _signedIn) return;
      final restore = widget.restore ?? getIt<BackupRestorer>().restore;
      final result = await restore(payload);
      switch (result) {
        case BackupRestoreResult.restored:
          await (widget.afterRestore ?? afterBackupRestore)();
          _snack(l10n.backupDone);
          if (mounted) context.go(AppRoutes.splash);
        case BackupRestoreResult.invalidSections:
          _snack(l10n.backupErrorInvalid);
        case BackupRestoreResult.writeFailed:
          _snack(l10n.errorUnknownMessage);
      }
    } catch (e, st) {
      TaliaLogger.w('Backup import failed', e, st);
      _snack(l10n.errorUnknownMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final signedIn = _signedIn;
    final subtle = AppTypography.bodyMedium.copyWith(
      color: context.tokens.textSecondary,
    );

    return SettingsSubpageScaffold(
      title: l10n.backupTitle,
      children: [
        Text(l10n.backupIncludes, style: subtle),
        Text(l10n.backupExcludes, style: subtle),
        FilledButton(
          onPressed: _busy ? null : _export,
          child: Text(l10n.backupExport),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: _busy || signedIn ? null : _import,
              child: Text(l10n.backupImport),
            ),
            if (signedIn) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.backupImportSignedIn, style: subtle),
            ],
          ],
        ),
      ],
    );
  }
}
