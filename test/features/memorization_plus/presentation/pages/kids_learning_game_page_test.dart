import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_log.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_session_policy.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_learning_game_cubit.dart';
import 'package:talia_quran/features/memorization_plus/presentation/pages/kids_learning_game_page.dart';

import '../cubits/memorization_session_cubit_test.mocks.dart'
    show MockAudioPlayer;

KidsSessionLog _log(int surahId) => KidsSessionLog(
  id: '$surahId',
  surahId: surahId,
  ayahNumber: 1,
  repeatsCompleted: 1,
  pointsEarned: 10,
  completedAt: DateTime.utc(2026, 10, 1),
  missionType: KidsMissionType.newMemorization,
);

void main() {
  late MockAudioPlayer player;
  late StreamController<PlayerState> states;

  setUp(() {
    player = MockAudioPlayer();
    states = StreamController<PlayerState>.broadcast(sync: true);
    when(player.playerStateStream).thenAnswer((_) => states.stream);
    when(player.stop()).thenAnswer((_) async {});
    when(player.dispose()).thenAnswer((_) async {});
  });

  tearDown(() => states.close());

  Future<KidsLearningGameCubit> pump(
    WidgetTester tester,
    List<KidsSessionLog> logs, {
    Locale locale = const Locale('en'),
  }) async {
    final cubit = KidsLearningGameCubit(
      sessionLogs: () async => logs,
      audioSource: (_, _) async => 'https://example.test/a.mp3',
      player: player,
      random: Random(5),
    );
    await cubit.start();
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const KidsLearningGameView(),
        ),
      ),
    );
    await tester.pump();
    addTearDown(cubit.close);
    return cubit;
  }

  testWidgets('without memorized ayahs it explains, with no options', (
    tester,
  ) async {
    await pump(tester, const []);

    expect(find.byKey(const ValueKey('kids-game-unavailable')), findsOne);
    expect(find.byKey(const ValueKey('kids-game-listen')), findsNothing);
  });

  testWidgets('shows the round counter and three surah options', (tester) async {
    final cubit = await pump(tester, [_log(114), _log(113), _log(112)]);
    final round = cubit.state.round!;

    for (final id in round.options) {
      expect(find.byKey(ValueKey('kids-game-option-$id')), findsOneWidget);
    }
    expect(find.text('Round 1 of 3'), findsOneWidget);
  });

  testWidgets('a wrong pick names the right surah, then moves on', (
    tester,
  ) async {
    final cubit = await pump(tester, [_log(114), _log(113), _log(112)]);
    final round = cubit.state.round!;
    final wrong = round.options.firstWhere((id) => id != round.surahId);

    await tester.tap(find.byKey(ValueKey('kids-game-option-$wrong')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('kids-game-feedback')), findsOneWidget);
    expect(find.textContaining('This ayah is from'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kids-game-next')));
    await tester.pumpAndSettle();
    expect(find.text('Round 2 of 3'), findsOneWidget);
  });

  testWidgets('renders in Arabic at 320px without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pump(tester, [
      _log(114),
      _log(113),
      _log(112),
    ], locale: const Locale('ar'));

    expect(find.text('الجولة ١ من ٣'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
