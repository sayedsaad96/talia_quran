import 'package:equatable/equatable.dart';

/// A lexical browsing choice carries no learner history or invented count.
final class SimilarAyahReferencePair extends Equatable {
  const SimilarAyahReferencePair({
    required this.targetSurahId,
    required this.targetAyahNumber,
    required this.otherSurahId,
    required this.otherAyahNumber,
  });
  final int targetSurahId;
  final int targetAyahNumber;
  final int otherSurahId;
  final int otherAyahNumber;

  @override
  List<Object?> get props => [
    targetSurahId,
    targetAyahNumber,
    otherSurahId,
    otherAyahNumber,
  ];
}
