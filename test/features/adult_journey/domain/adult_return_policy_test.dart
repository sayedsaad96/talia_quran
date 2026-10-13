import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_return_policy.dart';

void main() {
  // Tests pin the "local" zone to UTC so they never depend on the machine.
  const utcPolicy = AdultReturnPolicy(toLocal: _utc);

  AdultReturnDecision evaluate({
    required DateTime now,
    DateTime? last,
    String? offer,
    String? dismissed,
    bool returning = false,
    AdultReturnPolicy policy = utcPolicy,
  }) => policy.evaluate(
    now: now,
    lastHomeSeenAtUtc: last,
    returnOfferLocalDate: offer,
    returnDismissedLocalDate: dismissed,
    explicitlyReturning: returning,
  );

  test('seven calendar days qualifies despite less than 168 hours', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11, 0, 1),
      last: DateTime.utc(2026, 10, 4, 23, 59),
    );
    expect(result.showOffer, isTrue);
    expect(result.eligibleLocalDate, '2026-10-11');
    expect(result.reason, AdultReturnReason.absence);
  });

  test('six calendar days does not qualify', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11, 23, 59),
      last: DateTime.utc(2026, 10, 5, 0, 1),
    );
    expect(result.showOffer, isFalse);
  });

  test('no previous visit (first run or upgrade) never infers absence', () {
    expect(evaluate(now: DateTime.utc(2026, 10, 11)).showOffer, isFalse);
  });

  test('a future previous visit never offers', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11),
      last: DateTime.utc(2026, 12, 1),
    );
    expect(result.showOffer, isFalse);
  });

  test('dismissed today hides the offer, even if stored for today', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11, 9),
      last: DateTime.utc(2026, 10, 1),
      offer: '2026-10-11',
      dismissed: '2026-10-11',
      returning: true,
    );
    expect(result.showOffer, isFalse);
  });

  test('an offer stored for today survives a reopen after the visit moved', () {
    // The visit was already replaced by today's instant; the stored offer
    // day keeps the invitation for the rest of the day.
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11, 18),
      last: DateTime.utc(2026, 10, 11, 8),
      offer: '2026-10-11',
    );
    expect(result.showOffer, isTrue);
    expect(result.reason, AdultReturnReason.absence);
  });

  test('an offer stored for an earlier day is not shown today', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 12, 8),
      last: DateTime.utc(2026, 10, 11, 8),
      offer: '2026-10-11',
    );
    expect(result.showOffer, isFalse);
  });

  test('self-described returning shows options without an absence claim', () {
    final result = evaluate(
      now: DateTime.utc(2026, 10, 11),
      last: DateTime.utc(2026, 10, 10),
      returning: true,
    );
    expect(result.showOffer, isTrue);
    expect(result.reason, AdultReturnReason.selfDescribed);
  });

  test('calendar days use the injected zone, not the instant difference', () {
    // 2026-10-04 22:30Z is 2026-10-05 01:30 at UTC+3; 2026-10-11 21:30Z is
    // 2026-10-12 00:30 there: 7 local days although it is 167 hours.
    final plusThree = AdultReturnPolicy(
      toLocal: (value) => value.toUtc().add(const Duration(hours: 3)),
    );
    final last = DateTime.utc(2026, 10, 4, 22, 30);
    final now = DateTime.utc(2026, 10, 11, 21, 30);
    expect(now.difference(last).inDays, 6);
    expect(plusThree.calendarDayGap(last, now), 7);
    expect(evaluate(now: now, last: last, policy: plusThree).showOffer, isTrue);
  });

  test('the same instants can be six local days apart in another zone', () {
    // At UTC+3 a visit at 2026-10-05 20:00Z (23:00 local) and now at
    // 2026-10-11 22:00Z (2026-10-12 01:00 local) are 7 days apart, while in
    // UTC they are only 6.
    final plusThree = AdultReturnPolicy(
      toLocal: (value) => value.toUtc().add(const Duration(hours: 3)),
    );
    final last = DateTime.utc(2026, 10, 5, 20);
    final now = DateTime.utc(2026, 10, 11, 22);
    expect(utcPolicy.calendarDayGap(last, now), 6);
    expect(plusThree.calendarDayGap(last, now), 7);
  });

  test('a zone change that moves now before the stored day gives no offer', () {
    final minusTen = AdultReturnPolicy(
      toLocal: (value) => value.toUtc().subtract(const Duration(hours: 10)),
    );
    final last = DateTime.utc(2026, 10, 11, 12);
    final now = DateTime.utc(2026, 10, 11, 13);
    expect(minusTen.calendarDayGap(last, now), 0);
    expect(evaluate(now: now, last: last, policy: minusTen).showOffer, isFalse);
  });
}

DateTime _utc(DateTime value) => value.toUtc();
