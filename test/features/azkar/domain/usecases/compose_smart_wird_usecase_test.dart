import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_period_resolver.dart';
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

Zikr _periodZikr(String id, AzkarCategory category) => Zikr(
  id: id,
  text: 'نص $id',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: category,
);

class _FixedWindowSource implements AzkarPrayerWindowSource {
  const _FixedWindowSource(this.window);
  final AzkarPrayerWindow? window;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async => window;
}

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

  group('review findings', () {
    test('the night sleep-first ordering is stable for a long wird', () {
      // 22 evening + 3 sleep + 11 plain general = 36 items. Dart's List.sort is
      // not stable above 32 items, so the reorder must be a partition.
      final evening = [
        for (var i = 1; i <= 22; i++) _periodZikr('e$i', AzkarCategory.evening),
      ];
      final general = [
        _zikr('g1'),
        _zikr('s1', subcategory: 'أذكار النوم'),
        for (var i = 2; i <= 10; i++) _zikr('g$i'),
        _zikr('s2', subcategory: 'أذكار النوم'),
        _zikr('s3', subcategory: 'أذكار النوم'),
        _zikr('g11'),
      ];
      final corpus = {
        AzkarCategory.evening: evening,
        AzkarCategory.general: general,
      };
      final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));

      final wird = useCase.composeFromCorpus(
        corpus,
        AzkarDayPart.night,
        DateTime(2026, 9, 25, 22, 30),
      );

      final ids = wird.items.map((item) => item.zikr.id).toList();
      expect(ids.take(3), ['s1', 's2', 's3']);
      expect(ids.skip(3).take(22), [for (var i = 1; i <= 22; i++) 'e$i']);
      expect(ids.skip(25), [
        'g1',
        for (var i = 2; i <= 10; i++) 'g$i',
        'g11',
      ]);
    });

    test('a general zikr repeating a period zikr is left out of the wird', () {
      Zikr withText(String id, AzkarCategory category, String text) => Zikr(
        id: id,
        text: text,
        transliteration: '',
        translation: '',
        totalCount: 1,
        category: category,
      );
      final corpus = {
        AzkarCategory.morning: [
          withText('m-1', AzkarCategory.morning, 'لَا إِلَهَ إِلَّا اللَّهُ'),
        ],
        AzkarCategory.general: [
          withText('g-dup', AzkarCategory.general, 'لا إله إلا الله.'),
          withText('g-other', AzkarCategory.general, 'ذكر آخر'),
        ],
      };
      final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));

      final wird = useCase.composeFromCorpus(
        corpus,
        AzkarDayPart.afterFajr,
        DateTime(2026, 9, 25, 9),
      );

      expect(wird.items.map((item) => item.zikr.id), ['m-1', 'g-other']);
    });
  });

  group('period selection', () {
    final corpus = {
      AzkarCategory.morning: [_periodZikr('m-1', AzkarCategory.morning)],
      AzkarCategory.evening: [_periodZikr('e-1', AzkarCategory.evening)],
      AzkarCategory.general: [_zikr('g-1')],
    };

    test(
      'serves the evening set from 15:30 although the day part is afternoon',
      () async {
        final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));

        final result = await useCase(now: DateTime(2026, 9, 25, 16));
        final wird = result.fold((_) => null, (w) => w)!;

        expect(wird.dayPart, AzkarDayPart.afternoon);
        expect(wird.period, AzkarPeriod.evening);
        expect(wird.items.first.zikr.id, 'e-1');
      },
    );

    test('a prayer window moves the boundary to Asr', () async {
      final window = AzkarPrayerWindow(
        fajr: DateTime(2026, 9, 25, 4, 30),
        asr: DateTime(2026, 9, 25, 15, 45),
      );
      final useCase = ComposeSmartWirdUsecase(
        _StubRepo(corpus),
        windowSource: _FixedWindowSource(window),
      );

      final beforeAsr = await useCase(now: DateTime(2026, 9, 25, 15, 40));
      final afterAsr = await useCase(now: DateTime(2026, 9, 25, 15, 50));

      expect(beforeAsr.fold((_) => null, (w) => w)!.items.first.zikr.id, 'm-1');
      expect(afterAsr.fold((_) => null, (w) => w)!.items.first.zikr.id, 'e-1');
    });

    test('composeFromCorpus honours an explicit period', () {
      final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));

      final wird = useCase.composeFromCorpus(
        corpus,
        AzkarDayPart.afterFajr,
        DateTime(2026, 9, 25, 9),
        period: AzkarPeriod.evening,
      );

      expect(wird.period, AzkarPeriod.evening);
      expect(wird.items.first.zikr.id, 'e-1');
    });
  });
  group('general azkar selection', () {
    final corpus = {
      AzkarCategory.morning: [_periodZikr('m-1', AzkarCategory.morning)],
      AzkarCategory.evening: [_periodZikr('e-1', AzkarCategory.evening)],
      AzkarCategory.general: [
        _zikr('g-toilet', subcategory: 'أذكار الخلاء'),
        _zikr('g-sleep', subcategory: 'أذكار النوم'),
        _zikr('g-waking', subcategory: 'أذكار الاستيقاظ'),
        _zikr('g-misc', subcategory: 'أذكار منوعة'),
        _zikr('g-plain'),
      ],
    };

    List<String> idsAt(int hour) {
      final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));
      final wird = useCase.composeFromCorpus(
        corpus,
        AzkarTimeContext.resolveDayPart(DateTime(2026, 9, 25, hour)),
        DateTime(2026, 9, 25, hour),
      );
      return wird.items.map((item) => item.zikr.id).toList();
    }

    test('a morning wird has waking azkar, no sleep, no situational', () {
      expect(idsAt(9), ['m-1', 'g-waking', 'g-misc', 'g-plain']);
    });

    test('an evening wird has sleep azkar, no waking, no situational', () {
      // 19:00 is the evening day part, so no night re-sort applies.
      expect(idsAt(19), ['e-1', 'g-sleep', 'g-misc', 'g-plain']);
    });
  });
}
