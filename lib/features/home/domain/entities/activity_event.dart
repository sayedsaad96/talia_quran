import 'package:equatable/equatable.dart';

enum ActivityEventKind { reading, memorize, review, khatmah }

class ActivityEvent extends Equatable {
  const ActivityEvent({
    required this.occurredAt,
    required this.kind,
    required this.idempotencyKey,
    this.surahId,
    this.startAyah,
    this.endAyah,
    this.pageNumber,
    this.isKids = false,
  });

  final DateTime occurredAt;
  final ActivityEventKind kind;
  final String idempotencyKey;
  final int? surahId;
  final int? startAyah;
  final int? endAyah;
  final int? pageNumber;

  /// Logged by the kids track. Kids entries never appear in the adult home
  /// feed; they feed the guardian's view of the child instead.
  final bool isKids;

  @override
  List<Object?> get props => [
    occurredAt,
    kind,
    idempotencyKey,
    surahId,
    startAyah,
    endAyah,
    pageNumber,
    isKids,
  ];
}
