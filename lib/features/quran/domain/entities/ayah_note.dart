import 'package:equatable/equatable.dart';

/// A private, local-only reflection attached to one canonical ayah reference.
class AyahNote extends Equatable {
  const AyahNote({
    required this.surahId,
    required this.ayahNumber,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  final int surahId;
  final int ayahNumber;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [surahId, ayahNumber, body, createdAt, updatedAt];
}
