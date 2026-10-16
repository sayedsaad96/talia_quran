import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/content/content_manifest_summary.dart';

void main() {
  test('parse real manifest shape -> version + 4 sources', () {
    const json = '''
{
  "datasetVersion": "v1-owner-approved-1",
  "freezeDate": "2026-01-01",
  "reviewStatus": "approved",
  "items": [
    {"path": "assets/data/quran.json"},
    {"path": "assets/data/surahs.json"},
    {"path": "assets/data/azkar_release.json"},
    {"path": "assets/data/khatm_dua.json"}
  ]
}''';
    final summary = ContentManifestSummary.parse(json);
    expect(summary?.datasetVersion, 'v1-owner-approved-1');
    expect(summary?.sourceCount, 4);
  });

  test('malformed / missing items -> null', () {
    expect(ContentManifestSummary.parse('not json'), isNull);
    expect(ContentManifestSummary.parse('[]'), isNull);
    expect(ContentManifestSummary.parse('{"datasetVersion": "x"}'), isNull);
    expect(ContentManifestSummary.parse('{"items": "x"}'), isNull);
  });

  test('loader returns null on asset errors', () async {
    expect(await loadContentManifestSummary(_ThrowingBundle()), isNull);
  });

  test('bundled manifest parses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final summary = await loadContentManifestSummary(rootBundle);
    expect(summary, isNotNull);
    expect(summary!.sourceCount, greaterThan(0));
  });
}

class _ThrowingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => throw FlutterError('missing');
}
