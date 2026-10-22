import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_lengths.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_review/domain/repositories/prayer_review_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

class _Repository implements PrayerReviewRepository {
  PrayerReviewSelection? saved;
  int writes = 0;
  List<PrayerReviewSelection> dayAssignments = [];
  @override
  Future<List<PrayerReviewSelection>> readAssignmentsForDay(String day) async =>
      dayAssignments;
  @override
  Future<PrayerReviewSelection?> readAssignment({
    required String localDayKey,
    required String occurrenceKey,
  }) async => saved;
  @override
  Future<List<PrayerReviewReceipt>> readReceipts(String day) async => [];
  @override
  Future<PrayerReviewSelection> saveAssignmentIfAbsent(
    PrayerReviewSelection selection,
    PrayerReviewAuthority authority,
  ) async {
    authority.check();
    writes++;
    return saved ??= selection;
  }

  @override
  Future<PrayerReviewSelection?> consumePrompt(
    String key,
    PrayerReviewAuthority authority,
  ) async => saved;
}

void main() {
  late AccountDataBarrier barrier;
  late PrayerReviewLengths lengths;
  late _Repository repository;
  var enabled = true;
  var adult = true;
  var recordReads = 0;
  Future<bool> Function()? eligibility;
  final now = DateTime.utc(2026, 10, 20, 10);
  final occurrence = PrayerOccurrence(
    ownerId: 'owner',
    localDate: DateTime(2026, 10, 20),
    prayerKey: PrayerKey.dhuhr,
    scheduledAt: now.add(const Duration(hours: 2)),
  );

  PrayerReviewOfferService service() => PrayerReviewOfferService(
    repository: repository,
    lengths: lengths,
    isEnabled: () => enabled,
    captureAuthority: () =>
        PrayerReviewAuthority(ownerId: 'owner', lease: barrier.capture()),
    readAdultEligibility: () => eligibility?.call() ?? Future.value(adult),
    readRecords: () async {
      recordReads++;
      return [
        for (var n = 1; n <= 4; n++)
          AyahReviewRecord(
            surahId: 1,
            ayahNumber: n,
            strengthLevel: 7,
            intervalDays: 7,
            lastReviewedAt: now.subtract(const Duration(days: 1)),
            nextReviewDate: now.add(const Duration(days: 2)),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.v2Session,
          ),
      ];
    },
    readCanonicalAyahs: (_) async => [
      for (var n = 1; n <= 4; n++)
        Ayah(number: n, surahId: 1, numberInSurah: n, page: 1, text: ''),
    ],
    now: () => now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    lengths = PrayerReviewLengths(prefs, barrier);
    repository = _Repository();
    enabled = adult = true;
    recordReads = 0;
    eligibility = null;
  });

  test(
    'frozen assignment wins after settings change without re-reading records',
    () async {
      await lengths.write('owner', PrayerKey.dhuhr, 3, barrier.capture());
      final first = await service().forOccurrence(occurrence);
      expect(first?.selection.endAyah, 3);
      await lengths.write('owner', PrayerKey.dhuhr, 15, barrier.capture());
      final retry = await service().forOccurrence(occurrence);
      expect(retry?.selection, first?.selection);
      expect(recordReads, 1);
      expect(repository.writes, 1);
    },
  );

  test('a passage already assigned to another prayer today is not reused', () async {
    await lengths.write('owner', PrayerKey.dhuhr, 3, barrier.capture());
    final probe = await service().forOccurrence(occurrence);
    final taken = probe!.selection;
    repository
      ..saved = null
      ..dayAssignments = [
        PrayerReviewSelection(
          ownerId: 'owner',
          localDayKey: taken.localDayKey,
          prayerKey: PrayerKey.asr,
          scheduledAt: taken.scheduledAt.add(const Duration(hours: 3)),
          selectedAt: taken.selectedAt,
          surahId: taken.surahId,
          startAyah: taken.startAyah,
          endAyah: taken.endAyah,
        ),
      ];
    final next = await service().forOccurrence(occurrence);
    expect(
      next == null ||
          next.selection.surahId != taken.surahId ||
          next.selection.startAyah != taken.startAyah ||
          next.selection.endAyah != taken.endAyah,
      isTrue,
    );
  });

  test(
    'disabled and child paths never read review records or save assignments',
    () async {
      enabled = false;
      expect(await service().forOccurrence(occurrence), isNull);
      enabled = true;
      adult = false;
      expect(await service().forOccurrence(occurrence), isNull);
      expect(recordReads, 0);
      expect(repository.writes, 0);
    },
  );

  test(
    'invalidation during profile load cannot create a fresh assignment',
    () async {
      final pending = Completer<bool>();
      eligibility = () => pending.future;
      final result = service().forOccurrence(occurrence);
      barrier.invalidate();
      pending.complete(true);
      await expectLater(
        result,
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(recordReads, 0);
      expect(repository.writes, 0);
    },
  );

  test('confirmation lookup does not pick an unexposed passage', () async {
    expect(
      await service().forOccurrence(occurrence, allowSelection: false),
      isNull,
    );
    expect(recordReads, 0);
    expect(repository.writes, 0);
  });

  test(
    'an occurrence already started never creates a new suggestion',
    () async {
      final past = PrayerOccurrence(
        ownerId: 'owner',
        localDate: occurrence.localDate,
        prayerKey: occurrence.prayerKey,
        scheduledAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(await service().forOccurrence(past), isNull);
      expect(recordReads, 0);
      expect(repository.writes, 0);
    },
  );
}
