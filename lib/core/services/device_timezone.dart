import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

bool _databaseInitialized = false;

void ensureTimezoneDatabaseInitialized() {
  if (_databaseInitialized) return;
  tz_data.initializeTimeZones();
  _databaseInitialized = true;
}

Future<({String identifier, tz.Location? location})>
lookupDeviceTimezone() async {
  final device = await FlutterTimezone.getLocalTimezone();
  return (
    identifier: device.identifier,
    location: resolveTimezoneLocation(device.identifier),
  );
}

tz.Location? resolveTimezoneLocation(String identifier) {
  ensureTimezoneDatabaseInitialized();
  final trimmed = identifier.trim();
  try {
    return tz.getLocation(trimmed);
  } on tz.LocationNotFoundException {
    // Android sometimes supplies an offset instead of an IANA zone.
  }
  final offset = RegExp(r'^GMT([+-])(\d{1,2})(?::00)?$').firstMatch(trimmed);
  if (offset == null) return null;
  final hours = int.parse(offset.group(2)!);
  if (hours == 0) return tz.UTC;
  // Etc/GMT zones use the opposite sign.
  final sign = offset.group(1) == '+' ? '-' : '+';
  try {
    return tz.getLocation('Etc/GMT$sign$hours');
  } on tz.LocationNotFoundException {
    return null;
  }
}
