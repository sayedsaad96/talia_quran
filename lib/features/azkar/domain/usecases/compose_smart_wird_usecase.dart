import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/azkar_entities.dart';
import '../repositories/azkar_repository.dart';
import '../services/azkar_time_context.dart';

/// One item in a composed smart wird.
class SmartWirdItem extends Equatable {
  const SmartWirdItem({required this.zikr, required this.category});

  final Zikr zikr;

  /// Category the zikr came from — drives counter routing and titles.
  final AzkarCategory category;

  @override
  List<Object?> get props => [zikr.id, category];
}

/// Result of composing a smart wird for a given moment.
class SmartWird extends Equatable {
  const SmartWird({
    required this.items,
    required this.dayPart,
    required this.composedAt,
  });

  final List<SmartWirdItem> items;
  final AzkarDayPart dayPart;
  final DateTime composedAt;

  bool get isEmpty => items.isEmpty;

  int get totalRecitationCount =>
      items.fold(0, (sum, item) => sum + item.zikr.totalCount);

  @override
  List<Object?> get props => [items, dayPart, composedAt];
}

/// Composes a personalized wird from the approved corpus for the current
/// moment. The composer only re-orders and groups existing approved records —
/// it never generates, edits, or paraphrases religious text.
class ComposeSmartWirdUsecase {
  ComposeSmartWirdUsecase(this._repository);

  final AzkarRepository _repository;

  /// Pure composition over an already-loaded corpus — used by callers that
  /// resolved the repository data themselves (e.g. resuming a session) so the
  /// ordering logic has a single source of truth.
  SmartWird composeFromCorpus(
    Map<AzkarCategory, List<Zikr>> corpus,
    AzkarDayPart dayPart,
    DateTime time,
  ) =>
      _compose(corpus, dayPart, time);

  Future<Either<Failure, SmartWird>> call({DateTime? now}) async {
    final time = now ?? DateTime.now();
    final dayPart = AzkarTimeContext.resolveDayPart(time);

    final result = await _repository.getAllAzkar();
    return result.fold(
      (failure) => Left(failure),
      (corpus) => Right(_compose(corpus, dayPart, time)),
    );
  }

  SmartWird _compose(
    Map<AzkarCategory, List<Zikr>> corpus,
    AzkarDayPart dayPart,
    DateTime time,
  ) {
    final items = <SmartWirdItem>[];

    // 1. Time-window zikr for the current period (morning/evening wirds).
    final period = AzkarTimeContext.periodOfDayPart(dayPart);
    final periodCategory = period == AzkarPeriod.morning
        ? AzkarCategory.morning
        : AzkarCategory.evening;
    final periodZikr = corpus[periodCategory] ?? const <Zikr>[];
    if (periodZikr.isNotEmpty) {
      // Prefer records whose timeHint matches the day part, keeping dataset
      // order otherwise — ordering only, text untouched.
      final hint = _hintFor(dayPart);
      final preferred = periodZikr
          .where((z) => z.timeHint.isNotEmpty && z.timeHint == hint)
          .toList();
      final rest = periodZikr.where((z) => !preferred.contains(z)).toList();
      for (final z in [...preferred, ...rest]) {
        items.add(SmartWirdItem(zikr: z, category: periodCategory));
      }
    }

    // 2. Always-relevant daily adhkar (general category) come next.
    for (final z in corpus[AzkarCategory.general] ?? const <Zikr>[]) {
      items.add(SmartWirdItem(zikr: z, category: AzkarCategory.general));
    }

    // 3. Contextual ordering: at night, sleep-section adhkar surface first.
    //    Sorting is stable in Dart, so dataset order is preserved otherwise.
    if (dayPart == AzkarDayPart.night) {
      items.sort((a, b) {
        final aSleep = a.zikr.subcategory.contains('النوم') ? 0 : 1;
        final bSleep = b.zikr.subcategory.contains('النوم') ? 0 : 1;
        return aSleep.compareTo(bSleep);
      });
    }

    return SmartWird(items: items, dayPart: dayPart, composedAt: time);
  }

  String _hintFor(AzkarDayPart part) => switch (part) {
        AzkarDayPart.afterFajr => 'after_fajr',
        AzkarDayPart.morning || AzkarDayPart.forenoon => 'morning',
        AzkarDayPart.afternoon => 'afternoon',
        AzkarDayPart.evening => 'evening',
        AzkarDayPart.night => 'night',
      };
}
