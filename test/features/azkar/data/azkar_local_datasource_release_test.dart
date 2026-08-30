import 'dart:convert';
import 'dart:typed_data';

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

      expect(
        datasource.getAzkar(AzkarCategory.morning),
        throwsA(isA<CacheFailure>()),
      );
    },
  );
}

Map<String, dynamic> _approvedRecord() => {
  'id': 'morning-001',
  'text': 'نص معتمد',
  'count': 1,
  'citation': 'Quran 2:201',
  'sourceType': 'quran',
  'authenticityGrade': null,
  'tier': 'essential',
  'datasetVersion': 'v1-reviewed-1',
  'reviewStatus': 'approved',
};
