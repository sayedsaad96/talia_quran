import 'package:equatable/equatable.dart';

/// Proof that a guardian, after entering the guardian PIN on the child's
/// device, confirmed one «نتعلم سوا» practice. It is participation only:
/// it never completes an ayah, awards points or counts as memorization.
class KidsFamilyPracticeReceipt extends Equatable {
  const KidsFamilyPracticeReceipt({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.confirmedAt,
  });

  /// Fixed per practice, so a retried save never records it twice.
  final String id;
  final int surahId;
  final int ayahNumber;
  final DateTime confirmedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'surahId': surahId,
    'ayahNumber': ayahNumber,
    'confirmedAt': confirmedAt.toUtc().toIso8601String(),
  };

  /// Null for a malformed record, which the store skips.
  static KidsFamilyPracticeReceipt? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final surahId = json['surahId'];
    final ayahNumber = json['ayahNumber'];
    final at = json['confirmedAt'];
    if (id is! String || id.isEmpty) return null;
    if (surahId is! int || ayahNumber is! int || at is! String) return null;
    final confirmedAt = DateTime.tryParse(at);
    if (confirmedAt == null) return null;
    return KidsFamilyPracticeReceipt(
      id: id,
      surahId: surahId,
      ayahNumber: ayahNumber,
      confirmedAt: confirmedAt.toUtc(),
    );
  }

  @override
  List<Object?> get props => [id, surahId, ayahNumber, confirmedAt];
}
