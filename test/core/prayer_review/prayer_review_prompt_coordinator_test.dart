import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_prompt_coordinator.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';

void main() {
  late AccountDataBarrier barrier;
  late PrayerReviewAuthority authority;
  late PrayerReviewPromptCoordinator coordinator;
  late PrayerReviewOffer offer;
  var reads = 0;
  var claims = 0;
  var claimed = false;
  var enabled = true;
  final now = DateTime(2026, 10, 20, 13);
  final occurrence = PrayerOccurrence(
    ownerId: 'owner',
    localDate: DateTime(2026, 10, 20),
    prayerKey: PrayerKey.dhuhr,
    scheduledAt: DateTime(2026, 10, 20, 12),
  );
  final record = PrayerCompanionRecord(
    occurrence: occurrence,
    status: PrayerCompanionStatus.confirmed,
    statusUpdatedAt: now,
    followUpCount: 0,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    barrier = AccountDataBarrier.forPreferences(prefs)
      ..owner = const FixedRecordOwnerProvider('owner');
    authority = PrayerReviewAuthority(
      ownerId: 'owner',
      lease: barrier.capture(),
    );
    offer = PrayerReviewOffer(
      authority: authority,
      selection: PrayerReviewSelection(
        ownerId: 'owner',
        localDayKey: '2026-10-20',
        prayerKey: PrayerKey.dhuhr,
        scheduledAt: occurrence.scheduledAt.toUtc(),
        selectedAt: occurrence.scheduledAt.toUtc(),
        surahId: 1,
        startAyah: 1,
        endAyah: 3,
      ),
    );
    reads = claims = 0;
    claimed = false;
    enabled = true;
    coordinator = PrayerReviewPromptCoordinator(
      captureAuthority: () => authority,
      isEnabled: () => enabled,
      loadExisting: (_) async {
        reads++;
        return offer;
      },
      readAdultEligibility: () async => true,
      claimPrompt: (_, original) async {
        expect(identical(original, authority), isTrue);
        claims++;
        if (claimed) return null;
        claimed = true;
        return offer.selection.copyWith(promptConsumed: true);
      },
      now: () => now,
    );
  });

  test(
    'only a fresh explicit foreground confirmation claims the prompt once',
    () async {
      expect(
        await coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: false,
          foreground: true,
        ),
        isNull,
      );
      expect(
        await coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: true,
          foreground: false,
        ),
        isNull,
      );
      expect(reads, 0);
      final results = await Future.wait([
        coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: true,
          foreground: true,
        ),
        coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: true,
          foreground: true,
        ),
      ]);
      expect(results.whereType<PrayerReviewOffer>(), hasLength(1));
      expect(claims, 2);
    },
  );

  test(
    'disabled and invalidated work never reads a private assignment',
    () async {
      enabled = false;
      expect(
        await coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: true,
          foreground: true,
        ),
        isNull,
      );
      enabled = true;
      barrier.invalidate();
      await expectLater(
        coordinator.forConfirmation(
          record,
          authority: authority,
          newlyConfirmed: true,
          foreground: true,
        ),
        throwsA(isA<AccountDataUnavailableException>()),
      );
      expect(reads, 0);
      expect(claims, 0);
    },
  );
}
