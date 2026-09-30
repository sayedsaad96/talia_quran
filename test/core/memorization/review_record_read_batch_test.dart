import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/memorization/review_record_read_batch.dart';

void main() {
  group('ReviewRecordReadBatch', () {
    test('reads outside a batch always hit the store', () async {
      var loads = 0;
      Future<List<int>> load() async {
        loads++;
        return [1, 2];
      }

      await ReviewRecordReadBatch.read('owner|adult', load);
      await ReviewRecordReadBatch.read('owner|adult', load);

      expect(loads, 2);
    });

    test('concurrent reads of one key inside a batch share one load', () async {
      var loads = 0;
      final gate = Completer<void>();
      Future<List<int>> load() async {
        loads++;
        await gate.future;
        return [1, 2];
      }

      final results = await ReviewRecordReadBatch.run(() async {
        final reads = [
          ReviewRecordReadBatch.read('owner|adult', load),
          ReviewRecordReadBatch.read('owner|adult', load),
          ReviewRecordReadBatch.read('owner|adult', load),
        ];
        gate.complete();
        return Future.wait(reads);
      });

      expect(loads, 1);
      expect(results, everyElement([1, 2]));
    });

    test('different keys load separately', () async {
      final loaded = <String>[];
      await ReviewRecordReadBatch.run(() async {
        await ReviewRecordReadBatch.read('owner|adult', () async {
          loaded.add('adult');
          return <int>[];
        });
        await ReviewRecordReadBatch.read('owner|kids', () async {
          loaded.add('kids');
          return <int>[];
        });
        await ReviewRecordReadBatch.read('other|adult', () async {
          loaded.add('other');
          return <int>[];
        });
      });

      expect(loaded, ['adult', 'kids', 'other']);
    });

    test('each caller receives its own list', () async {
      await ReviewRecordReadBatch.run(() async {
        final first = await ReviewRecordReadBatch.read(
          'owner|adult',
          () async => [3, 1, 2],
        );
        first.sort();
        final second = await ReviewRecordReadBatch.read(
          'owner|adult',
          () async => <int>[],
        );

        expect(second, [3, 1, 2]);
      });
    });

    test('callbacks that outlive the batch read fresh data', () async {
      var loads = 0;
      Future<List<int>> load() async => [++loads];
      late Future<List<int>> Function() lateRead;

      await ReviewRecordReadBatch.run(() async {
        await ReviewRecordReadBatch.read('owner|adult', load);
        // A closure created inside the batch zone but run after it ends.
        lateRead = () => ReviewRecordReadBatch.read('owner|adult', load);
      });

      expect(await lateRead(), [2]);
      expect(loads, 2);
    });

    test('a failed read propagates to every sharing caller', () async {
      await ReviewRecordReadBatch.run(() async {
        Future<List<int>> load() async => throw StateError('isar');

        await expectLater(
          ReviewRecordReadBatch.read('owner|adult', load),
          throwsStateError,
        );
        await expectLater(
          ReviewRecordReadBatch.read('owner|adult', load),
          throwsStateError,
        );
      });
    });
  });
}
