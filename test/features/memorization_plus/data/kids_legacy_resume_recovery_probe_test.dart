import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/v2/session_phase.dart';
import 'package:talia_quran/features/memorization_plus/data/models/isar_v2_session.dart';
import 'package:talia_quran/features/memorization_plus/data/repositories/collaborators/kids_legacy_resume_recovery_probe.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/isar_test_core.dart';

class _Owner implements RecordOwnerProvider {
  _Owner(this.currentOwnerId);

  @override
  String currentOwnerId;

  @override
  bool get isSignedIn => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Isar isar;
  late Directory directory;
  late _Owner owner;
  late AccountDataBarrier barrier;
  late KidsLegacyResumeRecoveryProbe probe;

  setUp(() async {
    await initializeIsarCoreForTests();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    owner = _Owner('a');
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    directory = await Directory.systemTemp.createTemp('talia_kids_probe_');
    isar = await Isar.open(
      [IsarV2SessionSchema],
      directory: directory.path,
      name: 'kids_probe_${DateTime.now().microsecondsSinceEpoch}',
    );
    probe = KidsLegacyResumeRecoveryProbe(
      isar: isar,
      owner: owner,
      barrier: barrier,
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<void> save({
    String rowOwner = 'a',
    MemorizationAudience audience = MemorizationAudience.kids,
    int surahId = 67,
    int ayah = 3,
    V2SessionPhase phase = V2SessionPhase.learning,
    String? blockCsv,
    bool review = false,
  }) => isar.writeTxn(() async {
    final row = IsarV2Session.create(
      ownerId: rowOwner,
      audience: audience,
      surahId: surahId,
      review: review,
      blockAyahNumbers: [ayah],
      currentAyahIndex: 0,
      phaseIndex: phase.index,
      passedAyahNumbers: const {},
      failureCounts: const {},
      hintLevels: const {},
      blockReviewRequired: false,
    );
    if (blockCsv != null) row.blockAyahNumbersCsv = blockCsv;
    await isar.isarV2Sessions.put(row);
  });

  test(
    'valid original kids single-ayah resume requires an explicit choice',
    () async {
      await save();

      final result = await probe.inspect(surahId: 67, lease: barrier.capture());

      expect(
        result,
        const KidsLegacyResumeProbeResult.choiceRequired(checkpointAyah: 3),
      );
    },
  );

  for (final invalid in <({String name, Future<void> Function() save})>[
    (name: 'foreign', save: () => save(rowOwner: 'b')),
    (name: 'adult', save: () => save(audience: MemorizationAudience.adult)),
    (name: 'created', save: () => save(phase: V2SessionPhase.created)),
    (name: 'completed', save: () => save(phase: V2SessionPhase.completed)),
    (
      name: 'invalid phase',
      save: () async {
        await save();
        await isar.writeTxn(() async {
          final row = (await isar.isarV2Sessions.where().findAll()).single;
          row.phaseIndex = 999;
          await isar.isarV2Sessions.put(row);
        });
      },
    ),
    (name: 'review lane', save: () => save(review: true)),
    (name: 'zero ayah', save: () => save(blockCsv: '0')),
    (name: 'malformed block', save: () => save(blockCsv: '3,4')),
  ]) {
    test('${invalid.name} checkpoint is excluded without mutation', () async {
      await invalid.save();

      final result = await probe.inspect(surahId: 67, lease: barrier.capture());

      expect(result, const KidsLegacyResumeProbeResult.none());
      expect(await isar.isarV2Sessions.count(), 1);
    });
  }

  test(
    'an invalidated original lease fails closed without changing checkpoint',
    () async {
      await save();
      final lease = barrier.capture();
      barrier.invalidate();

      final result = await probe.inspect(surahId: 67, lease: lease);

      expect(result, const KidsLegacyResumeProbeResult.unavailable());
      expect(await isar.isarV2Sessions.count(), 1);
    },
  );
}
