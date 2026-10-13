import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/adult_journey/data/adult_journey_preferences_codec.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';

void main() {
  const codec = AdultJourneyPreferencesCodec();

  String raw(Map<String, Object?> fields) =>
      jsonEncode({'schemaVersion': 1, ...fields});

  test('missing record', () {
    expect(codec.decode(null), AdultJourneyLoadResult.missing);
  });

  test('round-trips every field', () {
    final value = AdultJourneyPreferences(
      goal: AdultJourneyGoal.azkar,
      experience: AdultJourneyExperience.beginner,
      profileCompleted: true,
      setupSnoozedLocalDate: '2026-10-10',
      todayLocalDate: '2026-10-11',
      todayMinutes: 10,
      lightReturnToday: true,
      lastHomeSeenAtUtc: DateTime.utc(2026, 10, 11, 8, 30),
      returnOfferLocalDate: '2026-10-11',
      returnDismissedLocalDate: '2026-10-09',
    );
    expect(
      codec.decode(codec.encode(value)),
      AdultJourneyLoadResult.ready(value),
    );
  });

  test('every goal round-trips, and null goal stays null', () {
    for (final goal in [...AdultJourneyGoal.values, null]) {
      final value = AdultJourneyPreferences(goal: goal);
      expect(codec.decode(codec.encode(value)).preferences.goal, goal);
    }
  });

  test('the stored JSON carries no owner id', () {
    final json = jsonDecode(codec.encode(AdultJourneyPreferences.empty)) as Map;
    expect(json.keys, isNot(contains('ownerId')));
    expect(json['schemaVersion'], 1);
  });

  group('rejects', () {
    final corrupt = {
      'invalid JSON': '{not json',
      'a list': '[]',
      'missing version': jsonEncode({'goal': 'reading'}),
      'string version': jsonEncode({'schemaVersion': '1'}),
      'minutes 7': raw({'todayMinutes': 7}),
      'unknown goal': raw({'goal': 'tafsir'}),
      'string flag': raw({'profileCompleted': 'yes'}),
      'bad local date': raw({'todayLocalDate': '2026-13-40'}),
      'non-UTC instant': raw({'lastHomeSeenAtUtc': '2026-10-11T08:00:00'}),
    };
    for (final entry in corrupt.entries) {
      test('${entry.key} as corrupt', () {
        expect(codec.decode(entry.value), AdultJourneyLoadResult.corrupt);
      });
    }

    test('a newer schema as unsupported', () {
      expect(
        codec.decode(jsonEncode({'schemaVersion': 2, 'goal': 'reading'})),
        AdultJourneyLoadResult.unsupported,
      );
    });
  });
}
