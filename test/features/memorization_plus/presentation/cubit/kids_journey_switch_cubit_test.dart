import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/core/identity/account_data_barrier.dart';
import 'package:talia_quran/core/identity/record_owner_provider.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/kids_journey_path_definition.dart';
import 'package:talia_quran/features/memorization_plus/domain/entities/memorization_entities.dart';
import 'package:talia_quran/features/memorization_plus/domain/repositories/memorization_plus_repository.dart';
import 'package:talia_quran/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart';
import 'package:talia_quran/features/memorization_plus/presentation/cubits/kids_journey_switch_cubit.dart';

class Repo extends Mock implements MemorizationPlusRepository {}

class Owner implements RecordOwnerProvider {
  @override
  String currentOwnerId = 'child';
  @override
  bool get isSignedIn => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Repo repo;
  late Owner owner;
  late AccountDataBarrier barrier;
  late KidsJourneySwitchCubit cubit;
  final profile = MemorizationProfile.empty().copyWith(
    selectedPath: MemorizationPath.child,
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repo = Repo();
    owner = Owner();
    barrier = AccountDataBarrier.forPreferences(prefs)..owner = owner;
    when(
      () => repo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(profile));
    when(
      () => repo.getKidsJourneyPath(),
    ).thenAnswer((_) async => const Right(KidsJourneyPathDefinition.adventure));
    when(
      () => repo.setKidsJourneyPath(any()),
    ).thenAnswer((_) async => const Right(ParentSettings()));
    cubit = KidsJourneySwitchCubit(
      repo,
      ParentAccessUsecase(repo),
      owner,
      barrier,
    );
    await cubit.load();
  });
  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });
  setUpAll(() => registerFallbackValue(KidsJourneyPathId.juzAmmaAdventure));
  test('unchanged and cancelled authorization do not write', () async {
    await cubit.save((_) async => true);
    cubit.select(KidsJourneyPathId.quranFromNas);
    await cubit.save((_) async => false);
    verifyNever(() => repo.setKidsJourneyPath(any()));
    expect(cubit.state.status, JourneySwitchStatus.ready);
  });
  for (final id in KidsJourneyPathId.values.where(
    (id) => id != KidsJourneyPathId.juzAmmaAdventure,
  )) {
    test('saves $id once', () async {
      cubit.select(id);
      final pin = Completer<bool>();
      final first = cubit.save((_) => pin.future);
      await Future<void>.delayed(Duration.zero);
      await cubit.save((_) async => true);
      pin.complete(true);
      await first;
      verify(() => repo.setKidsJourneyPath(id)).called(1);
      expect(cubit.state.status, JourneySwitchStatus.success);
    });
  }
  test('owner invalidation while authorizing aborts write', () async {
    cubit.select(KidsJourneyPathId.quranFromNas);
    await cubit.save((_) async {
      barrier.invalidate();
      return true;
    });
    verifyNever(() => repo.setKidsJourneyPath(any()));
    expect(cubit.state.status, JourneySwitchStatus.stale);
  });
  test('guardian link change while authorizing aborts write', () async {
    cubit.select(KidsJourneyPathId.quranFromNas);
    await cubit.save((_) async {
      when(() => repo.getMemorizationProfile()).thenAnswer(
        (_) async => Right(
          profile.copyWith(
            guardianLinkStatus: GuardianLinkStatus.linked,
            guardianId: 'guardian',
          ),
        ),
      );
      return true;
    });
    verifyNever(() => repo.setKidsJourneyPath(any()));
    expect(cubit.state.status, JourneySwitchStatus.stale);
  });
  test('returning to adventure saves the selected adventure', () async {
    when(() => repo.getKidsJourneyPath()).thenAnswer(
      (_) async => Right(
        KidsJourneyPathDefinition.of(KidsJourneyPathId.quranFromFatiha),
      ),
    );
    await cubit.load();
    cubit.select(KidsJourneyPathId.juzAmmaAdventure);
    await cubit.save((_) async => true);
    verify(
      () => repo.setKidsJourneyPath(KidsJourneyPathId.juzAmmaAdventure),
    ).called(1);
  });
  test('linked child requests linked authorization', () async {
    when(() => repo.getMemorizationProfile()).thenAnswer(
      (_) async => Right(
        profile.copyWith(guardianLinkStatus: GuardianLinkStatus.linked),
      ),
    );
    cubit.select(KidsJourneyPathId.quranFromNas);
    bool? linked;
    await cubit.save((value) async {
      linked = value;
      return false;
    });
    expect(linked, isTrue);
    verifyNever(() => repo.setKidsJourneyPath(any()));
  });
  test('profile and write errors stay recoverable', () async {
    when(
      () => repo.getMemorizationProfile(),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    await cubit.load();
    expect(cubit.state.status, JourneySwitchStatus.error);
    when(
      () => repo.getMemorizationProfile(),
    ).thenAnswer((_) async => Right(profile));
    await cubit.load();
    cubit.select(KidsJourneyPathId.quranFromNas);
    when(
      () => repo.setKidsJourneyPath(any()),
    ).thenAnswer((_) async => const Left(CacheFailure()));
    await cubit.save((_) async => true);
    expect(cubit.state.status, JourneySwitchStatus.error);
    await cubit.load();
    expect(cubit.state.status, JourneySwitchStatus.ready);
  });
  test('closing while authorization is pending prevents the write', () async {
    cubit.select(KidsJourneyPathId.quranFromNas);
    final pin = Completer<bool>();
    final save = cubit.save((_) => pin.future);
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    pin.complete(true);
    await save;
    verifyNever(() => repo.setKidsJourneyPath(any()));
  });
}
