import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:talia_quran/core/backup/portable_reading_data.dart';
import 'package:talia_quran/core/backup/portable_signed_in_import.dart';
import 'package:talia_quran/core/backup/restore_operation_gate.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/quran/data/datasources/bookmark_service.dart';
import 'package:talia_quran/features/quran/domain/entities/bookmark_entry.dart';

class FailingCheckpointStore extends InMemorySharedPreferencesStore {
  FailingCheckpointStore() : super.withData({});
  bool fail = true;
  void Function()? onFailure;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (fail && key.contains('quran_reading_checkpoint_owner_')) {
      onFailure?.call();
      return false;
    }
    return super.setValue(type, key, value);
  }
}

class Owner implements RecordOwnerProvider {
  String id = 'owner-a';
  @override
  String get currentOwnerId => id;
  @override
  bool get isSignedIn => true;
}

void main() {
  test(
    'previews tombstones and adds only missing; stale preview fails',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = Owner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final service = BookmarkService(prefs, owner: owner);
      final now = DateTime.utc(2026);
      BookmarkEntry entry(int ayah) => BookmarkEntry(
        surahId: 1,
        surahName: 'fixture',
        ayahNumber: ayah,
        ayahText: 'fixture',
        savedAt: now,
      );
      PortableBookmark reference(int ayah) =>
          PortableBookmark(surahId: 1, ayahNumber: ayah, savedAt: now);
      await service.toggle(entry(1));
      await service.toggle(entry(2));
      await service.toggle(entry(2));
      final importer = PortableSignedInImporter(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        bookmarks: service,
        gate: RestoreOperationGate(owner),
        resolve: (ref) async => entry(ref.ayahNumber),
      );
      final preview = await importer.preview([
        reference(1),
        reference(2),
        reference(3),
      ]);
      expect(preview.existing, hasLength(1));
      expect(preview.deletedConflicts, hasLength(1));
      expect(preview.additions, hasLength(1));
      await importer.apply(preview);
      expect(service.getAll().map((e) => e.ayahNumber).toSet(), {1, 3});
      await expectLater(
        importer.apply(preview),
        throwsA(isA<StalePortableImportException>()),
      );
      final checkpointPreview = await importer.preview(
        [],
        checkpoint: QuranReadingCheckpoint(pageNumber: 44),
      );
      await importer.apply(checkpointPreview, importCheckpoint: true);
      expect(prefs.getInt('quran_reading_checkpoint_owner_owner-a'), 44);
      final changed = await importer.preview([
        reference(4),
      ], checkpoint: QuranReadingCheckpoint(pageNumber: 45));
      await prefs.setInt('quran_reading_checkpoint_owner_owner-a', 46);
      await expectLater(
        importer.apply(changed, importCheckpoint: true),
        throwsA(isA<StalePortableImportException>()),
      );
      expect(service.getAll().map((e) => e.ayahNumber).toSet(), {1, 3});
      expect(prefs.getInt('quran_reading_checkpoint_owner_owner-a'), 46);
      final next = await importer.preview([reference(4)]);
      owner.id = 'owner-b';
      await expectLater(importer.apply(next), throwsA(anything));
    },
  );
  test(
    'checkpoint failure reports durable additions and retry does not duplicate',
    () async {
      final store = FailingCheckpointStore();
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      final prefs = await SharedPreferences.getInstance();
      final owner = Owner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final bookmarks = BookmarkService(prefs, owner: owner);
      final ref = PortableBookmark(
        surahId: 1,
        ayahNumber: 1,
        savedAt: DateTime.utc(2026),
      );
      final importer = PortableSignedInImporter(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        bookmarks: bookmarks,
        gate: RestoreOperationGate(owner),
        resolve: (r) async => BookmarkEntry(
          surahId: r.surahId,
          ayahNumber: r.ayahNumber,
          surahName: 'fixture',
          ayahText: 'fixture',
          savedAt: r.savedAt,
        ),
      );
      final preview = await importer.preview([
        ref,
      ], checkpoint: QuranReadingCheckpoint(pageNumber: 30));
      final result = await importer.apply(preview, importCheckpoint: true);
      expect(result, isA<BookmarksOnlyCheckpointFailed>());
      expect(result.bookmarksAdded, 1);
      expect(bookmarks.getAll(), hasLength(1));
      store.fail = false;
      final retry = await importer.preview([
        ref,
      ], checkpoint: QuranReadingCheckpoint(pageNumber: 30));
      expect(retry.existing, hasLength(1));
      final completed = await importer.apply(retry, importCheckpoint: true);
      expect(completed, isA<PortableImportCompleted>());
      expect(completed.bookmarksAdded, 0);
      expect(bookmarks.getAll(), hasLength(1));
      expect(prefs.getInt('quran_reading_checkpoint_owner_owner-a'), 30);
    },
  );
  test(
    'account switch during checkpoint failure is not a partial success',
    () async {
      final store = FailingCheckpointStore();
      SharedPreferencesStorePlatform.instance = store;
      SharedPreferences.resetStatic();
      final prefs = await SharedPreferences.getInstance();
      final owner = Owner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final bookmarks = BookmarkService(prefs, owner: owner);
      final ref = PortableBookmark(
        surahId: 1,
        ayahNumber: 1,
        savedAt: DateTime.utc(2026),
      );
      final importer = PortableSignedInImporter(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        bookmarks: bookmarks,
        gate: RestoreOperationGate(owner),
        resolve: (r) async => BookmarkEntry(
          surahId: r.surahId,
          ayahNumber: r.ayahNumber,
          surahName: 'fixture',
          ayahText: 'fixture',
          savedAt: r.savedAt,
        ),
      );
      final preview = await importer.preview([
        ref,
      ], checkpoint: QuranReadingCheckpoint(pageNumber: 30));
      store.onFailure = () => owner.id = 'owner-b';
      await expectLater(
        importer.apply(preview, importCheckpoint: true),
        throwsA(anything),
      );
      await prefs.reload();
      expect(prefs.getInt('quran_reading_checkpoint_owner_owner-a'), isNull);
      expect(prefs.getInt('quran_reading_checkpoint_owner_owner-b'), isNull);
    },
  );
  test(
    'uses the in-lease checkpoint authority for preview, freshness and write',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = Owner();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final bookmarks = BookmarkService(prefs, owner: owner);
      int? page = 10;
      final importer = PortableSignedInImporter(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        bookmarks: bookmarks,
        gate: RestoreOperationGate(owner),
        resolve: (_) async => null,
        readCheckpoint: (id, lease) async {
          lease.checkOwner(id);
          return QuranReadingCheckpoint(pageNumber: page!);
        },
        writeCheckpoint: (id, value, lease) async {
          lease.checkOwner(id);
          page = value;
        },
      );
      final preview = await importer.preview(
        [],
        checkpoint: QuranReadingCheckpoint(pageNumber: 20),
      );
      expect(preview.currentCheckpoint!.pageNumber, 10);
      page = 11;
      await expectLater(
        importer.apply(preview, importCheckpoint: true),
        throwsA(isA<StalePortableImportException>()),
      );
      final current = await importer.preview(
        [],
        checkpoint: QuranReadingCheckpoint(pageNumber: 20),
      );
      await importer.apply(current, importCheckpoint: true);
      expect(page, 20);
    },
  );
}
