import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_assignment.dart';
import 'package:talia_quran/features/prayer_review/data/models/isar_prayer_review_receipt.dart';
import 'package:talia_quran/features/prayer_review/data/repositories/isar_prayer_review_repository.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import '../../helpers/isar_test_core.dart';

void main() {
  setUpAll(initializeIsarCoreForTests);
  test(
    'concurrent prompt claims yield exactly one winner across retries',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const owner = FixedRecordOwnerProvider('owner');
      final barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
      final directory = await Directory(
        '.superpowers/tmp',
      ).createTemp('prompt_claim_');
      final isar = await Isar.open(
        [IsarPrayerReviewAssignmentSchema, IsarPrayerReviewReceiptSchema],
        directory: directory.path,
        name: 'prompt_${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        final repository = IsarPrayerReviewRepository(isar, owner, barrier);
        final authority = repository.captureAuthority();
        final selected = PrayerReviewSelection(
          ownerId: 'owner',
          localDayKey: '2026-10-20',
          prayerKey: PrayerKey.fajr,
          scheduledAt: DateTime.utc(2026, 10, 20, 4),
          selectedAt: DateTime.utc(2026, 10, 20, 3),
          surahId: 1,
          startAyah: 1,
          endAyah: 3,
        );
        await repository.saveAssignmentIfAbsent(selected, authority);
        final results = await Future.wait([
          repository.consumePrompt(selected.occurrenceKey, authority),
          repository.consumePrompt(selected.occurrenceKey, authority),
        ]);
        expect(results.whereType<PrayerReviewSelection>(), hasLength(1));
        expect(
          await repository.consumePrompt(selected.occurrenceKey, authority),
          isNull,
        );
        final retained = await repository.readAssignment(
          localDayKey: selected.localDayKey,
          occurrenceKey: selected.occurrenceKey,
        );
        expect(retained?.promptConsumed, isTrue);
        expect(retained?.startAyah, 1);
        expect(retained?.endAyah, 3);
      } finally {
        await isar.close(deleteFromDisk: true);
        expect(
          directory.absolute.path.startsWith(
            Directory('.superpowers/tmp').absolute.path,
          ),
          isTrue,
        );
        await directory.delete(recursive: true);
      }
    },
  );
}
