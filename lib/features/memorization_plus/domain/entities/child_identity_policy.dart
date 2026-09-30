/// Rules for a child's name and age, shared by child setup, the guardian's
/// edit dialog and the Supabase functions in
/// `supabase/migrations/20260929195346_guardian_child_identity.sql`, which
/// enforce the same limits server-side.
abstract final class ChildIdentityPolicy {
  static const int minAge = 5;
  static const int maxAge = 12;
  static const int maxNicknameLength = 50;

  static final _whitespace = RegExp(r'\s+');
  static final _control = RegExp(r'[\x00-\x1F\x7F]');

  static bool isValidAge(int? age) =>
      age != null && age >= minAge && age <= maxAge;

  /// Trimmed name with inner whitespace collapsed, or null when it is empty,
  /// longer than [maxNicknameLength] or contains control characters.
  static String? normalizeNickname(String? raw) {
    if (raw == null || _control.hasMatch(raw.replaceAll(_whitespace, ' '))) {
      return null;
    }
    final name = raw.replaceAll(_whitespace, ' ').trim();
    // Code points, matching Postgres char_length on the server.
    if (name.isEmpty || name.runes.length > maxNicknameLength) return null;
    return name;
  }
}
