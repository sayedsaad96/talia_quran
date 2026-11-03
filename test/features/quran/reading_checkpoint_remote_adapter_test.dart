import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/data/repositories/reading_checkpoint_remote_adapter.dart';

void main() {
  test(
    'both RPCs bind the request to the expected owner for server validation',
    () async {
      final calls = <Map<String, dynamic>>[];
      final adapter = ReadingCheckpointRemoteAdapter((name, {params}) async {
        calls.add({'rpc': name, ...?params});
        if (name == 'get_quran_reading_checkpoint') return null;
        return {'status': 'accepted', 'page_number': 12, 'revision': 1};
      });
      await adapter.get(expectedOwnerId: 'expected-a');
      await adapter.put(
        expectedOwnerId: 'expected-a',
        pageNumber: 12,
        expectedRevision: 0,
        mutationId: 'mutation-a',
      );
      expect(calls.length, 2);
      for (final call in calls) {
        expect(call['p_expected_owner'], 'expected-a');
      }
    },
  );
}
