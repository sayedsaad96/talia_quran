import 'package:file_picker/file_picker.dart';

import 'backup_file_format.dart';

class BackupFileTooLarge implements Exception {
  const BackupFileTooLarge();
}

/// Checks the provider's size before loading a backup into memory.
Future<List<int>?> readPickedBackup(PlatformFile? picked) async {
  if (picked == null) return null;
  final size = picked.lengthSync() ?? await picked.length();
  if (size != null && size > kBackupMaxBytes) throw const BackupFileTooLarge();
  return picked.readAsBytes();
}

Future<List<int>?> pickBackupFile() async =>
    readPickedBackup(await FilePicker.pickFile());
