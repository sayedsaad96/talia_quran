import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/home_widget/widget_snapshot_source.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/core/memorization/review_record_audience_scope.dart';
import 'package:talia_quran/core/memorization/review_record_identity.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/khatmah/domain/repositories/khatmah_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/ayah_review_record.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';

class _Records extends Mock implements MemorizationPlusRepository {}

class _Prayers extends Mock implements PrayerTimesService {}

class _Khatmah extends Mock implements KhatmahRepository {}

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  late _Records records;
  late _Prayers prayers;
  late _Khatmah khatmah;
  late AccountDataBarrier barrier;
  late WidgetSnapshotSource source;
  var enabled = true;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    const owner = FixedRecordOwnerProvider('a');
    barrier = AccountDataBarrier.forPreferences(
      await SharedPreferences.getInstance(),
    )..owner = owner;
    records = _Records();
    prayers = _Prayers();
    khatmah = _Khatmah();
    when(() => records.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      ),
    );
    when(
      () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    ).thenAnswer(
      (_) async => Right([
        AyahReviewRecord(
          surahId: 1,
          ayahNumber: 1,
          strengthLevel: 6,
          intervalDays: 1,
          lastReviewedAt: now.subtract(const Duration(days: 2)),
          nextReviewDate: now.subtract(const Duration(days: 1)),
          totalReviews: 1,
          lastRating: null,
          createdByMode: ReviewRecordCreatedByMode.v2Session,
        ),
      ]),
    );
    when(() => prayers.current(isArabic: true)).thenAnswer((_) async => null);
    when(() => prayers.tomorrowFajr()).thenAnswer((_) async => null);
    when(() => khatmah.getActivePlan()).thenAnswer((_) async => null);
    enabled = true;
    source = WidgetSnapshotSource(
      owner: owner,
      records: records,
      path: MemorizationPathResolver(records),
      prayers: prayers,
      khatmah: khatmah,
      isEnabled: () => enabled,
      now: () => now,
    );
  });
  test(
    'adult count uses the existing read scope and never saves progress',
    () async {
      final snapshot = await source.load(barrier.capture(), 'a');
      expect(snapshot.dueReviewCount, 1);
      verify(
        () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
      ).called(1);
    },
  );
  test('disabled flag never reads account material', () async {
    enabled = false;
    expect((await source.load(barrier.capture(), 'a')).isEmpty, isTrue);
    verifyNever(() => records.getMemorizationProfile());
  });
  test('unknown profile cannot expose adult reviews', () async {
    when(
      () => records.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(MemorizationProfile.empty()));
    expect((await source.load(barrier.capture(), 'a')).isEmpty, isTrue);
    verifyNever(
      () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
    );
  });
  test(
    'account switch rejects material returning from a delayed read',
    () async {
      final pending = Completer<MemorizationProfile>();
      when(
        () => records.getMemorizationProfile(),
      ).thenAnswer((_) async => Right(await pending.future));
      final loading = source.load(barrier.capture(), 'a');
      barrier.invalidate();
      pending.complete(
        MemorizationProfile.empty().copyWith(
          selectedPath: MemorizationPath.adult,
        ),
      );
      await expectLater(
        loading,
        throwsA(isA<AccountDataUnavailableException>()),
      );
      verifyNever(
        () => records.getAllReviewRecords(scope: ReviewRecordReadScope.adult),
      );
    },
  );
  WidgetSnapshotSource sourceFor(
    RecordOwnerProvider owner, {
    String Function()? languageCode,
  }) => WidgetSnapshotSource(
    owner: owner,
    records: records,
    path: MemorizationPathResolver(records),
    prayers: prayers,
    khatmah: khatmah,
    isEnabled: () => enabled,
    now: () => now,
    languageCode: languageCode,
  );
  test(
    'a guest owner gets a populated snapshot once the barrier is ready',
    () async {
      const guest = FixedRecordOwnerProvider(ReviewRecordIdentity.localOwnerId);
      barrier.owner = guest;
      final snapshot = await sourceFor(
        guest,
      ).load(barrier.capture(), ReviewRecordIdentity.localOwnerId);
      expect(guest.isSignedIn, isFalse);
      expect(snapshot.dueReviewCount, 1);
      expect(snapshot.isEmpty, isFalse);
    },
  );
  test(
    'the snapshot carries the app language, not the device language',
    () async {
      const owner = FixedRecordOwnerProvider('a');
      final snapshot = await sourceFor(
        owner,
        languageCode: () => 'en',
      ).load(barrier.capture(), 'a');
      expect(snapshot.languageCode, 'en');
      expect(snapshot.toJson()['locale'], 'en');
    },
  );
  test(
    'production after-isha prayers (no tomorrow snapshot) keep a next fajr',
    () async {
      // PrayerTimesService.current() after Isha: today's fields are all past,
      // nextName/nextTime is tomorrow's Fajr, and the source passes
      // `tomorrow: null` to the builder.
      final tomorrowFajr = DateTime.utc(2026, 10, 24, 3, 0);
      DateTime past(int hour) => DateTime.utc(2026, 10, 23, hour);
      when(() => prayers.current(isArabic: true)).thenAnswer(
        (_) async => PrayerTimesSnapshot(
          city: const PrayerCity(
            id: 'c',
            nameAr: 'م',
            nameEn: 'C',
            latitude: 0,
            longitude: 0,
            timeZone: 'UTC',
            countryId: 'x',
            countryAr: 'ب',
            countryEn: 'X',
            defaultMethod: 'muslim_world_league',
          ),
          nextName: 'fajr',
          nextTime: tomorrowFajr,
          minutesUntil: 900,
          fajr: past(3),
          sunrise: past(5),
          dhuhr: past(10),
          asr: past(8),
          maghrib: past(9),
          isha: past(11),
        ),
      );
      final snapshot = await sourceFor(
        const FixedRecordOwnerProvider('a'),
      ).load(barrier.capture(), 'a');
      expect(snapshot.nextPrayerKey, 'fajr');
      expect(snapshot.nextPrayerAt, tomorrowFajr);
      expect(snapshot.upcomingPrayers, [(key: 'fajr', at: tomorrowFajr)]);
    },
  );
  test(
    'tomorrow fajr from the service is published when today has no prayer data',
    () async {
      final tomorrowFajr = DateTime.utc(2026, 10, 24, 3, 0);
      when(() => prayers.tomorrowFajr()).thenAnswer((_) async => tomorrowFajr);
      final snapshot = await sourceFor(
        const FixedRecordOwnerProvider('a'),
      ).load(barrier.capture(), 'a');
      expect(snapshot.upcomingPrayers, [(key: 'fajr', at: tomorrowFajr)]);
    },
  );
}
