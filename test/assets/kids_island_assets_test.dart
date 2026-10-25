import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_quran_map_visuals.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  for (final island in KidsIsland.values) {
    test('${island.name} island art exists and is bundled', () {
      expect(File(island.asset).existsSync(), isTrue, reason: island.asset);
      expect(pubspec, contains('- ${island.asset}'));
    });
  }
}
