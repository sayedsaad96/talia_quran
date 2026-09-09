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
  });

  final DateTime occurredAt;
  final ActivityEventKind kind;
  final String idempotencyKey;
  final int? surahId;
  final int? startAyah;
  final int? endAyah;
  final int? pageNumber;

  @override
  List<Object?> get props => [
    occurredAt,
    kind,
    idempotencyKey,
    surahId,
    startAyah,
    endAyah,
    pageNumber,
  ];
}
