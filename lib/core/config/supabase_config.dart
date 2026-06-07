class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  static const String defaultPasswordRecoveryRedirectTo =
      'taliaquran://auth/update-password';

  static const fromDartDefine = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  static const passwordRecoveryRedirectTo = String.fromEnvironment(
    'SUPABASE_PASSWORD_RECOVERY_REDIRECT_TO',
    defaultValue: defaultPasswordRecoveryRedirectTo,
  );

  final String url;
  final String anonKey;

  bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
