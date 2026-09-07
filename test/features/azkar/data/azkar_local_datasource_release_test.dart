import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_local_datasource.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test(
    'fails closed when a release category contains duplicate stable IDs',
    () async {
      final source = jsonEncode({
        'morning': [_approvedRecord(), _approvedRecord()],
      });
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final path = utf8.decode(message!.buffer.asUint8List());
            if (path != 'assets/data/azkar_release.json') return null;
            final bytes = Uint8List.fromList(utf8.encode(source));
            return ByteData.view(bytes.buffer);
          });

      final datasource = AzkarLocalDatasourceImpl();

      await expectLater(
        datasource.getAzkar(AzkarCategory.morning),
        throwsA(isA<CacheFailure>()),
      );
    },
  );

  test(
    'shares the initial release-asset load across concurrent categories',
    () async {
      final source = jsonEncode({
        'morning': [_approvedRecord(id: 'morning-001')],
        'evening': [_approvedRecord(id: 'evening-001')],
        'general': [_approvedRecord(id: 'general-001')],
        'duas': [_approvedRecord(id: 'duas-001')],
      });
      final assetBundle = _CountingAssetBundle(source);

      final datasource = AzkarLocalDatasourceImpl(assetBundle: assetBundle);
      const categories = AzkarCategory.values;
      final results = await Future.wait(categories.map(datasource.getAzkar));

      expect(results.map((items) => items.single.id), [
        'morning-001',
        'evening-001',
        'general-001',
        'duas-001',
      ]);
      expect(assetBundle.loadCount, 1);
    },
  );
}

class _CountingAssetBundle extends AssetBundle {
  _CountingAssetBundle(this._source);

  final String _source;
  int loadCount = 0;

  @override
  Future<ByteData> load(String key) async {
    expect(key, 'assets/data/azkar_release.json');
    loadCount++;
    await Future<void>.delayed(Duration.zero);
    final bytes = Uint8List.fromList(utf8.encode(_source));
    return ByteData.view(bytes.buffer);
  }
}

Map<String, dynamic> _approvedRecord({String id = 'morning-001'}) => {
  'id': id,
  'text': 'نص معتمد',
  'count': 1,
  'citation': 'Quran 2:201',
  'sourceType': 'quran',
  'authenticityGrade': null,
  'tier': 'essential',
  'datasetVersion': 'v1-reviewed-1',
  'reviewStatus': 'approved',
};
