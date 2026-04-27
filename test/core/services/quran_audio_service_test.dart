import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/services/quran_audio_service.dart';
import 'package:talia_quran/core/constants/app_constants.dart';

void main() {
  group('QuranAudioService', () {
    test('builds correct URL with zero-padded surah and ayah', () {
      final url = QuranAudioService.buildUrl(2, 255);
      expect(url, equals('${AppConstants.audioBaseUrl}002255.mp3'));
    });

    test('pads single-digit surah number', () {
      final url = QuranAudioService.buildUrl(1, 1);
      expect(url, equals('${AppConstants.audioBaseUrl}001001.mp3'));
    });

    test('pads double-digit surah number', () {
      final url = QuranAudioService.buildUrl(36, 1);
      expect(url, equals('${AppConstants.audioBaseUrl}036001.mp3'));
    });

    test('handles last surah (114)', () {
      final url = QuranAudioService.buildUrl(114, 6);
      expect(url, equals('${AppConstants.audioBaseUrl}114006.mp3'));
    });

    test('handles max ayah count (Al-Baqarah 286)', () {
      final url = QuranAudioService.buildUrl(2, 286);
      expect(url, equals('${AppConstants.audioBaseUrl}002286.mp3'));
    });

    test('URL starts with the configured base URL', () {
      final url = QuranAudioService.buildUrl(1, 1);
      expect(url, startsWith(AppConstants.audioBaseUrl));
    });

    test('URL ends with .mp3 extension', () {
      final url = QuranAudioService.buildUrl(55, 13);
      expect(url, endsWith('.mp3'));
    });
  });
}
