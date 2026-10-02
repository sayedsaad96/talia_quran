import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/memorization_plus/presentation/widgets/kids_talia_companion.dart';

void main() {
  test('every KidsTaliaPose asset is bundled', () {
    for (final pose in KidsTaliaPose.values) {
      final file = File(pose.asset);
      expect(file.existsSync(), isTrue, reason: '${pose.name}: ${pose.asset}');
      final bytes = file.readAsBytesSync();
      final height = ByteData.sublistView(bytes, 20, 24).getUint32(0);
      expect(height, 360, reason: '${pose.name} PNG height');
    }
  });
}
