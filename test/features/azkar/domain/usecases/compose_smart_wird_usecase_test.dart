import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/domain/usecases/compose_smart_wird_usecase.dart';
import 'package:dartz/dartz.dart';

class _StubRepo implements AzkarRepository {
  const _StubRepo(this.corpus);

  final Map<AzkarCategory, List<Zikr>> corpus;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      Right(corpus[category] ?? const []);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      Right(corpus);
}

Zikr _zikr(String id, {int count = 1, String subcategory = ''}) => Zikr(
  id: id,
  text: 'نص $id',
  transliteration: '',
  translation: '',
  totalCount: count,
  category: AzkarCategory.general,
  subcategory: subcategory,
);

void main() {
  late ComposeSmartWirdUsecase usecase;

  setUp(() {
    usecase = ComposeSmartWirdUsecase(
      _StubRepo({
        AzkarCategory.morning: [
          const Zikr(
            id: 'm-1',
            text: 'صباح 1',
            transliteration: '',
            translation: '',
            totalCount: 1,
            category: AzkarCategory.morning,
          ),
        ],
        AzkarCategory.general: [
          _zikr('g-1', subcategory: 'أذكار النوم'),
          _zikr('g-2'),
          _zikr('g-3'),
        ],
      }),
    );
  });

  test('composes period zikr first, then general zikr', () async {
    // 09:00 → afterFajr → morning period.
    final result = await usecase(now: DateTime(2026, 9, 25, 9));
    final wird = result.fold((_) => null, (w) => w)!;

    expect(wird.dayPart, AzkarDayPart.afterFajr);
    expect(wird.items.first.zikr.id, 'm-1');
    expect(wird.items.first.category, AzkarCategory.morning);
    expect(
      wird.items
          .skip(1)
          .every((item) => item.category == AzkarCategory.general),
      isTrue,
    );
    // No duplicates: ids are unique.
    final ids = wird.items.map((item) => item.zikr.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('night session surfaces sleep adhkar first via stable sort', () async {
    final result = await usecase(now: DateTime(2026, 9, 25, 22, 30));
    final wird = result.fold((_) => null, (w) => w)!;

    expect(wird.dayPart, AzkarDayPart.night);
    expect(wird.items.first.zikr.id, 'g-1'); // sleep subcategory floats first.
  });

  test(
    'pure composeFromCorpus returns the same ordering as the async path',
    () {
      final corpus = {
        AzkarCategory.morning: [
          const Zikr(
            id: 'm-1',
            text: 'صباح 1',
            transliteration: '',
            translation: '',
            totalCount: 1,
            category: AzkarCategory.morning,
          ),
        ],
        AzkarCategory.general: [_zikr('g-1'), _zikr('g-2')],
      };
      final time = DateTime(2026, 9, 25, 9);
      final pure = usecase.composeFromCorpus(
        corpus,
        AzkarDayPart.afterFajr,
        time,
      );
      expect(pure.items.map((i) => i.zikr.id), ['m-1', 'g-1', 'g-2']);
    },
  );

  test('empty corpus yields an empty wird', () async {
    final empty = ComposeSmartWirdUsecase(const _StubRepo({}));
    final result = await empty(now: DateTime(2026, 9, 25, 9));
    final wird = result.fold((_) => null, (w) => w)!;
    expect(wird.isEmpty, isTrue);
  });
}
