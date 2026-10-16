import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

import '../../data/models/zikr_model.dart';
import '../entities/azkar_entities.dart';

/// The subcategory label as stored verbatim in `azkar_release.json`.
const String afterPrayerAzkarSubcategory = 'أذكار بعد الصلاة';

enum PrayerSlot { fajr, dhuhr, asr, maghrib, isha }

final class AfterPrayerWindow extends Equatable {
  const AfterPrayerWindow({
    required this.prayer,
    required this.from,
    required this.until,
  });

  final PrayerSlot prayer;
  final DateTime from;
  final DateTime until;

  @override
  List<Object?> get props => [prayer, from, until];
}

/// The window right after the most recent prayer:
/// [prayerTime + offset, prayerTime + length], clipped so it never overlaps the
/// next prayer time. Null outside every window.
AfterPrayerWindow? activeAfterPrayerWindow({
  required Map<PrayerSlot, DateTime> todayTimes,
  required DateTime now,
  int offsetMinutes = 10,
  int lengthMinutes = 60,
}) {
  final entries = todayTimes.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (var i = 0; i < entries.length; i++) {
    final from = entries[i].value.add(Duration(minutes: offsetMinutes));
    var until = entries[i].value.add(Duration(minutes: lengthMinutes));
    if (i + 1 < entries.length && entries[i + 1].value.isBefore(until)) {
      until = entries[i + 1].value;
    }
    if (!now.isBefore(from) && now.isBefore(until)) {
      return AfterPrayerWindow(
        prayer: entries[i].key,
        from: from,
        until: until,
      );
    }
  }
  return null;
}

/// Ids of approved release records whose subcategory is exactly
/// [afterPrayerAzkarSubcategory] (searched in the general list). Records are
/// never rewritten; only ids are returned.
Future<List<String>> loadAfterPrayerAzkarIds(AssetBundle bundle) async {
  try {
    final source = await bundle.loadString('assets/data/azkar_release.json');
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) return const [];
    final general = decoded['general'];
    if (general is! List<dynamic>) return const [];
    return List.unmodifiable([
      for (final record in general)
        if (record is Map<String, dynamic> &&
            record['subcategory'] == afterPrayerAzkarSubcategory &&
            _isShownApproved(record))
          record['id'] as String,
    ]);
  } catch (_) {
    return const [];
  }
}

/// Same acceptance rule the azkar pages apply when parsing the release file:
/// [ZikrModel.fromJson] only accepts approved, fully-sourced records.
bool _isShownApproved(Map<String, dynamic> record) {
  try {
    ZikrModel.fromJson(record, AzkarCategory.general);
    return true;
  } on FormatException {
    return false;
  }
}
