import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/security/parent_pin_verifier.dart';

void main() {
  test('creates a salted verifier that accepts only the original PIN', () {
    final verifier = ParentPinVerifier.create('1234', salt: List.filled(16, 7));

    expect(verifier, startsWith('pbkdf2-sha256\$'));
    expect(verifier, isNot(contains('1234')));
    expect(ParentPinVerifier.verify('1234', verifier), isTrue);
    expect(ParentPinVerifier.verify('0000', verifier), isFalse);
  });
}
