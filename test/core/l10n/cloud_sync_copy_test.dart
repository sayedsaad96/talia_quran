import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations_ar.dart';
import 'package:talia_quran/core/l10n/app_localizations_en.dart';

void main() {
  group('cloud sync copy', () {
    test('auth entry copy does not promise progress sync', () {
      final l10n = AppLocalizationsEn();

      expect(l10n.syncProgressDesc.toLowerCase(), isNot(contains('sync')));
      expect(l10n.syncProgressDesc.toLowerCase(), isNot(contains('cloud')));
      expect(l10n.profileSavedToCloud.toLowerCase(), isNot(contains('cloud')));
      expect(l10n.signOutWarning.toLowerCase(), isNot(contains('cloud')));
    });

    test('arabic account copy does not promise cloud synchronization', () {
      final l10n = AppLocalizationsAr();

      expect(l10n.syncProgressDesc, isNot(contains('مزامنة')));
      expect(l10n.syncProgressDesc, isNot(contains('السحابة')));
      expect(l10n.profileSavedToCloud, isNot(contains('السحابة')));
      expect(l10n.signOutWarning, isNot(contains('السحابة')));
    });

    // Khatmah plans are device-only and are cleared on sign-out; the warning
    // must not promise that local progress stays.
    test('sign-out warning says the khatmah will be removed', () {
      expect(AppLocalizationsEn().signOutWarning, contains('khatmah'));
      expect(AppLocalizationsEn().signOutWarning, isNot(contains('remain')));
      expect(AppLocalizationsAr().signOutWarning, contains('الختمة'));
      expect(AppLocalizationsAr().signOutWarning, isNot(contains('سيبقى')));
    });
  });
}
