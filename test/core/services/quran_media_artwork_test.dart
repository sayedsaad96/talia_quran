import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/quran_media_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('copies the real launcher artwork once to persistent storage', () async {
    final directory = await Directory.systemTemp.createTemp('talia_artwork_');
    addTearDown(() => directory.delete(recursive: true));
    var directoryCalls = 0;
    final artwork = QuranMediaArtwork(
      directory: () async {
        directoryCalls++;
        return directory;
      },
    );
    final first = await artwork.load();
    expect(first?.scheme, 'file');
    final file = File.fromUri(first!);
    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(0));
    expect(await artwork.load(), first);
    expect(directoryCalls, 1);
  });

  test('asset failure returns null and does not escape', () async {
    final directory = await Directory.systemTemp.createTemp('talia_artwork_');
    addTearDown(() => directory.delete(recursive: true));
    final artwork = QuranMediaArtwork(
      directory: () async => directory,
      bundle: _FailingBundle(),
    );
    expect(await artwork.load(), isNull);
  });

  test('replaces an interrupted empty cover from a staged asset', () async {
    final directory = await Directory.systemTemp.createTemp('talia_artwork_');
    addTearDown(() => directory.delete(recursive: true));
    final cover = File(
      '${directory.path}${Platform.pathSeparator}quran_media_cover.png',
    );
    await cover.create();
    final artwork = QuranMediaArtwork(directory: () async => directory);
    expect(await artwork.load(), cover.uri);
    expect(await cover.length(), greaterThan(0));
    expect(await File('${cover.path}.pending').exists(), isFalse);
  });
}

class _FailingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future.error(StateError('asset missing'));
}
