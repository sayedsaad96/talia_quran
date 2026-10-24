import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_continuous_player_service.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/presentation/cubits/quran_audio_player_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reciter_selector_sheet.dart';

import '../../core/services/quran_continuous_player_service_test.dart'
    show ControlledAudioPlayer, FakeQuranRepository;

void main() {
  late ControlledAudioPlayer audioPlayer;
  late QuranContinuousPlayerService playerService;
  late QuranAudioPlayerCubit audioCubit;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final reciterService = QuranReciterService(prefs);
    getIt.registerSingleton<QuranReciterService>(reciterService);
    audioPlayer = ControlledAudioPlayer();
    playerService = QuranContinuousPlayerService(
      quranRepository: FakeQuranRepository(),
      reciterService: reciterService,
      player: audioPlayer,
    );
    audioCubit = QuranAudioPlayerCubit(playerService);
    getIt.registerSingleton<QuranAudioPlayerCubit>(audioCubit);
  });

  tearDown(() async {
    await audioCubit.close();
    playerService.dispose();
    await audioPlayer.closeControllers();
    await getIt.reset();
  });

  testWidgets('reciter options build without hidden ListTile material', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ReciterSelectorSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ListTile), findsWidgets);
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'short large-text ${locale.languageCode} sheet selects new last reciter',
      (tester) async {
        tester.view.physicalSize = const Size(320, 480);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.7)),
              child: child!,
            ),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => ReciterSelectorSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final lastReciter = find.text(
          locale.languageCode == 'ar'
              ? QuranReciter.basfar.nameAr
              : QuranReciter.basfar.nameEn,
        );
        expect(lastReciter, findsOneWidget);
        await tester.ensureVisible(lastReciter);
        await tester.pumpAndSettle();
        await tester.tap(lastReciter);
        await tester.pumpAndSettle();
        final prefs = await SharedPreferences.getInstance();
        expect(
          getIt<QuranReciterService>().currentReciter.value,
          QuranReciter.basfar,
        );
        expect(audioCubit.state.reciter, QuranReciter.basfar);
        expect(prefs.getString('quran_selected_reciter_id'), 'basfar');
        expect(
          QuranReciterService(prefs).currentReciter.value,
          QuranReciter.basfar,
        );
      },
    );
  }

  testWidgets('legacy selection survives reciter service recreation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ReciterSelectorSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(QuranReciter.sudais.nameEn));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(
      getIt<QuranReciterService>().currentReciter.value,
      QuranReciter.sudais,
    );
    expect(audioCubit.state.reciter, QuranReciter.sudais);
    expect(prefs.getString('quran_selected_reciter_id'), 'sudais');
    expect(
      QuranReciterService(prefs).currentReciter.value,
      QuranReciter.sudais,
    );
  });
}
