import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/talia_logger.dart';

/// Copies bundled cover artwork to a URI Android media notifications can read.
class QuranMediaArtwork {
  QuranMediaArtwork({
    Future<Directory> Function()? directory,
    AssetBundle? bundle,
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/images/launcher_icon_full.png';
  static const fileName = 'quran_media_cover.png';

  final Future<Directory> Function() _directory;
  final AssetBundle _bundle;
  Future<Uri?>? _cached;

  Future<Uri?> load() => _cached ??= _copyArtwork();

  Future<Uri?> _copyArtwork() async {
    try {
      final directory = await _directory();
      await directory.create(recursive: true);
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      if (await file.exists() && await file.length() > 0) {
        return file.uri;
      }
      final data = await _bundle.load(assetPath);
      final pending = File('${file.path}.pending');
      await pending.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      if (await file.exists()) await file.delete();
      await pending.rename(file.path);
      return file.uri;
    } catch (error, stack) {
      TaliaLogger.w('Quran media artwork unavailable', error, stack);
      return null;
    }
  }
}
