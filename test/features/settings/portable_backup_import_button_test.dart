import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/backup/backup_file_format.dart';
import 'package:talia_quran/core/backup/portable_signed_in_import.dart';
import 'package:talia_quran/core/backup/restore_operation_gate.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';
import 'package:talia_quran/features/settings/presentation/widgets/portable_backup_import_button.dart';

void main() {
  testWidgets('checkpoint-only failure does not claim bookmarks were added', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const owner = FixedRecordOwnerProvider('account-a');
    final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    final importer = PortableSignedInImporter(
      prefs: prefs,
      owner: owner,
      barrier: barrier,
      bookmarks: BookmarkService(prefs, owner: owner),
      gate: RestoreOperationGate(owner),
      resolve: (_) async => throw StateError('No bookmarks in this fixture'),
      readCheckpoint: (_, _) async => null,
      writeCheckpoint: (_, _, _) async => throw StateError('storage failure'),
    );
    final bytes = encodeBackup(
      BackupPayload(
        schemaVersion: 5,
        createdAt: DateTime.utc(2026),
        sections: {
          'bookmarks': <Object?>[],
          'readingCheckpoint': {'pageNumber': 12},
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PortableBackupImportButton(
            importer: importer,
            pickFile: () async => bytes,
            signedIn: () => true,
            guardianGate: (_) async => true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Import bookmarks and reading position'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Import selected additions'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No new bookmarks were added'), findsOneWidget);
    expect(
      await importer.bookmarks.exportPortable(expectedOwnerId: 'account-a'),
      isEmpty,
    );
  });

  testWidgets(
    'preview cancel writes nothing; confirmed import preserves unrelated data',
    (tester) async {
      SharedPreferences.setMockInitialValues({'read_pages': '[42]'});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('account-a');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final bookmarks = BookmarkService(prefs, owner: owner);
      final importer = PortableSignedInImporter(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        bookmarks: bookmarks,
        gate: RestoreOperationGate(owner),
        resolve: (reference) async => BookmarkEntry(
          surahId: reference.surahId,
          surahName: 'synthetic fixture',
          ayahNumber: reference.ayahNumber,
          ayahText: 'synthetic fixture',
          savedAt: reference.savedAt,
        ),
      );
      final bytes = encodeBackup(
        BackupPayload(
          schemaVersion: 5,
          createdAt: DateTime.utc(2026),
          sections: {
            'bookmarks': [
              {
                'surahId': 1,
                'ayahNumber': 1,
                'savedAt': '2026-01-01T00:00:00Z',
              },
            ],
            'readingCheckpoint': {'pageNumber': 12},
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PortableBackupImportButton(
              importer: importer,
              pickFile: () async => bytes,
              signedIn: () => true,
              guardianGate: (_) async => true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Import bookmarks and reading position'));
      await tester.pumpAndSettle();
      expect(find.textContaining('New: 1'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        await bookmarks.exportPortable(expectedOwnerId: owner.currentOwnerId),
        isEmpty,
      );
      await tester.tap(find.text('Import bookmarks and reading position'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Import selected additions'),
      );
      await tester.pumpAndSettle();
      expect(
        (await bookmarks.exportPortable(
          expectedOwnerId: owner.currentOwnerId,
        )).length,
        1,
      );
      expect(prefs.getString('read_pages'), '[42]');
      expect(
        prefs.getInt('quran_reading_checkpoint_owner_account-a'),
        isNull,
        reason: 'The checkpoint checkbox was not selected',
      );
    },
  );
}
