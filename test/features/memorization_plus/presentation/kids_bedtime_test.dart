import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/memorization/kids_enrichment_feature_flags.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/sleep_timer.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/services/kids_world_phase.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_bedtime_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_bedtime_listen_page.dart';
import 'package:talia_quran/features/memorization_plus/presentation/world/kids_world_palette.dart';
import 'package:talia_quran/features/quran/domain/entities/quran_entities.dart';

KidsSessionLog _log(int surahId, int ayah) => KidsSessionLog(
  id: 's$surahId-$ayah',
  surahId: surahId,
  ayahNumber: ayah,
  repeatsCompleted: 3,
  pointsEarned: 10,
  completedAt: DateTime(2026, 10, 2),
);

List<KidsSessionLog> _whole(int surahId, int count) => [
  for (var a = 1; a <= count; a++) _log(surahId, a),
];

Surah _surah(int id, int count) => Surah(
  id: id,
  nameAr: 'سورة $id',
  nameEn: 'Surah $id',
  type: 'meccan',
  ayahCount: count,
  juz: 30,
  page: 600,
);

final _surahs = [
  _surah(1, 7),
  _surah(18, 2),
  _surah(36, 3),
  _surah(112, 4),
  _surah(113, 5),
  _surah(114, 6),
];

class _Calls {
  final plays = <(List<int>, SleepTimerChoice)>[];
  int stops = 0;
  final events = <String>[];

  /// When set, play() completes only once the test completes it.
  Completer<void>? playGate;
}

