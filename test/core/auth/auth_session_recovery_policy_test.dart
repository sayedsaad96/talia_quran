import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/auth/auth_session_recovery_policy.dart';

void main() {
  group('AuthSessionRecoveryPolicy', () {
    test('classifies revoked refresh credentials as terminal', () {
      expect(
        AuthSessionRecoveryPolicy.isTerminal('Invalid Refresh Token: Already Used'),
        isTrue,
      );
    });

    test('keeps an offline refresh failure recoverable', () {
      expect(
        AuthSessionRecoveryPolicy.isTerminal('SocketException: network unavailable'),
        isFalse,
      );
    });
  });
}
