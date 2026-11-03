import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran_study/presentation/widgets/reader_study_selection_guard.dart';

void main() {
  test('a slow ayah selection cannot replace a newer selection', () async {
    final guard = ReaderStudySelectionGuard();
    final delayed = Completer<String>();
    final first = guard.begin(5);
    final old = guard.resolve(first, delayed.future, currentPage: () => 5);
    final second = guard.begin(5);
    expect(
      await guard.resolve(second, Future.value('B'), currentPage: () => 5),
      'B',
    );
    delayed.complete('A');
    expect(await old, isNull);
  });
  test(
    'a page turn including A to B to A invalidates the old chooser',
    () async {
      final guard = ReaderStudySelectionGuard();
      final delayed = Completer<int>();
      final token = guard.begin(5);
      var page = 5;
      final old = guard.resolve(token, delayed.future, currentPage: () => page);
      page = 6;
      guard.invalidate();
      page = 5;
      delayed.complete(5);
      expect(await old, isNull);
      expect(guard.isCurrent(token, currentPage: page), isFalse);
    },
  );
}
