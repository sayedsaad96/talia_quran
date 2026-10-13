import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_journey_update_reducer.dart';
import 'package:talia_quran/features/adult_journey/domain/services/adult_return_policy.dart';

void main() {
  const reducer = AdultJourneyUpdateReducer(
    returnPolicy: AdultReturnPolicy(toLocal: _utc),
  );

  test('saving the profile keeps today and visit fields', () {
    final current = AdultJourneyPreferences(
      todayLocalDate: '2026-10-11',
      todayMinutes: 10,
      lastHomeSeenAtUtc: DateTime.utc(2026, 10, 11, 8),
    );
    final next = reducer.reduce(
      current,
      const SaveAdultProfile(
        goal: AdultJourneyGoal.review,
        experience: AdultJourneyExperience.returning,
      ),
    )!;
    expect(next.goal, AdultJourneyGoal.review);
    expect(next.experience, AdultJourneyExperience.returning);
    expect(next.profileCompleted, isTrue);
    expect(next.todayMinutes, 10);
    expect(next.lastHomeSeenAtUtc, DateTime.utc(2026, 10, 11, 8));
  });

  test('clearing today keeps the profile and return fields', () {
    const current = AdultJourneyPreferences(
      goal: AdultJourneyGoal.reading,
      profileCompleted: true,
      todayLocalDate: '2026-10-11',
      todayMinutes: 5,
      lightReturnToday: true,
      returnOfferLocalDate: '2026-10-11',
    );
    final next = reducer.reduce(current, const ClearAdultToday())!;
    expect(next.todayLocalDate, isNull);
    expect(next.todayMinutes, isNull);
    expect(next.lightReturnToday, isFalse);
    expect(next.goal, AdultJourneyGoal.reading);
    expect(next.returnOfferLocalDate, '2026-10-11');
  });

  test('a command that changes nothing returns null (no write)', () {
    expect(
      reducer.reduce(AdultJourneyPreferences.empty, const ClearAdultToday()),
      isNull,
    );
  });

  test('only 5, 10 and 20 minutes can be set', () {
    expect(
      () => SetAdultToday(localDate: '2026-10-11', minutes: 7),
      throwsArgumentError,
    );
    final next = reducer.reduce(
      AdultJourneyPreferences.empty,
      SetAdultToday(localDate: '2026-10-11', minutes: 20),
    )!;
    expect(next.minutesFor('2026-10-11'), 20);
    expect(next.minutesFor('2026-10-12'), isNull, reason: 'expires next day');
  });

  group('home visit', () {
    test('first visit records a baseline without an offer', () {
      final next = reducer.reduce(
        AdultJourneyPreferences.empty,
        RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 8)),
      )!;
      expect(next.lastHomeSeenAtUtc, DateTime.utc(2026, 10, 11, 8));
      expect(next.returnOfferLocalDate, isNull);
    });

    test('a second visit on the same local day writes nothing', () {
      final current = AdultJourneyPreferences(
        lastHomeSeenAtUtc: DateTime.utc(2026, 10, 11, 8),
      );
      expect(
        reducer.reduce(
          current,
          RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 22)),
        ),
        isNull,
      );
    });

    test('a visit after seven days stores the offer with the new visit', () {
      final current = AdultJourneyPreferences(
        lastHomeSeenAtUtc: DateTime.utc(2026, 10, 4, 23, 59),
      );
      final next = reducer.reduce(
        current,
        RecordAdultHomeVisit(DateTime.utc(2026, 10, 11, 0, 1)),
      )!;
      expect(next.lastHomeSeenAtUtc, DateTime.utc(2026, 10, 11, 0, 1));
      expect(next.returnOfferLocalDate, '2026-10-11');
    });

    test('a visit after six days moves the baseline without an offer', () {
      final current = AdultJourneyPreferences(
        lastHomeSeenAtUtc: DateTime.utc(2026, 10, 5),
      );
      final next = reducer.reduce(
        current,
        RecordAdultHomeVisit(DateTime.utc(2026, 10, 11)),
      )!;
      expect(next.returnOfferLocalDate, isNull);
    });

    test('a future stored visit is replaced without an offer', () {
      final current = AdultJourneyPreferences(
        lastHomeSeenAtUtc: DateTime.utc(2027, 1, 1),
      );
      final next = reducer.reduce(
        current,
        RecordAdultHomeVisit(DateTime.utc(2026, 10, 11)),
      )!;
      expect(next.lastHomeSeenAtUtc, DateTime.utc(2026, 10, 11));
      expect(next.returnOfferLocalDate, isNull);
    });
  });

  test('snooze and dismissal are separate fields', () {
    final snoozed = reducer.reduce(
      AdultJourneyPreferences.empty,
      const SnoozeAdultSetup('2026-10-11'),
    )!;
    expect(snoozed.setupSnoozedLocalDate, '2026-10-11');
    expect(snoozed.returnDismissedLocalDate, isNull);
    final dismissed = reducer.reduce(
      snoozed,
      const DismissAdultReturn('2026-10-11'),
    )!;
    expect(dismissed.returnDismissedLocalDate, '2026-10-11');
    expect(dismissed.setupSnoozedLocalDate, '2026-10-11');
  });
}

DateTime _utc(DateTime value) => value.toUtc();
