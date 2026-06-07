import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('.env is not bundled as a Flutter asset', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      pubspec,
      isNot(contains(RegExp(r'^\s*-\s*\.env\s*$', multiLine: true))),
    );
  });
}
