import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/share_good/domain/entities/invite_types.dart';
import 'package:talia_quran/features/share_good/domain/services/inviter_identity_resolver.dart';

void main() {
  const resolver = InviterIdentityResolver();
  test('fallback names are never disclosed', () {
    expect(
      resolver.resolve(
        InviteIdentityMode.fullName,
        profileName: ' مستخدم تالية ',
        authDisplayName: 'Talia User',
      ),
      const InviterIdentity(mode: InviteIdentityMode.anonymous),
    );
  });
  test('uses first whitespace token and a real fallback name', () {
    expect(
      resolver.resolve(
        InviteIdentityMode.firstName,
        profileName: 'مستخدم',
        authDisplayName: '  Ahmed  Saad ',
      ),
      const InviterIdentity(
        mode: InviteIdentityMode.firstName,
        visibleName: 'Ahmed',
      ),
    );
  });
  test('caps disclosed name and honours anonymity', () {
    expect(
      resolver
          .resolve(InviteIdentityMode.fullName, profileName: 'a' * 50)
          .visibleName,
      'a' * 40,
    );
    expect(
      resolver
          .resolve(InviteIdentityMode.anonymous, profileName: 'Ahmed')
          .visibleName,
      isNull,
    );
  });
}
