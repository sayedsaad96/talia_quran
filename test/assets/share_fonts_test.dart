import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const fontPath = 'assets/fonts/Reem_Kufi/ReemKufi-Variable.ttf';

  test('Reem Kufi ships with its OFL licence and a pubspec declaration', () {
    expect(File(fontPath).existsSync(), isTrue);
    expect(File('assets/fonts/Reem_Kufi/OFL.txt').existsSync(), isTrue);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Reem_Kufi'));
    expect(pubspec, contains(fontPath));
  });

  test('Reem Kufi file is a TrueType font', () {
    final bytes = File(fontPath).readAsBytesSync();
    expect(bytes.sublist(0, 4), [0x00, 0x01, 0x00, 0x00]);
  });
}
