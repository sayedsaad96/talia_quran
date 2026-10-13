import 'dart:convert';

import '../domain/entities/adult_journey_preferences.dart';
import '../domain/services/adult_local_date.dart';

/// JSON v1 for [AdultJourneyPreferences] (spec §5). Decoding validates every
/// field; anything unexpected is reported as corrupt rather than guessed.
class AdultJourneyPreferencesCodec {
  const AdultJourneyPreferencesCodec();

  String encode(AdultJourneyPreferences value) => jsonEncode({
    'schemaVersion': AdultJourneyPreferences.schemaVersion,
    'goal': value.goal?.name,
    'experience': value.experience?.name,
    'profileCompleted': value.profileCompleted,
    'setupSnoozedLocalDate': value.setupSnoozedLocalDate,
    'todayLocalDate': value.todayLocalDate,
    'todayMinutes': value.todayMinutes,
    'lightReturnToday': value.lightReturnToday,
    'lastHomeSeenAtUtc': value.lastHomeSeenAtUtc?.toUtc().toIso8601String(),
    'returnOfferLocalDate': value.returnOfferLocalDate,
    'returnDismissedLocalDate': value.returnDismissedLocalDate,
  });

  AdultJourneyLoadResult decode(String? raw) {
    if (raw == null) return AdultJourneyLoadResult.missing;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return AdultJourneyLoadResult.corrupt;
    }
    if (json is! Map<String, dynamic>) return AdultJourneyLoadResult.corrupt;
    final version = json['schemaVersion'];
    if (version is! int) return AdultJourneyLoadResult.corrupt;
    if (version != AdultJourneyPreferences.schemaVersion) {
      return version > AdultJourneyPreferences.schemaVersion
          ? AdultJourneyLoadResult.unsupported
          : AdultJourneyLoadResult.corrupt;
    }
    try {
      return AdultJourneyLoadResult.ready(_fromJson(json));
    } on FormatException {
      return AdultJourneyLoadResult.corrupt;
    }
  }

  AdultJourneyPreferences _fromJson(Map<String, dynamic> json) {
    final minutes = _optional<int>(json, 'todayMinutes');
    if (minutes != null && !adultJourneyMinuteChoices.contains(minutes)) {
      throw const FormatException('todayMinutes');
    }
    return AdultJourneyPreferences(
      goal: _enum(json, 'goal', AdultJourneyGoal.values),
      experience: _enum(json, 'experience', AdultJourneyExperience.values),
      profileCompleted: _optional<bool>(json, 'profileCompleted') ?? false,
      setupSnoozedLocalDate: _date(json, 'setupSnoozedLocalDate'),
      todayLocalDate: _date(json, 'todayLocalDate'),
      todayMinutes: minutes,
      lightReturnToday: _optional<bool>(json, 'lightReturnToday') ?? false,
      lastHomeSeenAtUtc: _instant(json, 'lastHomeSeenAtUtc'),
      returnOfferLocalDate: _date(json, 'returnOfferLocalDate'),
      returnDismissedLocalDate: _date(json, 'returnDismissedLocalDate'),
    );
  }

  static T? _optional<T>(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! T) throw FormatException(key);
    return value;
  }

  static E? _enum<E extends Enum>(
    Map<String, dynamic> json,
    String key,
    List<E> values,
  ) {
    final name = _optional<String>(json, key);
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException(key);
  }

  static String? _date(Map<String, dynamic> json, String key) {
    final value = _optional<String>(json, key);
    if (value != null && !AdultLocalDate.isValid(value)) {
      throw FormatException(key);
    }
    return value;
  }

  static DateTime? _instant(Map<String, dynamic> json, String key) {
    final value = _optional<String>(json, key);
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null || !parsed.isUtc) throw FormatException(key);
    return parsed;
  }
}
