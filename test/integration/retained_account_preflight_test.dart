import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/guest_store_ownership.dart';
import 'package:talia_quran/core/services/app_initializer.dart';
import 'package:talia_quran/features/auth/presentation/cubits/auth_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await getIt.reset();
    AppInitializer.resetForTesting();
    SharedPreferences.setMockInitialValues({
      GuestStoreOwnership.accountKey: true,
      'auth_last_signed_in_user_id': 'account-a',
      'unscoped_test_progress': 37,
    });
  });
  tearDown(() async {
    await getIt.reset();
    AppInitializer.resetForTesting();
  });
  test(
    'real initializer stops before opening progress or creating auth consumers for retained guest data',
    () async {
      final decision = await AppInitializer.prepareIdentity();
      expect(decision.canStartProgress, isFalse);
      await expectLater(AppInitializer.initialize(), throwsStateError);
      expect(getIt.isRegistered<Isar>(), isFalse);
      expect(getIt.isRegistered<AuthCubit>(), isFalse);
      expect(AppInitializer.isInitialized, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('unscoped_test_progress'), 37);
      expect(prefs.getBool(GuestStoreOwnership.accountKey), isTrue);
    },
  );
  test(
    'clean guest passes identity preflight without creating progress dependencies',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(GuestStoreOwnership.accountKey);
      await prefs.setBool(GuestStoreOwnership.cleanKey, true);
      expect((await AppInitializer.prepareIdentity()).canStartProgress, isTrue);
      expect(getIt.isRegistered<Isar>(), isFalse);
    },
  );
}
