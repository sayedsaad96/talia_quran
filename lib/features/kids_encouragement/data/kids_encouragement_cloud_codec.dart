import '../domain/entities/kids_encouragement.dart';

/// Validates the fields used by the app before application state changes.
abstract final class KidsEncouragementCloudCodec {
  static KidsEncouragement decode(Object? raw) {
    if (raw is! Map) throw const FormatException('Invalid encouragement row');
    final row = Map<String, dynamic>.from(raw);
    final id = row['id'];
    final parent = row['parent_user_id'];
    final child = row['child_user_id'];
    final message = row['message_key'];
    final sticker = row['sticker_key'];
    final request = row['client_request_id'];
    if (id is! int ||
        id <= 0 ||
        parent is! String ||
        parent.isEmpty ||
        child is! String ||
        child.isEmpty ||
        message is! String ||
        sticker is! String ||
        request is! String ||
        !_isUuid(request)) {
      throw const FormatException('Invalid encouragement row');
    }
    final createdAt = _time(row['created_at']);
    final seenRaw = row['seen_at'];
    final seenAt = seenRaw == null ? null : _time(seenRaw);
    final parsedMessage = KidsEncouragementMessage.fromServerKey(message);
    final parsedSticker = KidsEncouragementSticker.fromServerKey(sticker);
    if (createdAt == null ||
        (seenRaw != null && seenAt == null) ||
        parsedMessage == null ||
        parsedSticker == null) {
      throw const FormatException('Invalid encouragement row');
    }
    return KidsEncouragement(
      id: id,
      parentUserId: parent,
      childUserId: child,
      message: parsedMessage,
      sticker: parsedSticker,
      createdAt: createdAt,
      seenAt: seenAt,
      clientRequestId: request,
    );
  }

  static List<KidsEncouragement> decodeRows(Object? raw) {
    if (raw is! List) throw const FormatException('Invalid encouragement rows');
    return List.unmodifiable(raw.map(decode));
  }

  static bool isUuid(String value) => _isUuid(value);

  static DateTime? _time(Object? raw) {
    if (raw is! String) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed?.toUtc();
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
