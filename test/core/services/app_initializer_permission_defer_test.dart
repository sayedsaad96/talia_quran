import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/router/launch_destination.dart';
import 'package:talia_quran/core/services/app_initializer.dart';

void main() {
  test(
    'first launch defers permission prompts until onboarding ends',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(
        AppInitializer.deferPermissionPrompts(
          await SharedPreferences.getInstance(),
        ),
        isTrue,
      );
    },
  );

  test('after onboarding, startup asks as before', () async {
    SharedPreferences.setMockInitialValues({
      LaunchDestination.firstTimePreferenceKey: false,
    });
    expect(
      AppInitializer.deferPermissionPrompts(
        await SharedPreferences.getInstance(),
      ),
      isFalse,
    );
  });
}
