import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talia_quran/core/router/quran_audio_notification_controller.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';

void main() {
  const active = ContinuousPlaybackState(
    status: PlaybackStatus.playing,
    currentSurahId: 1,
    currentAyahNumber: 1,
    currentPageNumber: 1,
  );

  test(
    'holds early click until ready and ignores duplicate current page',
    () async {
      final clicks = StreamController<bool>.broadcast(sync: true);
      addTearDown(clicks.close);
      final opened = <String>[];
      var location = '/home';
      final controller = QuranAudioNotificationController(
        notificationClicks: clicks.stream,
        currentState: () => active,
        canOpenReader: () => true,
        currentLocation: () => location,
        onOpen: (target) {
          opened.add(target);
          location = target;
        },
      )..start();
      addTearDown(controller.dispose);
      clicks.add(true);
      clicks.add(true);
      expect(opened, isEmpty);
      controller.setReady(true);
      await Future<void>.delayed(Duration.zero);
      expect(opened, ['/quran/page/1']);
      clicks.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(opened, hasLength(1));
      location = '/home';
      clicks.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(opened, hasLength(2));
    },
  );

  test('ordinary launch clears an early buffered click', () async {
    final clicks = StreamController<bool>.broadcast(sync: true);
    addTearDown(clicks.close);
    var opens = 0;
    final controller = QuranAudioNotificationController(
      notificationClicks: clicks.stream,
      currentState: () => active,
      canOpenReader: () => true,
      currentLocation: () => '/home',
      onOpen: (_) => opens++,
    )..start();
    addTearDown(controller.dispose);
    clicks.add(true);
    clicks.add(false);
    controller.setReady(true);
    await Future<void>.delayed(Duration.zero);
    expect(opens, 0);
  });

  test('stale, training, invalid, and false events do not navigate', () async {
    final clicks = StreamController<bool>.broadcast(sync: true);
    addTearDown(clicks.close);
    var state = const ContinuousPlaybackState();
    var allowed = true;
    var count = 0;
    final controller =
        QuranAudioNotificationController(
            notificationClicks: clicks.stream,
            currentState: () => state,
            canOpenReader: () => allowed,
            currentLocation: () => '/home',
            onOpen: (_) => count++,
          )
          ..start()
          ..setReady(true);
    addTearDown(controller.dispose);
    clicks.add(false);
    clicks.add(true);
    state = active;
    allowed = false;
    clicks.add(true);
    allowed = true;
    state = const ContinuousPlaybackState(
      status: PlaybackStatus.playing,
      currentSurahId: 1,
      currentAyahNumber: 1,
      currentPageNumber: 0,
    );
    clicks.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(count, 0);
  });

  test(
    'coalesces taps during asynchronous navigation and cancels on dispose',
    () async {
      final clicks = StreamController<bool>.broadcast(sync: true);
      addTearDown(clicks.close);
      final navigation = Completer<void>();
      var opens = 0;
      final controller =
          QuranAudioNotificationController(
              notificationClicks: clicks.stream,
              currentState: () => active,
              canOpenReader: () => true,
              currentLocation: () => '/home',
              onOpen: (_) {
                opens++;
                return navigation.future;
              },
            )
            ..start()
            ..setReady(true);
      clicks.add(true);
      clicks.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(opens, 1);
      await controller.dispose();
      navigation.complete();
      clicks.add(true);
      await Future<void>.delayed(Duration.zero);
      expect(opens, 1);
    },
  );

  testWidgets('notification opens the active GoRouter page only once', (
    tester,
  ) async {
    final clicks = StreamController<bool>.broadcast(sync: true);
    addTearDown(clicks.close);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => const Text('Home')),
        GoRoute(
          path: '/quran/page/:pageNumber',
          builder: (_, state) =>
              Text('Page ${state.pathParameters['pageNumber']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final controller =
        QuranAudioNotificationController(
            notificationClicks: clicks.stream,
            currentState: () => active,
            canOpenReader: () => true,
            currentLocation: () =>
                router.routeInformationProvider.value.uri.path,
            onOpen: (location) => router.go(location),
          )
          ..start()
          ..setReady(true);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.text('Home'), findsOneWidget);
    clicks.add(true);
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
    clicks.add(true);
    await tester.pumpAndSettle();
    expect(find.text('Page 1'), findsOneWidget);
  });
}
