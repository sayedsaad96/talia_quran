import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_after_restore.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_child_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_policy_controller.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';

void main() {
  late GetIt locator;

  setUp(() => locator = GetIt.asNewInstance());
  tearDown(() => locator.reset());

  test(
    'ProfileCubit shows the restored name after afterBackupRestore',
    () async {
      SharedPreferences.setMockInitialValues({
        'user_profile': '{"name":"Old","age":30}',
      });
      final prefs = await SharedPreferences.getInstance();
      final cubit = ProfileCubit(prefs)..loadProfile();
      locator.registerSingleton<ProfileCubit>(cubit);
      expect((cubit.state as ProfileLoaded).profile.name, 'Old');

      // What a restore writes.
      await prefs.setString('user_profile', '{"name":"Restored","age":9}');
      await afterBackupRestore(locator);

      final profile = (cubit.state as ProfileLoaded).profile;
      expect(profile.name, 'Restored');
      expect(profile.age, 9);

      // A later edit builds on the restored profile, not the stale one.
      await cubit.updateProfile(age: 10);
      expect(prefs.getString('user_profile'), contains('Restored'));
      await cubit.close();
    },
  );

  test('kids policy is reloaded and the path resolver notified', () async {
    var loads = 0;
    final policy = KidsPolicyController(
      load: () async {
        loads++;
        return const KidsChildPolicy();
      },
    );
    locator.registerSingleton<KidsPolicyController>(policy);
    final resolver = _Resolver();
    locator.registerSingleton<MemorizationPathResolver>(resolver);

    await afterBackupRestore(locator);

    expect(loads, 1);
    expect(resolver.notified, 1);
  });

  test('nothing registered: no throw', () async {
    await afterBackupRestore(locator);
  });
}

class _Resolver implements MemorizationPathResolver {
  int notified = 0;

  @override
  void notifyChanged() => notified++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
