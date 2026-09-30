import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_completion_store.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_period_resolver.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_hub_cubit.dart';

Zikr _zikr(String id, AzkarCategory category) => Zikr(
  id: id,
  text: 'نص $id',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: category,
);

class _Repo implements AzkarRepository {
  const _Repo();

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right([_zikr('${category.name}-1', category)]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      Right({
        for (final category in AzkarCategory.values)
          category: [_zikr('${category.name}-1', category)],
      });
}

class _WindowSource implements AzkarPrayerWindowSource {
  const _WindowSource(this.window);
  final AzkarPrayerWindow? window;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async => window;
}

class _ThrowingSource implements AzkarPrayerWindowSource {
  const _ThrowingSource();

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async =>
      throw StateError('no prayer times');
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  AzkarHubCubit build({AzkarPrayerWindowSource? source}) {
    final cubit = AzkarHubCubit(
      const _Repo(),
      AzkarCompletionStore(prefs),
      AzkarPreferencesStore(prefs),
      windowSource: source,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  final now = DateTime(2026, 9, 29, 15, 40);
  final window = AzkarPrayerWindow(
    fajr: DateTime(2026, 9, 29, 4, 30),
    asr: DateTime(2026, 9, 29, 15, 45),
  );

  test('without a source the fixed rule applies (evening from 15:30)', () async {
    final cubit = build();

    await cubit.load(now);

    expect(cubit.state.period, AzkarPeriod.evening);
  });

  test('a prayer window keeps 15:40 in the morning period', () async {
    final cubit = build(source: _WindowSource(window));

    await cubit.load(now);

    expect(cubit.state.period, AzkarPeriod.morning);
  });

  test('a failing source falls back to the fixed rule', () async {
    final cubit = build(source: const _ThrowingSource());

    await cubit.load(now);

    expect(cubit.state.status, AzkarHubStatus.ready);
    expect(cubit.state.period, AzkarPeriod.evening);
  });
}
