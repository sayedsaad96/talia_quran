import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/app_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AppSessionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = AppSessionService(prefs);
  });

  test('saves and restores a valid Quran reader page', () async {
    await service.saveLocation('/quran/page/42');

    expect(service.getLastRestorableLocation(), '/quran/page/42');
  });

  test('does not save startup or onboarding routes', () async {
    await service.saveLocation('/quran/page/42');
    await service.saveLocation('/splash');
    await service.saveLocation('/onboarding');
    await service.saveLocation('/onboarding/child');

    expect(service.getLastRestorableLocation(), '/quran/page/42');
  });

  test('does not restore incomplete memorization routes', () async {
    await service.saveLocation('/memorization-plus/daily-plan');

    expect(service.getLastRestorableLocation(), isNull);
  });

  test(
    'restores memorization routes when required query data exists',
    () async {
      await service.saveLocation('/memorization-v2/session?surahId=2&startAyah=5');

      expect(
        service.getLastRestorableLocation(),
        '/memorization-v2/session?surahId=2&startAyah=5',
      );
    },
  );

  test('restores Kids Journey route aliases with a valid journey id', () async {
    await service.saveLocation('/memorization-plus/journey/114');

    expect(
      service.getLastRestorableLocation(),
      '/memorization-plus/journey/114',
    );
  });

  test(
    'does not restore Kids Journey route aliases without a valid id',
    () async {
      await service.saveLocation('/memorization-plus/journey/115');

      expect(service.getLastRestorableLocation(), isNull);
    },
  );
}
