import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'background audio integration is scoped to the continuous Quran player',
    () {
      final mainSource = File('lib/main.dart').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final injection = File('lib/core/di/injection.dart').readAsStringSync();

      expect(mainSource, isNot(contains('JustAudioBackground.init')));
      expect(mainSource, isNot(contains('package:just_audio_background')));
      expect(pubspec, contains('audio_service:'));
      expect(pubspec, isNot(contains('just_audio_background:')));
      expect(
        injection,
        contains('enableBackgroundAudioIntegration: true'),
        reason: 'Only the production continuous Quran player should opt in.',
      );
    },
  );
}
