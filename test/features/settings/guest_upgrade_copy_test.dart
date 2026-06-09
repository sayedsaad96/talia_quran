import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest upgrade copy does not promise cloud sync or backup', () {
    final arb =
        jsonDecode(File('lib/core/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    const keys = [
      'guestModeWarning',
      'syncProgressDesc',
      'backupProgressDesc',
      'settingsGuestStatusSubtitle',
      'guardianSignInRequired',
      'guestUpgradeMessage',
      'guestUpgradeLocalProgress',
      'parentDashboardGuestSubtitle',
    ];
    final copy = keys.map((key) => arb[key] as String).join(' ').toLowerCase();

    expect(copy, isNot(contains('cloud')));
    expect(copy, isNot(contains('sync')));
    expect(copy, isNot(contains('backup')));
    expect(copy, contains('local progress'));
    expect(copy, contains('family features'));
  });
}
