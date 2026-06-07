import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/settings/presentation/cubits/settings_state.dart';

void main() {
  group('SettingsState parent tools visibility', () {
    test('hides parent tools for child track outside parent mode', () {
      const state = SettingsState(selectedTrack: 'kids');

      expect(state.shouldShowParentSection, isFalse);
    });

    test('hides parent tools for legacy backward hifz outside parent mode', () {
      const state = SettingsState(selectedHifzPath: 'backward');

      expect(state.shouldShowParentSection, isFalse);
    });

    test('shows parent tools only for adult parent mode', () {
      const state = SettingsState(selectedTrack: 'adults', isParentMode: true);

      expect(state.shouldShowParentSection, isTrue);
    });
  });
}
