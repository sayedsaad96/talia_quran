import 'package:equatable/equatable.dart';

/// Lifecycle of a guardian-assigned home mission. Only the child reports;
/// only the guardian acknowledges ("seen by guardian", never "verified").
enum KidsHomeMissionStatus { assigned, reported, acknowledged }

/// A short real-life task («رتّب غرفتك») assigned by a guardian.
final class KidsHomeMission extends Equatable {
  const KidsHomeMission({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    this.reportedAt,
    this.acknowledgedAt,
    this.pendingReportSync = false,
  });

  final String id;
  final String title;
  final KidsHomeMissionStatus status;
  final DateTime createdAt;
  final DateTime? reportedAt;
  final DateTime? acknowledgedAt;

  /// Reported locally, not yet on the server.
  final bool pendingReportSync;

  KidsHomeMission copyWith({
    String? id,
    String? title,
    KidsHomeMissionStatus? status,
    DateTime? createdAt,
    DateTime? reportedAt,
    DateTime? acknowledgedAt,
    bool? pendingReportSync,
  }) => KidsHomeMission(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    reportedAt: reportedAt ?? this.reportedAt,
    acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    pendingReportSync: pendingReportSync ?? this.pendingReportSync,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'reportedAt': reportedAt?.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'pendingReportSync': pendingReportSync,
  };

  /// Throws [FormatException] on an unknown status or malformed fields so the
  /// storage layer can quarantine the payload.
  factory KidsHomeMission.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'];
    final status = KidsHomeMissionStatus.values
        .where((s) => s.name == statusName)
        .firstOrNull;
    if (status == null) {
      throw FormatException('Unknown home mission status: $statusName');
    }
    final id = json['id'];
    final title = json['title'];
    if (id is! String || title is! String) {
      throw const FormatException('Malformed home mission');
    }
    DateTime? optional(Object? v) => v == null ? null : _parse(v);
    return KidsHomeMission(
      id: id,
      title: title,
      status: status,
      createdAt: _parse(json['createdAt']),
      reportedAt: optional(json['reportedAt']),
      acknowledgedAt: optional(json['acknowledgedAt']),
      pendingReportSync: json['pendingReportSync'] == true,
    );
  }

  static DateTime _parse(Object? value) {
    if (value is! String) {
      throw const FormatException('Malformed home mission date');
    }
    return DateTime.parse(value);
  }

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    createdAt,
    reportedAt,
    acknowledgedAt,
    pendingReportSync,
  ];
}
