import 'review_record_audience_scope.dart';

/// Which historical format a stored `compositeKey` uses.
enum ReviewRecordKeyGeneration {
  /// `"{surahId}_{ayahNumber}"` — pre-audience.
  legacy,

  /// `"adult_{surahId}_{ayahNumber}"` / `"kids_{surahId}_{ayahNumber}"`.
  audienceScoped,

  /// `"{ownerUserId}|{audience}|{surahId}|{ayahNumber}"`.
  identity,
}

/// The four immutable fields that identify one review record.
///
/// A record for one identity must never be read, merged, scheduled, displayed
/// or synchronized as another identity.
class ReviewRecordIdentity {
  const ReviewRecordIdentity({
    required this.ownerUserId,
    required this.audience,
    required this.surahId,
    required this.ayahNumber,
  });

  /// Reserved owner for records written while no account is signed in. These
  /// records stay on the device and are never uploaded or merged.
  static const String localOwnerId = 'local';

  static const String separator = '|';

  final String ownerUserId;
  final ReviewRecordReadScope audience;
  final int surahId;
  final int ayahNumber;

  String get storageKey =>
      '$ownerUserId$separator${audience.name}$separator$surahId$separator$ayahNumber';

  bool get isSyncable => ownerUserId != localOwnerId && ownerUserId.isNotEmpty;

  static ReviewRecordIdentity? tryParse(String compositeKey) {
    final parts = compositeKey.split(separator);
    if (parts.length != 4) return null;

    final owner = parts[0];
    if (owner.isEmpty) return null;

    final audience = audienceFromName(parts[1]);
    if (audience == null) return null;

    final surahId = int.tryParse(parts[2]);
    final ayahNumber = int.tryParse(parts[3]);
    if (surahId == null || ayahNumber == null) return null;

    return ReviewRecordIdentity(
      ownerUserId: owner,
      audience: audience,
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
  }

  static ReviewRecordReadScope? audienceFromName(String name) {
    for (final scope in ReviewRecordReadScope.values) {
      if (scope.name == name) return scope;
    }
    return null;
  }

  static ReviewRecordKeyGeneration generationOf(String compositeKey) {
    if (tryParse(compositeKey) != null) {
      return ReviewRecordKeyGeneration.identity;
    }
    if (!ReviewRecordAudienceScope.isLegacyCompositeKey(compositeKey)) {
      return ReviewRecordKeyGeneration.audienceScoped;
    }
    return ReviewRecordKeyGeneration.legacy;
  }

  @override
  bool operator ==(Object other) =>
      other is ReviewRecordIdentity &&
      other.ownerUserId == ownerUserId &&
      other.audience == audience &&
      other.surahId == surahId &&
      other.ayahNumber == ayahNumber;

  @override
  int get hashCode => Object.hash(ownerUserId, audience, surahId, ayahNumber);

  @override
  String toString() => 'ReviewRecordIdentity($storageKey)';
}
