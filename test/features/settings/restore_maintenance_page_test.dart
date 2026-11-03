import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/restore_maintenance_session.dart';
import 'package:talia_quran/core/backup/restore_request_store.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/settings/presentation/pages/restore_maintenance_page.dart';
import 'package:talia_quran/features/settings/presentation/widgets/cold_restore_request_button.dart';

class _Session extends Mock implements RestoreMaintenanceSession {}

void main() {
  setUpAll(
    () => registerFallbackValue(
      BackupPayload(
        schemaVersion: 5,
        createdAt: DateTime.utc(2026),
        sections: const {},
      ),
    ),
  );
  testWidgets(
    'settings schedules only an opaque request and explains a full stop',
    (tester) async {
      SharedPreferences.setMockInitialValues({'existing_progress': 12});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ColdRestoreRequestButton(
              requests: RestoreRequestStore(prefs),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(await RestoreRequestStore(prefs).pendingId(), isNotNull);
      expect(prefs.getInt('existing_progress'), 12);
      expect(prefs.getKeys(), {'existing_progress', RestoreRequestStore.key});
      expect(find.textContaining('Fully stop Talia'), findsOneWidget);
    },
  );

  testWidgets(
    'maintenance blocks replacement for an unsafe destination and can continue',
    (tester) async {
      final session = _Session();
      when(() => session.canReplace).thenAnswer((_) async => false);
      var resumed = false;
      await tester.pumpWidget(
        RestoreMaintenanceApp(
          open: () async => session,
          resume: (value) async {
            expect(value, same(session));
            resumed = true;
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('الاستعادة غير متاحة'), findsOneWidget);
      verifyNever(() => session.restore(any(), any()));
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(resumed, isTrue);
    },
  );

  testWidgets(
    'unreadable recovery offers retry without entering the normal app',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        RestoreMaintenanceApp(
          open: () async {
            opens++;
            throw StateError('keystore');
          },
          resume: (_) async => fail('normal runtime must remain absent'),
        ),
      );
      await tester.pumpAndSettle();
      expect(opens, 1);
      expect(find.byType(OutlinedButton), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(opens, 2);
    },
  );

  testWidgets(
    'busy admission message supports Arabic large text on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(RestoreAdmissionBusyApp(retry: () async {}));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );
}
