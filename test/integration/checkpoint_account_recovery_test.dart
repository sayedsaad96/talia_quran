import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/account_data_reset.dart';
import 'package:talia_quran/core/identity/pending_checkpoint_recovery_marker.dart';
import 'package:talia_quran/core/storage/app_isar.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_repository_impl.dart';
import '../helpers/isar_test_core.dart';
import '../features/quran/reading_checkpoint_repository_test.dart'
    show MutableOwner, SecureStore, Remote;

void main() {
  test(
    'pending checkpoint survives A-B-A reset and actual deletion erases it',
    () async {
      await initializeIsarCoreForTests();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final owner = MutableOwner();
      final secure = SecureStore();
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final dir = await Directory.systemTemp.createTemp(
        'talia_checkpoint_recovery_',
      );
      final isar = await Isar.open(
        appIsarSchemas,
        directory: dir.path,
        name: 'checkpoint_${DateTime.now().microsecondsSinceEpoch}',
      );
      addTearDown(() async {
        await isar.close(deleteFromDisk: true);
        await dir.delete(recursive: true);
      });
      final repo = ReadingCheckpointRepositoryImpl(
        prefs: prefs,
        owner: owner,
        barrier: barrier,
        secureStore: secure,
        remote: Remote(),
      );
      final reset = AccountDataReset(
        isar,
        prefs,
        owner: owner,
        encryptedAccountPreferences: secure,
        documentsDirectory: () async => dir,
      );
      await repo.saveLocal(expectedOwnerId: 'a', pageNumber: 42);
      final original = (await repo.readLocal(expectedOwnerId: 'a'))!;
      await reset.clearAccountOwnedData(departingOwnerId: 'a');
      owner.currentOwnerId = 'b';
      barrier.prepareOwner('b');
      await barrier.markOwnerReady('b');
      expect(await repo.readLocal(expectedOwnerId: 'b'), isNull);
      owner.currentOwnerId = 'a';
      barrier.prepareOwner('a');
      await barrier.markOwnerReady('a');
      final recovered = (await repo.readLocal(expectedOwnerId: 'a'))!;
      expect(recovered.pageNumber, 42);
      expect(recovered.pendingMutationId, original.pendingMutationId);
      expect(PendingCheckpointRecoveryMarker.contains(prefs, 'a'), isTrue);
      await reset.eraseDeletedAccountLocally(departingOwnerId: 'a');
      expect(await secure.read('a', 'reading_checkpoint_v1'), isNull);
      expect(PendingCheckpointRecoveryMarker.contains(prefs, 'a'), isFalse);
    },
  );
}
