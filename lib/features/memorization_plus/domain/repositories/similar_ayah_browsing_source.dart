import '../entities/similar_ayah_reference_pair.dart';

/// Reviewed comparison references; null indicates unavailable content.
abstract interface class SimilarAyahBrowsingSource {
  Future<List<SimilarAyahReferencePair>?> loadBrowsingPairs();
}
