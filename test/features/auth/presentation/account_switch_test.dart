import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

void main() {
  group('account switch detection', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a first sign-in records the user without wiping', () async {
      final prefs = await SharedPreferences.getInstance();
      final wiped = <String>[];

      final changed = await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-a',
        onDepartingAccount: () async => wiped.add('wipe'),
      );

      expect(changed, isFalse);
      expect(wiped, isEmpty);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-a');
    });

    test('the same user signing in again does not wipe', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
      final wiped = <String>[];

      final changed = await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-a',
        onDepartingAccount: () async => wiped.add('wipe'),
      );

      expect(changed, isFalse);
      expect(wiped, isEmpty);
    });

    test('a different user wipes the departing account data first', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AuthCubit.lastSignedInUserIdKey, 'user-a');
      final wiped = <String>[];

      final changed = await AuthCubit.resolveOwnerChange(
        prefs: prefs,
        userId: 'user-b',
        onDepartingAccount: () async => wiped.add('wipe'),
      );

      expect(changed, isTrue);
      expect(wiped, ['wipe']);
      expect(prefs.getString(AuthCubit.lastSignedInUserIdKey), 'user-b');
    });
  });
}