KidsBedtimeCubit _cubit({
  required List<KidsSessionLog> logs,
  KidsJourneyPathDefinition path = KidsJourneyPathDefinition.adventure,
  _Calls? calls,
  ValueNotifier<ContinuousPlaybackState>? playback,
}) {
  final c = calls ?? _Calls();
  return KidsBedtimeCubit(
    sessionLogs: () async => logs,
    surahs: () async => _surahs,
    pathLoader: () async => path,
    play: (ids, sleep) async {
      c.plays.add((ids, sleep));
      await c.playGate?.future;
      c.events.add('played');
    },
    stop: () async {
      c.stops++;
      c.events.add('stopped');
    },
    playback: playback,
  );
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  final memorizedLogs = [
    ..._whole(114, 6),
    ..._whole(1, 7),
    ..._whole(113, 5),
    _log(112, 1), // partial: not memorized
  ];

  group('KidsBedtimeCubit', () {
    test('lists memorized surahs in the adventure path order', () async {
      final cubit = _cubit(logs: memorizedLogs);
      await cubit.load();
      expect(cubit.state.status, KidsBedtimeStatus.ready);
      expect(cubit.state.surahs.map((s) => s.id), [1, 114, 113]);
      expect(cubit.state.selected, {1, 114, 113});
      expect(cubit.state.timer, SleepTimerChoice.min15);
      await cubit.close();
    });

    test('follows the Quran-from-Fatiha path order', () async {
      final cubit = _cubit(
        logs: memorizedLogs,
        path: KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha),
      );
      await cubit.load();
      expect(cubit.state.surahs.map((s) => s.id), [1, 113, 114]);
      await cubit.close();
    });

    test('memorized surahs off the current path follow, ascending', () async {
      final cubit = _cubit(
        logs: [..._whole(36, 3), ...memorizedLogs, ..._whole(18, 2)],
      );
      await cubit.load();
      expect(cubit.state.surahs.map((s) => s.id), [1, 114, 113, 18, 36]);
      await cubit.close();
    });

    test('stop during a pending start waits for it, then stops', () async {
      final calls = _Calls()..playGate = Completer<void>();
      final cubit = _cubit(logs: _whole(114, 6), calls: calls);
      await cubit.load();

      final starting = cubit.start();
      final stopping = cubit.stop();
      expect(cubit.state.playing, isFalse);
      calls.playGate!.complete();
      await Future.wait([starting, stopping]);

      expect(calls.events, ['played', 'stopped']);
      expect(cubit.state.playing, isFalse);
      await cubit.close();
    });

    test('no memorized surah gives the empty state', () async {
      final cubit = _cubit(logs: _whole(114, 5));
      await cubit.load();
      expect(cubit.state.status, KidsBedtimeStatus.empty);
      expect(cubit.state.surahs, isEmpty);
      await cubit.close();
    });

    test(
      'start plays the selected surahs in list order with the timer',
      () async {
        final calls = _Calls();
        final cubit = _cubit(logs: memorizedLogs, calls: calls);
        await cubit.load();
        cubit.toggleSurah(1);
        cubit.setTimer(SleepTimerChoice.min30);
        await cubit.start();
        expect(calls.plays.single.$1, [114, 113]);
        expect(calls.plays.single.$2, SleepTimerChoice.min30);
        expect(cubit.state.playing, isTrue);

        await cubit.stop();
        expect(calls.stops, 1);
        expect(cubit.state.playing, isFalse);
        await cubit.close();
      },
    );

    test('nothing selected never starts playback', () async {
      final calls = _Calls();
      final cubit = _cubit(logs: _whole(114, 6), calls: calls);
      await cubit.load();
      cubit.toggleSurah(114);
      await cubit.start();
      expect(calls.plays, isEmpty);
      expect(cubit.state.playing, isFalse);
      await cubit.close();
    });

    test('playback going idle (timer ended) flips back to stopped', () async {
      final playback = ValueNotifier(
        const ContinuousPlaybackState(status: PlaybackStatus.idle),
      );
      final cubit = _cubit(logs: _whole(114, 6), playback: playback);
      await cubit.load();
      await cubit.start();
      playback.value = const ContinuousPlaybackState(
        status: PlaybackStatus.playing,
      );
      expect(cubit.state.playing, isTrue);
      playback.value = const ContinuousPlaybackState(
        status: PlaybackStatus.idle,
      );
      expect(cubit.state.playing, isFalse);
      await cubit.close();
      playback.dispose();
    });
  });

  group('KidsBedtimeView', () {
    testWidgets('shows the empty message without memorized surahs', (
      tester,
    ) async {
      final cubit = _cubit(logs: const []);
      await cubit.load();
      await tester.pumpWidget(
        _app(BlocProvider.value(value: cubit, child: const KidsBedtimeView())),
      );
      expect(
        find.text('احفظ سورة أولاً لتستمع إليها قبل النوم'),
        findsOneWidget,
      );
      expect(find.text('ابدأ'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });

    testWidgets('lists surahs, timer choices and toggles start/stop', (
      tester,
    ) async {
      final calls = _Calls();
      final cubit = _cubit(logs: memorizedLogs, calls: calls);
      await cubit.load();
      await tester.pumpWidget(
        _app(BlocProvider.value(value: cubit, child: const KidsBedtimeView())),
      );
      expect(find.text('استماع قبل النوم'), findsOneWidget);
      expect(find.text('سورة 114'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(3));
      expect(find.text('يتوقف بعد'), findsOneWidget);

      await tester.tap(find.text('ابدأ'));
      await tester.pump();
      expect(calls.plays.single.$1, [1, 114, 113]);
      expect(calls.plays.single.$2, SleepTimerChoice.min15);
      expect(find.text('إيقاف'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('kids-bedtime-toggle')));
      await tester.pump();
      expect(calls.stops, 1);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
    });
  });

  group('KidsBedtimeCard', () {
    Widget card(KidsWorldPhase phase) => _app(
      KidsWorldPhaseScope(
        phase: phase,
        child: KidsBedtimeCard(onTap: () {}),
      ),
    );

    testWidgets('shows at night', (tester) async {
      await tester.pumpWidget(card(KidsWorldPhase.night));
      expect(
        find.text('حان وقت الهدوء: استمع لسورك قبل النوم'),
        findsOneWidget,
      );
    });

    testWidgets('hides by day', (tester) async {
      await tester.pumpWidget(card(KidsWorldPhase.day));
      expect(find.text('حان وقت الهدوء: استمع لسورك قبل النوم'), findsNothing);
    });
  });

  group('kidsBedtimeListeningEnabled', () {
    tearDown(() async {
      if (getIt.isRegistered<KidsEnrichmentFlags>()) {
        await getIt.unregister<KidsEnrichmentFlags>();
      }
    });

    test('off without the flags wired', () {
      expect(kidsBedtimeListeningEnabled(), isFalse);
    });

    test('follows the bedtimeListening flag', () {
      getIt.registerSingleton<KidsEnrichmentFlags>(
        KidsEnrichmentFlags(
          (key) => key == KidsEnrichmentFeature.bedtimeListening.storageKey,
        ),
      );
      expect(kidsBedtimeListeningEnabled(), isTrue);
    });

    test('off when the flag is off', () {
      getIt.registerSingleton<KidsEnrichmentFlags>(
        KidsEnrichmentFlags((_) => false),
      );
      expect(kidsBedtimeListeningEnabled(), isFalse);
    });
  });
}
