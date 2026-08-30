import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('V1 release verifier covers every reproducible release gate', () {
    final script = File('scripts/verify_v1_release.ps1');

    expect(script.existsSync(), isTrue);
    final source = script.readAsStringSync();

    for (final requiredToken in <String>[
      r"$ErrorActionPreference = 'Stop'",
      r'[switch] $BuildAndroidRelease',
      'TALIA_RELEASE_DART_DEFINES_FILE',
      'TALIA_SUPABASE_FRESH_DB_URL',
      'TALIA_SUPABASE_STAGING_DB_URL',
      'SUPABASE_DB_URL',
      '--enforce-lockfile',
      'gen-l10n',
      'build_runner',
      'analyze',
      'test',
      'build',
      'appbundle',
      'Get-FileHash',
      'content_manifest.json',
      'azkar_release.json',
      'assets/data/azkar.json',
      '.env',
      'NOT RUN',
      'NOT FROZEN',
      'Release build not requested',
    ]) {
      expect(
        source,
        contains(requiredToken),
        reason: 'release verifier must contain $requiredToken',
      );
    }

    expect(
      source,
      isNot(contains('SUPABASE_ANON_KEY=')),
      reason: 'the verifier must not embed a Supabase credential',
    );
    expect(
      source,
      isNot(contains('postgresql://postgres:')),
      reason: 'the verifier must not embed a database credential',
    );
    expect(
      source,
      contains(r'if ($BuildAndroidRelease)'),
      reason: 'Android release builds must require explicit opt-in',
    );
  });
}
