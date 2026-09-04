import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talia_quran/features/khatmah/data/datasources/khatm_dua_datasource.dart';
import 'package:talia_quran/features/khatmah/domain/usecases/get_khatm_dua_usecase.dart';
import 'package:talia_quran/features/khatmah/presentation/cubits/khatm_dua_cubit.dart';

class MockGetKhatmDuaUsecase extends Mock implements GetKhatmDuaUsecase {}

void main() {
  late MockGetKhatmDuaUsecase mockGetKhatmDua;
  late KhatmDuaCubit cubit;

  const testData = KhatmDuaData(
    arabicText: 'اللَّهُمَّ ارْحَمْنِي بِالقُرْآنِ...',
    source: 'مصحف مجمع الملك فهد لطباعة المصحف الشريف',
    sourceNote: 'دعاء مأثور ومشهور مطبوع في ملحق المصحف الشريف',
    tier: 'guidance',
    dedicationInserts: {
      'alive': 'بركة لـ {name}',
      'deceased': 'رحمة لـ {name}',
      'sick': 'شفاء لـ {name}',
    },
  );

  setUp(() {
    mockGetKhatmDua = MockGetKhatmDuaUsecase();
    cubit = KhatmDuaCubit(mockGetKhatmDua);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is KhatmDuaInitial', () {
    expect(cubit.state, const KhatmDuaInitial());
  });

  test('pending Dua load settles safely after owned cubit disposal', () async {
    final load = Completer<KhatmDuaData>();
    when(() => mockGetKhatmDua()).thenAnswer((_) => load.future);
    final pending = cubit.load();
    await cubit.close();
    load.complete(testData);
    await expectLater(pending, completes);
    expect(cubit.state, isA<KhatmDuaLoading>());
  });

  test('load() emits [KhatmDuaLoading, KhatmDuaLoaded] on success', () async {
    when(() => mockGetKhatmDua()).thenAnswer((_) async => testData);

    final expected = [
      const KhatmDuaLoading(),
      const KhatmDuaLoaded(data: testData, fontScale: 1.0),
    ];

    unawaited(expectLater(cubit.stream, emitsInOrder(expected)));

    await cubit.load();
    verify(() => mockGetKhatmDua()).called(1);
  });

  test('load() emits [KhatmDuaLoading, KhatmDuaError] on failure', () async {
    when(() => mockGetKhatmDua()).thenThrow(Exception('Asset load failed'));

    final expected = [
      const KhatmDuaLoading(),
      const KhatmDuaError('Exception: Asset load failed'),
    ];

    unawaited(expectLater(cubit.stream, emitsInOrder(expected)));

    await cubit.load();
  });

  group('font scale operations', () {
    setUp(() async {
      when(() => mockGetKhatmDua()).thenAnswer((_) async => testData);
      await cubit.load();
    });

    test('increaseFontSize increases font scale by 0.1 up to 1.8 max', () {
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.0);

      cubit.increaseFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.1);

      for (int i = 0; i < 15; i++) {
        cubit.increaseFontSize();
      }
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.8);
    });

    test('decreaseFontSize decreases font scale by 0.1 down to 1.0 min', () {
      cubit.increaseFontSize();
      cubit.increaseFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.2);

      cubit.decreaseFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.1);

      cubit.decreaseFontSize();
      cubit.decreaseFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.0);
    });

    test('resetFontSize resets font scale to 1.0', () {
      cubit.increaseFontSize();
      cubit.increaseFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.2);

      cubit.resetFontSize();
      expect((cubit.state as KhatmDuaLoaded).fontScale, 1.0);
    });
  });
}
