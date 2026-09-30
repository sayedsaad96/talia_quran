/// Remembers which record ids were hidden as duplicates of another record, so
/// favorites saved on a hidden copy still count for the visible one.
class AzkarAliasRegistry {
  final Map<String, Set<String>> _aliasesByCanonical = {};

  void record(Map<String, Set<String>> aliases) {
    for (final entry in aliases.entries) {
      _aliasesByCanonical[entry.key] = Set.unmodifiable(entry.value);
    }
  }

  Set<String> aliasesOf(String canonicalId) =>
      _aliasesByCanonical[canonicalId] ?? const <String>{};
}
