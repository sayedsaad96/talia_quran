import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/config/supabase_config.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

void main() {
  const token = 'abcdefghijklmnopqrstuvwxyzABCDEFGH123456789';
  const links = ShareGoodLinks('example.com');
  test('raw parser accepts links built from a mixed-case configured host', () {
    const mixedCase = ShareGoodLinks('Example.COM');
    expect(mixedCase.parseRaw(mixedCase.build(token).toString()), token);
  });
  test('accepts only exact secure invitation links', () {
    expect(links.parse(links.build(token)), token);
    for (final value in [
      'http://example.com/i/$token',
      'https://other.com/i/$token',
      'https://example.com/i/$token/',
      'https://example.com/i/$token?x=1',
      'https://example.com/i/$token#x',
      'https://example.com:444/i/$token',
      'https://user@example.com/i/$token',
      'https://example.com/i/${token.substring(1)}',
    ]) {
      expect(links.parse(Uri.parse(value)), isNull, reason: value);
    }
    expect(() => links.build('bad'), throwsFormatException);
  });
  test('raw ingress rejects aliases normalized by Uri', () {
    expect(links.parseRaw('https://example.com/i/$token'), token);
    for (final value in [
      'https://example.com:443/i/$token',
      'https://example.com/%69/$token',
      'https://@example.com/i/$token',
    ]) {
      expect(links.parseRaw(value), isNull, reason: value);
    }
  });
  test('referrer accepts only an exact invite', () {
    expect(links.parseReferrer('inv=$token'), token);
    expect(links.parseReferrer('utm_source=tc&inv=$token'), isNull);
  });
  test('rollout is off without a debug Labs override', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final availability = ShareGoodAvailability(
      ExperienceFlags.fromPreferences(prefs),
      const SupabaseConfig(url: 'https://example.com', anonKey: 'key'),
      linkHost: 'example.com',
    );
    expect(availability.isAvailable, isFalse);
    await prefs.setBool(ExperienceFeature.shareGood.storageKey, true);
    expect(availability.isAvailable, isTrue);
  });
  test('invalid host and missing backend disable availability', () {
    final flags = ExperienceFlags((_) => true);
    const backend = SupabaseConfig(url: 'https://example.com', anonKey: 'key');
    for (final host in [
      '',
      'https://example.com',
      'example.com:443',
      'user@example.com',
      'example.com/path',
    ]) {
      expect(
        ShareGoodAvailability(flags, backend, linkHost: host).isAvailable,
        isFalse,
      );
    }
    expect(
      ShareGoodAvailability(
        flags,
        const SupabaseConfig(url: '', anonKey: ''),
        linkHost: 'example.com',
      ).isAvailable,
      isFalse,
    );
  });
}
