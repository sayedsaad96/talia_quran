import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_home_loader.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_lengths.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';
import 'package:talia_quran/features/prayer_review/domain/repositories/prayer_review_repository.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

void main() {
  final now = DateTime.utc(2026, 10, 20, 11, 50);
  late AccountDataBarrier barrier;
  late _Repository repository;
  late PrayerReviewHomeLoader loader;
  var enabled = true;
  var adult = true;
  var settings = const PrayerCompanionSettings();
  PrayerTimesSnapshot? snapshot;
  var settingsReads = 0;
  var snapshotReads = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(preferences)
      ..owner = const FixedRecordOwnerProvider('owner');
    repository = _Repository();
    enabled = adult = true;
    settings = const PrayerCompanionSettings();
    snapshot = _snapshot(now);
    settingsReads = snapshotReads = 0;
    final offerService = PrayerReviewOfferService(
      repository: repository,
      lengths: PrayerReviewLengths(preferences, barrier),
      isEnabled: () => enabled,
      captureAuthority: () =>
          PrayerReviewAuthority(ownerId: 'owner', lease: barrier.capture()),
      readAdultEligibility: () async => adult,
      readRecords: () async => [
        for (var number = 1; number <= 3; number++)
          AyahReviewRecord(
            surahId: 1,
            ayahNumber: number,
            strengthLevel: 7,
            intervalDays: 7,
            lastReviewedAt: now.subtract(const Duration(days: 2)),
            nextReviewDate: now.subtract(const Duration(days: 1)),
            totalReviews: 2,
            lastRating: PerformanceRating.average,
            createdByMode: ReviewRecordCreatedByMode.v2Session,
          ),
      ],
      readCanonicalAyahs: (_) async => [
        for (var number = 1; number <= 3; number++)
          Ayah(
            number: number,
            surahId: 1,
            numberInSurah: number,
            text: '',
            page: number == 1 ? 1 : 2,
          ),
      ],
      now: () => now,
    );
    loader = PrayerReviewHomeLoader(
      offers: offerService,
      isEnabled: () => enabled,
      readAdultEligibility: () async => adult,
      readSettings: () async {
        settingsReads++;
        return settings;
      },
      readPrayerTimes: () async {
        snapshotReads++;
        return snapshot;
      },
      accountChanges: const Stream.empty(),
      now: () => now,
    );
  });

  test('loads a fallback offer inside the no-preparation window', () async {
    final result = await loader.load();

    expect(result?.occurrence.prayerKey, PrayerKey.dhuhr);
    expect(result?.offer.selection.surahId, 1);
    expect(result?.offer.selection.startAyah, 1);
    expect(result?.offer.selection.endAyah, 3);
  });

  test(
    'suppresses Home fallback when Companion preparation is configured',
    () async {
      settings = const PrayerCompanionSettings(
        enabled: true,
        preparationMinutes: 5,
      );

      expect(await loader.load(), isNull);
      expect(repository.writes, isZero);
    },
  );

  test(
    'does not read settings or prayer times when feature or adult gate is off',
    () async {
      enabled = false;
      expect(await loader.load(), isNull);
      expect(settingsReads, isZero);
      expect(snapshotReads, isZero);
      enabled = true;
      adult = false;
      expect(await loader.load(), isNull);
      expect(settingsReads, isZero);
      expect(snapshotReads, isZero);
    },
  );

  test(
    'requires every obligatory prayer time before selecting a fallback',
    () async {
      snapshot = PrayerTimesSnapshot(
        city: _city,
        nextName: 'Dhuhr',
        nextTime: now.add(const Duration(minutes: 10)),
        minutesUntil: 10,
        fajr: now.subtract(const Duration(hours: 7)),
        sunrise: now.subtract(const Duration(hours: 6)),
        dhuhr: now.add(const Duration(minutes: 10)),
        asr: now.add(const Duration(hours: 3)),
        maghrib: now.add(const Duration(hours: 6)),
      );

      expect(await loader.load(), isNull);
      expect(repository.writes, isZero);
    },
  );
}

const _city = PrayerCity(
  id: 'test',
  nameAr: '',
  nameEn: '',
  latitude: 0,
  longitude: 0,
  timeZone: 'UTC',
  countryId: 'test',
  countryAr: '',
  countryEn: '',
  defaultMethod: 'MWL',
);

PrayerTimesSnapshot _snapshot(DateTime now) => PrayerTimesSnapshot(
  city: _city,
  nextName: 'Dhuhr',
  nextTime: now.add(const Duration(minutes: 10)),
  minutesUntil: 10,
  fajr: now.subtract(const Duration(hours: 7)),
  sunrise: now.subtract(const Duration(hours: 6)),
  dhuhr: now.add(const Duration(minutes: 10)),
  asr: now.add(const Duration(hours: 3)),
  maghrib: now.add(const Duration(hours: 6)),
  isha: now.add(const Duration(hours: 8)),
);

final class _Repository implements PrayerReviewRepository {
  PrayerReviewSelection? saved;
  int writes = 0;

  @override
  Future<List<PrayerReviewSelection>> readAssignmentsForDay(
    String localDayKey,
  ) async => const [];

  @override
  Future<PrayerReviewSelection?> readAssignment({
    required String localDayKey,
    required String occurrenceKey,
  }) async => saved;

  @override
  Future<List<PrayerReviewReceipt>> readReceipts(String localDayKey) async =>
      [];

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
    String occurrenceKey,
    PrayerReviewAuthority authority,
  ) async => saved;
}
