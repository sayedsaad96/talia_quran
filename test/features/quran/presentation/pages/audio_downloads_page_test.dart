import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/icons/talia_icons.dart';
import 'package:talia_quran/core/memorization/memorization_path_resolver.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_profile.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/core/experience/experience_feature_flags.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/core/services/quran_audio_download_manager.dart';
import 'package:talia_quran/core/services/quran_reciter.dart';
import 'package:talia_quran/core/services/quran_reciter_service.dart';
import 'package:talia_quran/features/quran/domain/repositories/quran_repository.dart';
import 'package:talia_quran/features/quran/presentation/pages/audio_downloads_page.dart';
import 'package:talia_quran/features/quran/presentation/pages/audio_storage_page.dart';
import 'package:talia_quran/features/quran/presentation/cubits/audio_downloads_cubit.dart';
import 'package:talia_quran/features/quran/presentation/widgets/reciter_selector_sheet.dart';

void main() {
  late _Downloads downloads;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    downloads = _Downloads(await SharedPreferences.getInstance());
    getIt.registerSingleton<QuranAudioDownloadManager>(downloads);
  });

  tearDown(() async {
    await downloads.events.close();
    await getIt.reset();
  });

  Widget app(Widget page) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: page,
  );

  test('two immediate starts create only one download request', () async {
    final cubit = AudioDownloadsCubit(downloads);
    await Future.wait([
      cubit.start(
        reciter: QuranReciter.alafasy,
        wifiOnly: true,
        allowUnverifiedNetwork: true,
        surah: 1,
      ),
      cubit.start(
        reciter: QuranReciter.alafasy,
        wifiOnly: true,
        allowUnverifiedNetwork: true,
        surah: 1,
      ),
    ]);
    expect(downloads.requests, hasLength(1));
    await cubit.close();
  });

  testWidgets(
    'reciter sheet scrolls on a short Arabic screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      getIt.registerSingleton<ExperienceFlags>(ExperienceFlags((_) => true));
      getIt.registerSingleton<QuranReciterService>(
        QuranReciterService(await SharedPreferences.getInstance()),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
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
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(QuranReciter.shuraim.nameAr), findsOneWidget);
    },
  );

  testWidgets('unknown storage never appears as measured zero', (tester) async {
    downloads.bytesResult = Completer<int>();
    await tester.pumpWidget(app(const AudioStoragePage()));
    await tester.pump();
    expect(find.text('0 bytes'), findsNothing);
    downloads.bytesResult!.completeError(StateError('measurement failed'));
    await tester.pumpAndSettle();
    expect(find.text('0 bytes'), findsNothing);
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('requires explicit network decision and preserves Wi-Fi intent', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AudioDownloadsPage(initialSurah: 2)));
    await tester.pumpAndSettle();
    final wifi = find.byType(SwitchListTile).last;
    expect(tester.widget<SwitchListTile>(wifi).value, isTrue);
    await tester.tap(find.text('Download or resume'));
    await tester.pumpAndSettle();
    expect(downloads.requests, isEmpty);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(downloads.requests, isEmpty);
    await tester.tap(find.text('Download or resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue downloading'));
    await tester.pumpAndSettle();
    expect(downloads.requests.single, (
      surah: 2,
      juz: null,
      wifi: true,
      allowed: true,
    ));
    downloads.events.add(
      const DownloadProgress(
        phase: DownloadPhase.downloading,
        completedAyahs: 1,
        totalAyahs: 3,
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(downloads.cancelCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving while downloading asks before stopping', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AudioDownloadsPage(initialSurah: 2),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download or resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue downloading'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Stop the download?'), findsOneWidget);
    expect(downloads.cancelCalls, 0);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Download or resume'), findsOneWidget);
    expect(downloads.cancelCalls, 0);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop download'));
    await tester.pumpAndSettle();
    expect(downloads.cancelCalls, 1);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a child profile never sees the download entry', (tester) async {
    getIt.registerSingleton<ExperienceFlags>(ExperienceFlags((_) => true));
    getIt.registerSingleton<QuranReciterService>(
      QuranReciterService(await SharedPreferences.getInstance()),
    );
    getIt.registerSingleton<MemorizationPathResolver>(
      MemorizationPathResolver(_ProfileRepo(MemorizationPath.child)),
    );
    await tester.pumpWidget(
      app(
        Builder(
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
    expect(find.text('Download recitations'), findsNothing);
    expect(find.byIcon(TaliaIcons.download), findsNothing);
  });

  testWidgets('Juz Amma sends exact juz 30 rather than a surah list', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AudioDownloadsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Juz 30'), findsOneWidget);
    await tester.tap(find.text('Download or resume'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue downloading'));
    await tester.pumpAndSettle();
    expect(downloads.requests.single.juz, 30);
    expect(downloads.requests.single.surah, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('storage deletion needs confirmation and targets one reciter', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AudioStoragePage()));
    await tester.pumpAndSettle();
    expect(find.text('128 bytes'), findsNWidgets(QuranReciter.values.length));
    await tester.tap(find.byTooltip("Delete this reciter's downloads").first);
    await tester.pumpAndSettle();
    expect(downloads.deleted, isEmpty);
    await tester.tap(find.text("Delete this reciter's downloads"));
    await tester.pumpAndSettle();
    expect(downloads.deleted, [QuranReciter.alafasy]);
  });
}

class _Downloads extends QuranAudioDownloadManager {
  _Downloads(SharedPreferences prefs) : super(prefs, _Quran());
  final events = StreamController<DownloadProgress>.broadcast();
  final requests = <({int? surah, int? juz, bool wifi, bool allowed})>[];
  final deleted = <QuranReciter>[];
  int cancelCalls = 0;
  Completer<int>? bytesResult;

  @override
  Stream<DownloadProgress> downloadSurahs(
    QuranReciter reciter,
    List<int> surahIds, {
    bool wifiOnly = true,
    bool allowUnverifiedNetwork = false,
  }) {
    requests.add((
      surah: surahIds.single,
      juz: null,
      wifi: wifiOnly,
      allowed: allowUnverifiedNetwork,
    ));
    return events.stream;
  }

  @override
  Stream<DownloadProgress> downloadJuz(
    QuranReciter reciter,
    int juz, {
    bool wifiOnly = true,
    bool allowUnverifiedNetwork = false,
  }) {
    requests.add((
      surah: null,
      juz: juz,
      wifi: wifiOnly,
      allowed: allowUnverifiedNetwork,
    ));
    return events.stream;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Future<int> usedBytes({QuranReciter? reciter}) async =>
      bytesResult == null ? 128 : await bytesResult!.future;

  @override
  Future<void> deleteReciter(QuranReciter reciter) async {
    deleted.add(reciter);
  }
}

class _ProfileRepo extends Fake implements MemorizationPlusRepository {
  _ProfileRepo(this.path);
  final MemorizationPath path;
  @override
  Future<Either<Failure, MemorizationProfile>> getMemorizationProfile() async =>
      Right(
        MemorizationProfile(
          schemaVersion: 1,
          selectedPath: path,
          guardianLinkStatus: GuardianLinkStatus.none,
          guardianOnboardingStatus: GuardianOnboardingStatus.required,
          isParentGuardian: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
}

class _Quran implements QuranRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
