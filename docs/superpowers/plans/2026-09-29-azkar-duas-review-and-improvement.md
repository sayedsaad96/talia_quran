# Azkar & Duas Review and Improvement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make morning/evening azkar selection consistent, hide duplicate duas without losing favorites, fix the reading, smart-wird and library defects found in review, and add tests that keep them fixed.

**Architecture:** Small pure domain services (`AzkarPeriodResolver`, `AzkarDedupe`, `SmartWirdGeneralPolicy`) carry the new rules and are injected into the existing cubit, use case and repository. Presentation changes reuse one shared index sheet and one shared copy-text helper instead of per-page copies. Religious text and `azkar_release.json` are never modified.

**Tech Stack:** Flutter, `flutter_bloc` cubits, `get_it` manual DI, `dartz` `Either`, `shared_preferences`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-29-azkar-duas-review-and-improvement-design.md`

## Global Constraints

- Never add, edit, translate or re-normalize text in `assets/data/azkar_release.json`. Its sha256 in `assets/data/content_manifest.json` must not change.
- Work in `D:\Flutter\talia_quran`. The tree holds the owner's uncommitted work in `lib/core/di/injection.dart`, `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` and the generated `lib/core/l10n/app_localizations*.dart`. Edit those files only where a task says so, and touch only the lines it names.
- Do not run `dart format` on directories. Format only the files a task creates or edits: `dart format <file> <file>`.
- Do not commit. The tree is dirty and some touched files contain the owner's unrelated hunks. Each task ends with a checkpoint (tests and analyzer), not a commit. The owner decides what to commit.
- New user-facing strings go into both `app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`.
- Lints in force: `unawaited_futures`, `avoid_print` (use `TaliaLogger`), `prefer_final_locals`.
- Baseline before Task 1: `flutter test test/features/azkar test/core/content test/features/khatmah/presentation/pages/khatm_dua_page_test.dart` passes (69 tests) and `flutter analyze lib/features/azkar lib/core/content` reports no issues.
- Quran-type records must match `quran.json`; an item that fails is reported, never "fixed" from memory.

## Review Focus

Inputs and conditions the spec implies but no single feature test would exercise. Each line names the task that pins it.

1. Prayer times disabled, no city chosen, or the prayer lookup throws: the hub and smart wird must fall back to the fixed 04:00–15:30 rule and never crash. (Task 1, Task 3)
2. A stale prayer window (computed for another day) or one where Fajr is after Asr must be ignored, not applied. (Task 1)
3. A user favorited the *hidden* copy of a duplicate dua before this change: it must show as a favorite on the visible copy, and toggling must clear both ids. (Task 5)
4. A corrupt or legacy saved smart-wird session (no `period` field, or wrong types) must still load without throwing. (Task 4)
5. A category with zero records must deduplicate to an empty list and still reach the existing "under review" screens, not an index error. (Task 5 empty-list test; the existing `azkar_release_ui_test.dart` covers the screens)

## File Structure

Create:
- `lib/features/azkar/domain/services/azkar_period_resolver.dart` — `AzkarPrayerWindow`, `AzkarPrayerWindowSource`, `AzkarPeriodResolver`.
- `lib/features/azkar/domain/services/azkar_dedupe.dart` — `DedupedAzkar`, `AzkarDedupe`.
- `lib/features/azkar/domain/services/smart_wird_general_policy.dart` — which general azkar join a wird.
- `lib/features/azkar/data/datasources/prayer_times_window_source.dart` — adapts `PrayerTimesService`.
- `lib/features/azkar/data/datasources/azkar_alias_registry.dart` — canonical id to hidden duplicate ids.
- `lib/features/azkar/presentation/widgets/azkar_index_sheet.dart` — shared index sheet and title helper.
- `lib/features/azkar/presentation/widgets/zikr_audio_state_builder.dart` — rebuilds on audio state.
- `lib/features/azkar/presentation/services/zikr_copy_text.dart` — one copy-text format.
- Tests mirror each file under `test/features/azkar/...`, plus `test/assets/azkar_dedupe_contract_test.dart`, `test/assets/azkar_quran_text_contract_test.dart`, `test/assets/smart_wird_subcategory_contract_test.dart`.

Modify:
- `lib/features/azkar/domain/services/azkar_time_context.dart` — remove `periodOfDayPart`.
- `lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart`
- `lib/features/azkar/data/datasources/smart_wird_progress_store.dart`
- `lib/features/azkar/data/datasources/azkar_preferences_store.dart`
- `lib/features/azkar/data/repositories/azkar_repository_impl.dart`
- `lib/features/azkar/presentation/cubits/azkar_hub_cubit.dart`, `azkar_cubit.dart`, `azkar_state.dart`
- `lib/features/azkar/presentation/pages/azkar_page.dart`, `azkar_category_page.dart`, `smart_wird_page.dart`, `general_azkar_page.dart`
- `lib/features/azkar/presentation/services/zikr_audio_service.dart`
- `lib/core/di/injection.dart` (lines near 337–342, 529 and 805–812 only)
- `lib/core/l10n/app_ar.arb`, `app_en.arb` (Task 12 only)

---

# Phase 1: Stability and correctness

### Task 1: One period resolver

**Files:**
- Create: `lib/features/azkar/domain/services/azkar_period_resolver.dart`
- Test: `test/features/azkar/domain/services/azkar_period_resolver_test.dart`

**Interfaces:**
- Consumes: `AzkarPeriod`, `AzkarTimeContext.resolvePeriod(DateTime)` from `azkar_time_context.dart`.
- Produces:
  - `class AzkarPrayerWindow { const AzkarPrayerWindow({required DateTime fajr, required DateTime asr}); bool get isConsistent; bool appliesTo(DateTime now); }`
  - `abstract interface class AzkarPrayerWindowSource { Future<AzkarPrayerWindow?> load(DateTime now); }`
  - `AzkarPeriodResolver.resolve(DateTime now, {AzkarPrayerWindow? window}) -> AzkarPeriod`
  - `AzkarPeriodResolver.resolveWith(DateTime now, AzkarPrayerWindowSource? source) -> Future<AzkarPeriod>` (never throws)

- [ ] **Step 0: Record the dirty-tree baseline**

Run: `git status --short lib/features/azkar test/features/azkar test/assets`
Expected: no lines (these paths are clean). If lines appear, note them and do not overwrite those hunks.

- [ ] **Step 1: Write the failing test**

Create `test/features/azkar/domain/services/azkar_period_resolver_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_period_resolver.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';

DateTime _at(int hour, [int minute = 0, int day = 29]) =>
    DateTime(2026, 9, day, hour, minute);

class _FixedSource implements AzkarPrayerWindowSource {
  const _FixedSource(this.window);
  final AzkarPrayerWindow? window;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async => window;
}

class _ThrowingSource implements AzkarPrayerWindowSource {
  const _ThrowingSource();

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async =>
      throw StateError('prayer lookup failed');
}

