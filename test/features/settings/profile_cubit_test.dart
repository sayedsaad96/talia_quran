import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/settings/presentation/cubits/profile_cubit.dart';

void main() {
  group('ProfileCubit', () {
    test('loads default profile when stored profile is corrupted', () async {
      SharedPreferences.setMockInitialValues({'user_profile': '{bad json'});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ProfileCubit(prefs);

      cubit.loadProfile();

      final state = cubit.state;
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).profile.hasName, isFalse);
      await cubit.close();
    });

    test('saves and emits updated profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cubit = ProfileCubit(prefs)..loadProfile();

      final saved = await cubit.updateProfile(name: 'أحمد', age: 12);

      final state = cubit.state;
      expect(saved, isTrue);
      expect(state, isA<ProfileLoaded>());
      expect((state as ProfileLoaded).profile.name, 'أحمد');
      expect(state.profile.age, 12);
      await cubit.close();
    });
  });
}
