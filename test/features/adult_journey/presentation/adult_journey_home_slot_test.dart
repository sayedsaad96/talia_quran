import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/core/di/injection.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/core/journey/unified_journey_action.dart';
import 'package:talia_quran/features/adult_journey/adult_journey_feature_flags.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_preferences.dart';
import 'package:talia_quran/features/adult_journey/domain/entities/adult_journey_update.dart';
import 'package:talia_quran/features/adult_journey/presentation/cubits/adult_journey_cubit.dart';
import 'package:talia_quran/features/adult_journey/presentation/widgets/adult_journey_home_slot.dart';
import 'package:talia_quran/features/home/presentation/cubits/home_cubit.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/progress/domain/entities/progress_entities.dart';

import 'adult_journey_test_harness.dart';

class _FakeHomeCubit extends Cubit<HomeState> implements HomeCubit {
  _FakeHomeCubit(super.initialState);

  void push(HomeState next) => emit(next);

  @override
  Future<void> load() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _progress = OverallProgress(
  memorizedAyahs: 0,
  totalAyahs: 6236,
  memorizedSurahs: 0,
  totalSurahs: 114,
  memorizedJuz: 0,
  totalJuz: 30,
  readAyahs: 0,
  readSurahs: 0,
  readJuz: 0,
  streakDays: 0,
  lastActiveDate: null,
  achievements: [],
  readPagesCount: 0,
  totalQuranPages: 604,
  learningAyahs: 0,
  reviewAyahs: 0,
  kidsPoints: 0,
  kidsStars: 0,
);

const _explore = UnifiedJourneyAction(
  route: '/quran',
  priority: UnifiedJourneyPriority.p6FreeExploration,
  source: 'test',
  actionType: UnifiedJourneyActionType.explore,
  intent: JourneyIntent.explore,
);

/// [firstRun] true leaves every field empty so `HomeLoaded.isFirstRun` holds.
HomeLoaded _home({
  MemorizationTrack? track = MemorizationTrack.adults,
  bool isKids = false,
  bool firstRun = false,
}) => HomeLoaded(
  progress: _progress,
  greeting: 'morning',
  activityStartDate: DateTime.utc(2026, 1, 1),
  selectedTrack: track,
  isKids: isKids,
  heroAction: firstRun ? null : _explore,
  alternativeActions: firstRun ? const [] : const [_explore],
);

const _inviteTitle = 'Make your journey fit you';
const _todayTitle = 'How much time do you have today?';

void main() {
  late MockLoadAdultJourney load;
  late MockUpdateAdultJourney update;
  late Map<String, bool> flagValues;
  late int cubitsBuilt;

  setUpAll(() => registerFallbackValue(const ClearAdultToday()));

  setUp(() async {
    await getIt.reset();
    load = MockLoadAdultJourney();
    update = MockUpdateAdultJourney();
    cubitsBuilt = 0;
    flagValues = {
      AdultJourneyFeature.personalization.storageKey: true,
      AdultJourneyFeature.todayBudget.storageKey: false,
    };
    when(
      () => load(any()),
    ).thenAnswer((_) async => AdultJourneyLoadResult.missing);
    const owner = FixedRecordOwnerProvider('owner-a');
    getIt.registerSingleton<RecordOwnerProvider>(owner);
    getIt.registerSingleton<AdultJourneyFlags>(
      AdultJourneyFlags((key) => flagValues[key]),
    );
    getIt.registerFactory<AdultJourneyCubit>(() {
      cubitsBuilt++;
      return AdultJourneyCubit(
        loadAdultJourney: load,
        updateAdultJourney: update,
        flags: getIt<AdultJourneyFlags>(),
        owner: owner,
        accountChanges: const Stream<void>.empty(),
        now: () => adultTestNow,
      );
    });
  });

  tearDown(() => getIt.reset());

  Future<_FakeHomeCubit> pumpSlot(
    WidgetTester tester,
    HomeState home, {
    Brightness brightness = Brightness.light,
    String locale = 'en',
  }) async {
    final cubit = _FakeHomeCubit(home);
    addTearDown(cubit.close);
    await tester.pumpWidget(
      adultTestApp(
        locale: locale,
        brightness: brightness,
        home: BlocProvider<HomeCubit>.value(
          value: cubit,
          child: const CustomScrollView(slivers: [AdultJourneyHomeSlot()]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('flags off: nothing rendered and no cubit or read', (
    tester,
  ) async {
    flagValues[AdultJourneyFeature.personalization.storageKey] = false;
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsNothing);
    expect(cubitsBuilt, 0);
    verifyNever(() => load(any()));
  });

  testWidgets('a confirmed adult without a profile sees the invite', (
    tester,
  ) async {
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    expect(find.text(_todayTitle), findsNothing, reason: 'budget flag off');
  });

  testWidgets('one welcome card: no invite while first-run shows', (
    tester,
  ) async {
    final home = _home(firstRun: true);
    expect(home.isFirstRun, isTrue);
    await pumpSlot(tester, home);
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('no chosen track or a child profile sees nothing', (
    tester,
  ) async {
    await pumpSlot(tester, _home(track: null));
    expect(find.text(_inviteTitle), findsNothing);
    await pumpSlot(tester, _home(track: MemorizationTrack.kids, isKids: true));
    expect(find.text(_inviteTitle), findsNothing);
    verifyNever(() => load(any()));
  });

  testWidgets('a new Home state for a child hides the visible overlay', (
    tester,
  ) async {
    final home = await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    home.push(_home(track: MemorizationTrack.kids, isKids: true));
    await tester.pumpAndSettle();
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('"Later" snoozes the invite for today only', (tester) async {
    when(() => update(any(), any())).thenAnswer(
      (_) async => const AdultJourneySaveResult.saved(
        AdultJourneyPreferences(setupSnoozedLocalDate: adultTestToday),
      ),
    );
    await pumpSlot(tester, _home());
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    final command =
        verify(() => update('owner-a', captureAny())).captured.single
            as SnoozeAdultSetup;
    expect(command.localDate, adultTestToday);
    expect(find.text(_inviteTitle), findsNothing);
  });

  testWidgets('the budget flag adds the time card under the invite', (
    tester,
  ) async {
    flagValues[AdultJourneyFeature.todayBudget.storageKey] = true;
    await pumpSlot(tester, _home());
    expect(find.text(_inviteTitle), findsOneWidget);
    expect(find.text(_todayTitle), findsOneWidget);
  });

  group('dark mode and accessibility', () {
    for (final brightness in Brightness.values) {
      for (final locale in ['ar', 'en']) {
        testWidgets('${brightness.name} $locale: guidelines met at 320 px', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          flagValues[AdultJourneyFeature.todayBudget.storageKey] = true;

          await pumpSlot(
            tester,
            _home(),
            brightness: brightness,
            locale: locale,
          );

          expect(tester.takeException(), isNull);
          // Not vacuous: the invite and the three time chips are on screen.
          expect(find.byType(ChoiceChip), findsNWidgets(3));
          expect(find.byType(FilledButton), findsWidgets);
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          handle.dispose();
        });
      }
    }
  });
}