void main() {
  final window = AzkarPrayerWindow(fajr: _at(4, 30), asr: _at(15, 45));

  group('with a prayer window', () {
    test('morning runs from Fajr up to Asr', () {
      expect(
        AzkarPeriodResolver.resolve(_at(4, 29), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(4, 30), window: window),
        AzkarPeriod.morning,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(15, 44), window: window),
        AzkarPeriod.morning,
      );
    });

    test('evening starts at Asr and lasts until the next Fajr', () {
      expect(
        AzkarPeriodResolver.resolve(_at(15, 45), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(18, 30), window: window),
        AzkarPeriod.evening,
      );
      expect(
        AzkarPeriodResolver.resolve(_at(0, 30), window: window),
        AzkarPeriod.evening,
      );
    });

    test('15:40 is still morning when Asr is later than 15:30', () {
      // The fixed rule would say evening here; the window must win.
      expect(AzkarTimeContext.resolvePeriod(_at(15, 40)), AzkarPeriod.evening);
      expect(
        AzkarPeriodResolver.resolve(_at(15, 40), window: window),
        AzkarPeriod.morning,
      );
    });
  });

  group('without a usable window', () {
    test('no window uses the fixed rule', () {
      expect(AzkarPeriodResolver.resolve(_at(15, 29)), AzkarPeriod.morning);
      expect(AzkarPeriodResolver.resolve(_at(16)), AzkarPeriod.evening);
    });

    test('a stale window from two days ago is ignored', () {
      final stale = AzkarPrayerWindow(
        fajr: _at(4, 30, 27),
        asr: _at(15, 45, 27),
      );
      // If the stale window were applied, 10:00 on the 29th would be after its
      // Asr and read as evening.
      expect(
        AzkarPeriodResolver.resolve(_at(10), window: stale),
        AzkarPeriod.morning,
      );
    });

    test('a window with Fajr after Asr is ignored', () {
      final broken = AzkarPrayerWindow(fajr: _at(16), asr: _at(5));
      expect(broken.isConsistent, isFalse);
      expect(
        AzkarPeriodResolver.resolve(_at(10), window: broken),
        AzkarPeriod.morning,
      );
    });
  });

  group('resolveWith', () {
    test('uses the window a source returns', () async {
      final period = await AzkarPeriodResolver.resolveWith(
        _at(15, 40),
        _FixedSource(window),
      );
      expect(period, AzkarPeriod.morning);
    });

    test('falls back to the fixed rule when there is no source', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(_at(15, 40), null),
        AzkarPeriod.evening,
      );
    });

    test('falls back to the fixed rule when the source returns null', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(
          _at(15, 40),
          const _FixedSource(null),
        ),
        AzkarPeriod.evening,
      );
    });

    test('falls back to the fixed rule when the source throws', () async {
      expect(
        await AzkarPeriodResolver.resolveWith(
          _at(15, 40),
          const _ThrowingSource(),
        ),
        AzkarPeriod.evening,
      );
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/azkar/domain/services/azkar_period_resolver_test.dart`
Expected: FAIL to compile, `azkar_period_resolver.dart` not found.

- [ ] **Step 3: Write the implementation**

Create `lib/features/azkar/domain/services/azkar_period_resolver.dart`:

```dart
import 'azkar_time_context.dart';

/// Fajr and Asr for one day, used to decide whether it is the morning or the
/// evening azkar period. Boundaries are product ordering, never a ruling.
class AzkarPrayerWindow {
  const AzkarPrayerWindow({required this.fajr, required this.asr});

  final DateTime fajr;
  final DateTime asr;

  bool get isConsistent => fajr.isBefore(asr);

  /// A window is only trusted near the day it was computed for: from six hours
  /// before its Fajr (the tail of the previous evening) up to 24 hours after.
  bool appliesTo(DateTime now) =>
      isConsistent &&
      !now.isBefore(fajr.subtract(const Duration(hours: 6))) &&
      now.isBefore(fajr.add(const Duration(hours: 24)));
}

/// Supplies today's prayer window, or null when prayer times are unavailable.
abstract interface class AzkarPrayerWindowSource {
  Future<AzkarPrayerWindow?> load(DateTime now);
}

/// The single rule that says whether it is morning or evening for azkar.
abstract class AzkarPeriodResolver {
  /// Morning is `[Fajr, Asr)` when a usable [window] exists, evening is the
  /// rest. Otherwise the fixed 04:00–15:30 rule applies.
  static AzkarPeriod resolve(DateTime now, {AzkarPrayerWindow? window}) {
    if (window != null && window.appliesTo(now)) {
      final inMorning = !now.isBefore(window.fajr) && now.isBefore(window.asr);
      return inMorning ? AzkarPeriod.morning : AzkarPeriod.evening;
    }
    return AzkarTimeContext.resolvePeriod(now);
  }

  /// Like [resolve], loading the window from [source]. Never throws: any
  /// failure falls back to the fixed rule.
  static Future<AzkarPeriod> resolveWith(
    DateTime now,
    AzkarPrayerWindowSource? source,
  ) async {
    AzkarPrayerWindow? window;
    if (source != null) {
      try {
        window = await source.load(now);
      } catch (_) {
        window = null;
      }
    }
    return resolve(now, window: window);
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/features/azkar/domain/services/azkar_period_resolver_test.dart`
Expected: PASS (10 tests).

- [ ] **Step 5: Checkpoint**

Run: `dart format lib/features/azkar/domain/services/azkar_period_resolver.dart test/features/azkar/domain/services/azkar_period_resolver_test.dart` then `flutter analyze lib/features/azkar/domain/services test/features/azkar/domain/services`
Expected: no issues.

---

### Task 2: Smart wird uses the resolver; remove the dead `timeHint` path

**Files:**
- Modify: `lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart` (replace whole file)
- Modify: `lib/features/azkar/domain/services/azkar_time_context.dart` (delete `periodOfDayPart`)
- Modify: `lib/features/azkar/presentation/pages/smart_wird_page.dart:126`
- Test: `test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`

**Interfaces:**
- Consumes: `AzkarPeriodResolver.resolve`, `AzkarPeriodResolver.resolveWith`, `AzkarPrayerWindowSource` (Task 1).
- Produces:
  - `SmartWird` gains `final AzkarPeriod period;` (required in the constructor; part of `props`).
  - `ComposeSmartWirdUsecase(AzkarRepository repository, {AzkarPrayerWindowSource? windowSource})`
  - `SmartWird composeFromCorpus(Map<AzkarCategory, List<Zikr>> corpus, AzkarDayPart dayPart, DateTime time, {AzkarPeriod? period})`

- [ ] **Step 1: Add the failing tests**

In `test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`, add the import
`import 'package:talia_quran/features/azkar/domain/services/azkar_period_resolver.dart';`
below the existing `azkar_time_context.dart` import, add these helpers above `void main()`:

```dart
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
```

and add these tests before the final `}` of `main()`:

```dart
  group('period selection', () {
    final corpus = {
      AzkarCategory.morning: [_periodZikr('m-1', AzkarCategory.morning)],
      AzkarCategory.evening: [_periodZikr('e-1', AzkarCategory.evening)],
      AzkarCategory.general: [_zikr('g-1')],
    };

    test('serves the evening set from 15:30 although the day part is afternoon',
        () async {
      final useCase = ComposeSmartWirdUsecase(_StubRepo(corpus));

      final result = await useCase(now: DateTime(2026, 9, 25, 16));
      final wird = result.fold((_) => null, (w) => w)!;

      expect(wird.dayPart, AzkarDayPart.afternoon);
      expect(wird.period, AzkarPeriod.evening);
      expect(wird.items.first.zikr.id, 'e-1');
    });

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
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`
Expected: FAIL to compile, `period` / `windowSource` undefined.

- [ ] **Step 3: Replace the use case**

Replace the whole content of `lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart` with:

```dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/app_failure.dart';
import '../entities/azkar_entities.dart';
import '../repositories/azkar_repository.dart';
import '../services/azkar_period_resolver.dart';
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
  }) => _compose(corpus, dayPart, period ?? AzkarPeriodResolver.resolve(time), time);

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
    final items = <SmartWirdItem>[];

    // 1. Time-window zikr for the current period, in dataset order.
    final periodCategory = period == AzkarPeriod.morning
        ? AzkarCategory.morning
        : AzkarCategory.evening;
    for (final z in corpus[periodCategory] ?? const <Zikr>[]) {
      items.add(SmartWirdItem(zikr: z, category: periodCategory));
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

    return SmartWird(
      items: items,
      dayPart: dayPart,
      period: period,
      composedAt: time,
    );
  }
}
```

- [ ] **Step 4: Remove `periodOfDayPart`**

In `lib/features/azkar/domain/services/azkar_time_context.dart`, delete this block (the doc comment and the method):

```dart
  /// Maps a stored [AzkarDayPart] back to its coarse period.
  static AzkarPeriod periodOfDayPart(AzkarDayPart part) => switch (part) {
        AzkarDayPart.afterFajr ||
        AzkarDayPart.morning ||
        AzkarDayPart.forenoon ||
        AzkarDayPart.afternoon => AzkarPeriod.morning,
        AzkarDayPart.evening || AzkarDayPart.night => AzkarPeriod.evening,
      };

```

Run: `grep -rn "periodOfDayPart" lib test`
Expected: no matches.

- [ ] **Step 5: Keep the page re-composition on the same period**

In `lib/features/azkar/presentation/pages/smart_wird_page.dart`, replace

```dart
    return _compose.composeFromCorpus(_corpus!, wird.dayPart, wird.composedAt);
```

with

```dart
    return _compose.composeFromCorpus(
      _corpus!,
      wird.dayPart,
      wird.composedAt,
      period: wird.period,
    );
```

- [ ] **Step 6: Run the tests**

Run: `flutter test test/features/azkar/domain test/features/azkar/presentation/smart_wird_page_test.dart`
Expected: PASS, including the three new tests and the four existing compose tests.

- [ ] **Step 7: Checkpoint**

Run: `dart format lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart lib/features/azkar/domain/services/azkar_time_context.dart lib/features/azkar/presentation/pages/smart_wird_page.dart test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Task 3: Prayer window source, hub cubit, DI

**Files:**
- Create: `lib/features/azkar/data/datasources/prayer_times_window_source.dart`
- Modify: `lib/features/azkar/presentation/cubits/azkar_hub_cubit.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_page.dart:27-40`
- Modify: `lib/core/di/injection.dart` (lines 340–342 and 805–812)
- Test: `test/features/azkar/data/prayer_times_window_source_test.dart`, `test/features/azkar/presentation/azkar_hub_cubit_test.dart`

**Interfaces:**
- Consumes: `AzkarPrayerWindowSource`, `AzkarPrayerWindow`, `AzkarPeriodResolver.resolveWith` (Task 1); `PrayerTimesService.current({required bool isArabic})` returning `PrayerTimesSnapshot?` with nullable `fajr`/`asr`; `ComposeSmartWirdUsecase(repo, windowSource:)` (Task 2).
- Produces:
  - `class PrayerTimesWindowSource implements AzkarPrayerWindowSource { PrayerTimesWindowSource(PrayerTimesService service); }`
  - `AzkarHubCubit(repo, completionStore, prefsStore, {DateTime Function()? now, SmartWirdProgressStore? smartWirdStore, AzkarPrayerWindowSource? windowSource})`

- [ ] **Step 1: Write the failing source test**

Create `test/features/azkar/data/prayer_times_window_source_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/services/prayer_times_service.dart';
import 'package:talia_quran/features/azkar/data/datasources/prayer_times_window_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns null when prayer times are disabled', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final source = PrayerTimesWindowSource(PrayerTimesService(prefs));

    expect(await source.load(DateTime(2026, 9, 29, 10)), isNull);
  });

  test('returns Fajr before Asr for a configured city', () async {
    SharedPreferences.setMockInitialValues({
      PrayerTimesService.enabledKey: true,
      PrayerTimesService.cityIdKey: 'makkah',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = PrayerTimesService(
      prefs,
      now: () => DateTime.utc(2026, 9, 29, 7),
    );
    final source = PrayerTimesWindowSource(service);

    final window = await source.load(DateTime.utc(2026, 9, 29, 7));

    expect(window, isNotNull);
    expect(window!.isConsistent, isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/data/prayer_times_window_source_test.dart`
Expected: FAIL to compile, `prayer_times_window_source.dart` not found.

- [ ] **Step 3: Write the source**

Create `lib/features/azkar/data/datasources/prayer_times_window_source.dart`:

```dart
import '../../../../core/services/prayer_times_service.dart';
import '../../domain/services/azkar_period_resolver.dart';

/// Reads today's Fajr and Asr from the offline prayer-times service. Returns
/// null when prayer times are off, no city is chosen, or the lookup fails, so
/// callers fall back to the fixed period rule.
class PrayerTimesWindowSource implements AzkarPrayerWindowSource {
  PrayerTimesWindowSource(this._service);

  final PrayerTimesService _service;

  @override
  Future<AzkarPrayerWindow?> load(DateTime now) async {
    try {
      final snapshot = await _service.current(isArabic: true);
      final fajr = snapshot?.fajr;
      final asr = snapshot?.asr;
      if (fajr == null || asr == null) return null;
      return AzkarPrayerWindow(fajr: fajr, asr: asr);
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/data/prayer_times_window_source_test.dart`
Expected: PASS (2 tests). If the second test fails because the bundled city list is unavailable in the test bundle, the service falls back to its built-in Makkah city, so a failure means a real regression: read the error before changing the test.

- [ ] **Step 5: Write the failing hub cubit test**

Create `test/features/azkar/presentation/azkar_hub_cubit_test.dart`:

```dart
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
```

- [ ] **Step 6: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/azkar_hub_cubit_test.dart`
Expected: FAIL to compile, `windowSource` is not a named parameter.

- [ ] **Step 7: Wire the hub cubit**

In `lib/features/azkar/presentation/cubits/azkar_hub_cubit.dart`:

Add the import next to the other domain service import:

```dart
import '../../domain/services/azkar_period_resolver.dart';
```

Change the constructor and fields:

```dart
  AzkarHubCubit(
    this._repository,
    this._completionStore,
    this._prefsStore, {
    DateTime Function()? now,
    SmartWirdProgressStore? smartWirdStore,
    AzkarPrayerWindowSource? windowSource,
  })  : _now = now ?? DateTime.now,
        _smartWirdStore = smartWirdStore,
        _windowSource = windowSource,
        super(const AzkarHubState(status: AzkarHubStatus.loading));

  final AzkarRepository _repository;
  final AzkarCompletionStore _completionStore;
  final AzkarPreferencesStore _prefsStore;
  final SmartWirdProgressStore? _smartWirdStore;
  final AzkarPrayerWindowSource? _windowSource;
  final DateTime Function() _now;
```

In `load`, right after the `if (failed) { ... return; }` block, add:

```dart
    final period = await AzkarPeriodResolver.resolveWith(now, _windowSource);
    if (isClosed) return;
```

and replace `period: AzkarTimeContext.resolvePeriod(now),` with `period: period,`. Keep the `azkar_time_context.dart` import (the file still uses `AzkarPeriod`).

- [ ] **Step 8: Wire DI and the hub page**

In `lib/core/di/injection.dart`, add these imports beside the other azkar imports (place them in alphabetical order with their neighbors):

```dart
import '../../features/azkar/data/datasources/prayer_times_window_source.dart';
import '../../features/azkar/domain/services/azkar_period_resolver.dart';
```

Replace lines 340–342:

```dart
  getIt.registerLazySingleton<ComposeSmartWirdUsecase>(
    () => ComposeSmartWirdUsecase(getIt<AzkarRepository>()),
  );
```

with

```dart
  getIt.registerLazySingleton<AzkarPrayerWindowSource>(
    () => PrayerTimesWindowSource(getIt<PrayerTimesService>()),
  );
  getIt.registerLazySingleton<ComposeSmartWirdUsecase>(
    () => ComposeSmartWirdUsecase(
      getIt<AzkarRepository>(),
      windowSource: getIt<AzkarPrayerWindowSource>(),
    ),
  );
```

In the `registerFactory<AzkarHubCubit>` block (around line 805) add `windowSource: getIt<AzkarPrayerWindowSource>(),` after `smartWirdStore: getIt<SmartWirdProgressStore>(),`.

In `lib/features/azkar/presentation/pages/azkar_page.dart`, add the import
`import '../../domain/services/azkar_period_resolver.dart';` and change the cubit creation to:

```dart
      create: (_) => AzkarHubCubit(
        getIt<AzkarRepository>(),
        getIt<AzkarCompletionStore>(),
        getIt<AzkarPreferencesStore>(),
        smartWirdStore: getIt<SmartWirdProgressStore>(),
        windowSource: getIt.isRegistered<AzkarPrayerWindowSource>()
            ? getIt<AzkarPrayerWindowSource>()
            : null,
      )..load(currentTime),
```

- [ ] **Step 9: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS.

- [ ] **Step 10: Checkpoint**

Run: `dart format lib/features/azkar/data/datasources/prayer_times_window_source.dart lib/features/azkar/presentation/cubits/azkar_hub_cubit.dart lib/features/azkar/presentation/pages/azkar_page.dart test/features/azkar/data/prayer_times_window_source_test.dart test/features/azkar/presentation/azkar_hub_cubit_test.dart` (do **not** format `injection.dart`; it has the owner's hunks)
then `flutter analyze lib/features/azkar lib/core/di test/features/azkar`
Expected: no issues.

---

### Task 4: Smart-wird resume compares the period

**Files:**
- Modify: `lib/features/azkar/data/datasources/smart_wird_progress_store.dart` (`SmartWirdSession`)
- Modify: `lib/features/azkar/presentation/pages/smart_wird_page.dart` (`_load`, `_persistProgress`)
- Test: `test/features/azkar/data/smart_wird_progress_store_test.dart`, `test/features/azkar/presentation/smart_wird_page_test.dart`

**Interfaces:**
- Consumes: `SmartWird.period` (Task 2).
- Produces: `SmartWirdSession({required AzkarDayPart dayPart, required Map<String,int> counts, required DateTime updatedAt, AzkarPeriod? period})`; `toJson` writes `period`, `fromJson` reads it and tolerates absence or bad values.

- [ ] **Step 1: Write the failing store test**

Append inside `main()` of `test/features/azkar/data/smart_wird_progress_store_test.dart` (add the imports `package:talia_quran/features/azkar/domain/services/azkar_time_context.dart` if not already present):

```dart
  group('SmartWirdSession period', () {
    test('round-trips the period', () {
      final session = SmartWirdSession(
        dayPart: AzkarDayPart.afterFajr,
        period: AzkarPeriod.morning,
        counts: const {'m-1': 1},
        updatedAt: DateTime(2026, 9, 25, 9),
      );

      final restored = SmartWirdSession.fromJson(session.toJson());

      expect(restored.period, AzkarPeriod.morning);
    });

    test('a legacy session without a period loads with a null period', () {
      final restored = SmartWirdSession.fromJson({
        'dayPart': 'afterFajr',
        'counts': {'m-1': 1},
        'updatedAt': DateTime(2026, 9, 25, 9).millisecondsSinceEpoch,
      });

      expect(restored.period, isNull);
      expect(restored.dayPart, AzkarDayPart.afterFajr);
    });

    test('an unknown period name loads as null instead of throwing', () {
      final restored = SmartWirdSession.fromJson({
        'dayPart': 'morning',
        'period': 'midday',
        'counts': const <String, dynamic>{},
        'updatedAt': 0,
      });

      expect(restored.period, isNull);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/data/smart_wird_progress_store_test.dart`
Expected: FAIL to compile, `period` is not a named parameter of `SmartWirdSession`.

- [ ] **Step 3: Extend `SmartWirdSession`**

In `smart_wird_progress_store.dart` replace the `SmartWirdSession` class with:

```dart
class SmartWirdSession {
  const SmartWirdSession({
    required this.dayPart,
    required this.counts,
    required this.updatedAt,
    this.period,
  });

  final AzkarDayPart dayPart;

  /// Morning or evening. Null for sessions saved before this field existed;
  /// those resume by [dayPart] only.
  final AzkarPeriod? period;

  /// Persisted counts keyed by zikr id (only entries > 0 are stored).
  final Map<String, int> counts;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'dayPart': dayPart.name,
        'period': period?.name,
        'counts': counts,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  static SmartWirdSession fromJson(Map<String, dynamic> json) {
    final rawCounts = (json['counts'] as Map<String, dynamic>? ?? const {});
    return SmartWirdSession(
      dayPart: AzkarTimeContext.dayPartFromName(
        json['dayPart'] as String? ?? '',
      ),
      period: AzkarPeriod.values
          .where((value) => value.name == json['period'])
          .firstOrNull,
      counts: {
        for (final entry in rawCounts.entries)
          if (entry.value is int && (entry.value as int) > 0)
            entry.key: entry.value as int,
      },
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] as int? ?? 0,
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/data/smart_wird_progress_store_test.dart`
Expected: PASS.

- [ ] **Step 5: Write the failing page test**

Append inside `main()` of `test/features/azkar/presentation/smart_wird_page_test.dart`:

```dart
  testWidgets(
    'resume survives crossing a day-part boundary inside the same period',
    (tester) async {
      // Saved at 09:00 (afterFajr). The page reopens at 10:30 (morning day
      // part) but it is still the morning period, so progress must restore.
      final store = SmartWirdProgressStore(prefs);
      await store.saveActiveSession(
        SmartWirdSession(
          dayPart: AzkarDayPart.afterFajr,
          period: AzkarPeriod.morning,
          counts: {'m-1': 2, 'g-1': 1},
          updatedAt: DateTime(2026, 9, 25, 9),
        ),
        DateTime(2026, 9, 25, 10, 30),
      );

      await tester.pumpWidget(
        buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 10, 30))),
      );
      await tester.pumpAndSettle();

      // Restored on card 2 with count 1: one tap completes the wird.
      await tester.tap(find.text('1').first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('اكتمل الورد الذكي'), findsOneWidget);
    },
  );
```

Add the import `package:talia_quran/features/azkar/domain/services/azkar_time_context.dart` — it is already imported in that file. `AzkarPeriod` lives in the same file, so no new import is needed.

- [ ] **Step 6: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/smart_wird_page_test.dart --plain-name "resume survives crossing"`
Expected: FAIL: the wird shows card 1 with count 0 because `saved.dayPart != wird.dayPart`.

- [ ] **Step 7: Compare periods in the page**

In `smart_wird_page.dart`, replace

```dart
    final saved = _progressStore.activeSession(time);
    if (saved != null && saved.dayPart == wird!.dayPart) {
```

with

```dart
    final saved = _progressStore.activeSession(time);
    if (saved != null && _isSameSitting(saved, wird!)) {
```

Add this method to `_SmartWirdPageState` (next to `_persistProgress`):

```dart
  /// A saved session belongs to the same sitting when it is the same period
  /// (morning or evening). Sessions saved before periods were recorded fall
  /// back to comparing the finer day part.
  bool _isSameSitting(SmartWirdSession saved, SmartWird wird) {
    final savedPeriod = saved.period;
    return savedPeriod != null
        ? savedPeriod == wird.period
        : saved.dayPart == wird.dayPart;
  }
```

and in `_persistProgress` add `period: wird.period,` to the `SmartWirdSession(...)` call (after `dayPart: wird.dayPart,`).

- [ ] **Step 8: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS, including the three existing resume tests.

- [ ] **Step 9: Checkpoint**

Run: `dart format lib/features/azkar/data/datasources/smart_wird_progress_store.dart lib/features/azkar/presentation/pages/smart_wird_page.dart test/features/azkar/data/smart_wird_progress_store_test.dart test/features/azkar/presentation/smart_wird_page_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Task 5: Hide duplicate duas; keep favorites working

**Files:**
- Create: `lib/features/azkar/domain/services/azkar_dedupe.dart`
- Create: `lib/features/azkar/data/datasources/azkar_alias_registry.dart`
- Modify: `lib/features/azkar/data/repositories/azkar_repository_impl.dart` (replace whole file)
- Modify: `lib/features/azkar/data/datasources/azkar_preferences_store.dart` (constructor, `isFavorite`, `toggleFavorite`)
- Modify: `lib/features/azkar/presentation/pages/general_azkar_page.dart` (`_ZikrCard` favorite state)
- Modify: `lib/core/di/injection.dart` (lines 337–339 and 529)
- Test: `test/features/azkar/domain/services/azkar_dedupe_test.dart`, `test/features/azkar/data/azkar_favorites_alias_test.dart`, `test/features/azkar/data/azkar_repository_dedupe_test.dart`, `test/assets/azkar_dedupe_contract_test.dart`

**Interfaces:**
- Consumes: `ArabicNormalizer.normalize(String)` from `lib/core/utils/arabic_normalizer.dart`; `Zikr`, `ZikrModel`.
- Produces:
  - `class DedupedAzkar { final List<Zikr> items; final Map<String, Set<String>> aliases; }`
  - `AzkarDedupe.apply(List<Zikr> records) -> DedupedAzkar` (first record wins; same normalized text and same `totalCount` are duplicates)
  - `class AzkarAliasRegistry { void record(Map<String, Set<String>> aliases); Set<String> aliasesOf(String canonicalId); }`
  - `AzkarRepositoryImpl(AzkarLocalDatasource, {AzkarAliasRegistry? aliasRegistry})`
  - `AzkarPreferencesStore([SharedPreferences? prefs, AzkarAliasRegistry? aliases])`; `isFavorite(id)` is true for the canonical id or any alias; `toggleFavorite(id)` writes the canonical id and removes aliases.

- [ ] **Step 1: Write the failing dedupe test**

Create `test/features/azkar/domain/services/azkar_dedupe_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_dedupe.dart';

Zikr _zikr(String id, String text, {int count = 1}) => Zikr(
  id: id,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: count,
  category: AzkarCategory.duas,
);

void main() {
  test('keeps the first record and lists later copies as aliases', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'),
      _zikr('b', 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى'),
      _zikr('c', 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً'),
    ]);

    expect(result.items.map((z) => z.id), ['a', 'b']);
    expect(result.aliases, {
      'a': {'c'},
    });
  });

  test('matches across diacritics and alef variants', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'رَبَّنَا آتِنَا'),
      _zikr('b', 'ربنا اتنا'),
    ]);

    expect(result.items.map((z) => z.id), ['a']);
    expect(result.aliases['a'], {'b'});
  });

  test('same text with a different count is not a duplicate', () {
    final result = AzkarDedupe.apply([
      _zikr('a', 'سُبْحَانَ اللَّهِ', count: 3),
      _zikr('b', 'سُبْحَانَ اللَّهِ', count: 33),
    ]);

    expect(result.items.map((z) => z.id), ['a', 'b']);
    expect(result.aliases, isEmpty);
  });

  test('a list without duplicates comes back unchanged', () {
    final input = [_zikr('a', 'نص أول'), _zikr('b', 'نص ثان')];

    final result = AzkarDedupe.apply(input);

    expect(result.items, input);
    expect(result.aliases, isEmpty);
  });

  test('an empty list yields an empty result', () {
    final result = AzkarDedupe.apply(const []);

    expect(result.items, isEmpty);
    expect(result.aliases, isEmpty);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/domain/services/azkar_dedupe_test.dart`
Expected: FAIL to compile, `azkar_dedupe.dart` not found.

- [ ] **Step 3: Write `AzkarDedupe`**

Create `lib/features/azkar/domain/services/azkar_dedupe.dart`:

```dart
import '../../../../core/utils/arabic_normalizer.dart';
import '../entities/azkar_entities.dart';

/// A record list with repeated records removed, plus which ids were hidden.
class DedupedAzkar {
  const DedupedAzkar({required this.items, required this.aliases});

  /// Records to display, in dataset order.
  final List<Zikr> items;

  /// Canonical record id -> ids of later records with the same text and count.
  final Map<String, Set<String>> aliases;
}

/// Hides repeated records in the presentation layer. The release file is not
/// edited: two records are the same when their normalized text and required
/// count match, and the first one in dataset order is kept.
abstract class AzkarDedupe {
  static DedupedAzkar apply(List<Zikr> records) {
    final canonicalByKey = <String, Zikr>{};
    final items = <Zikr>[];
    final aliases = <String, Set<String>>{};

    for (final zikr in records) {
      final key = '${zikr.totalCount}|${ArabicNormalizer.normalize(zikr.text)}';
      final canonical = canonicalByKey[key];
      if (canonical == null) {
        canonicalByKey[key] = zikr;
        items.add(zikr);
      } else {
        aliases.putIfAbsent(canonical.id, () => <String>{}).add(zikr.id);
      }
    }

    return DedupedAzkar(
      items: List.unmodifiable(items),
      aliases: {
        for (final entry in aliases.entries)
          entry.key: Set.unmodifiable(entry.value),
      },
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/domain/services/azkar_dedupe_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Write the failing favorites test**

Create `test/features/azkar/data/azkar_favorites_alias_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_alias_registry.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_preferences_store.dart';

void main() {
  late AzkarAliasRegistry registry;

  setUp(() {
    registry = AzkarAliasRegistry()
      ..record({
        'dq1': {'dua_quran_1'},
      });
  });

  Future<AzkarPreferencesStore> storeWith(List<String> saved) async {
    SharedPreferences.setMockInitialValues({
      'azkar_favorite_duas': saved,
    });
    final prefs = await SharedPreferences.getInstance();
    return AzkarPreferencesStore(prefs, registry);
  }

  test('a favorite saved on the hidden copy shows on the visible copy', () async {
    final store = await storeWith(['dua_quran_1']);

    expect(store.isFavorite('dq1'), isTrue);
  });

  test('toggling the visible copy clears every copy', () async {
    final store = await storeWith(['dua_quran_1', 'dq1']);

    final nowFavorite = await store.toggleFavorite('dq1');

    expect(nowFavorite, isFalse);
    expect(store.getFavoriteDuaIds(), isEmpty);
  });

  test('adding a favorite stores only the visible id', () async {
    final store = await storeWith([]);

    final nowFavorite = await store.toggleFavorite('dq1');

    expect(nowFavorite, isTrue);
    expect(store.getFavoriteDuaIds(), {'dq1'});
  });

  test('a record without aliases behaves as before', () async {
    final store = await storeWith(['dp3']);

    expect(store.isFavorite('dp3'), isTrue);
    expect(await store.toggleFavorite('dp3'), isFalse);
    expect(store.isFavorite('dp3'), isFalse);
  });

  test('works without a registry', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = AzkarPreferencesStore(prefs);

    expect(await store.toggleFavorite('x'), isTrue);
    expect(store.isFavorite('x'), isTrue);
  });
}
```

- [ ] **Step 6: Run to verify failure**

Run: `flutter test test/features/azkar/data/azkar_favorites_alias_test.dart`
Expected: FAIL to compile, `azkar_alias_registry.dart` not found.

- [ ] **Step 7: Write the registry and update the store**

Create `lib/features/azkar/data/datasources/azkar_alias_registry.dart`:

```dart
/// Remembers which record ids were hidden as duplicates of another record, so
/// favorites saved on a hidden copy still count for the visible one.
class AzkarAliasRegistry {
  final Map<String, Set<String>> _aliasesByCanonical = {};

  void record(Map<String, Set<String>> aliases) {
    for (final entry in aliases.entries) {
      _aliasesByCanonical[entry.key] = Set.unmodifiable(entry.value);
    }
  }

  Set<String> aliasesOf(String canonicalId) =>
      _aliasesByCanonical[canonicalId] ?? const <String>{};
}
```

In `lib/features/azkar/data/datasources/azkar_preferences_store.dart`:

Add the import `import 'azkar_alias_registry.dart';` under the existing imports.

Change the constructor head to accept the registry and store it:

```dart
class AzkarPreferencesStore {
  AzkarPreferencesStore([this._prefs, this._aliases]) {
```

Add the field next to `_prefs`:

```dart
  final AzkarAliasRegistry? _aliases;
```

Replace `isFavorite` and `toggleFavorite` with:

```dart
  bool isFavorite(String id) {
    final favorites = _favoritesNotifier.value;
    if (favorites.contains(id)) return true;
    final aliases = _aliases?.aliasesOf(id) ?? const <String>{};
    return aliases.any(favorites.contains);
  }

  /// Toggles [id]. A record with hidden duplicate copies is one favorite: the
  /// visible id is written and every copy id is cleared on removal.
  Future<bool> toggleFavorite(String id) async {
    final aliases = _aliases?.aliasesOf(id) ?? const <String>{};
    final updated = Set<String>.from(_favoritesNotifier.value);
    final wasFavorite = updated.contains(id) || aliases.any(updated.contains);
    updated
      ..remove(id)
      ..removeAll(aliases);
    if (!wasFavorite) updated.add(id);
    _favoritesNotifier.value = updated;

    await _prefs?.setStringList(_keyFavoriteDuas, updated.toList());
    return !wasFavorite;
  }
```

- [ ] **Step 8: Run to verify it passes**

Run: `flutter test test/features/azkar/data/azkar_favorites_alias_test.dart test/features/azkar/data/azkar_preferences_store_test.dart`
Expected: PASS, including the existing preferences-store tests.

- [ ] **Step 9: Write the failing repository test**

Create `test/features/azkar/data/azkar_repository_dedupe_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_alias_registry.dart';
import 'package:talia_quran/features/azkar/data/datasources/azkar_local_datasource.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';

ZikrModel _model(String id, String text) => ZikrModel(
  id: id,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.duas,
);

class _Datasource implements AzkarLocalDatasource {
  const _Datasource(this.models);
  final List<ZikrModel> models;

  @override
  Future<List<ZikrModel>> getAzkar(AzkarCategory category) async => models;
}

void main() {
  test('hides duplicates, records aliases and keeps dataset order', () async {
    final registry = AzkarAliasRegistry();
    final repository = AzkarRepositoryImpl(
      _Datasource([
        _model('a', 'دعاء أول'),
        _model('b', 'دعاء ثان'),
        _model('c', 'دعاء أول'),
      ]),
      aliasRegistry: registry,
    );

    final result = await repository.getAzkar(AzkarCategory.duas);

    final items = result.fold((_) => <Zikr>[], (list) => list);
    expect(items.map((z) => z.id), ['a', 'b']);
    expect(registry.aliasesOf('a'), {'c'});
  });

  test('works without a registry', () async {
    final repository = AzkarRepositoryImpl(
      _Datasource([_model('a', 'x'), _model('b', 'x')]),
    );

    final result = await repository.getAzkar(AzkarCategory.duas);

    expect(result.fold((_) => 0, (list) => list.length), 1);
  });

  test('getAllAzkar returns deduplicated categories', () async {
    final repository = AzkarRepositoryImpl(
      _Datasource([_model('a', 'x'), _model('b', 'x')]),
    );

    final result = await repository.getAllAzkar();

    final corpus = result.getOrElse(() => {});
    expect(corpus[AzkarCategory.duas]!.length, 1);
    expect(corpus[AzkarCategory.morning]!.length, 1);
  });
}
```

Add `import 'package:dartz/dartz.dart';` at the top (for `getOrElse`).

- [ ] **Step 10: Run to verify failure**

Run: `flutter test test/features/azkar/data/azkar_repository_dedupe_test.dart`
Expected: FAIL: `aliasRegistry` is not a named parameter.

- [ ] **Step 11: Update the repository**

Replace the whole content of `lib/features/azkar/data/repositories/azkar_repository_impl.dart` with:

```dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/app_failure.dart';
import '../../domain/entities/azkar_entities.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/services/azkar_dedupe.dart';
import '../datasources/azkar_alias_registry.dart';
import '../datasources/azkar_local_datasource.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl(this._datasource, {AzkarAliasRegistry? aliasRegistry})
    : _aliasRegistry = aliasRegistry;
  final AzkarLocalDatasource _datasource;
  final AzkarAliasRegistry? _aliasRegistry;

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async {
    try {
      final models = await _datasource.getAzkar(category);
      final deduped = AzkarDedupe.apply(models);
      _aliasRegistry?.record(deduped.aliases);
      return Right(deduped.items);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(CacheFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async {
    final results = <AzkarCategory, List<Zikr>>{};
    for (final category in AzkarCategory.values) {
      final result = await getAzkar(category);
      var list = const <Zikr>[];
      var failed = false;
      result.fold(
        (_) => failed = true,
        (items) => list = items,
      );
      if (failed) return const Left(CacheFailure('Failed to load azkar corpus'));
      results[category] = list;
    }
    return Right(results);
  }
}
```

- [ ] **Step 12: Wire DI**

In `lib/core/di/injection.dart` add the import
`import '../../features/azkar/data/datasources/azkar_alias_registry.dart';` next to the other azkar data imports.

Replace lines 337–339:

```dart
  getIt.registerLazySingleton<AzkarPreferencesStore>(
    () => AzkarPreferencesStore(getIt<SharedPreferences>()),
  );
```

with

```dart
  getIt.registerLazySingleton<AzkarAliasRegistry>(() => AzkarAliasRegistry());
  getIt.registerLazySingleton<AzkarPreferencesStore>(
    () => AzkarPreferencesStore(
      getIt<SharedPreferences>(),
      getIt<AzkarAliasRegistry>(),
    ),
  );
```

Replace line 529 `() => AzkarRepositoryImpl(getIt<AzkarLocalDatasource>()),` with:

```dart
    () => AzkarRepositoryImpl(
      getIt<AzkarLocalDatasource>(),
      aliasRegistry: getIt<AzkarAliasRegistry>(),
    ),
```

- [ ] **Step 13: Make the library card read favorite state through the store**

In `lib/features/azkar/presentation/pages/general_azkar_page.dart`, inside `_ZikrCard.build`, replace

```dart
                      builder: (context, favorites, _) {
                        final isFav = favorites.contains(zikr.id);
```

with

```dart
                      builder: (context, _, _) {
                        final isFav = prefsStore.isFavorite(zikr.id);
```

- [ ] **Step 14: Write the contract test on the real release data**

Create `test/assets/azkar_dedupe_contract_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/data/models/zikr_model.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_dedupe.dart';

void main() {
  const categories = {
    'morning': AzkarCategory.morning,
    'evening': AzkarCategory.evening,
    'general': AzkarCategory.general,
    'duas': AzkarCategory.duas,
  };

  final release =
      jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
          as Map<String, dynamic>;

  DedupedAzkar dedupe(String key) {
    final records = (release[key] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((json) => ZikrModel.fromJson(json, categories[key]!))
        .toList();
    return AzkarDedupe.apply(records);
  }

  test('the duas library hides exactly the five verified repeats', () {
    final result = dedupe('duas');

    // If this fails, read both texts before changing the expected set: a
    // repeat that appears or disappears means the release data changed.
    expect(result.aliases, {
      'dq1': {'dua_quran_1'},
      'dq2': {'dua_quran_2'},
      'dp1': {'dua_prophet_1'},
      'dp2': {'dua_prophet_2'},
      'dp6': {'dua_prophet_3'},
    });
    expect(result.items, hasLength(34 - 5));
  });

  test('no other category loses a record to deduplication', () {
    for (final key in const ['morning', 'evening', 'general']) {
      expect(dedupe(key).aliases, isEmpty, reason: key);
    }
  });

  test('Ta-Ha 25:28 and Ta-Ha 25-26 are distinct records and both stay', () {
    final ids = dedupe('duas').items.map((z) => z.id).toSet();

    expect(ids, containsAll(['dq4', 'dua_quran_3']));
  });
}
```

- [ ] **Step 15: Run the contract test**

Run: `flutter test test/assets/azkar_dedupe_contract_test.dart`
Expected: PASS. If the alias set differs, stop and compare the two records' text with `assets/data/azkar_release.json` before deciding whether the normalizer or the data is at fault; do not edit the release file.

- [ ] **Step 16: Run all azkar tests and fix count assertions**

Run: `flutter test test/features/azkar test/core/content test/assets`
Expected: PASS. If an existing test asserts `34` duas through the repository, update that number to `29` and add a one-line comment naming the five hidden repeats. Tests that read the datasource directly keep 34.

- [ ] **Step 17: Checkpoint**

Run: `dart format lib/features/azkar/domain/services/azkar_dedupe.dart lib/features/azkar/data/datasources/azkar_alias_registry.dart lib/features/azkar/data/repositories/azkar_repository_impl.dart lib/features/azkar/data/datasources/azkar_preferences_store.dart lib/features/azkar/presentation/pages/general_azkar_page.dart test/features/azkar/domain/services/azkar_dedupe_test.dart test/features/azkar/data/azkar_favorites_alias_test.dart test/features/azkar/data/azkar_repository_dedupe_test.dart test/assets/azkar_dedupe_contract_test.dart`
then `flutter analyze lib/features/azkar lib/core/di test/features/azkar test/assets`
Expected: no issues.

---

### Task 6: Quran-text contract test

**Files:**
- Test: `test/assets/azkar_quran_text_contract_test.dart` (no library code changes)

**Interfaces:**
- Consumes: `assets/data/azkar_release.json`, `assets/data/quran.json` (top-level map of surah number to a list of `{chapter, verse, text}`).
- Produces: a test that fails, naming the record id, when a `sourceType: quran` record is not found in the Quran corpus.

- [ ] **Step 1: Write the test**

Create `test/assets/azkar_quran_text_contract_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Reduces Arabic text to its consonant skeleton so records written in plain
/// spelling still compare equal to the Uthmani corpus. It drops diacritics,
/// tatweel (U+0640), and the alef, waw, yaa, hamza, ta marbuta and ha families.
String _skeleton(String text) {
  final letters = text.replaceAll(RegExp(r'[^\u0621-\u063A\u0641-\u064A]'), '');
  return letters.replaceAll(RegExp('[ءاأإآٱوؤيئىةه]'), '');
}

void main() {
  test('every Quran-type azkar record exists in quran.json', () {
    final release =
        jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
            as Map<String, dynamic>;
    final quran =
        jsonDecode(File('assets/data/quran.json').readAsStringSync())
            as Map<String, dynamic>;

    final corpus = StringBuffer();
    for (final surah in quran.values) {
      for (final ayah in (surah as List<dynamic>).cast<Map<String, dynamic>>()) {
        corpus.write(_skeleton(ayah['text'] as String));
      }
    }
    final corpusText = corpus.toString();

    // Recitation openers that are not part of the quoted ayah.
    final openers = [
      _skeleton('أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ'),
      _skeleton('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
    ];

    var checked = 0;
    final missing = <String>[];
    for (final records in release.values) {
      for (final record in (records as List<dynamic>).cast<Map<String, dynamic>>()) {
        if (record['sourceType'] != 'quran') continue;
        checked++;
        var skeleton = _skeleton(record['text'] as String);
        for (final opener in openers) {
          skeleton = skeleton.replaceAll(opener, '');
        }
        if (!corpusText.contains(skeleton)) {
          missing.add('${record['id']} (${record['reference']})');
        }
      }
    }

    expect(checked, greaterThan(20), reason: 'the check must not pass vacuously');
    expect(
      missing,
      isEmpty,
      reason: 'Quran text not found in quran.json. Report these to the owner; '
          'never correct religious text from memory.',
    );
  });
}
```

- [ ] **Step 2: Run the test**

Run: `flutter test test/assets/azkar_quran_text_contract_test.dart`
Expected: PASS. If it fails for a record, re-run the diagnosis before concluding anything: compare that record's skeleton with the ayah's skeleton and find the first differing letter. A tatweel or similar script variant is a test problem; a different word is a P0 finding to report to the owner unchanged.

- [ ] **Step 3: Prove the test can fail**

Temporarily change one word inside a *copy* of the release JSON, not the real file:

Run: `flutter test test/assets/azkar_quran_text_contract_test.dart` is unchanged. To prove sensitivity, add this extra test at the end of `main()` and run it:

```dart
  test('the skeleton comparison detects a changed word', () {
    final original = _skeleton('رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً');
    final altered = _skeleton('رَبَّنَا آتِنَا فِي الدُّنْيَا سَيِّئَةً');

    expect(altered, isNot(original));
  });
```

Expected: PASS (keeps a permanent guard that the skeleton is not too lossy to tell two different words apart).

- [ ] **Step 4: Checkpoint**

Run: `dart format test/assets/azkar_quran_text_contract_test.dart` then `flutter analyze test/assets`
Expected: no issues.

---

### Task 7: Audio button follows audio state

**Files:**
- Create: `lib/features/azkar/presentation/widgets/zikr_audio_state_builder.dart`
- Modify: `lib/features/azkar/presentation/services/zikr_audio_service.dart` (declare the interface it already satisfies)
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart:577-592`
- Modify: `lib/features/azkar/presentation/pages/smart_wird_page.dart:464-475`
- Test: `test/features/azkar/presentation/zikr_audio_state_builder_test.dart`

**Interfaces:**
- Consumes: `ZikrAudioState` (`status`, `zikrId`, `isPlaying`) from `zikr_audio_service.dart`.
- Produces:
  - `abstract interface class ZikrAudioStateSource { ZikrAudioState get state; void addListener(void Function(ZikrAudioState) listener); void removeListener(void Function(ZikrAudioState) listener); }` (declared in `zikr_audio_service.dart`; `ZikrAudioService implements` it)
  - `ZikrAudioStateBuilder({required ZikrAudioStateSource source, required Widget Function(BuildContext, ZikrAudioState) builder})`

- [ ] **Step 1: Write the failing test**

Create `test/features/azkar/presentation/zikr_audio_state_builder_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_audio_service.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/zikr_audio_state_builder.dart';

class _FakeSource implements ZikrAudioStateSource {
  ZikrAudioState _state = const ZikrAudioState();
  final List<void Function(ZikrAudioState)> listeners = [];

  @override
  ZikrAudioState get state => _state;

  @override
  void addListener(void Function(ZikrAudioState) listener) =>
      listeners.add(listener);

  @override
  void removeListener(void Function(ZikrAudioState) listener) =>
      listeners.remove(listener);

  void emit(ZikrAudioState next) {
    _state = next;
    for (final listener in List.of(listeners)) {
      listener(next);
    }
  }
}

void main() {
  testWidgets('rebuilds when the audio state changes', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ZikrAudioStateBuilder(
          source: source,
          builder: (context, state) => Text(state.status.name),
        ),
      ),
    );
    expect(find.text('idle'), findsOneWidget);

    source.emit(
      const ZikrAudioState(status: ZikrAudioStatus.playing, zikrId: 'z1'),
    );
    await tester.pump();

    expect(find.text('playing'), findsOneWidget);
  });

  testWidgets('stops listening when removed', (tester) async {
    final source = _FakeSource();
    await tester.pumpWidget(
      MaterialApp(
        home: ZikrAudioStateBuilder(
          source: source,
          builder: (context, state) => const SizedBox(),
        ),
      ),
    );
    expect(source.listeners, hasLength(1));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(source.listeners, isEmpty);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/zikr_audio_state_builder_test.dart`
Expected: FAIL to compile, `ZikrAudioStateSource` and the builder do not exist.

- [ ] **Step 3: Declare the interface on the service**

In `lib/features/azkar/presentation/services/zikr_audio_service.dart`, add above `class ZikrAudioService`:

```dart
/// The read side of the audio service, so widgets can follow playback state
/// without depending on the platform player.
abstract interface class ZikrAudioStateSource {
  ZikrAudioState get state;
  void addListener(void Function(ZikrAudioState) listener);
  void removeListener(void Function(ZikrAudioState) listener);
}
```

and change `class ZikrAudioService {` to `class ZikrAudioService implements ZikrAudioStateSource {`. The existing `state`, `addListener` and `removeListener` members already match; add `@override` above each of the three.

- [ ] **Step 4: Write the builder**

Create `lib/features/azkar/presentation/widgets/zikr_audio_state_builder.dart`:

```dart
import 'package:flutter/widgets.dart';

import '../services/zikr_audio_service.dart';

/// Rebuilds [builder] whenever the audio state changes, and stops listening
/// when it leaves the tree.
class ZikrAudioStateBuilder extends StatefulWidget {
  const ZikrAudioStateBuilder({
    super.key,
    required this.source,
    required this.builder,
  });

  final ZikrAudioStateSource source;
  final Widget Function(BuildContext context, ZikrAudioState state) builder;

  @override
  State<ZikrAudioStateBuilder> createState() => _ZikrAudioStateBuilderState();
}

class _ZikrAudioStateBuilderState extends State<ZikrAudioStateBuilder> {
  @override
  void initState() {
    super.initState();
    widget.source.addListener(_onState);
  }

  @override
  void didUpdateWidget(ZikrAudioStateBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_onState);
      widget.source.addListener(_onState);
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_onState);
    super.dispose();
  }

  void _onState(ZikrAudioState _) {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.source.state);
}
```

- [ ] **Step 5: Run to verify it passes**

Run: `flutter test test/features/azkar/presentation/zikr_audio_state_builder_test.dart`
Expected: PASS.

- [ ] **Step 6: Use it in the reader page**

In `azkar_category_page.dart` add `import '../widgets/zikr_audio_state_builder.dart';`. In the `PageView.builder` `itemBuilder`, replace the returned `_ZikrReaderPage(...)` so the audio arguments come from the builder:

```dart
                      itemBuilder: (context, index) {
                        final session = widget.state.sessions[index];
                        return ZikrAudioStateBuilder(
                          source: _audioService,
                          builder: (context, audioState) => _ZikrReaderPage(
                            session: session,
                            fontSize: 26.0 * fontScale,
                            isDark: widget.isDark,
                            showUndo: _showUndo && _undoIndex == index,
                            onTap: () =>
                                _handleCounterTap(context, index, session),
                            onLongPress: () => _undoLastCount(context),
                            onUndo: () => _undoLastCount(context),
                            onShare: () => _shareZikr(context, session),
                            onCopy: () => _copyZikr(context, session),
                            onToggleAudio: () =>
                                _audioService.toggle(session.zikr),
                            hasAudio: _audioService.hasAudio(session.zikr),
                            isAudioPlaying:
                                audioState.isPlaying &&
                                audioState.zikrId == session.zikr.id,
                          ),
                        );
                      },
```

- [ ] **Step 7: Use it in the smart wird page**

In `smart_wird_page.dart` add `import '../widgets/zikr_audio_state_builder.dart';` and replace the `itemBuilder` return with:

```dart
              itemBuilder: (context, index) {
                final item = wird.items[index];
                final count = _counts[item.zikr.id] ?? 0;
                final done = count >= item.zikr.totalCount;
                return ZikrAudioStateBuilder(
                  source: _audioService,
                  builder: (context, audioState) => _SmartWirdCard(
                    item: item,
                    count: count,
                    done: done,
                    isDark: isDark,
                    onTap: () => _bump(item),
                    onLongPress: () => _undo(item),
                    onToggleAudio: () => _audioService.toggle(item.zikr),
                    hasAudio: _audioService.hasAudio(item.zikr),
                    isAudioPlaying: audioState.isPlaying &&
                        audioState.zikrId == item.zikr.id,
                  ),
                );
              },
```

- [ ] **Step 8: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS.

- [ ] **Step 9: Checkpoint**

Run: `dart format lib/features/azkar/presentation/services/zikr_audio_service.dart lib/features/azkar/presentation/widgets/zikr_audio_state_builder.dart lib/features/azkar/presentation/pages/azkar_category_page.dart lib/features/azkar/presentation/pages/smart_wird_page.dart test/features/azkar/presentation/zikr_audio_state_builder_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Phase 1 exit gate

- [ ] Run: `flutter test test/features/azkar test/core/content test/assets test/features/khatmah/presentation/pages/khatm_dua_page_test.dart`
  Expected: all pass (69 original tests plus the new ones).
- [ ] Run: `flutter analyze lib/features/azkar lib/core/content lib/core/di test/features/azkar test/assets`
  Expected: no issues.
- [ ] Run: `git diff --stat assets/data/azkar_release.json`
  Expected: empty output (the release file is untouched).

---

# Phase 2: Reading experience

### Task 8: Shared index sheet with readable titles; fix wird index navigation

**Files:**
- Create: `lib/features/azkar/presentation/widgets/azkar_index_sheet.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (`_openIndexSheet`, lines 273–393)
- Modify: `lib/features/azkar/presentation/pages/smart_wird_page.dart` (`_openIndexSheet`, lines 263–346)
- Test: `test/features/azkar/presentation/azkar_index_sheet_test.dart`, `test/features/azkar/presentation/smart_wird_page_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `AppTypography`, `AppSpacing`, `context.tokens`, `context.l10n.azkarIndex` (already used by the old sheets).
- Produces:
  - `String azkarIndexTitle(Zikr zikr, {int maxChars = 40})`
  - `class AzkarIndexEntry { const AzkarIndexEntry({required String title, required String subtitle, required bool done, required bool selected}); }`
  - `Future<void> showAzkarIndexSheet(BuildContext context, {required List<AzkarIndexEntry> entries, required ValueChanged<int> onSelected})`

- [ ] **Step 1: Write the failing test**

Create `test/features/azkar/presentation/azkar_index_sheet_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/l10n/app_localizations.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/presentation/widgets/azkar_index_sheet.dart';

Zikr _zikr(String text) => Zikr(
  id: text,
  text: text,
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.morning,
);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  group('azkarIndexTitle', () {
    test('returns a short text unchanged', () {
      expect(azkarIndexTitle(_zikr('سُبْحَانَ اللَّهِ')), 'سُبْحَانَ اللَّهِ');
    });

    test('collapses line breaks and whitespace', () {
      expect(azkarIndexTitle(_zikr('أول\n\n  ثان')), 'أول ثان');
    });

    test('truncates long text on a letter boundary and adds an ellipsis', () {
      const long =
          'اللَّهُمَّ بِكَ أَصْبَحْنَا وَبِكَ أَمْسَيْنَا وَبِكَ نَحْيَا وَبِكَ نَمُوتُ وَإِلَيْكَ النُّشُورُ';
      final title = azkarIndexTitle(_zikr(long));

      expect(title.endsWith('…'), isTrue);
      expect(title.characters.length, 41);
      // A cut must never leave a diacritic without its letter.
      expect(
        RegExp(r'[\u064B-\u065F]').hasMatch(title.characters.first),
        isFalse,
      );
    });
  });

  testWidgets('lists rows with text titles and reports the tapped index', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAzkarIndexSheet(
              context,
              entries: const [
                AzkarIndexEntry(
                  title: 'الذكر الأول',
                  subtitle: 'سنن أبي داود · 0 من 3',
                  done: false,
                  selected: true,
                ),
                AzkarIndexEntry(
                  title: 'الذكر الثاني',
                  subtitle: 'سنن أبي داود · 1 من 1',
                  done: true,
                  selected: false,
                ),
              ],
              onSelected: (index) => tapped = index,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('الذكر الأول'), findsOneWidget);
    expect(find.text('الذكر الثاني'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('الذكر الثاني'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(find.text('الذكر الثاني'), findsNothing); // sheet closed
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/azkar_index_sheet_test.dart`
Expected: FAIL to compile, `azkar_index_sheet.dart` not found.

- [ ] **Step 3: Write the shared sheet**

Create `lib/features/azkar/presentation/widgets/azkar_index_sheet.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/azkar_entities.dart';

/// Row title for the index: the opening of the zikr text, so rows are
/// distinguishable even when many share the same source. The cut is made on a
/// letter boundary; the stored text is never altered.
String azkarIndexTitle(Zikr zikr, {int maxChars = 40}) {
  final flat = zikr.text.replaceAll(RegExp(r'\s+'), ' ').trim();
  final letters = flat.characters;
  if (letters.length <= maxChars) return flat;
  return '${letters.take(maxChars)}…';
}

class AzkarIndexEntry {
  const AzkarIndexEntry({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final bool done;
  final bool selected;
}

/// Bottom sheet listing every zikr with its progress. Shared by the category
/// reader and the smart wird so both index sheets behave the same.
Future<void> showAzkarIndexSheet(
  BuildContext context, {
  required List<AzkarIndexEntry> entries,
  required ValueChanged<int> onSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Directionality(
      textDirection: Directionality.of(context),
      child: _AzkarIndexSheet(
        entries: entries,
        onSelected: (index) {
          Navigator.pop(sheetContext);
          onSelected(index);
        },
      ),
    ),
  );
}

class _AzkarIndexSheet extends StatefulWidget {
  const _AzkarIndexSheet({required this.entries, required this.onSelected});

  final List<AzkarIndexEntry> entries;
  final ValueChanged<int> onSelected;

  @override
  State<_AzkarIndexSheet> createState() => _AzkarIndexSheetState();
}

class _AzkarIndexSheetState extends State<_AzkarIndexSheet> {
  static const double _rowExtent = 72;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final selected = widget.entries.indexWhere((entry) => entry.selected);
    // Open with the current row a little below the top, not at the very edge.
    final offset = selected <= 1 ? 0.0 : (selected - 1) * _rowExtent;
    _controller = ScrollController(initialScrollOffset: offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Material(
      color: context.tokens.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: math.min(460, height * 0.7)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: context.tokens.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  context.l10n.azkarIndex,
                  style: AppTypography.headlineSmall.copyWith(
                    color: context.tokens.textPrimary,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  controller: _controller,
                  itemExtent: _rowExtent,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: widget.entries.length,
                  itemBuilder: (context, index) {
                    final entry = widget.entries[index];
                    return ListTile(
                      selected: entry.selected,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      leading: entry.done
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            )
                          : CircleAvatar(
                              radius: 14,
                              backgroundColor: entry.selected
                                  ? AppColors.primary
                                  : context.tokens.surfaceVariant,
                              foregroundColor: entry.selected
                                  ? Colors.white
                                  : context.tokens.textPrimary,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                      title: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: AppTypography.bodyMedium.copyWith(
                          color: context.tokens.textPrimary,
                          fontFamily: 'Amiri',
                          fontWeight: entry.selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        entry.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSmall.copyWith(
                          color: context.tokens.textSecondary,
                        ),
                      ),
                      onTap: () => widget.onSelected(index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/presentation/azkar_index_sheet_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Use it in the category page**

In `azkar_category_page.dart` add `import '../widgets/azkar_index_sheet.dart';` and replace the whole `_openIndexSheet` method (from `void _openIndexSheet(BuildContext context) {` through its closing brace, lines 273–393) with:

```dart
  void _openIndexSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    final cubit = context.read<AzkarCubit>();
    // Snapshot the live state so the sheet reflects current counts/progress
    // even if it stays open while the user completes zikr in the background.
    final current = cubit.state;
    final snapshot = current is AzkarLoaded ? current : widget.state;

    showAzkarIndexSheet(
      context,
      entries: [
        for (var i = 0; i < snapshot.sessions.length; i++)
          AzkarIndexEntry(
            title: azkarIndexTitle(snapshot.sessions[i].zikr),
            subtitle: [
              if (snapshot.sessions[i].zikr.reference.isNotEmpty)
                snapshot.sessions[i].zikr.reference,
              context.l10n.miniProgressOf(
                snapshot.sessions[i].zikr.totalCount,
                snapshot.sessions[i].currentCount,
              ),
            ].join(' · '),
            done: snapshot.sessions[i].isDone,
            selected: i == snapshot.currentIndex,
          ),
      ],
      onSelected: cubit.goTo,
    );
  }
```

- [ ] **Step 6: Write the failing wird navigation test**

Append inside `main()` of `test/features/azkar/presentation/smart_wird_page_test.dart`:

```dart
  testWidgets('tapping a row in the index moves to that card', (tester) async {
    await tester.pumpWidget(
      buildApp(SmartWirdPage(currentTime: DateTime(2026, 9, 25, 9))),
    );
    await tester.pumpAndSettle();

    // Card 1 (m-1) is showing; card 2 (g-1) has not been built yet.
    expect(find.text('نص تجريبي g-1'), findsNothing);

    await tester.tap(find.byIcon(Icons.format_list_bulleted_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('نص تجريبي g-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('نص تجريبي g-1'), findsOneWidget);
  });
```

- [ ] **Step 7: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/smart_wird_page_test.dart --plain-name "tapping a row in the index"`
Expected: FAIL: after the tap the card `نص تجريبي g-1` is not shown (the old sheet titles rows with the reference, and the `PageView` never moves).

- [ ] **Step 8: Use the shared sheet in the smart wird and move the page**

In `smart_wird_page.dart` add `import '../widgets/azkar_index_sheet.dart';` and replace the whole `_openIndexSheet` method (lines 263–346) with:

```dart
  void _openIndexSheet() {
    unawaited(HapticFeedback.selectionClick());
    final wird = _wird!;
    showAzkarIndexSheet(
      context,
      entries: [
        for (var i = 0; i < wird.items.length; i++)
          AzkarIndexEntry(
            title: azkarIndexTitle(wird.items[i].zikr),
            subtitle: [
              if (wird.items[i].zikr.reference.isNotEmpty)
                wird.items[i].zikr.reference,
              '${_counts[wird.items[i].zikr.id] ?? 0} / '
                  '${wird.items[i].zikr.totalCount}',
            ].join(' · '),
            done:
                (_counts[wird.items[i].zikr.id] ?? 0) >=
                wird.items[i].zikr.totalCount,
            selected: i == _currentCard,
          ),
      ],
      onSelected: _goToCard,
    );
  }

  /// Moves the pager to [index]. Setting only `_currentCard` would leave the
  /// `PageView` where it was.
  void _goToCard(int index) {
    final controller = _pageController ??= PageController(
      initialPage: _currentCard,
    );
    setState(() => _currentCard = index);
    if (controller.hasClients) controller.jumpToPage(index);
  }
```

- [ ] **Step 9: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS. The old index sheets are gone; remove any now-unused import the analyzer reports.

- [ ] **Step 10: Checkpoint**

Run: `dart format lib/features/azkar/presentation/widgets/azkar_index_sheet.dart lib/features/azkar/presentation/pages/azkar_category_page.dart lib/features/azkar/presentation/pages/smart_wird_page.dart test/features/azkar/presentation/azkar_index_sheet_test.dart test/features/azkar/presentation/smart_wird_page_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Task 9: Reader header fits small screens

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (header `Row`, around lines 438–543)
- Test: `test/features/azkar/presentation/azkar_category_page_test.dart`

**Interfaces:**
- Consumes: `context.screenWidth` (already used for `isSmall`), `_prefsStore.autoAdvanceListenable`, `_prefsStore.setAutoAdvance`, `_openIndexSheet` (Task 8).
- Produces: below 360 dp the auto-advance and index buttons move into one overflow menu; at 360 dp and above the header is unchanged.

- [ ] **Step 1: Write the failing tests**

Add these two tests inside `main()` of `test/features/azkar/presentation/azkar_category_page_test.dart` (before the `group('haptic feedback ...` block):

```dart
  testWidgets('narrow screens move auto-advance and index into a menu', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    registerCubitWith([testZikr1, testZikr2]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.format_list_bulleted_rounded), findsNothing);
    expect(find.byIcon(Icons.autorenew_rounded), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('فهرس الأذكار'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow menu toggles auto-advance', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await prefsStore.setAutoAdvance(true);
    registerCubitWith([testZikr1]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الانتقال التلقائي مفعّل'));
    await tester.pumpAndSettle();

    expect(prefsStore.getAutoAdvance(), isFalse);
  });

  testWidgets('wide screens keep the separate buttons', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 800);
    addTearDown(tester.view.reset);
    registerCubitWith([testZikr1]);

    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart --plain-name "narrow"`
Expected: FAIL: the list icon is still present at 320 px and no `PopupMenuButton<String>` exists.

- [ ] **Step 3: Replace the auto-advance and index buttons in the header**

In the header `Row` of `_ActiveAzkarScreenState.build`, keep the back button, title column and font-size button as they are. Replace the two `IconButton`s that follow the font-size button (the `ValueListenableBuilder<bool>` for auto-advance and the index `IconButton`) with:

```dart
                      if (isSmall)
                        ValueListenableBuilder<bool>(
                          valueListenable: _prefsStore.autoAdvanceListenable,
                          builder: (context, autoAdvance, _) =>
                              PopupMenuButton<String>(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).showMenuTooltip,
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: context.tokens.textPrimary,
                                ),
                                onSelected: (value) {
                                  if (value == 'auto') {
                                    HapticFeedback.selectionClick();
                                    _prefsStore.setAutoAdvance(!autoAdvance);
                                  } else {
                                    _openIndexSheet(context);
                                  }
                                },
                                itemBuilder: (menuContext) => [
                                  PopupMenuItem<String>(
                                    value: 'auto',
                                    child: Text(
                                      autoAdvance
                                          ? context.l10n.azkarAutoAdvanceOn
                                          : context.l10n.azkarAutoAdvanceOff,
                                    ),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'index',
                                    child: Text(context.l10n.azkarIndex),
                                  ),
                                ],
                              ),
                        )
                      else ...[
                        ValueListenableBuilder<bool>(
                          valueListenable: _prefsStore.autoAdvanceListenable,
                          builder: (context, autoAdvance, _) => IconButton(
                            tooltip: autoAdvance
                                ? context.l10n.azkarAutoAdvanceOn
                                : context.l10n.azkarAutoAdvanceOff,
                            icon: Icon(
                              autoAdvance
                                  ? Icons.autorenew_rounded
                                  : Icons.pause_circle_outline_rounded,
                              color: autoAdvance
                                  ? AppColors.primary
                                  : context.tokens.textHint,
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _prefsStore.setAutoAdvance(!autoAdvance);
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.azkarIndex,
                          icon: const Icon(Icons.format_list_bulleted_rounded),
                          color: context.tokens.textPrimary,
                          onPressed: () => _openIndexSheet(context),
                        ),
                      ],
```

The `iconConstraints` and `visualDensity` locals stay for the back and font buttons; the wide buttons no longer need them because that branch only runs when `isSmall` is false.

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart`
Expected: PASS, including the four original tests.

- [ ] **Step 5: Checkpoint**

Run: `dart format lib/features/azkar/presentation/pages/azkar_category_page.dart test/features/azkar/presentation/azkar_category_page_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Task 10: Undo the last tap from the completion screen

**Files:**
- Modify: `lib/features/azkar/presentation/cubits/azkar_state.dart`
- Modify: `lib/features/azkar/presentation/cubits/azkar_cubit.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (`_AzkarCategoryView`, `_CompletionScreen`)
- Test: `test/features/azkar/presentation/azkar_cubit_completion_undo_test.dart`, `test/features/azkar/presentation/azkar_category_page_test.dart`

**Interfaces:**
- Consumes: `AzkarCubit.decrementCurrent()`, `context.l10n.undo` (existing key, "تراجع").
- Produces: `AzkarLoaded.canUndoCompletion` (true only right after the tap that finished the last zikr); `_CompletionScreen(onUndo: VoidCallback?)` shows a button with key `azkar-completion-undo` when non-null.

- [ ] **Step 1: Write the failing cubit test**

Create `test/features/azkar/presentation/azkar_cubit_completion_undo_test.dart`:

```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talia_quran/core/error/app_failure.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/repositories/azkar_repository.dart';
import 'package:talia_quran/features/azkar/domain/usecases/get_azkar_usecase.dart';
import 'package:talia_quran/features/azkar/presentation/cubits/azkar_cubit.dart';

class _OneZikrRepo implements AzkarRepository {
  const _OneZikrRepo();

  static const zikr = Zikr(
    id: 'z1',
    text: 'ذكر',
    transliteration: '',
    translation: '',
    totalCount: 1,
    category: AzkarCategory.morning,
  );

  @override
  Future<Either<Failure, List<Zikr>>> getAzkar(AzkarCategory category) async =>
      const Right([zikr]);

  @override
  Future<Either<Failure, Map<AzkarCategory, List<Zikr>>>> getAllAzkar() async =>
      const Right({
        AzkarCategory.morning: [zikr],
      });
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  AzkarCubit build() {
    final cubit = AzkarCubit(GetAzkarUsecase(const _OneZikrRepo()), prefs);
    addTearDown(cubit.close);
    return cubit;
  }

  test('the tap that finishes the last zikr can be undone', () async {
    final cubit = build();
    await cubit.load(AzkarCategory.morning);

    await cubit.increment();

    final done = cubit.state as AzkarLoaded;
    expect(done.allDone, isTrue);
    expect(done.canUndoCompletion, isTrue);

    await cubit.decrementCurrent();

    final reopened = cubit.state as AzkarLoaded;
    expect(reopened.allDone, isFalse);
    expect(reopened.canUndoCompletion, isFalse);
    expect(reopened.current.currentCount, 0);
  });

  test('a wird that was already complete on entry offers no undo', () async {
    final first = build();
    await first.load(AzkarCategory.morning);
    await first.increment();

    final reopened = build();
    await reopened.load(AzkarCategory.morning);

    final state = reopened.state as AzkarLoaded;
    expect(state.allDone, isTrue);
    expect(state.canUndoCompletion, isFalse);
  });

  test('reset clears the undo offer', () async {
    final cubit = build();
    await cubit.load(AzkarCategory.morning);
    await cubit.increment();

    await cubit.reset();

    expect((cubit.state as AzkarLoaded).canUndoCompletion, isFalse);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/azkar_cubit_completion_undo_test.dart`
Expected: FAIL to compile, `canUndoCompletion` is not defined.

- [ ] **Step 3: Add the flag to the state**

In `azkar_state.dart`, replace `AzkarLoaded` with:

```dart
class AzkarLoaded extends AzkarState {
  const AzkarLoaded({
    required this.category,
    required this.sessions,
    required this.currentIndex,
    this.allDone = false,
    this.canUndoCompletion = false,
  });

  final AzkarCategory category;
  final List<ZikrSession> sessions;
  final int currentIndex;
  final bool allDone;

  /// True only right after the tap that completed the last zikr in this
  /// session, so the completion screen can offer to take that tap back. A wird
  /// that was already complete when opened never offers it.
  final bool canUndoCompletion;

  ZikrSession get current => sessions[currentIndex];
  int get completedCount => sessions.where((s) => s.isDone).length;

  AzkarLoaded copyWith({
    AzkarCategory? category,
    List<ZikrSession>? sessions,
    int? currentIndex,
    bool? allDone,
    bool? canUndoCompletion,
  }) => AzkarLoaded(
    category: category ?? this.category,
    sessions: sessions ?? this.sessions,
    currentIndex: currentIndex ?? this.currentIndex,
    allDone: allDone ?? this.allDone,
    canUndoCompletion: canUndoCompletion ?? this.canUndoCompletion,
  );

  @override
  List<Object?> get props => [
    category,
    sessions,
    currentIndex,
    allDone,
    canUndoCompletion,
  ];
}
```

- [ ] **Step 4: Set and clear the flag in the cubit**

In `azkar_cubit.dart`:

In `_increment`, replace `emit(state.copyWith(sessions: sessions, allDone: allDone));` with:

```dart
    emit(
      state.copyWith(
        sessions: sessions,
        allDone: allDone,
        canUndoCompletion: allDone,
      ),
    );
```

In `_reset`, replace `emit(state.copyWith(sessions: sessions, allDone: false));` with:

```dart
    emit(
      state.copyWith(
        sessions: sessions,
        allDone: false,
        canUndoCompletion: false,
      ),
    );
```

In `_decrementCurrent`, replace `emit(state.copyWith(sessions: sessions, allDone: false));` with:

```dart
    emit(
      state.copyWith(
        sessions: sessions,
        allDone: false,
        canUndoCompletion: false,
      ),
    );
```

- [ ] **Step 5: Run to verify the cubit tests pass**

Run: `flutter test test/features/azkar/presentation/azkar_cubit_completion_undo_test.dart test/features/azkar/presentation/azkar_cubit_test.dart`
Expected: PASS.

- [ ] **Step 6: Write the failing page test**

Add inside `main()` of `test/features/azkar/presentation/azkar_category_page_test.dart`, before the `group('haptic feedback ...` block:

```dart
  testWidgets('the completion screen can take back the last tap', (
    tester,
  ) async {
    registerCubitWith([testZikr2]); // totalCount 1
    await tester.pumpWidget(
      buildApp(const AzkarCategoryPage(category: 'morning')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('الذكر الثاني المعتمد'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('azkar-completion-morning')),
      findsOneWidget,
    );
    final undo = find.byKey(const ValueKey('azkar-completion-undo'));
    expect(undo, findsOneWidget);

    await tester.tap(undo);
    await tester.pumpAndSettle();

    expect(find.text('الذكر الثاني المعتمد'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.byKey(const ValueKey('azkar-completion-morning')), findsNothing);
  });
```

- [ ] **Step 7: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart --plain-name "take back the last tap"`
Expected: FAIL: no widget with key `azkar-completion-undo`.

- [ ] **Step 8: Show the undo button**

In `_AzkarCategoryView.build` (`azkar_category_page.dart`), change the `_CompletionScreen(...)` call to pass the callback:

```dart
              return _CompletionScreen(
                key: ValueKey('azkar-completion-${category.name}'),
                title: _title(context),
                completedCount: state.completedCount,
                totalCount: state.sessions.length,
                isDark: isDark,
                onReset: () => context.read<AzkarCubit>().reset(),
                onUndo: state.canUndoCompletion
                    ? () => context.read<AzkarCubit>().decrementCurrent()
                    : null,
              );
```

In `_CompletionScreen`, add the field and constructor parameter:

```dart
    required this.onReset,
    this.onUndo,
  });
  ...
  final VoidCallback onReset;
  final VoidCallback? onUndo;
```

and add this widget in the `Column` children right after the `Row` of reset/share buttons (before the closing `],` of the column, keeping the `.animate` chain on the `Row` intact):

```dart
            if (widget.onUndo != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                key: const ValueKey('azkar-completion-undo'),
                onPressed: widget.onUndo,
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: Text(context.l10n.undo),
                style: TextButton.styleFrom(
                  foregroundColor: context.tokens.textSecondary,
                ),
              ),
            ],
```

- [ ] **Step 9: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS.

- [ ] **Step 10: Checkpoint**

Run: `dart format lib/features/azkar/presentation/cubits/azkar_state.dart lib/features/azkar/presentation/cubits/azkar_cubit.dart lib/features/azkar/presentation/pages/azkar_category_page.dart test/features/azkar/presentation/azkar_cubit_completion_undo_test.dart test/features/azkar/presentation/azkar_category_page_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar`
Expected: no issues.

---

### Task 11: Smart wird leaves out situational general azkar

**Files:**
- Create: `lib/features/azkar/domain/services/smart_wird_general_policy.dart`
- Modify: `lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart` (step 2 of `_compose`)
- Test: `test/features/azkar/domain/services/smart_wird_general_policy_test.dart`, `test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`, `test/assets/smart_wird_subcategory_contract_test.dart`

**Interfaces:**
- Consumes: `Zikr.subcategory`, `AzkarPeriod` (Task 2).
- Produces: `SmartWirdGeneralPolicy.includes(Zikr zikr, AzkarPeriod period) -> bool`, and public const sets `situational`, `alwaysIncluded`, `sleep`, `waking`.

- [ ] **Step 1: Write the failing policy test**

Create `test/features/azkar/domain/services/smart_wird_general_policy_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/domain/services/azkar_time_context.dart';
import 'package:talia_quran/features/azkar/domain/services/smart_wird_general_policy.dart';

Zikr _zikr(String subcategory) => Zikr(
  id: 'z-$subcategory',
  text: 'نص',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.general,
  subcategory: subcategory,
);

void main() {
  test('situational subcategories never join a wird', () {
    for (final sub in SmartWirdGeneralPolicy.situational) {
      for (final period in AzkarPeriod.values) {
        expect(
          SmartWirdGeneralPolicy.includes(_zikr(sub), period),
          isFalse,
          reason: '$sub / $period',
        );
      }
    }
  });

  test('always-included subcategories join in both periods', () {
    for (final sub in SmartWirdGeneralPolicy.alwaysIncluded) {
      for (final period in AzkarPeriod.values) {
        expect(SmartWirdGeneralPolicy.includes(_zikr(sub), period), isTrue);
      }
    }
  });

  test('sleep azkar join only the evening period', () {
    final zikr = _zikr(SmartWirdGeneralPolicy.sleep);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.evening), isTrue);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.morning), isFalse);
  });

  test('waking azkar join only the morning period', () {
    final zikr = _zikr(SmartWirdGeneralPolicy.waking);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.morning), isTrue);
    expect(SmartWirdGeneralPolicy.includes(zikr, AzkarPeriod.evening), isFalse);
  });

  test('an empty or unknown subcategory is kept', () {
    expect(SmartWirdGeneralPolicy.includes(_zikr(''), AzkarPeriod.morning), isTrue);
    expect(
      SmartWirdGeneralPolicy.includes(_zikr('تصنيف جديد'), AzkarPeriod.evening),
      isTrue,
    );
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/domain/services/smart_wird_general_policy_test.dart`
Expected: FAIL to compile, `smart_wird_general_policy.dart` not found.

- [ ] **Step 3: Write the policy**

Create `lib/features/azkar/domain/services/smart_wird_general_policy.dart`:

```dart
import '../entities/azkar_entities.dart';
import 'azkar_time_context.dart';

/// Decides which records of the general category join a composed wird. It only
/// selects existing records; the text is never touched. Everything left out
/// stays available in the general azkar page.
abstract class SmartWirdGeneralPolicy {
  /// Tied to a situation (toilet, rain, travel...), so wrong in a daily wird.
  static const situational = {
    'أذكار الخلاء',
    'أذكار المسجد',
    'أذكار المنزل',
    'أذكار الطعام',
    'أذكار الكرب',
    'أذكار المطر',
    'أذكار السفر',
    'عيادة المريض',
    'كفارة المجلس',
    'أذكار الريح',
    'ذكر الغضب',
    'أذكار اللباس',
    'الرقية الشرعية',
  };

  /// Relevant at any time of day.
  static const alwaysIncluded = {
    'أذكار منوعة',
    'أذكار بعد الصلاة',
    'أذكار الصباح والمساء',
  };

  static const sleep = 'أذكار النوم';
  static const waking = 'أذكار الاستيقاظ';

  static bool includes(Zikr zikr, AzkarPeriod period) {
    final sub = zikr.subcategory;
    if (situational.contains(sub)) return false;
    if (sub == sleep) return period == AzkarPeriod.evening;
    if (sub == waking) return period == AzkarPeriod.morning;
    return true;
  }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/domain/services/smart_wird_general_policy_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Write the failing compose tests**

Add inside `main()` of `test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart`:

```dart
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

    test('a morning wird has waking azkar, no sleep and no situational ones', () {
      expect(idsAt(9), ['m-1', 'g-waking', 'g-misc', 'g-plain']);
    });

    test('an evening wird has sleep azkar, no waking and no situational ones', () {
      // 19:30 is the evening day part, so no night re-sort applies.
      expect(idsAt(19), ['e-1', 'g-sleep', 'g-misc', 'g-plain']);
    });
  });
```

- [ ] **Step 6: Run to verify failure**

Run: `flutter test test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart --plain-name "general azkar selection"`
Expected: FAIL: the wird still contains `g-toilet` and both sleep and waking items.

- [ ] **Step 7: Apply the policy in the composer**

In `compose_smart_wird_usecase.dart` add `import '../services/smart_wird_general_policy.dart';` and replace step 2 of `_compose` with:

```dart
    // 2. Daily adhkar from the general category, minus situational ones (see
    //    SmartWirdGeneralPolicy). Dataset order is kept.
    for (final z in corpus[AzkarCategory.general] ?? const <Zikr>[]) {
      if (!SmartWirdGeneralPolicy.includes(z, period)) continue;
      items.add(SmartWirdItem(zikr: z, category: AzkarCategory.general));
    }
```

- [ ] **Step 8: Run to verify it passes**

Run: `flutter test test/features/azkar/domain`
Expected: PASS, including the original compose tests (`g-1` is a sleep item at 22:30, an evening period, so it is still included and sorts first).

- [ ] **Step 9: Write the subcategory contract test**

Create `test/assets/smart_wird_subcategory_contract_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/services/smart_wird_general_policy.dart';

void main() {
  test('every general subcategory is classified by the smart-wird policy', () {
    final release =
        jsonDecode(File('assets/data/azkar_release.json').readAsStringSync())
            as Map<String, dynamic>;
    final classified = {
      ...SmartWirdGeneralPolicy.situational,
      ...SmartWirdGeneralPolicy.alwaysIncluded,
      SmartWirdGeneralPolicy.sleep,
      SmartWirdGeneralPolicy.waking,
    };

    final unclassified = <String>{};
    for (final record
        in (release['general'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final sub = record['subcategory'] as String? ?? '';
      if (sub.isNotEmpty && !classified.contains(sub)) unclassified.add(sub);
    }

    expect(
      unclassified,
      isEmpty,
      reason: 'New general subcategory: decide whether it belongs in a daily '
          'wird and add it to SmartWirdGeneralPolicy.',
    );
  });
}
```

- [ ] **Step 10: Run the contract test**

Run: `flutter test test/assets/smart_wird_subcategory_contract_test.dart`
Expected: PASS. If it fails, the release file has a subcategory spelling that differs from the policy sets; copy the spelling from the failure message into the correct set after checking what the records are, and do not edit the release file.

- [ ] **Step 11: Checkpoint**

Run: `dart format lib/features/azkar/domain/services/smart_wird_general_policy.dart lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart test/features/azkar/domain/services/smart_wird_general_policy_test.dart test/features/azkar/domain/usecases/compose_smart_wird_usecase_test.dart test/assets/smart_wird_subcategory_contract_test.dart`
then `flutter analyze lib/features/azkar test/features/azkar test/assets`
Expected: no issues.

---

### Phase 2 exit gate

- [ ] Run: `flutter test test/features/azkar test/core/content test/assets test/features/khatmah/presentation/pages/khatm_dua_page_test.dart`
  Expected: all pass.
- [ ] Run: `flutter analyze lib/features/azkar lib/core/content test/features/azkar test/assets`
  Expected: no issues.

---

# Phase 3: Duas library

### Task 12: Library card fixes and per-chip counts

**Files:**
- Create: `lib/features/azkar/presentation/services/zikr_copy_text.dart`
- Modify: `lib/features/azkar/presentation/pages/general_azkar_page.dart`
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart` (`_shareableText`)
- Modify: `lib/core/l10n/app_ar.arb` (after line 392), `lib/core/l10n/app_en.arb` (after line 388)
- Test: `test/features/azkar/presentation/zikr_copy_text_test.dart`, `test/features/azkar/presentation/general_azkar_page_test.dart`

**Interfaces:**
- Consumes: `Zikr.text`, `Zikr.reference`; `SocialShareData.dua({required Zikr zikr, ..., bool isDua})` and its `category` field (`SocialShareCategory.dua` or `.azkar`).
- Produces:
  - `String zikrCopyText(Zikr zikr, {required String footer})` — text, reference (when present), then footer, separated by blank lines.
  - `@visibleForTesting SocialShareData libraryShareData(Zikr zikr, AzkarCategory category)` in `general_azkar_page.dart`.
  - New l10n keys `azkarFavoriteAdd`, `azkarFavoriteRemove`.

- [ ] **Step 1: Write the failing copy-text test**

Create `test/features/azkar/presentation/zikr_copy_text_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/azkar/domain/entities/azkar_entities.dart';
import 'package:talia_quran/features/azkar/presentation/services/zikr_copy_text.dart';

Zikr _zikr({String reference = ''}) => Zikr(
  id: 'z',
  text: 'نص الذكر',
  transliteration: '',
  translation: '',
  totalCount: 1,
  category: AzkarCategory.duas,
  reference: reference,
);

void main() {
  test('joins text, reference and footer with blank lines', () {
    expect(
      zikrCopyText(_zikr(reference: 'صحيح مسلم'), footer: 'من تطبيق تالية'),
      'نص الذكر\n\nصحيح مسلم\n\nمن تطبيق تالية',
    );
  });

  test('skips an empty reference', () {
    expect(
      zikrCopyText(_zikr(), footer: 'من تطبيق تالية'),
      'نص الذكر\n\nمن تطبيق تالية',
    );
  });

  test('never alters the stored text', () {
    const text = 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً';
    final zikr = Zikr(
      id: 'z',
      text: text,
      transliteration: '',
      translation: '',
      totalCount: 1,
      category: AzkarCategory.duas,
    );

    expect(zikrCopyText(zikr, footer: 'f').startsWith(text), isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/zikr_copy_text_test.dart`
Expected: FAIL to compile, `zikr_copy_text.dart` not found.

- [ ] **Step 3: Write the helper**

Create `lib/features/azkar/presentation/services/zikr_copy_text.dart`:

```dart
import '../../domain/entities/azkar_entities.dart';

/// The one format for copying a zikr: the verbatim text, its reference when
/// there is one, then [footer]. Used by the reader and the library so both
/// copy the same thing.
String zikrCopyText(Zikr zikr, {required String footer}) => [
  zikr.text,
  if (zikr.reference.isNotEmpty) zikr.reference,
  footer,
].join('\n\n');
```

- [ ] **Step 4: Run to verify it passes**

Run: `flutter test test/features/azkar/presentation/zikr_copy_text_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Reuse it in the reader**

In `azkar_category_page.dart` add `import '../services/zikr_copy_text.dart';` and replace `_shareableText` with:

```dart
  String _shareableText(BuildContext context, ZikrSession session) =>
      zikrCopyText(session.zikr, footer: context.l10n.sharedFromTalia);
```

- [ ] **Step 6: Add the l10n keys**

In `lib/core/l10n/app_ar.arb`, after the line `"azkarFavoritesEmptyDesc": "اضغط على علامة الإشارة المرجعية بجانب أي دعاء لحفظه هنا",` insert:

```json
  "azkarFavoriteAdd": "إضافة إلى المفضلة",
  "azkarFavoriteRemove": "إزالة من المفضلة",
```

In `lib/core/l10n/app_en.arb`, after the line `"azkarFavoritesEmptyDesc": "Tap the bookmark icon next to any dua to save it here",` insert:

```json
  "azkarFavoriteAdd": "Add to favorites",
  "azkarFavoriteRemove": "Remove from favorites",
```

Run: `flutter gen-l10n`
Expected: completes without errors; `lib/core/l10n/app_localizations.dart` now declares `azkarFavoriteAdd` and `azkarFavoriteRemove`.

- [ ] **Step 7: Write the failing page tests**

Add these imports to `test/features/azkar/presentation/general_azkar_page_test.dart`:

```dart
import 'package:talia_quran/core/widgets/social_share/social_share_model.dart';
```

and add inside `main()`:

```dart
  testWidgets('favorite tooltips follow the app language', (tester) async {
    registerCubitWith([testDua1]);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GeneralAzkarPage(category: AzkarCategory.duas),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add to favorites'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bookmark-dua-1')));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
  });

  testWidgets('subcategory chips show how many duas each holds', (tester) async {
    registerCubitWith([testDua1, testDua2]);

    await tester.pumpWidget(
      buildApp(const GeneralAzkarPage(category: AzkarCategory.duas)),
    );
    await tester.pumpAndSettle();

    expect(find.text('أدعية نبوية (1)'), findsOneWidget);
    expect(find.text('أدعية من القرآن (1)'), findsOneWidget);
  });

  test('sharing from the duas page uses the dua card, from general the azkar card', () {
    const dua = testDua1;

    expect(
      libraryShareData(dua, AzkarCategory.duas).category,
      SocialShareCategory.dua,
    );
    expect(
      libraryShareData(dua, AzkarCategory.general).category,
      SocialShareCategory.azkar,
    );
  });
```

`testDua1`/`testDua2` are declared inside `main()` above these tests, so the new tests sit below those declarations. `libraryShareData` comes from `general_azkar_page.dart`, already imported.

- [ ] **Step 8: Run to verify failure**

Run: `flutter test test/features/azkar/presentation/general_azkar_page_test.dart`
Expected: FAIL to compile, `libraryShareData` is not defined.

- [ ] **Step 9: Apply the page changes**

In `general_azkar_page.dart`:

1. Add imports:

```dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import '../services/zikr_copy_text.dart';
```

2. Add near the top of the file (below the imports):

```dart
String _normalizedSubcategory(String subcategory) =>
    subcategory == 'أدعية قرآنية' ? 'أدعية من القرآن' : subcategory;

/// The share payload for a library card: a dua card on the duas page, an azkar
/// card on the general azkar page.
@visibleForTesting
SocialShareData libraryShareData(Zikr zikr, AzkarCategory category) =>
    SocialShareData.dua(zikr: zikr, isDua: category == AzkarCategory.duas);
```

3. In `_buildContent`, replace the `uniqueSubcategories` block with a counted version:

```dart
    // Unique subcategories in dataset order, with how many records each holds.
    final subcategoryCounts = <String, int>{};
    for (final session in state.sessions) {
      final sub = _normalizedSubcategory(session.zikr.subcategory);
      if (sub.isEmpty) continue;
      subcategoryCounts.update(sub, (count) => count + 1, ifAbsent: () => 1);
    }
    final uniqueSubcategories = subcategoryCounts.keys.toList();

    final tabs = ['', _favoritesTabKey, ...uniqueSubcategories];
```

4. In the same method's filter, replace

```dart
        final rawSub = s.zikr.subcategory;
        final mappedSub =
            rawSub == 'أدعية قرآنية' ? 'أدعية من القرآن' : rawSub;
```

with

```dart
        final rawSub = s.zikr.subcategory;
        final mappedSub = _normalizedSubcategory(rawSub);
```

5. Change the `_buildCategoriesFilter` signature to `_buildCategoriesFilter(List<String> tabs, Map<String, int> counts, bool isDark)`, update its call site to `_buildCategoriesFilter(tabs, subcategoryCounts, isDark)`, and change the last label branch from `labelWidget = Text(tab);` to:

```dart
            labelWidget = Text('$tab (${counts[tab] ?? 0})');
```

6. In `_ZikrCard`, add a `category` field and constructor parameter (`required this.category,`, `final AzkarCategory category;`), pass `category: widget.category` where the card is built, and change:
   - the tooltip to `tooltip: isFav ? context.l10n.azkarFavoriteRemove : context.l10n.azkarFavoriteAdd,`
   - the copy handler to `Clipboard.setData(ClipboardData(text: zikrCopyText(zikr, footer: context.l10n.sharedFromTalia)));`
   - the share handler to `final data = libraryShareData(zikr, category);`

- [ ] **Step 10: Run the tests**

Run: `flutter test test/features/azkar`
Expected: PASS, including the original four library tests. The favorites-chip test still passes because the favorites chip and "All" chip keep their labels; only subcategory chips carry counts.

- [ ] **Step 11: Checkpoint**

Run: `dart format lib/features/azkar/presentation/services/zikr_copy_text.dart lib/features/azkar/presentation/pages/general_azkar_page.dart lib/features/azkar/presentation/pages/azkar_category_page.dart test/features/azkar/presentation/zikr_copy_text_test.dart test/features/azkar/presentation/general_azkar_page_test.dart` (not the ARB or generated l10n files)
then `flutter analyze lib/features/azkar lib/core/l10n test/features/azkar`
Expected: no issues.

---

### Final gate

- [ ] Run: `flutter test test/features/azkar test/core/content test/assets test/features/khatmah/presentation/pages/khatm_dua_page_test.dart`
  Expected: all pass.
- [ ] Run: `flutter analyze lib/features/azkar lib/core/content lib/core/di lib/core/l10n test/features/azkar test/assets`
  Expected: no issues.
- [ ] Run: `git diff --stat assets/data/`
  Expected: empty output (no data file changed).
- [ ] Run: `git status --short` and compare with the baseline noted in Task 1 Step 0. Every new modified file must be one this plan names.
- [ ] Report to the owner: what changed per phase, the two open items (Quiet Night, smart-wird XP by day part), the smart-wird selection rule, and that nothing was committed.
- [ ] Also report, without acting on it: azkar counters, favorites and smart-wird progress live in unscoped `SharedPreferences` keys, so two accounts on one device share them. `test/integration/account_switch_isolation_test.dart` covers Isar records only. Whether these need owner scoping is the owner's call.
