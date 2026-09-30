import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/azkar_entities.dart';
import '../repositories/azkar_repository.dart';
import '../services/azkar_dedupe.dart';
import '../services/azkar_period_resolver.dart';
import '../services/azkar_time_context.dart';
import '../services/smart_wird_general_policy.dart';

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
    required this.period,
    required this.composedAt,
  });

  final List<SmartWirdItem> items;
  final AzkarDayPart dayPart;

  /// Morning or evening, from [AzkarPeriodResolver]. This is what decides
  /// which time-window azkar lead the wird and whether saved progress resumes.
  final AzkarPeriod period;
  final DateTime composedAt;

  bool get isEmpty => items.isEmpty;

  int get totalRecitationCount =>
      items.fold(0, (sum, item) => sum + item.zikr.totalCount);

  @override
  List<Object?> get props => [items, dayPart, period, composedAt];
}

/// Composes a personalized wird from the approved corpus for the current
/// moment. The composer only re-orders and groups existing approved records —
/// it never generates, edits, or paraphrases religious text.
class ComposeSmartWirdUsecase {
  ComposeSmartWirdUsecase(
    this._repository, {
    AzkarPrayerWindowSource? windowSource,
  }) : _windowSource = windowSource;

  final AzkarRepository _repository;
  final AzkarPrayerWindowSource? _windowSource;

  /// Pure composition over an already-loaded corpus — used by callers that
  /// resolved the repository data themselves (e.g. resuming a session) so the
  /// ordering logic has a single source of truth. When [period] is omitted it
  /// is derived from [time] with the fixed rule.
  SmartWird composeFromCorpus(
    Map<AzkarCategory, List<Zikr>> corpus,
    AzkarDayPart dayPart,
    DateTime time, {
    AzkarPeriod? period,
  }) => _compose(
    corpus,
    dayPart,
    period ?? AzkarPeriodResolver.resolve(time),
    time,
  );

  Future<Either<Failure, SmartWird>> call({DateTime? now}) async {
    final time = now ?? DateTime.now();
    final dayPart = AzkarTimeContext.resolveDayPart(time);
    final period = await AzkarPeriodResolver.resolveWith(time, _windowSource);

    final result = await _repository.getAllAzkar();
    return result.fold(
      (failure) => Left(failure),
      (corpus) => Right(_compose(corpus, dayPart, period, time)),
    );
  }

  SmartWird _compose(
    Map<AzkarCategory, List<Zikr>> corpus,
    AzkarDayPart dayPart,
    AzkarPeriod period,
    DateTime time,
  ) {
    var items = <SmartWirdItem>[];

    // 1. Time-window zikr for the current period, in dataset order.
    final periodCategory = period == AzkarPeriod.morning
        ? AzkarCategory.morning
        : AzkarCategory.evening;
    final seenTexts = <String>{};
    for (final z in corpus[periodCategory] ?? const <Zikr>[]) {
      seenTexts.add(AzkarDedupe.comparisonText(z.text));
      items.add(SmartWirdItem(zikr: z, category: periodCategory));
    }

    // 2. Daily adhkar from the general category, minus situational ones (see
    //    SmartWirdGeneralPolicy) and minus any that repeat a period zikr, so a
    //    wird never asks for the same zikr twice. Dataset order is kept.
    for (final z in corpus[AzkarCategory.general] ?? const <Zikr>[]) {
      if (!SmartWirdGeneralPolicy.includes(z, period)) continue;
      if (seenTexts.contains(AzkarDedupe.comparisonText(z.text))) continue;
      items.add(SmartWirdItem(zikr: z, category: AzkarCategory.general));
    }

    // 3. Contextual ordering: at night, sleep-section adhkar surface first.
    //    A stable partition, not List.sort: sort is not stable above 32 items
    //    and a full wird is longer than that.
    if (dayPart == AzkarDayPart.night) {
      bool isSleep(SmartWirdItem item) =>
          item.zikr.subcategory.contains('النوم');
      items = [
        ...items.where(isSleep),
        ...items.where((item) => !isSleep(item)),
      ];
    }

    return SmartWird(
      items: items,
      dayPart: dayPart,
      period: period,
      composedAt: time,
    );
  }
}
