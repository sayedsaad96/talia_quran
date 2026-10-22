import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/quran_audio_download_manager.dart';

void main() {
  late Directory support;

  setUp(() async {
    support = await Directory('.superpowers/tmp').createTemp('audio_support_');
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test('downloads live under the app-support directory, per store key', () async {
    final fileSystem = QuranAudioSupportFileSystem(
      'quran_audio_downloads_alafasy',
      base: () async => support,
    );

    final created = await fileSystem.createFile('001001.mp3');

    expect(
      created.path,
      '${support.path}${Platform.pathSeparator}'
      'quran_audio_downloads_alafasy${Platform.pathSeparator}001001.mp3',
    );
    expect(await created.parent.exists(), isTrue);
  });

  test('a store directory removed underneath is recreated', () async {
    final fileSystem = QuranAudioSupportFileSystem(
      'store',
      base: () async => support,
    );
    final first = await fileSystem.createFile('a.mp3');
    await first.parent.delete(recursive: true);

    final second = await fileSystem.createFile('b.mp3');

    expect(await second.parent.exists(), isTrue);
  });
}
