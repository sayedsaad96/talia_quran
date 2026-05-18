import 'package:equatable/equatable.dart';

enum PairingSessionStatus { pending, completed, expired, used, cancelled }

class PairingSession extends Equatable {
  const PairingSession({
    required this.id,
    required this.pairingCode,
    required this.qrData,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
    required this.isUsed,
    this.guardianId,
    this.failureReason,
  });

  final String id;
  final String pairingCode;
  final String qrData;
  final DateTime createdAt;
  final DateTime expiresAt;
  final PairingSessionStatus status;
  final bool isUsed;
  final String? guardianId;
  final String? failureReason;

  bool get isPending => status == PairingSessionStatus.pending;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canBeUsed => isPending && !isUsed && !isExpired;

  PairingSession copyWith({
    String? id,
    String? pairingCode,
    String? qrData,
    DateTime? createdAt,
    DateTime? expiresAt,
    PairingSessionStatus? status,
    bool? isUsed,
    String? guardianId,
    bool clearGuardianId = false,
    String? failureReason,
    bool clearFailureReason = false,
  }) => PairingSession(
    id: id ?? this.id,
    pairingCode: pairingCode ?? this.pairingCode,
    qrData: qrData ?? this.qrData,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    status: status ?? this.status,
    isUsed: isUsed ?? this.isUsed,
    guardianId: clearGuardianId ? null : (guardianId ?? this.guardianId),
    failureReason: clearFailureReason
        ? null
        : (failureReason ?? this.failureReason),
  );

  @override
  List<Object?> get props => [
    id,
    pairingCode,
    qrData,
    createdAt,
    expiresAt,
    status,
    isUsed,
    guardianId,
    failureReason,
  ];
}
