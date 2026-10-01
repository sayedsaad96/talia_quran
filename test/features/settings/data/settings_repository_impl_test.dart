import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/memorization/v2/recitation_evaluator.dart';
import 'package:talia_quran/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:talia_quran/features/settings/domain/repositories/settings_repository.dart';

void main() {
  Future<double> thresholdFor(double? stored) async {
    SharedPreferences.setMockInitialValues({
      SettingsRepositoryImpl.similarityThresholdKey: ?stored,
    });
    final prefs = await SharedPreferences.getInstance();
    return SettingsRepositoryImpl(prefs).getSimilarityThreshold();
  }

  test('balanced (the default) keeps the engine standard threshold', () async {
    expect(await thresholdFor(null), kV2PassThreshold);
    expect(SettingsRepository.balancedPassThreshold, kV2PassThreshold);
  });

  test('each accuracy level maps to its threshold', () async {
    expect(await thresholdFor(0.70), SettingsRepository.lenientPassThreshold);
    expect(await thresholdFor(0.92), SettingsRepository.strictPassThreshold);
  });

  test('the 0.85 stored by older builds reads as balanced', () async {
    expect(await thresholdFor(0.85), SettingsRepository.balancedPassThreshold);
  });
}
