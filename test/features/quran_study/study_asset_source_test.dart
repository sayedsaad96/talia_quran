import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/data/datasources/study_asset_source.dart';
import 'package:talia_quran/features/quran_study/domain/entities/study_entry.dart';

class FixtureAssets extends CachingAssetBundle {
  final requested = <String>[];
  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    final content = key.endsWith('study_manifest.json')
        ? jsonEncode({
            'tafsir': {'sourceId': 'test'},
          })
        : 'synthetic bytes';
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

void main() {
  test('loads only fixed bundled paths', () async {
    final assets = FixtureAssets();
    final result = await ApprovedStudyBundleSource(
      assets,
    ).load(StudyKind.tafsir);
    expect(result!.manifest['sourceId'], 'test');
    expect(utf8.decode(result.bytes), 'synthetic bytes');
    expect(assets.requested, [
      'assets/data/quran_study/study_manifest.json',
      'assets/data/quran_study/tafsir_ar.json',
    ]);
  });
}
