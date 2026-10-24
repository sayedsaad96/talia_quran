import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/widgets/settings_account_tiles.dart';

void main() {
  tearDown(() => getIt.reset());
  testWidgets(
    'account deletion warns about owned groups with no feature services',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DeleteAccountTile(isDark: false, email: 'test@example.com'),
          ),
        ),
      );
      await tester.tap(find.byType(DeleteAccountTile));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AlertDialog));
      expect(
        find.text(
          AppLocalizations.of(context).groupKhatmahAccountDeletionWarning,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(AppLocalizations.of(context).cancel));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
