import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Creates and verifies a PBKDF2-HMAC-SHA256 parent-PIN verifier.
abstract final class ParentPinVerifier {
  static const iterations = 120000;

  static String create(String pin, {List<int>? salt}) {
    _validatePin(pin);
    final pinSalt = salt ?? _newSalt();
    if (pinSalt.length != 16) throw ArgumentError.value(salt, 'salt');
    final hash = _derive(pin, pinSalt);
    return 'pbkdf2-sha256\$$iterations\$${base64UrlEncode(pinSalt)}\$${base64UrlEncode(hash)}';
  }

  static bool verify(String pin, String verifier) {
    _validatePin(pin);
    final parts = verifier.split(r'$');
    if (parts.length != 4 ||
        parts[0] != 'pbkdf2-sha256' ||
        parts[1] != '$iterations') {
      return false;
    }
    try {
      final expected = base64Url.decode(parts[3]);
      final actual = _derive(pin, base64Url.decode(parts[2]));
      return _equalBytes(actual, expected);
    } on FormatException {
      return false;
    }
  }

  static List<int> _newSalt() {
    final random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }

  static List<int> _derive(String pin, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final output = List<int>.from(block);
    for (var round = 1; round < iterations; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < output.length; index++) {
        output[index] ^= block[index];
      }
    }
    return output;
  }

  static bool _equalBytes(List<int> left, List<int> right) {
    var difference = left.length ^ right.length;
    final length = min(left.length, right.length);
    for (var index = 0; index < length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  static void _validatePin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError.value(pin, 'pin', 'must contain exactly four digits');
    }
  }
}
