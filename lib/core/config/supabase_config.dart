class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  static const String defaultPasswordRecoveryRedirectTo =
      'taliaquran://auth/update-password';

  static const fromDartDefine = SupabaseConfig(
    url: String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    ),
    anonKey: String.fromEnvironment(
      'SUPABASE_ANON_KEY',
    ),
  );

  static const passwordRecoveryRedirectTo = String.fromEnvironment(
    'SUPABASE_PASSWORD_RECOVERY_REDIRECT_TO',
    defaultValue: defaultPasswordRecoveryRedirectTo,
  );

  final String url;
  final String anonKey;

  /// Returns true only when both values look like real Supabase credentials.
  /// A URL must start with `https://` to rule out placeholder strings.
  bool get isConfigured =>
      url.trim().startsWith('https://') && anonKey.trim().isNotEmpty;
}
