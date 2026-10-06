import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:isar_community/isar.dart';

bool _initialized = false;

/// Loads the Isar core bundled with `isar_community_flutter_libs` for the
/// host desktop, so tests use the exact native library the app ships with
/// instead of a hard-coded pub-cache path.
Future<void> initializeIsarCoreForTests() async {
  if (_initialized) return;
  final library = await _bundledIsarCore();
  if (library != null) {
    await Isar.initializeIsarCore(libraries: {Abi.current(): library});
  } else {
    await Isar.initializeIsarCore(download: true);
  }
  _initialized = true;
}

Future<String?> _bundledIsarCore() async {
  final relative = Platform.isWindows
      ? 'windows/libisar.dll'
      : Platform.isMacOS
      ? 'macos/libisar.dylib'
      : Platform.isLinux
      ? 'linux/libisar.so'
      : null;
  if (relative == null) return null;
  // `flutter test` runs from the package root; Isolate.resolvePackageUri is
  // unsupported there, so read the package config directly.
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) return null;
  final config = jsonDecode(await configFile.readAsString()) as Map;
  for (final package in config['packages'] as List) {
    if (package is! Map || package['name'] != 'isar_community_flutter_libs') {
      continue;
    }
    final root = configFile.absolute.uri.resolve(package['rootUri'] as String);
    final file = File.fromUri(
      Uri.parse(
        root.toString().endsWith('/') ? '$root' : '$root/',
      ).resolve(relative),
    );
    return file.existsSync() ? file.path : null;
  }
  return null;
}
