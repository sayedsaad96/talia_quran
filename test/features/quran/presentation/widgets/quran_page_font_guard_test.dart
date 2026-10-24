import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/quran/presentation/widgets/quran_page_font_guard.dart';

class _FakeFontLoader implements QuranPageFontLoader {
  final loadedPages = <int>{};
  final throwingPages = <int>{};
  final requests = <int, List<Completer<void>>>{};

  @override
  bool isFontLoaded(int pageNumber) => loadedPages.contains(pageNumber);

  @override
  Future<void> ensureFontLoaded(int pageNumber) {
    if (throwingPages.contains(pageNumber)) throw StateError('sync failure');
    final request = Completer<void>();
    requests.putIfAbsent(pageNumber, () => []).add(request);
    return request.future;
  }

  void complete(int page, int request, {bool register = true}) {
    if (register) loadedPages.add(page);
    requests[page]![request].complete();
  }

  void fail(int page, int request) =>
      requests[page]![request].completeError(StateError('async failure'));
}

void main() {
  Future<void> pumpGuard(
    WidgetTester tester, {
    required int page,
    required QuranPageFontLoader loader,
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: QuranPageFontGuard(
          key: const ValueKey('guard'),
          pageNumber: page,
          isDark: false,
          fontLoader: loader,
          child: Text('page $page', key: ValueKey('page_$page')),
        ),
      ),
    );
  }

  testWidgets('shows a skeleton until a registered current font succeeds', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);

    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    expect(find.byKey(const ValueKey('page_1')), findsNothing);
    expect(loader.requests[1], hasLength(1));

    loader.complete(1, 0);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_1')), findsOneWidget);
  });

  testWidgets('uses an already registered font without loading', (
    tester,
  ) async {
    final loader = _FakeFontLoader()..loadedPages.add(1);
    await pumpGuard(tester, page: 1, loader: loader);

    expect(find.byKey(const ValueKey('page_1')), findsOneWidget);
    expect(loader.requests, isEmpty);
  });

  testWidgets('keeps the skeleton after asynchronous or synchronous failure', (
    tester,
  ) async {
    final asyncLoader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: asyncLoader);
    asyncLoader.fail(1, 0);
    await tester.pump();
    await tester.pump();
    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    expect(asyncLoader.requests[1], hasLength(1));

    final syncLoader = _FakeFontLoader()..throwingPages.add(2);
    await pumpGuard(tester, page: 2, loader: syncLoader);
    await tester.pump();
    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    expect(find.byKey(const ValueKey('page_2')), findsNothing);
  });

  testWidgets('does not trust a successful future without registration', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    loader.complete(1, 0, register: false);
    await tester.pump();

    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    expect(find.byKey(const ValueKey('page_1')), findsNothing);
  });

  testWidgets('ignores stale page completions and failures', (tester) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    await pumpGuard(tester, page: 2, loader: loader);

    loader.complete(1, 0);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_2')), findsNothing);
    loader.complete(2, 0);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_2')), findsOneWidget);
  });

  testWidgets('keeps newer success visible after stale failure or success', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    await pumpGuard(tester, page: 2, loader: loader);
    loader.complete(2, 0);
    await tester.pump();
    loader.fail(1, 0);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_2')), findsOneWidget);
  });

  testWidgets('requires the latest request when returning A to B to A', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    await pumpGuard(tester, page: 2, loader: loader);
    await pumpGuard(tester, page: 1, loader: loader);

    loader.complete(1, 0);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_1')), findsNothing);
    loader.complete(1, 1);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_1')), findsOneWidget);
  });

  testWidgets(
    'uses replacement loader readiness and ignores disposal completions',
    (tester) async {
      final oldLoader = _FakeFontLoader();
      final newLoader = _FakeFontLoader();
      await pumpGuard(tester, page: 1, loader: oldLoader);
      await pumpGuard(tester, page: 1, loader: newLoader);
      oldLoader.complete(1, 0);
      await tester.pump();
      expect(find.byKey(const ValueKey('page_1')), findsNothing);
      newLoader.complete(1, 0);
      await tester.pump();
      expect(find.byKey(const ValueKey('page_1')), findsOneWidget);

      final pending = _FakeFontLoader();
      await pumpGuard(tester, page: 3, loader: pending);
      await tester.pumpWidget(const SizedBox());
      pending.fail(3, 0);
      await tester.pump();
    },
  );

  testWidgets('retries a failed load and shows the page once registered', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    loader.fail(1, 0);
    await tester.pump();
    expect(loader.requests[1], hasLength(1));

    await tester.pump(const Duration(milliseconds: 500));
    expect(loader.requests[1], hasLength(2));
    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    loader.complete(1, 1);
    await tester.pump();
    expect(find.byKey(const ValueKey('page_1')), findsOneWidget);
  });

  testWidgets('retries are bounded and stay fail-closed', (tester) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    loader.fail(1, 0);
    await tester.pump(const Duration(milliseconds: 500));
    loader.fail(1, 1);
    await tester.pump(const Duration(seconds: 2));
    loader.fail(1, 2);
    await tester.pump(const Duration(seconds: 30));

    expect(loader.requests[1], hasLength(3));
    expect(find.byType(QuranPageSkeletonLoader), findsOneWidget);
    expect(find.byKey(const ValueKey('page_1')), findsNothing);
  });

  testWidgets('an unregistered success is retried, never trusted', (
    tester,
  ) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    loader.complete(1, 0, register: false);
    await tester.pump(const Duration(milliseconds: 500));
    expect(loader.requests[1], hasLength(2));
    expect(find.byKey(const ValueKey('page_1')), findsNothing);
  });

  testWidgets('a pending retry for an old page never fires', (tester) async {
    final loader = _FakeFontLoader();
    await pumpGuard(tester, page: 1, loader: loader);
    loader.fail(1, 0);
    await tester.pump();
    await pumpGuard(tester, page: 2, loader: loader);
    await tester.pump(const Duration(seconds: 5));
    expect(loader.requests[1], hasLength(1));
    expect(loader.requests[2], hasLength(1));
  });
}
