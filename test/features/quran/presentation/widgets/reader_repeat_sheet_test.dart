import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/core/services/reader_repeat_plan.dart';
import 'package:talia_quran/core/services/sleep_timer.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reader_docked_audio_bar.dart';

import '../../../../core/services/quran_continuous_player_repeat_test.dart';
import '../../../../core/services/quran_continuous_player_service_test.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranContinuousPlayerService service;
  late QuranAudioPlayerCubit cubit;
  late RecordingPlayer player;

  // Built inside each test body so the cubit streams live in the test's
  // fake-async zone (pump flushes their microtasks).
  Future<void> build() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    player = RecordingPlayer();
    service = QuranContinuousPlayerService(
      quranRepository: FakeQuranRepository(),
      reciterService: QuranReciterService(prefs),
      player: player,
    );
    cubit = QuranAudioPlayerCubit(service);
    await service.playPage(1);
    addTearDown(() async {
      await cubit.close();
      service.dispose();
      await player.closeControllers();
    });
  }

  Widget host({required bool flag}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<QuranAudioPlayerCubit>.value(
      value: cubit,
      child: Scaffold(body: ReaderDockedAudioBar(showRepeatControls: flag)),
    ),
  );

  testWidgets('repeat button is hidden when the flag is off', (tester) async {
    await build();
    await tester.pumpWidget(host(flag: false));
    expect(find.byKey(const ValueKey('reader-repeat-button')), findsNothing);
  });

  Widget hostDefault() => MaterialApp(
    locale: const Locale('ar'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<QuranAudioPlayerCubit>.value(
      value: cubit,
      child: const Scaffold(body: ReaderDockedAudioBar()),
    ),
  );

  testWidgets('registered flags with readerRepeat missing hide the button', (
    tester,
  ) async {
    await build();
    getIt.registerSingleton<ExperienceFlags>(ExperienceFlags((_) => null));
    addTearDown(() => getIt.unregister<ExperienceFlags>());
    await tester.pumpWidget(hostDefault());
    await settle(tester);
    expect(find.byKey(const ValueKey('reader-repeat-button')), findsNothing);
  });

  testWidgets('registered flag on shows the button; speeds use Arabic digits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await build();
    getIt.registerSingleton<ExperienceFlags>(
      ExperienceFlags(
        (key) => key == ExperienceFeature.readerRepeat.storageKey,
      ),
    );
    addTearDown(() => getIt.unregister<ExperienceFlags>());
    await tester.pumpWidget(hostDefault());
    await tester.tap(find.byKey(const ValueKey('reader-repeat-button')));
    await settle(tester);
    expect(find.text('١.٥x'), findsOneWidget);
    expect(find.text('1.5x'), findsNothing);
  });

  testWidgets('button opens the sheet and choices change the cubit state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await build();
    await tester.pumpWidget(host(flag: true));
    await tester.tap(find.byKey(const ValueKey('reader-repeat-button')));
    await settle(tester);
    expect(find.text('Repeat each ayah'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('repeat-per-ayah-3')));
    await settle(tester);
    expect(cubit.state.repeat.perAyah, 3);

    await tester.tap(find.byKey(const ValueKey('repeat-range-infinite')));
    await settle(tester);
    expect(cubit.state.repeat.rangeTimes, 0);
    expect(cubit.state.repeat.perAyah, 3);

    await tester.tap(find.byKey(const ValueKey('repeat-speed-1.5')));
    await settle(tester);
    expect(cubit.state.repeat.speed, 1.5);

    await tester.tap(find.byKey(const ValueKey('sleep-endOfSurah')));
    await settle(tester);
    expect(cubit.state.sleepChoice, SleepTimerChoice.endOfSurah);

    final chip = tester.widget<ChoiceChip>(
      find.descendant(
        of: find.byKey(const ValueKey('sleep-endOfSurah')),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
    expect(
      cubit.state.repeat,
      const ReaderRepeatSettings(perAyah: 3, rangeTimes: 0, speed: 1.5),
    );
  });
}
