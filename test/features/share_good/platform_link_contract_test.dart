import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/share_good/share_good_config.dart';

void main() {
  String read(String path) => File(path).readAsStringSync();
  test(
    'Android owns verified HTTPS invite ingress and disables Flutter handler',
    () {
      final manifest = read('android/app/src/main/AndroidManifest.xml');
      expect(manifest, contains('android:autoVerify="true"'));
      expect(
        manifest,
        contains(
          'android:scheme="https" android:host="\${shareGoodLinkHost}" android:pathPrefix="/i/"',
        ),
      );
      expect(
        manifest,
        contains(
          'android:name="flutter_deeplinking_enabled" android:value="false"',
        ),
      );
    },
  );
  test('invite redirect carries the token only inside Play referrer', () {
    final line = read(
      'hosting/share_good_links/_redirects',
    ).split('\n').first.trim();
    expect(
      line,
      '/i/:token  https://play.google.com/store/apps/details?id=com.talia.quran&referrer=inv%3D:token  302',
    );
    const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    final url = Uri.parse(
      line.split(RegExp(r'\s+'))[1].replaceAll(':token', token),
    );
    expect(url.host, 'play.google.com');
    expect(url.queryParameters, {
      'id': 'com.talia.quran',
      'referrer': 'inv=$token',
    });
    expect(
      const ShareGoodLinks(
        'example.com',
      ).parseReferrer(url.queryParameters['referrer']!),
      token,
    );
  });
  test('hosting has an offline landing page and placeholder association', () {
    final page = read('hosting/share_good_links/index.html').toLowerCase();
    expect(page, isNot(contains('<script')));
    expect(page, isNot(matches(RegExp(r'<(?:img|link|iframe|script)\b'))));
    final entries =
        jsonDecode(
              read(
                'hosting/share_good_links/.well-known/assetlinks.json.template',
              ),
            )
            as List;
    final entry = entries.single as Map<String, dynamic>;
    expect(
      entry['relation'],
      contains('delegate_permission/common.handle_all_urls'),
    );
    expect(entry['target']['package_name'], 'com.talia.quran');
    expect(entry['target']['sha256_cert_fingerprints'], [
      '__SHA256_FINGERPRINTS__',
    ]);
  });
  test('Android defaults to an invalid host and checks both supplied hosts', () {
    final gradle = read('android/app/build.gradle.kts');
    expect(gradle, contains('"invalid.localhost"'));
    expect(gradle, contains('SHARE_GOOD_LINK_HOST='));
    expect(
      gradle,
      contains(
        'shareGoodDartHost.lowercase(Locale.ROOT) == shareGoodGradleHost.lowercase(Locale.ROOT)',
      ),
    );
    expect(
      gradle,
      contains(
        'manifestPlaceholders["shareGoodLinkHost"] = normalizedShareGoodHost',
      ),
    );
    final rollout = read('lib/core/experience/rollout_manifest.dart');
    expect(
      rollout,
      matches(RegExp(r'ExperienceFeature\.shareGood\s*=>\s*_off\(')),
    );
  });
  test(
    'release host gate validates unset, matching, mismatch and malformed values',
    () async {
      final temp = await Directory.systemTemp.createTemp('talia_link_gate_');
      addTearDown(() => temp.delete(recursive: true));
      final defines = File('${temp.path}${Platform.pathSeparator}defines.json');
      const command = r'''
$repositoryRoot = (Get-Location).Path
function Add-Result([string] $Gate, [string] $Status, [string] $Detail) {}
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repositoryRoot 'scripts/verify_v1_release.ps1'), [ref]$tokens, [ref]$errors)
if ($errors.Count -ne 0) { exit 9 }
$node = $ast.Find({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Assert-ShareGoodLinkHost' }, $true)
Invoke-Expression $node.Extent.Text
try { Assert-ShareGoodLinkHost $env:TEST_LINK_DEFINE; exit 0 } catch { exit 1 }
''';
      Future<int> check(String dartHost, String gradleHost) async {
        await defines.writeAsString(
          jsonEncode({'SHARE_GOOD_LINK_HOST': dartHost}),
        );
        final result = await Process.run(
          'powershell',
          ['-NoProfile', '-NonInteractive', '-Command', command],
          environment: {
            'TEST_LINK_DEFINE': defines.path,
            'ORG_GRADLE_PROJECT_shareGoodLinkHost': gradleHost,
          },
        );
        return result.exitCode;
      }

      expect(await check('', ''), 0);
      expect(await check('Example.COM', 'example.com'), 0);
      expect(await check('example.com', 'other.com'), isNot(0));
      expect(await check('example.com:443', 'example.com:443'), isNot(0));
      expect(await check('invalid.localhost', 'invalid.localhost'), isNot(0));
      expect(await check('', 'example.com'), isNot(0));
    },
    skip: !Platform.isWindows,
  );
}
