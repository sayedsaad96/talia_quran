import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('treats missing values as offline mode', () {
      const config = SupabaseConfig(url: '', anonKey: '');

      expect(config.isConfigured, isFalse);
    });

    test('requires both url and anon key', () {
      const missingKey = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: '',
      );
      const missingUrl = SupabaseConfig(url: '', anonKey: 'anon-key');
      const configured = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'anon-key',
      );

      expect(missingKey.isConfigured, isFalse);
      expect(missingUrl.isConfigured, isFalse);
      expect(configured.isConfigured, isTrue);
    });
  });
}
