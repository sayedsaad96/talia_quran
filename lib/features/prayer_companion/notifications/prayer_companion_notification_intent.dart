import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../core/utils/talia_logger.dart';
import '../domain/entities/prayer_companion.dart';

/// Typed, versioned payload for Prayer Companion notifications.
///
/// The payload carries occurrence identity metadata ONLY — owner id, local
/// civil date, prayer key, scheduled-at instant, and notification kind. It
/// never contains localized title/body copy, user history, or a route path,
/// so a leaked or stale payload reveals nothing and can never be mistaken
/// for a go_router location (it does not start with '/').
///
/// Format: `pc1|<ownerId>|<yyyy-MM-dd>|<prayerKey>|<scheduledAtMillisUtc>|<kind>`
/// The owner id is Base64Url-encoded so it may itself contain '|'.
class PrayerCompanionNotificationIntent extends Equatable {
  const PrayerCompanionNotificationIntent({
    required this.occurrence,
    required this.kind,
  });

  /// Payload schema version. Bumping requires a matching [tryParse] branch;
  /// unknown versions are rejected (null) rather than misinterpreted.
  static const String version = 'pc1';

  final PrayerOccurrence occurrence;
  final PrayerCompanionNotificationKind kind;

  String encode() {
    final occurrence = this.occurrence;
    final date = occurrence.localDate;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return [
      version,
      _encodeOwner(occurrence.ownerId),
      '$y-$m-$d',
      occurrence.prayerKey.name,
      occurrence.scheduledAt.toUtc().millisecondsSinceEpoch,
      kind.name,
    ].join('|');
  }

  /// Strictly validates [payload]; returns null (never throws) for null,
  /// garbage, malformed, or wrong/old-version payloads.
  static PrayerCompanionNotificationIntent? tryParse(String? payload) {
    try {
      if (payload == null || payload.isEmpty) return null;
      final parts = payload.split('|');
      if (parts.length != 6) return null;
      if (parts[0] != version) return null;

      final ownerId = _decodeOwner(parts[1]);
      if (ownerId == null || ownerId.isEmpty) return null;

      final localDate = _parseLocalDate(parts[2]);
      if (localDate == null) return null;

      final prayerKey = _parseEnum(PrayerKey.values, parts[3]);
      if (prayerKey == null) return null;

      final millis = int.tryParse(parts[4]);
      if (millis == null) return null;
      final scheduledAt = DateTime.fromMillisecondsSinceEpoch(millis);

      final kind = _parseEnum(PrayerCompanionNotificationKind.values, parts[5]);
      if (kind == null) return null;

      return PrayerCompanionNotificationIntent(
        occurrence: PrayerOccurrence(
          ownerId: ownerId,
          localDate: localDate,
          prayerKey: prayerKey,
          scheduledAt: scheduledAt,
        ),
        kind: kind,
      );
    } catch (error, stack) {
      // Invalid/old payloads are a no-op, never a crash.
      TaliaLogger.w('Invalid companion notification payload', error, stack);
      return null;
    }
  }

  static String _encodeOwner(String ownerId) => base64Url
      .encode(utf8.encode(ownerId))
      .replaceAll('=', '~'); // keep the payload '|'- and padding-safe

  static String? _decodeOwner(String encoded) {
    try {
      final padded = encoded.replaceAll('~', '=');
      return utf8.decode(base64Url.decode(padded));
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseLocalDate(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static T? _parseEnum<T extends Enum>(List<T> values, String raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  @override
  List<Object?> get props => [occurrence, kind];
}
