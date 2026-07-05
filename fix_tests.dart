import 'dart:io';

void main() {
  final file = File(
    'test/features/memorization_plus/presentation/cubits/kids_journey_cubit_test.dart',
  );
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'await expectLater(',
    'final expectation = expectLater(',
  );
  content = content.replaceAll(
    RegExp(r'(await cubit\.load\([^;]+\);)'),
    r'\n        await expectation;',
  );
  content = content.replaceAll(
    RegExp(r'(await cubit\.createRemoteLinkQr\(\);)'),
    r'\n        await expectation;',
  );
  file.writeAsStringSync(content);
}
