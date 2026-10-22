import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_home_loader.dart';
import 'package:talia_quran/core/prayer_review/prayer_review_offer_service.dart';
import 'package:talia_quran/features/home/presentation/theme/home_skin.dart';
import 'package:talia_quran/features/home/presentation/widgets/prayer_review_home_slot.dart';
import 'package:talia_quran/features/prayer_companion/domain/entities/prayer_companion.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_authority.dart';
import 'package:talia_quran/features/prayer_review/domain/entities/prayer_review_selection.dart';

void main() {
  late PrayerReviewHomeOffer offer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final barrier = AccountDataBarrier.forPreferences(preferences)
      ..owner = const FixedRecordOwnerProvider('owner');
    final authority = PrayerReviewAuthority(
      ownerId: 'owner',
      lease: barrier.capture(),
    );
    final occurrence = PrayerOccurrence(
      ownerId: 'owner',
      localDate: DateTime(2026, 10, 20),
      prayerKey: PrayerKey.dhuhr,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
    );
    offer = PrayerReviewHomeOffer(
      occurrence: occurrence,
      offer: PrayerReviewOffer(
        authority: authority,
        selection: PrayerReviewSelection(
          ownerId: 'owner',
          localDayKey: '2026-10-20',
          prayerKey: PrayerKey.dhuhr,
          scheduledAt: occurrence.scheduledAt.toUtc(),
          selectedAt: DateTime.now().toUtc(),
          surahId: 1,
          startAyah: 1,
          endAyah: 3,
        ),
      ),
    );
  });

  testWidgets('does not resolve an offer when feature or adult gates are off', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      _harness(
        PrayerReviewHomeSlot(
          skin: HomeSkin.forBrightness(Brightness.light),
          isEnabled: false,
          isAdult: true,
          loadOffer: () async {
            calls++;
            return offer;
          },
        ),
      ),
    );
    await tester.pump();
    expect(calls, isZero);

    await tester.pumpWidget(
      _harness(
        PrayerReviewHomeSlot(
          skin: HomeSkin.forBrightness(Brightness.light),
          isEnabled: true,
          isAdult: false,
          loadOffer: () async {
            calls++;
            return offer;
          },
        ),
      ),
    );
    await tester.pump();
    expect(calls, isZero);
  });

  testWidgets('renders the frozen reference and opens its exact occurrence', (
    tester,
  ) async {
    PrayerOccurrence? opened;
    await tester.pumpWidget(
      _harness(
        PrayerReviewHomeSlot(
          skin: HomeSkin.forBrightness(Brightness.light),
          isEnabled: true,
          isAdult: true,
          loadOffer: () async => offer,
          onOpen: (occurrence) => opened = occurrence,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prayer_review_home_open')), findsOneWidget);
    expect(find.textContaining('1–3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prayer_review_home_open')));
    await tester.pump();
    expect(opened, offer.occurrence);
  });

  testWidgets('clears immediately on account change and ignores a late load', (
    tester,
  ) async {
    final changes = StreamController<void>();
    final delayed = Completer<PrayerReviewHomeOffer?>();
    await tester.pumpWidget(
      _harness(
        PrayerReviewHomeSlot(
          skin: HomeSkin.forBrightness(Brightness.light),
          isEnabled: true,
          isAdult: true,
          loadOffer: () => delayed.future,
          accountChanges: changes.stream,
        ),
      ),
    );
    await tester.pump();
    changes.add(null);
    await tester.pump();
    delayed.complete(offer);
    await tester.pumpAndSettle();

    expect(find.text('Review in your prayer'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(changes.close);
  });

  testWidgets('removes the card at the exact prayer expiry', (tester) async {
    var now = DateTime(2026, 10, 20, 11, 59, 59);
    final expiring = PrayerReviewHomeOffer(
      occurrence: PrayerOccurrence(
        ownerId: offer.occurrence.ownerId,
        localDate: offer.occurrence.localDate,
        prayerKey: offer.occurrence.prayerKey,
        scheduledAt: now.add(const Duration(seconds: 1)),
      ),
      offer: offer.offer,
    );
    await tester.pumpWidget(
      _harness(
        PrayerReviewHomeSlot(
          skin: HomeSkin.forBrightness(Brightness.light),
          isEnabled: true,
          isAdult: true,
          loadOffer: () async => expiring,
          now: () => now,
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('prayer_review_home_open')), findsOneWidget);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Review in your prayer'), findsNothing);
  });
}

Widget _harness(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
