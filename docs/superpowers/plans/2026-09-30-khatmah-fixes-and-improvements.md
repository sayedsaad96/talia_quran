# Khatmah Fixes & Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every defect found in the 2026-09-30 khatmah review (gendered dedication duas, adjustment crash, wrap-around progress, stale reminders, small UX gaps) and ship the local-only experience improvements (edit dedication, juz-per-day Ramadan wird, "ahead of schedule" projection, catch-up sheet, juz map, "same settings" restart, history stats).

**Architecture:** All scheduling rules stay in pure Dart on `KhatmahPlan` / `KhatmahSchedulingEngine` (no Flutter imports) so they are unit-testable; every write still goes through `KhatmahRepository.mutatePlan` (the account-barrier, compare-and-swap path). Reminders become a pure policy (`KhatmahReminderPolicy`) that produces up to 7 one-shot slots, scheduled by the notification service and refreshed whenever khatmah data changes. UI changes are surgical edits in existing pages plus two new focused widgets.

**Tech Stack:** Flutter, flutter_bloc Cubits, get_it, SharedPreferences, flutter_local_notifications + timezone, ARB l10n (`flutter gen-l10n`), flutter_test + mocktail/mockito.

**Spec:** the review in this session (findings P1–P3 + suggestions 1–8). Summary is reproduced in "Findings covered" below; there is no separate spec file.

## Findings covered

| # | Sev | Finding | Task |
|---|-----|---------|------|
| F1 | P1 | Approved dedication duas are masculine only; no gender modelled; certificate honorific masculine; templates gate ignores `dedicationTemplatesReview.enabled` | 4 |
| F2 | P2 | `_keepEndDateTransform` calls `needed.clamp(pace, 20)` → `ArgumentError` when pace > 20 (Ramadan preset = 21) | 2 |
| F3 | P2 | Khatmah starting at page > 1 cannot log physical pages after wrapping 604→1; physical range loop does not wrap and uses a stale start | 3 |
| F4 | P2 | Khatmah reminder is a static daily repeat: fires after wird is done, shows stale pages, fires for users without a plan and for paused plans | 5 |
| F5 | P3 | Reader session bar shows "page 0"; model `currentPage` ignores `startPage` | 6 |
| F6 | P3 | Custom pages-per-day input rejects Arabic-Indic digits | 6 |
| F7 | P3 | Completion page without `extra` is a dead end (no app bar / action) | 6 |
| F8 | P3 | Dedication cannot be edited after creation | 7 |
| F9 | — | `MushafHizbHelper.getJuz` never returns 30 (loop starts at index 28): pages 582–604 report juz 29 | 1 |
| S1 | sugg | Juz-per-day wird (Ramadan = 30 juz in 30 days) | 8 |
| S2 | sugg | "Ahead of schedule" + projected finish date | 9 |
| S3 | sugg | Clear catch-up choices with previews | 10 |
| S4 | sugg | Juz map of covered pages | 11 |
| S5 | sugg | "New khatmah with same settings"; history stats | 12 |

Out of this plan (each needs its own spec — see "Deferred" at the end): group/family khatmah, khatmah cloud sync, prayer-anchored and learned reminder times, multiple/plural recipients, feminine/plural dua **texts**, dead-code removal.

## Decisions (delegated — rationale recorded per owner preference)

| # | Decision | Why |
|---|----------|-----|
| D1 | Add `DedicationGender {male, female}`; `effectiveGender` = explicit gender, else derived from an explicit relationship (الأب/الأم/والد/والدة/Father/Mother), else `null`. Never inferred from the name. | Fixes F1 without guessing; legacy "mother" dedications become correct. |
| D2 | Dua templates are looked up as `"<condition>_<gender>"`; a legacy flat key (`"deceased"`) counts **only** for `male` (its grammar is masculine). Unknown gender or missing key → no insert (fail closed). No feminine/plural text is written by us. | Content policy: never generate religious text. Feminine templates arrive later through the review pipeline as `deceased_female` etc. with zero code change. |
| D3 | Templates render only when `reviewStatus == approved` **and** `dedicationTemplatesReview.reviewStatus == approved && enabled == true`. | The owner's JSON already carries this gate; code must honour it. |
| D4 | Certificate honorific is gendered (حفظه/حفظها، رحمه/رحمها، شفاه/شفاها الله); unknown gender → name without honorific. Legacy certificates with unknown gender lose the (possibly wrong) masculine suffix. | A missing honorific is harmless; a wrong-gender one on a certificate for a deceased mother is not. These are grammatical agreement of a fixed phrase, not new religious text. |
| D5 | `keepEndDate` never lowers the pace and never exceeds 20 unless the pace is already above 20: `max(pace, min(needed, 20))`. | Removes the crash, preserves the existing "cap at 20" intent. |
| D6 | Daily wird ranges stay single ranges capped at 604; after page 604 the next day starts at page 1. | A wird ending at the mushaf end is a natural stop; avoids two-range UI everywhere. |
| D7 | Reminder = up to 7 one-shot notifications (ids 1110–1116) at the chosen time, skipping today if today's wird is complete or the time passed; none when there is no active plan (no plan, paused, complete). Legacy repeating id 1062 is always cancelled. Refreshed on app resume/locale (existing) **and** on every khatmah data change (debounced 2 s). | Removes nagging and stale content; 7 slots cover a week away from the app, with the same (correct) target because progress cannot change without opening the app. |
| D8 | Users without a khatmah get no khatmah reminder. | The home "start khatmah" card already invites; a daily nudge for a feature you never started is noise. |
| D9 | Juz mode: new `KhatmahWirdUnit {pages, juz}` on the plan (json `wirdUnit`, default `pages`). Ramadan preset creates a juz plan with pace 21 (used only for pace math). Daily target = next unread page → end of its juz. In juz mode only the "calm" adjustment is offered; boost/keep-end-date previews return `null`. Pace/behind/projection count juz, not pages. | 30 juz = 30 days exactly; ends at the traditional juz boundary; avoids "+1 page/day" nonsense for juz plans. |
| D10 | "Natural stop" snapping to rub'/hizb/surah is **not** done: rub' boundaries fall mid-page and progress is page-based. | Would need ayah-level progress; out of scope. |
| D11 | "Same settings" prefill copies pace + wird unit (and Ramadan duration for juz plans), **not** the dedication. | A next khatmah is often for someone else; dedication is one tap away. |
| D12 | History stats card (count, average days, fastest) appears only with ≥ 2 completions. | A single completion makes "average/fastest" meaningless. |
| D13 | Dead code (`UpdateKhatmahProgressUsecase`, `createPlan`, `getCompletedCount`) is kept; `recordThroughPage` is made wrap-aware instead of removed. | Seven test files use them (including authority tests); removal is churn with no user value. |
| D14 | Dedication edits are allowed on active **and** paused plans; title follows the recipient name (`KhatmahPlan.titleFor`). | Same rule as creation; pausing should not freeze a typo. |

## Global Constraints

- Never generate or alter Quran text, dua text, or religious wording. Only JSON **keys** and gate logic may change in `assets/data/khatm_dua.json`; its text values are the owner's reviewed content.
- All plan writes go through `KhatmahRepository.mutatePlan` (or existing create/delete paths). No direct `savePlan` from presentation.
- Pure rules (`khatmah_plan.dart`, `khatmah_scheduling_engine.dart`, new `khatmah_reminder_policy.dart`, `khatmah_history_stats.dart`) import no Flutter.
- New ARB keys go in both `lib/core/l10n/app_ar.arb` and `app_en.arb` (ICU plural style: `{count, plural, =1{…} =2{…} few{{countText} …} other{{countText} …}}` with `count:int, countText:String`), then `flutter gen-l10n`.
- Arabic UI shows Arabic-Indic digits via `MushafHizbHelper.toArabicNumber`.
- `dart format` only **new** files. Existing files carry owner work and are not format-clean: hand-indent edits, then check `git diff --stat` for noise.
- Relative imports inside `lib/` (house style).
- **No commits** — the owner reviews and commits. Each task ends with a verification checkpoint.
- Verify each task: `flutter analyze <edited files>` → "No issues found!", then the task's tests, then `flutter test test/features/khatmah`.

## Review Focus

- A plan whose `startPage` is 300, fully read 300–604, then 1–9, logging physical page 10 → only page 10 is added; logging page 350 (already read) is rejected (Task 3).
- A Ramadan (juz) plan on its **last** day with 23 pages left in juz 30 must show "on track", not "behind by 2" (Task 8).
- Reminder refresh when the plan was just completed/abandoned → all 7 slots cancelled, legacy 1062 cancelled (Task 5).
- Dedication with relationship "والد / والدة" (legacy, ambiguous) and no explicit gender → no dua insert, no honorific (Task 4).
- Tapping a fully-read juz in the juz map opens that juz's first page in khatmah mode without crashing on `nextUnreadPage == 605` (Task 11).

---

### Task 1: Correct juz lookup and expose juz page ranges

**Files:**
- Modify: `lib/core/utils/mushaf_hizb_helper.dart` (`getJuz`, add `juzPageRange`)
- Test: `test/core/utils/mushaf_hizb_helper_juz_test.dart` (create)

**Interfaces:**
- Produces: `static ({int start, int end}) MushafHizbHelper.juzPageRange(int juz)`; `getJuz(582..604) == 30`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/core/utils/mushaf_hizb_helper.dart';

void main() {
  group('juz lookup', () {
    test('last juz pages report juz 30', () {
      expect(MushafHizbHelper.getJuz(581), 29);
      expect(MushafHizbHelper.getJuz(582), 30);
      expect(MushafHizbHelper.getJuz(604), 30);
    });

    test('first juz boundaries', () {
      expect(MushafHizbHelper.getJuz(1), 1);
      expect(MushafHizbHelper.getJuz(21), 1);
      expect(MushafHizbHelper.getJuz(22), 2);
    });

    test('juzPageRange covers the mushaf without gaps', () {
      expect(MushafHizbHelper.juzPageRange(1), (start: 1, end: 21));
      expect(MushafHizbHelper.juzPageRange(30), (start: 582, end: 604));
      var expected = 1;
      for (var juz = 1; juz <= 30; juz++) {
        final range = MushafHizbHelper.juzPageRange(juz);
        expect(range.start, expected);
        expected = range.end + 1;
      }
      expect(expected, 605);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/core/utils/mushaf_hizb_helper_juz_test.dart`
Expected: FAIL (`getJuz(582)` returns 29; `juzPageRange` undefined).

- [ ] **Step 3: Implement**

In `getJuz`, change `for (int i = 28; i >= 0; i--)` to `for (int i = juzStartPages.length - 1; i >= 0; i--)`. Add below `getJuz`:

```dart
  /// First and last Madinah-mushaf page of [juz] (1-30).
  static ({int start, int end}) juzPageRange(int juz) {
    final index = juz.clamp(1, 30) - 1;
    final start = juzStartPages[index];
    final end = index == juzStartPages.length - 1
        ? 604
        : juzStartPages[index + 1] - 1;
    return (start: start, end: end);
  }
```

- [ ] **Step 4: Verify** — the new test passes; `flutter test test/core/utils` passes (hizb fallback uses `getJuz`).

- [ ] **Step 5: Checkpoint** — `flutter analyze lib/core/utils/mushaf_hizb_helper.dart`.

---

### Task 2: Schedule adjustment no longer crashes above 20 pages/day (F2)

**Files:**
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart` (`_keepEndDateTransform`)
- Test: `test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart`

**Interfaces:** none new.

- [ ] **Step 1: Write the failing test** (add to the existing file, reusing its mock setup for `GetActiveKhatmahUsecase` that returns a given plan):

```dart
test('keep-end-date preview works when the pace is above the boost cap', () async {
  final today = DateTime(2026, 3, 1);
  final plan = KhatmahPlan(
    id: 'ramadan',
    title: KhatmahPlan.defaultTitle,
    targetPagesPerDay: 21,
    targetDays: 30,
    startDate: today.subtract(const Duration(days: 10)),
    expectedEndDate: today.add(const Duration(days: 19)),
    completedPages: {for (var p = 1; p <= 100; p++) p},
  );
  final cubit = buildCubit(activePlan: plan, now: () => today);
  await cubit.load();

  final preview = cubit.previewAdjustment(kind: KhatmahAdjustment.keepEndDate);

  expect(preview, isNotNull);
  expect(preview!.targetPagesPerDay, greaterThanOrEqualTo(21));
});
```

(Use the file's existing cubit factory; if it has none that takes a plan and clock, add a local helper constructing `KhatmahCubit(getActive, recordReading, pauseResume, delete, updateSchedule: updateSchedule, now: now)` with the file's mocks.)

- [ ] **Step 2: Run** `flutter test test/features/khatmah/presentation/cubits/khatmah_cubit_test.dart --plain-name "above the boost cap"` → FAIL with `Invalid argument(s): 21`.

- [ ] **Step 3: Implement** — replace

```dart
    final target = needed.clamp(plan.targetPagesPerDay, maxPagesPerDay);
```
with
```dart
    // Never lower the pace; only raise it up to the boost cap (D5).
    final target = max(plan.targetPagesPerDay, min(needed, maxPagesPerDay));
```
and add `import 'dart:math';` at the top.

- [ ] **Step 4: Verify** the test passes and the whole cubit test file passes.

- [ ] **Step 5: Checkpoint** — analyze the cubit.

---

### Task 3: Wrap-aware physical logging (F3)

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart` (add `pagesThrough`, make `recordThroughPage` use it)
- Modify: `lib/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart` (physical branch)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (`_PhysicalMushafLoggerDialogState._save`, `build` validity + wird-end chip)
- Test: `test/features/khatmah/domain/entities/khatmah_plan_test.dart`, `test/features/khatmah/domain/usecases/record_khatmah_reading_usecase_test.dart`

**Interfaces:**
- Produces: `Iterable<int> KhatmahPlan.pagesThrough(int page)` — unread-order pages from `nextUnreadPage` through `page` inclusive, following `readingOrder(startPage)`; empty when `page` is before `nextUnreadPage` in reading order, out of 1..604, or the plan is complete.

- [ ] **Step 1: Write failing entity tests**

```dart
group('pagesThrough (wrap-aware)', () {
  KhatmahPlan planFrom(int start, Set<int> read) => KhatmahPlan(
    id: 'p',
    title: KhatmahPlan.defaultTitle,
    startPage: start,
    completedPages: read,
    targetPagesPerDay: 5,
    targetDays: 121,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 5, 1),
  );

  test('continues across 604 to page 1', () {
    final plan = planFrom(300, {for (var p = 300; p <= 600; p++) p});
    expect(plan.pagesThrough(3), [601, 602, 603, 604, 1, 2, 3]);
  });

  test('already-read page in reading order yields nothing', () {
    final plan = planFrom(300, {
      for (var p = 300; p <= 604; p++) p,
      for (var p = 1; p <= 9; p++) p,
    });
    expect(plan.nextUnreadPage, 10);
    expect(plan.pagesThrough(350), isEmpty);
    expect(plan.pagesThrough(10), [10]);
  });

  test('plain plan from page 1', () {
    final plan = planFrom(1, {1, 2});
    expect(plan.pagesThrough(5), [3, 4, 5]);
    expect(plan.pagesThrough(0), isEmpty);
    expect(plan.pagesThrough(605), isEmpty);
  });

  test('recordThroughPage wraps too', () {
    final plan = planFrom(600, {600, 601, 602, 603, 604});
    expect(plan.recordThroughPage(2).completedPages, containsAll([1, 2]));
  });
});
```

- [ ] **Step 2: Write the failing use-case test** (in `record_khatmah_reading_usecase_test.dart`, using its fake repository whose `mutatePlan` applies the closure to the stored plan):

```dart
test('physical logging after wrapping records only the new range', () async {
  final plan = KhatmahPlan(
    id: 'wrap',
    title: KhatmahPlan.defaultTitle,
    startPage: 300,
    completedPages: {for (var p = 300; p <= 604; p++) p},
    targetPagesPerDay: 10,
    targetDays: 61,
    startDate: DateTime(2026, 1, 1),
    expectedEndDate: DateTime(2026, 3, 2),
  );
  repository.stored = plan;

  final result = await usecase(
    plan, 4, source: KhatmahReadingSource.physical, readAt: DateTime(2026, 2, 1));

  expect(result.newlyCompletedPages, {1, 2, 3, 4});
});
```

(Match the existing fake's field names; if the fake stores the plan differently, set it the same way the neighbouring physical-range test does.)

- [ ] **Step 3: Run both** → FAIL (`pagesThrough` undefined; use case records nothing).

- [ ] **Step 4: Implement in `khatmah_plan.dart`** (below `readingOrder`):

```dart
  /// Position of [page] in the reading order that begins at [startPage].
  static int readingIndex(int page, int startPage) {
    const total = KhatmahSchedulingEngine.totalPages;
    final first = startPage.clamp(1, total);
    return (page - first + total) % total;
  }

  /// Pages from [nextUnreadPage] through [page] in reading order (wrapping
  /// after 604). Empty when [page] was already passed or is out of range.
  Iterable<int> pagesThrough(int page) sync* {
    const total = KhatmahSchedulingEngine.totalPages;
    final next = nextUnreadPage;
    if (next > total || page < 1 || page > total) return;
    final from = readingIndex(next, startPage);
    final to = readingIndex(page, startPage);
    if (to < from) return;
    final first = startPage.clamp(1, total);
    for (var index = from; index <= to; index++) {
      yield (first - 1 + index) % total + 1;
    }
  }
```

Replace `recordThroughPage`'s body with:

```dart
  KhatmahPlan recordThroughPage(int pageNumber) {
    final pages = pagesThrough(pageNumber).toList();
    if (pages.isEmpty) return this;
    return copyWith(completedPages: {...completedPages, ...pages});
  }
```

- [ ] **Step 5: Implement in the use case** — delete `final confirmedStart = plan.nextUnreadPage;` and change the physical branch to:

```dart
        KhatmahReadingSource.physical => anchoredPlan.recordThroughPage(
          pageNumber,
        ),
```

- [ ] **Step 6: Dashboard logger** — in `_save`, replace the range condition

```dart
    if (page == null ||
        page < widget.plan.nextUnreadPage ||
        page > KhatmahSchedulingEngine.totalPages ||
        _isSaving) {
```
with
```dart
    if (page == null || widget.plan.pagesThrough(page).isEmpty || _isSaving) {
```
In `build`, replace `validRange` with `page != null && widget.plan.pagesThrough(page).isNotEmpty`, and the chip guard `if (wirdEnd >= widget.plan.nextUnreadPage)` with `if (widget.plan.pagesThrough(wirdEnd).isNotEmpty)`. Remove the now-unused `KhatmahSchedulingEngine` import only if analyze reports it unused.

- [ ] **Step 7: Verify** entity + use-case tests pass; `flutter test test/features/khatmah` passes.

- [ ] **Step 8: Checkpoint** — analyze the three lib files.

---

### Task 4: Gendered dedication, fail-closed dua inserts, gendered honorific (F1)

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_dedication.dart`
- Modify: `lib/features/khatmah/data/models/khatmah_dedication_model.dart`
- Modify: `lib/features/khatmah/data/datasources/khatm_dua_datasource.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatm_dua_page.dart` (2 call sites)
- Modify: `lib/features/khatmah/domain/entities/khatmah_history_entry.dart` (honorific)
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_dedication_form.dart`
- Modify: `lib/core/l10n/app_ar.arb`, `app_en.arb`
- Test: `test/features/khatmah/data/datasources/khatm_dua_datasource_test.dart`, `test/features/khatmah/data/models/khatmah_dedication_model_test.dart` (create), `test/features/certificate/domain/entities/certificate_award_khatmah_test.dart`, `test/features/khatmah/presentation/widgets/khatmah_dedication_form_test.dart`, `test/features/khatmah/integration/khatmah_e2e_flow_test.dart` (call-site update)

**Interfaces:**
- Produces: `enum DedicationGender { male, female }`; `KhatmahDedication.recipientGender`; `DedicationGender? KhatmahDedication.effectiveGender`; `KhatmahDedication.copyWith(...)`; `String KhatmDuaData.getDedicationInsert(DedicationCondition condition, DedicationGender? gender, [String? name])`; `bool KhatmDuaData.templatesApproved`.

- [ ] **Step 1: Failing tests — dua datasource** (replace the three `getDedicationInsert` tests):

```dart
Map<String, dynamic> approvedJson(Map<String, String> inserts) => {
  'arabicText': 'text',
  'source': 'source',
  'sourceNote': 'note',
  'tier': 'guidance',
  'reviewStatus': 'approved',
  'dedicationTemplatesReview': {'reviewStatus': 'approved', 'enabled': true},
  'dedicationInserts': inserts,
};

test('legacy flat templates serve only a male recipient', () {
  final data = KhatmDuaData.fromJson(approvedJson({'deceased': 'اللهم ارحم {name}'}));
  expect(
    data.getDedicationInsert(DedicationCondition.deceased, DedicationGender.male, 'أحمد'),
    'اللهم ارحم أحمد',
  );
  expect(
    data.getDedicationInsert(DedicationCondition.deceased, DedicationGender.female, 'فاطمة'),
    '',
  );
  expect(data.getDedicationInsert(DedicationCondition.deceased, null, 'فاطمة'), '');
});

test('gendered keys win when present', () {
  final data = KhatmDuaData.fromJson(approvedJson({
    'deceased': 'M {name}',
    'deceased_female': 'F {name}',
  }));
  expect(
    data.getDedicationInsert(DedicationCondition.deceased, DedicationGender.female, 'فاطمة'),
    'F فاطمة',
  );
});

test('templates stay closed unless the templates review is enabled', () {
  final json = approvedJson({'alive': 'M {name}'})
    ..['dedicationTemplatesReview'] = {'reviewStatus': 'approved', 'enabled': false};
  final data = KhatmDuaData.fromJson(json);
  expect(
    data.getDedicationInsert(DedicationCondition.alive, DedicationGender.male, 'أحمد'),
    '',
  );
});

test('unreviewed data never renders templates', () {
  final data = KhatmDuaData.fromJson({
    'arabicText': 'text', 'source': 's', 'sourceNote': 'n', 'tier': 'guidance',
    'dedicationInserts': {'alive': 'M {name}'},
  });
  for (final condition in DedicationCondition.values) {
    for (final gender in DedicationGender.values) {
      expect(data.getDedicationInsert(condition, gender, 'x'), isEmpty);
    }
  }
});
```

Delete the old tests `unreviewed legacy templates cannot infer gender from a name`, `legacy templates stay quarantined…`, `approved templates interpolate…` (superseded above). Keep `fromJson parses all fields correctly` and the datasource caching test.

- [ ] **Step 2: Failing tests — dedication model** (`test/features/khatmah/data/models/khatmah_dedication_model_test.dart`):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/data/models/khatmah_dedication_model.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_dedication.dart';

void main() {
  test('gender round-trips through JSON', () {
    const entity = KhatmahDedication(
      isDedicated: true,
      recipientName: 'فاطمة',
      recipientGender: DedicationGender.female,
    );
    final json = KhatmahDedicationModel.fromEntity(entity).toJson();
    expect(json['recipientGender'], 'female');
    expect(KhatmahDedicationModel.fromJson(json).toEntity(), entity);
  });

  test('legacy JSON without gender stays unknown', () {
    final entity = KhatmahDedicationModel.fromJson({
      'isDedicated': true,
      'recipientName': 'x',
      'relationship': 'والد / والدة',
    }).toEntity();
    expect(entity.recipientGender, isNull);
    expect(entity.effectiveGender, isNull);
  });

  test('explicit relationship implies gender', () {
    expect(const KhatmahDedication(relationship: 'الأم').effectiveGender, DedicationGender.female);
    expect(const KhatmahDedication(relationship: 'والدة').effectiveGender, DedicationGender.female);
    expect(const KhatmahDedication(relationship: 'Father').effectiveGender, DedicationGender.male);
    expect(
      const KhatmahDedication(relationship: 'الأم', recipientGender: DedicationGender.male)
          .effectiveGender,
      DedicationGender.male,
    );
  });
}
```

- [ ] **Step 3: Failing test — honorific** (add to `certificate_award_khatmah_test.dart`, following its existing entry builder):

```dart
test('honorific agrees with the recipient gender', () {
  KhatmahHistoryEntry entry(KhatmahDedication d) => KhatmahHistoryEntry(
    id: 'h', khatmahNumber: 1, title: 't',
    startDate: DateTime(2026, 1, 1), completedDate: DateTime(2026, 2, 1),
    totalDays: 32, dedication: d, certificateId: 'khatmah-h',
  );
  expect(
    entry(const KhatmahDedication(isDedicated: true, recipientName: 'فاطمة',
        condition: DedicationCondition.deceased, recipientGender: DedicationGender.female))
        .certificate!.dedication,
    'فاطمة (رحمها الله)',
  );
  expect(
    entry(const KhatmahDedication(isDedicated: true, recipientName: 'أحمد',
        condition: DedicationCondition.alive, recipientGender: DedicationGender.male))
        .certificate!.dedication,
    'أحمد (حفظه الله)',
  );
  expect(
    entry(const KhatmahDedication(isDedicated: true, recipientName: 'سعاد',
        condition: DedicationCondition.sick))
        .certificate!.dedication,
    'سعاد',
  );
});
```

Update any existing expectation in that file that relied on a masculine suffix without gender: give its dedication `recipientGender: DedicationGender.male`.

- [ ] **Step 4: Run** the three test files → FAIL (types/params undefined).

- [ ] **Step 5: Implement the entity** (`khatmah_dedication.dart`):

```dart
enum DedicationCondition { alive, deceased, sick }

enum DedicationGender { male, female }

class KhatmahDedication extends Equatable {
  const KhatmahDedication({
    this.isDedicated = false,
    this.recipientName,
    this.relationship,
    this.condition,
    this.customNote,
    this.recipientGender,
  });

  final bool isDedicated;
  final String? recipientName;
  final String? relationship;
  final DedicationCondition? condition;
  final String? customNote;
  final DedicationGender? recipientGender;

  static const none = KhatmahDedication();

  /// Explicit gender, else one implied by an explicit relationship. Never
  /// inferred from the recipient's name.
  DedicationGender? get effectiveGender =>
      recipientGender ?? genderForRelationship(relationship);

  static DedicationGender? genderForRelationship(String? relationship) =>
      switch (relationship) {
        'الأم' || 'والدة' || 'Mother' => DedicationGender.female,
        'الأب' || 'والد' || 'Father' => DedicationGender.male,
        _ => null,
      };

  KhatmahDedication copyWith({
    bool? isDedicated,
    String? recipientName,
    String? relationship,
    DedicationCondition? condition,
    String? customNote,
    DedicationGender? recipientGender,
  }) => KhatmahDedication(
    isDedicated: isDedicated ?? this.isDedicated,
    recipientName: recipientName ?? this.recipientName,
    relationship: relationship ?? this.relationship,
    condition: condition ?? this.condition,
    customNote: customNote ?? this.customNote,
    recipientGender: recipientGender ?? this.recipientGender,
  );

  @override
  List<Object?> get props => [
    isDedicated,
    recipientName,
    relationship,
    condition,
    customNote,
    recipientGender,
  ];
}
```

- [ ] **Step 6: Implement the model** — add `final String? recipientGender;` (constructor param), `fromJson`: `recipientGender: json['recipientGender'] as String?`, `toJson`: `'recipientGender': recipientGender`, `fromEntity`: `recipientGender: entity.recipientGender?.name`, `toEntity`:

```dart
    recipientGender: DedicationGender.values
        .where((g) => g.name == recipientGender)
        .firstOrNull,
```

(Unknown strings map to `null`, never to a default gender.)

- [ ] **Step 7: Implement the dua data** — add field `final bool templatesEnabled;` (constructor default `false`), parse in `fromJson`:

```dart
      templatesEnabled: switch (json['dedicationTemplatesReview']) {
        {'reviewStatus': 'approved', 'enabled': true} => true,
        _ => false,
      },
```

and replace `getDedicationInsert`:

```dart
  bool get templatesApproved => isApproved && templatesEnabled;

  /// Approved insert for [condition] and [gender]; '' when not approved, the
  /// gender is unknown, or no reviewed template exists. A legacy flat key is
  /// masculine and therefore serves only [DedicationGender.male].
  String getDedicationInsert(
    DedicationCondition condition,
    DedicationGender? gender, [
    String? name,
  ]) {
    if (!templatesApproved || gender == null) return '';
    final template =
        dedicationInserts['${condition.name}_${gender.name}'] ??
        (gender == DedicationGender.male
            ? dedicationInserts[condition.name]
            : null);
    if (template == null || template.isEmpty) return '';
    if (name != null && name.trim().isNotEmpty) {
      return template.replaceAll('{name}', name.trim());
    }
    return template.replaceAll('{name}', '').replaceAll('  ', ' ').trim();
  }
```

`dedicationInserts` parsing must not merge `quarantinedDedicationInserts` into approved ones: keep `json['dedicationInserts'] ?? const {}` only (drop the quarantined fallback).

- [ ] **Step 8: Dua page call sites** — both `state.data.getDedicationInsert(widget.dedication!.condition!, widget.dedication!.recipientName)` and `data.getDedicationInsert(...)` become `...getDedicationInsert(widget.dedication!.condition!, widget.dedication!.effectiveGender, widget.dedication!.recipientName)`. Also update `khatmah_e2e_flow_test.dart:518` to pass `DedicationGender.male` (or the dedication's `effectiveGender`).

- [ ] **Step 9: Honorific** — in `KhatmahHistoryEntry.certificate`, replace the `suffix` switch with:

```dart
      final female = dedication!.effectiveGender == DedicationGender.female;
      final male = dedication!.effectiveGender == DedicationGender.male;
      final suffix = !male && !female
          ? ''
          : switch (dedication!.condition) {
              DedicationCondition.alive => female ? ' (حفظها الله)' : ' (حفظه الله)',
              DedicationCondition.deceased => female ? ' (رحمها الله)' : ' (رحمه الله)',
              DedicationCondition.sick => female ? ' (شفاها الله)' : ' (شفاه الله)',
              null => '',
            };
```

- [ ] **Step 10: Form** — in `khatmah_dedication_form.dart`:
  - `_relationshipOptionsArabic = ['الأب', 'الأم', 'صديق', 'قريب', 'أخرى']` (legacy stored values still appear through `{..., ?_relationship}`).
  - Add state `DedicationGender? _gender;` initialised from `init?.recipientGender`; include `recipientGender: _gender` in `_notifyChange`.
  - Relationship `onChanged`: also `_gender = KhatmahDedication.genderForRelationship(val) ?? _gender;`.
  - Under the name field add a labelled `Wrap` of two `ChoiceChip`s (keys `khatmah_dedication_gender_male` / `_female`, labels `l10n.khatmahRecipientMale` / `khatmahRecipientFemale`), title `l10n.khatmahRecipientGender`, toggling `_gender` exactly like the condition chips.
  - ARB (ar/en): `khatmahRecipientGender` "المُهدى إليه" / "Recipient", `khatmahRecipientMale` "ذكر" / "Male", `khatmahRecipientFemale` "أنثى" / "Female". Run `flutter gen-l10n`.
  - Add a widget test: selecting `الأم` then submitting yields `effectiveGender == female`; tapping `khatmah_dedication_gender_male` yields `recipientGender == male`.

- [ ] **Step 11: Verify** — all Task 4 tests pass; `flutter test test/features/khatmah test/features/certificate test/assets` passes.

- [ ] **Step 12: Checkpoint** — analyze every edited lib file.

---

### Task 5: Reminders that follow real progress (F4)

**Files:**
- Create: `lib/features/khatmah/domain/services/khatmah_reminder_policy.dart`
- Create: `lib/core/services/khatmah_reminder_sync.dart`
- Modify: `lib/core/services/notification_service.dart` (add `_khatmahReminderBaseId = 1110`, `scheduleKhatmahReminders`, extend `cancelKhatmahReminder`)
- Modify: `lib/core/services/notification_scheduler.dart` (extract `refreshKhatmahReminder(AppLocalizations l10n)` and call it from `refreshNotifications`)
- Modify: `lib/core/di/injection.dart` (register `KhatmahReminderSync`), `lib/core/services/app_initializer.dart` (start it after notifications are refreshed) — surgical edits, owner work present
- Test: `test/features/khatmah/domain/services/khatmah_reminder_policy_test.dart` (create), `test/core/services/khatmah_reminder_sync_test.dart` (create), existing scheduler test for khatmah (update expectations if it asserts the repeating call)

**Interfaces:**
- Produces:
  - `class KhatmahReminderSlot { final DateTime at; final int startPage; final int endPage; }`
  - `List<KhatmahReminderSlot> KhatmahReminderPolicy.slots({required KhatmahPlan? plan, required DateTime now, required int hour, required int minute})` (max `KhatmahReminderPolicy.maxSlots = 7`)
  - `Future<void> TaliaNotificationService.scheduleKhatmahReminders({required String title, required List<({DateTime at, String body, String payload})> reminders})`
  - `Future<void> NotificationScheduler.refreshKhatmahReminder(AppLocalizations l10n)`
  - `KhatmahReminderSync(Stream<void>? changes, Future<void> Function() refresh, {Duration debounce})` with `start()` / `dispose()`

- [ ] **Step 1: Failing policy tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:talia_quran/features/khatmah/domain/entities/khatmah_plan.dart';
import 'package:talia_quran/features/khatmah/domain/services/khatmah_reminder_policy.dart';

void main() {
  KhatmahPlan plan({Set<int> read = const {}, KhatmahStatus status = KhatmahStatus.active}) =>
      KhatmahPlan(
        id: 'p', title: KhatmahPlan.defaultTitle, completedPages: read,
        targetPagesPerDay: 5, targetDays: 121, status: status,
        startDate: DateTime(2026, 1, 1), expectedEndDate: DateTime(2026, 5, 1),
      );

  test('no plan, paused or complete → no reminders', () {
    final now = DateTime(2026, 2, 1, 9);
    expect(KhatmahReminderPolicy.slots(plan: null, now: now, hour: 17, minute: 0), isEmpty);
    expect(
      KhatmahReminderPolicy.slots(plan: plan(status: KhatmahStatus.paused), now: now, hour: 17, minute: 0),
      isEmpty,
    );
  });

  test('before the time with wird pending: today plus six more days', () {
    final slots = KhatmahReminderPolicy.slots(
      plan: plan(), now: DateTime(2026, 2, 1, 9), hour: 17, minute: 0);
    expect(slots, hasLength(7));
    expect(slots.first.at, DateTime(2026, 2, 1, 17));
    expect(slots.last.at, DateTime(2026, 2, 7, 17));
    expect((slots.first.startPage, slots.first.endPage), (1, 5));
  });

  test('wird already done today → starts tomorrow', () {
    final done = plan(read: {1, 2, 3, 4, 5})
        .anchorDailyTarget(DateTime(2026, 2, 1, 8))
        .copyWith(dailyTargetStartPage: 1, dailyTargetEndPage: 5);
    final slots = KhatmahReminderPolicy.slots(
      plan: done, now: DateTime(2026, 2, 1, 9), hour: 17, minute: 0);
    expect(slots.first.at, DateTime(2026, 2, 2, 17));
    expect((slots.first.startPage, slots.first.endPage), (6, 10));
  });

  test('time already passed today → starts tomorrow', () {
    final slots = KhatmahReminderPolicy.slots(
      plan: plan(), now: DateTime(2026, 2, 1, 18), hour: 17, minute: 0);
    expect(slots.first.at, DateTime(2026, 2, 2, 17));
    expect(slots, hasLength(7));
  });
}
```

(The "done" fixture: `anchorDailyTarget` on a plan with pages 1–5 read computes the target from `nextUnreadPage` = 6; the explicit `copyWith` pins today's anchored range to 1–5 so `isDailyTargetComplete` is true.)

- [ ] **Step 2: Run** → FAIL (file missing).

- [ ] **Step 3: Implement the policy**

```dart
import '../entities/khatmah_plan.dart';

class KhatmahReminderSlot {
  const KhatmahReminderSlot({
    required this.at,
    required this.startPage,
    required this.endPage,
  });

  final DateTime at;
  final int startPage;
  final int endPage;
}

/// Which khatmah reminders to schedule (D7): one-shot, only for an active
/// plan, never for a day whose wird is already complete or whose time passed.
class KhatmahReminderPolicy {
  const KhatmahReminderPolicy._();

  static const maxSlots = 7;

  static List<KhatmahReminderSlot> slots({
    required KhatmahPlan? plan,
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    if (plan == null ||
        plan.status != KhatmahStatus.active ||
        plan.isComplete) {
      return const [];
    }
    final result = <KhatmahReminderSlot>[];
    for (var offset = 0; result.length < maxSlots; offset++) {
      final at = DateTime(now.year, now.month, now.day + offset, hour, minute);
      if (!at.isAfter(now)) continue;
      if (offset == 0 && plan.isDailyTargetComplete(now)) continue;
      final target = plan.dailyTargetFor(at);
      result.add(
        KhatmahReminderSlot(
          at: at,
          startPage: target.startPage,
          endPage: target.endPage,
        ),
      );
    }
    return result;
  }
}
```

`dart format` this new file.

- [ ] **Step 4: Verify policy tests pass.**

- [ ] **Step 5: Notification service** — add `static const int _khatmahReminderBaseId = 1110;` next to `_khatmahReminderId`, and:

```dart
  /// One-shot khatmah reminders (D7). Always clears the legacy repeating one.
  Future<void> scheduleKhatmahReminders({
    required String title,
    required List<({DateTime at, String body, String payload})> reminders,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await cancelKhatmahReminder();
    final availableSlots = await _availableScheduledNotificationSlots();
    final count = math.min(reminders.length, availableSlots);
    for (var i = 0; i < count; i++) {
      final reminder = reminders[i];
      await _plugin.zonedSchedule(
        id: _khatmahReminderBaseId + i,
        title: title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
        notificationDetails: _khatmahNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload,
      );
    }
  }
```

Extend `cancelKhatmahReminder` to also cancel `_khatmahReminderBaseId + i` for `i < 7`. Use the file's existing `tz` / `math` import aliases (check the imports at the top; add `import 'package:timezone/timezone.dart' as tz;` only if absent). Keep the old `scheduleKhatmahReminder` method only if something else calls it (`grep -rn scheduleKhatmahReminder lib test`); otherwise delete it and its tests' references.

- [ ] **Step 6: Scheduler** — move the whole "Khatmah Daily Progress Reminder" block into:

```dart
  Future<void> refreshKhatmahReminder(AppLocalizations l10n) async {
    final prefs = /* same SharedPreferences source refreshNotifications uses */;
    final enabled =
        prefs.getBool(TaliaNotificationService.khatmahReminderPreferenceKey) ?? true;
    if (!enabled) {
      await _service.cancelKhatmahReminder();
      return;
    }
    final hour = prefs.getInt('${TaliaNotificationService.khatmahReminderPreferenceKey}_hour') ?? 17;
    final minute = prefs.getInt('${TaliaNotificationService.khatmahReminderPreferenceKey}_minute') ?? 0;
    final quietTime = /* same applyQuietHours call the `quiet` closure makes */;

    KhatmahPlan? activePlan;
    try {
      final usecase = _getActiveKhatmah ??
          (getIt.isRegistered<GetActiveKhatmahUsecase>() ? getIt<GetActiveKhatmahUsecase>() : null);
      activePlan = await usecase?.call();
    } catch (e, stack) {
      TaliaLogger.w('Failed to load active khatmah for notification', e, stack);
    }

    final slots = KhatmahReminderPolicy.slots(
      plan: activePlan, now: DateTime.now(),
      hour: quietTime.hour, minute: quietTime.minute,
    );
    if (slots.isEmpty) {
      await _service.cancelKhatmahReminder();
      return;
    }
    await _service.scheduleKhatmahReminders(
      title: l10n.notificationKhatmahTitle,
      reminders: [
        for (final slot in slots)
          (
            at: slot.at,
            body: l10n.notificationKhatmahBodyWithTarget(slot.startPage, slot.endPage),
            payload: '/quran/page/${slot.startPage}?mode=khatmah',
          ),
      ],
    );
  }
```

Fill the two `/* same … */` spots by reading how `refreshNotifications` obtains `prefs` and how its `quiet` closure calls `applyQuietHours` (line ~194) — reuse the identical expression; if `quiet` depends on locals, lift it into a private method `_quiet(SharedPreferences prefs, int hour, int minute)` and use it from both places. `refreshNotifications` then just does `await refreshKhatmahReminder(l10n);` where the block was. `notificationKhatmahBody` stays in ARB (still used elsewhere? `grep`; if unused, leave it — ARB cleanup is not in scope).

Update the existing scheduler khatmah test(s): expect `scheduleKhatmahReminders` with 7 reminders for an active plan and `cancelKhatmahReminder` for null/paused plans.

- [ ] **Step 7: Sync service + test**

```dart
import 'dart:async';

/// Re-plans khatmah reminders whenever khatmah data changes (D7).
class KhatmahReminderSync {
  KhatmahReminderSync(
    this._changes,
    this._refresh, {
    this.debounce = const Duration(seconds: 2),
  });

  final Stream<void>? _changes;
  final Future<void> Function() _refresh;
  final Duration debounce;
  StreamSubscription<void>? _subscription;
  Timer? _timer;

  void start() {
    _subscription ??= _changes?.listen((_) {
      _timer?.cancel();
      _timer = Timer(debounce, () => unawaited(_refresh()));
    });
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
  }
}
```

Test (`test/core/services/khatmah_reminder_sync_test.dart`) with `fakeAsync`: three change events 500 ms apart → one refresh after 2 s of quiet; no refresh before `start()`.

- [ ] **Step 8: Wiring** — `injection.dart`, next to the other khatmah registrations:

```dart
  getIt.registerLazySingleton<KhatmahReminderSync>(
    () => KhatmahReminderSync(
      getIt<GetActiveKhatmahUsecase>().changes,
      () => getIt<NotificationScheduler>().refreshKhatmahReminder(
        lookupAppLocalizations(getIt<LocaleCubit>().state),
      ),
    ),
  );
```

In `app_initializer.dart`, right after `await getIt<NotificationScheduler>().refreshNotifications(l10n);` add `getIt<KhatmahReminderSync>().start();`. Check both files' imports and add the missing ones.

- [ ] **Step 9: Verify** — policy, sync, scheduler tests pass; `flutter test test/core/services test/features/khatmah` passes.

- [ ] **Step 10: Checkpoint** — analyze all edited/created files.

---

### Task 6: Small UX fixes (F5, F6, F7)

**Files:**
- Modify: `lib/features/khatmah/presentation/widgets/khatmah_reader_session_bar.dart`
- Modify: `lib/features/khatmah/data/models/khatmah_plan_model.dart` (`currentPage`)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart` (custom input)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart` (invalid branch)
- Modify: ARB (ar/en) — `khatmahBackHome` only if no equivalent key exists (`grep -n '"khatmahBackToHome\|"khatmahHome' lib/core/l10n/app_ar.arb`; reuse the key the completion page's home button already uses)
- Test: `test/features/khatmah/data/models/khatmah_plan_model_test.dart`, `test/features/khatmah/presentation/pages/khatmah_setup_page_test.dart`, `test/features/khatmah/presentation/pages/khatmah_completion_page_test.dart`, a session-bar widget test in `test/features/khatmah/presentation/widgets/khatmah_reader_session_bar_test.dart` (create)

- [ ] **Step 1: Failing tests**
  - Model: a model built with `startPage: 300, completedPages: {300, 301}` has `currentPage == 301`; `toJson()['currentPage'] == 301`.
  - Session bar: plan with `completedPages: {}`, state `KhatmahActive(plan, wirdStartPage: 1, wirdEndPage: 5)`, `currentPage: 200` → text contains the localized page `1` (next unread), never `0`. Pump inside `MaterialApp` with `AppLocalizations` delegates and `locale: Locale('en')` like the other khatmah widget tests.
  - Setup: entering `٧` into `khatmah_setup_custom_input` updates the summary to the 7-pages estimate (87 days) — mirror the existing "custom pages input updates calculation live" test.
  - Completion: pumping `KhatmahCompletionPage(completion: null)` shows `khatmahNoSavedCompletionAvailable` **and** a button with key `khatmah_completion_invalid_home_button`.

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**
  - Model: replace `_highestContiguousPage(...)` with a start-aware version:

```dart
       currentPage = _lastContiguousPage(
         _normalizeCompletedPages(completedPages ?? const <int>{}),
         startPage,
       );
...
  static int _lastContiguousPage(Set<int> pages, int startPage) {
    var current = 0;
    for (final page in KhatmahPlan.readingOrder(startPage)) {
      if (!pages.contains(page)) break;
      current = page;
    }
    return current;
  }
```
  (Delete `_highestContiguousPage`.)
  - Session bar: replace the `current` fallback `: plan.currentPage;` with `: (plan.currentPage > 0 ? plan.currentPage : plan.nextUnreadPage);`.
  - Setup custom input: `inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]'))]`, and in `_onCustomChanged` use `final parsed = parseKhatmahPageInput(value);`.
  - Completion invalid branch:

```dart
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.khatmahNoSavedCompletionAvailable,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  key: const Key('khatmah_completion_invalid_home_button'),
                  onPressed: () => context.go(AppRoutes.khatmahHistory),
                  child: Text(context.l10n.khatmahRecentCompletions),
                ),
              ],
            ),
          ),
        ),
      );
```
  (History is where a real completion lives; `khatmahRecentCompletions` already exists.)

- [ ] **Step 4: Verify** tests pass; `flutter test test/features/khatmah`.

- [ ] **Step 5: Checkpoint** — analyze edited files.

---

### Task 7: Edit the dedication after creation (F8)

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart` (add `static String titleFor(KhatmahDedication)`)
- Create: `lib/features/khatmah/domain/usecases/update_khatmah_dedication_usecase.dart`
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart` (use `titleFor`)
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart` (optional ctor param + `updateDedication`)
- Modify: `lib/core/di/injection.dart` (register use case, pass to `KhatmahCubit`)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (menu item + sheet)
- Modify: ARB (`khatmahEditDedication` "تعديل الإهداء"/"Edit dedication", `khatmahDedicationSaved` "حُفظ الإهداء"/"Dedication saved", `khatmahSave` only if absent)
- Test: `test/features/khatmah/domain/usecases/update_khatmah_dedication_usecase_test.dart` (create), cubit test, dashboard page test

**Interfaces:**
- Produces: `KhatmahPlan.titleFor(KhatmahDedication d)`; `UpdateKhatmahDedicationUsecase.call(KhatmahPlan plan, KhatmahDedication dedication) → Future<KhatmahPlan>`; `KhatmahCubit({..., UpdateKhatmahDedicationUsecase? updateDedication})`, `Future<bool> KhatmahCubit.updateDedication(KhatmahDedication dedication)`.

- [ ] **Step 1: Failing use-case test** (fake repository applying the closure, like `update_khatmah_schedule_usecase_test.dart`):

```dart
test('updates dedication and title on a paused plan without touching progress', () async {
  final plan = KhatmahPlan(
    id: 'p', title: KhatmahPlan.defaultTitle, completedPages: {1, 2},
    targetPagesPerDay: 5, targetDays: 121, status: KhatmahStatus.paused,
    startDate: DateTime(2026, 1, 1), expectedEndDate: DateTime(2026, 5, 1),
  );
  repository.stored = plan;
  const dedication = KhatmahDedication(
    isDedicated: true, recipientName: ' فاطمة ', recipientGender: DedicationGender.female);

  final updated = await UpdateKhatmahDedicationUsecase(repository)(plan, dedication);

  expect(updated.title, 'فاطمة');
  expect(updated.dedication, dedication);
  expect(updated.completedPages, {1, 2});
  expect(updated.status, KhatmahStatus.paused);
});

test('clearing the dedication restores the default title', () async {
  // same plan with title 'فاطمة'; call with KhatmahDedication.none
  // expect(updated.title, KhatmahPlan.defaultTitle);
});
```

Write the second test fully by copying the first with `title: 'فاطمة'` on the input plan and `KhatmahDedication.none` as the argument.

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

`khatmah_plan.dart`:

```dart
  /// Plan title derived from a dedication: the recipient's name, else the
  /// stable default that presentation localizes.
  static String titleFor(KhatmahDedication dedication) {
    final name = dedication.recipientName?.trim();
    return dedication.isDedicated && name != null && name.isNotEmpty
        ? name
        : defaultTitle;
  }
```

Setup cubit: replace its inline `title` computation with `final title = KhatmahPlan.titleFor(dedication);`.

Use case:

```dart
import '../entities/khatmah_dedication.dart';
import '../entities/khatmah_plan.dart';
import '../repositories/khatmah_repository.dart';

/// Changes only the dedication (and the title derived from it) (D14).
class UpdateKhatmahDedicationUsecase {
  const UpdateKhatmahDedicationUsecase(this._repository);

  final KhatmahRepository _repository;

  Future<KhatmahPlan> call(
    KhatmahPlan plan,
    KhatmahDedication dedication,
  ) async {
    final result = await _repository.mutatePlan(
      plan,
      (current) => current.copyWith(
        dedication: dedication,
        title: KhatmahPlan.titleFor(dedication),
      ),
      requiredStatus: plan.status,
    );
    return result.plan;
  }
}
```

Cubit: add ctor param `UpdateKhatmahDedicationUsecase? updateDedication` stored as `_updateDedication`, and:

```dart
  Future<bool> updateDedication(KhatmahDedication dedication) async {
    final plan = _lastKnownPlan;
    final usecase = _updateDedication;
    if (plan == null || usecase == null) return false;
    try {
      _checkAuthority();
      final updated = await usecase(plan, dedication);
      _lastKnownPlan = updated;
      if (updated.status == KhatmahStatus.paused) {
        _emitIfOpen(KhatmahPaused(plan: updated));
      } else {
        _emitActive(updated);
      }
      return true;
    } catch (error) {
      _emitIfOpen(
        KhatmahProgressFailure(
          plan: _lastKnownPlan,
          pageNumber: 0,
          source: KhatmahReadingSource.digital,
          error: error,
        ),
      );
      return false;
    }
  }
```

DI: register `UpdateKhatmahDedicationUsecase(getIt<KhatmahRepository>())` lazily; pass `updateDedication: getIt<UpdateKhatmahDedicationUsecase>()` to the `KhatmahCubit` factory.

Dashboard: add a `PopupMenuItem<void>` (key `khatmah_dashboard_edit_dedication_button`, icon `Icons.volunteer_activism_outlined`, label `khatmahEditDedication`) **before** the abandon item, calling `_showEditDedicationSheet(plan)`:

```dart
  Future<void> _showEditDedicationSheet(KhatmahPlan plan) async {
    var draft = plan.dedication;
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              KhatmahDedicationForm(
                initialDedication: plan.dedication,
                onChanged: (value) => draft = value,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('khatmah_edit_dedication_save_button'),
                onPressed: () => Navigator.pop(sheetContext, true),
                child: Text(sheetContext.l10n.khatmahSaveProgress),
              ),
            ],
          ),
        ),
      ),
    );
    if (save != true || !mounted) return;
    final saved = await _cubit.updateDedication(draft);
    if (saved && mounted) {
      context.showSnackBar(context.l10n.khatmahDedicationSaved);
    }
  }
```

(Use an existing "save" label key; `khatmahSaveProgress` is a fallback — prefer a plain "حفظ" key if `grep '"save"\|"khatmahSave"' app_ar.arb` finds one.) Import `../widgets/khatmah_dedication_form.dart`.

- [ ] **Step 4: Widget test** (dashboard): open menu → tap edit → type a name in `khatmah_dedication_recipient_name` → tap save → `updateDedication` mock called once with that name.

- [ ] **Step 5: Verify** all Task 7 tests + `flutter test test/features/khatmah`.

- [ ] **Step 6: Checkpoint** — analyze edited files.

---

### Task 8: Juz-per-day wird (Ramadan) (S1)

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart` (`KhatmahWirdUnit`, field, `dailyTargetFor`, `pagesBehind`, `remainingJuzCount`, `copyWith`, props)
- Modify: `lib/features/khatmah/data/models/khatmah_plan_model.dart` (`wirdUnit` json)
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_setup_cubit.dart` (`createPlan({... KhatmahWirdUnit wirdUnit = KhatmahWirdUnit.pages})`)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart` (Ramadan chip → juz)
- Modify: `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart` (`previewAdjustment`, `canBoost`, `_calmTransform` for juz)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (hide boost/keep-end-date in juz mode; wird card label "الجزء N")
- Modify: ARB: `khatmahDurationRamadan` → "رمضان (جزء يومياً)" / "Ramadan (a juz a day)"; new `khatmahWirdJuz` "ورد اليوم: الجزء {juz}" / "Today's wird: Juz {juz}" (`juz: String`)
- Test: `khatmah_plan_test.dart`, `khatmah_plan_model_test.dart`, `khatmah_setup_cubit_test.dart`, `khatmah_cubit_test.dart`

**Interfaces:**
- Consumes: `MushafHizbHelper.getJuz`, `MushafHizbHelper.juzPageRange` (Task 1).
- Produces: `enum KhatmahWirdUnit { pages, juz }`; `KhatmahPlan.wirdUnit`; `int KhatmahPlan.remainingJuzCount`; `int KhatmahPlan.remainingWirdDays` (pages: `ceil(remaining / pace)`; juz: `remainingJuzCount`).

Note: `khatmah_plan.dart` is pure Dart but `mushaf_hizb_helper.dart` imports qcf (Flutter). Therefore move the juz table into the domain: create `lib/features/khatmah/domain/entities/khatmah_juz_table.dart` holding a copy-free re-export is impossible without Flutter — instead **move** `juzStartPages`, `getJuz` and `juzPageRange` logic into a new pure file `lib/core/utils/mushaf_juz_table.dart` (no imports) and have `MushafHizbHelper.juzStartPages/getJuz/juzPageRange` delegate to it. The data (the 30 start pages) moves verbatim; Task 1's tests keep passing.

- [ ] **Step 1: Pure juz table** — create `lib/core/utils/mushaf_juz_table.dart`:

```dart
/// Juz page boundaries of the 604-page Madinah mushaf. Pure Dart so domain
/// rules can use it without Flutter.
abstract final class MushafJuzTable {
  static const List<int> startPages = [
    1, 22, 42, 62, 82, 102, 121, 142, 162, 182, // Juz  1–10
    201, 222, 242, 262, 282, 302, 322, 342, 362, 382, // Juz 11–20
    402, 422, 442, 462, 482, 502, 522, 542, 562, 582, // Juz 21–30
  ];

  static int juzOf(int page) {
    final clamped = page.clamp(1, 604);
    for (var i = startPages.length - 1; i >= 0; i--) {
      if (clamped >= startPages[i]) return i + 1;
    }
    return 1;
  }

  static ({int start, int end}) range(int juz) {
    final index = juz.clamp(1, 30) - 1;
    final end = index == startPages.length - 1 ? 604 : startPages[index + 1] - 1;
    return (start: startPages[index], end: end);
  }
}
```

(`// dart format off` around the table if format would explode it; the list must stay byte-identical to `MushafHizbHelper.juzStartPages`.) Make `MushafHizbHelper.juzStartPages = MushafJuzTable.startPages`, `getJuz(p) => MushafJuzTable.juzOf(p)`, `juzPageRange(j) => MushafJuzTable.range(j)`. Run Task 1 tests.

- [ ] **Step 2: Failing entity tests**

```dart
group('juz wird', () {
  KhatmahPlan juzPlan(Set<int> read, {DateTime? end}) => KhatmahPlan(
    id: 'r', title: KhatmahPlan.defaultTitle, wirdUnit: KhatmahWirdUnit.juz,
    completedPages: read, targetPagesPerDay: 21, targetDays: 30,
    startDate: DateTime(2026, 2, 18), expectedEndDate: end ?? DateTime(2026, 3, 19),
  );

  test('daily target is the rest of the current juz', () {
    expect(juzPlan({}).dailyTargetFor(DateTime(2026, 2, 18)), (startPage: 1, endPage: 21));
    expect(
      juzPlan({for (var p = 1; p <= 25; p++) p}).dailyTargetFor(DateTime(2026, 2, 19)),
      (startPage: 26, endPage: 41),
    );
  });

  test('remaining juz count and last-day pace', () {
    final lastDay = juzPlan({for (var p = 1; p <= 581; p++) p}, end: DateTime(2026, 3, 19));
    expect(lastDay.remainingJuzCount, 1);
    expect(lastDay.pagesBehind(DateTime(2026, 3, 19)), 0);
    expect(lastDay.pagesBehind(DateTime(2026, 3, 20)), 23);
  });

  test('two juz left with one day left is behind by the second juz', () {
    final plan = juzPlan({for (var p = 1; p <= 561; p++) p}, end: DateTime(2026, 3, 19));
    expect(plan.pagesBehind(DateTime(2026, 3, 19)), 23);
  });
});
```

Model test: `wirdUnit: juz` round-trips; JSON without `wirdUnit` → `pages`; unknown string → `pages`.

- [ ] **Step 3: Run** → FAIL.

- [ ] **Step 4: Implement entity**

```dart
enum KhatmahWirdUnit { pages, juz }
```
Add `this.wirdUnit = KhatmahWirdUnit.pages` ctor param, `final KhatmahWirdUnit wirdUnit;`, `KhatmahWirdUnit? wirdUnit` in `copyWith`, and to `props`.

```dart
  /// Juz (1–30) that still hold an unread page.
  int get remainingJuzCount => {
    for (var page = 1; page <= KhatmahSchedulingEngine.totalPages; page++)
      if (!completedPages.contains(page)) MushafJuzTable.juzOf(page),
  }.length;

  /// Wird days needed for the remaining pages at the plan's pace.
  int get remainingWirdDays => wirdUnit == KhatmahWirdUnit.juz
      ? remainingJuzCount
      : KhatmahSchedulingEngine.calculateDaysFromPages(
          remainingPages,
          targetPagesPerDay,
        );
```

In `dailyTargetFor`, replace the final `return KhatmahSchedulingEngine.todaysWird(...)` with:

```dart
    if (wirdUnit == KhatmahWirdUnit.juz) {
      final first = nextUnreadPage.clamp(1, KhatmahSchedulingEngine.totalPages);
      return (
        startPage: first,
        endPage: MushafJuzTable.range(MushafJuzTable.juzOf(first)).end,
      );
    }
    return KhatmahSchedulingEngine.todaysWird(
      nextUnreadPage - 1,
      targetPagesPerDay,
    );
```

In `pagesBehind`, replace `final capacity = daysLeft * targetPagesPerDay;` with `final capacity = _capacityPages(daysLeft);` and add:

```dart
  /// Pages the plan can cover in [days] wird days from the next unread page.
  int _capacityPages(int days) {
    if (wirdUnit == KhatmahWirdUnit.pages) return days * targetPagesPerDay;
    final unreadByJuz = <int, int>{};
    for (final page in readingOrder(startPage)) {
      if (completedPages.contains(page)) continue;
      final juz = MushafJuzTable.juzOf(page);
      unreadByJuz[juz] = (unreadByJuz[juz] ?? 0) + 1;
    }
    return unreadByJuz.values.take(days).fold(0, (sum, pages) => sum + pages);
  }
```

(`readingOrder` visits juz in reading order, and a `Map` literal keeps insertion order, so `take(days)` takes the next juz in order.) Import `../../../../core/utils/mushaf_juz_table.dart`.

Model: `final String wirdUnit;` default `'pages'`; json key `wirdUnit`; `toEntity`: `KhatmahWirdUnit.values.where((u) => u.name == wirdUnit).firstOrNull ?? KhatmahWirdUnit.pages`.

- [ ] **Step 5: Setup** — `createPlan` gains `KhatmahWirdUnit wirdUnit = KhatmahWirdUnit.pages` and passes it to `KhatmahPlan`. Setup page: `_onSubmit` passes `wirdUnit: _selectedDays == 30 ? KhatmahWirdUnit.juz : KhatmahWirdUnit.pages`. Cubit test: `createPlan(pagesPerDay: 21, targetDays: 30, wirdUnit: KhatmahWirdUnit.juz)` creates a juz plan ending 30 days later.

- [ ] **Step 6: Adjustments in juz mode** — in `KhatmahCubit`:
  - `canBoost`: add `&& plan.wirdUnit == KhatmahWirdUnit.pages`.
  - `previewAdjustment`: `KhatmahAdjustment.keepEndDate => plan.wirdUnit == KhatmahWirdUnit.juz ? null : _keepEndDateTransform(plan)`.
  - `applyAdjustment(keepEndDate)`: return `Future.value(false)` when the preview is null.
  - `_calmTransform`: `final days = plan.remainingWirdDays;` (same result for pages mode).
  - Test: juz plan → `previewAdjustment(keepEndDate) == null`, `canBoost == false`, calm preview end date = today + remainingJuzCount − 1.

- [ ] **Step 7: Dashboard** — hide the mild-boost button when `plan.wirdUnit == KhatmahWirdUnit.juz` (wrap its `Expanded` in `if (plan.wirdUnit == KhatmahWirdUnit.pages) ...[ ... ]` together with its preceding `SizedBox`), and in the wird card replace the `khatmahPagesTo(...)` line with `khatmahWirdJuz(<localized juz of wirdStartPage>)` + the page range when in juz mode. Regenerate l10n.

- [ ] **Step 8: Verify** — `flutter test test/features/khatmah test/core/utils`.

- [ ] **Step 9: Checkpoint** — analyze edited files; `dart format` only `mushaf_juz_table.dart`.

---

### Task 9: Ahead-of-schedule projection (S2)

**Files:**
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart` (`projectedEndDate`, `daysAhead`)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (`_PaceLine`)
- Modify: ARB: `khatmahPaceAhead` "متقدم — ستختم قبل موعدك ب{count, plural, =1{يوم واحد} =2{يومين} few{{countText} أيام} other{{countText} يوماً}}" / "Ahead — you'll finish {count, plural, =1{a day} other{{countText} days}} early"
- Test: `khatmah_plan_test.dart`, `khatmah_dashboard_page_test.dart`

**Interfaces:**
- Consumes: `remainingWirdDays` (Task 8).
- Produces: `DateTime KhatmahPlan.projectedEndDate(DateTime today)`; `int KhatmahPlan.daysAhead(DateTime today)`.

- [ ] **Step 1: Failing tests**

```dart
test('projection counts from tomorrow once today is done', () {
  final plan = KhatmahPlan(
    id: 'p', title: KhatmahPlan.defaultTitle,
    completedPages: {for (var p = 1; p <= 20; p++) p},
    targetPagesPerDay: 5, targetDays: 121,
    startDate: DateTime(2026, 1, 1), expectedEndDate: DateTime(2026, 5, 1),
    dailyTargetDate: DateTime(2026, 1, 1), dailyTargetStartPage: 1, dailyTargetEndPage: 5,
  );
  final today = DateTime(2026, 1, 1, 20);
  // 584 pages / 5 = 117 days starting 2026-01-02 → ends 2026-04-28.
  expect(plan.projectedEndDate(today), DateTime(2026, 4, 28));
  expect(plan.daysAhead(today), 3);
});

test('never negative', () {
  final plan = KhatmahPlan(
    id: 'p', title: KhatmahPlan.defaultTitle, targetPagesPerDay: 5, targetDays: 121,
    startDate: DateTime(2026, 1, 1), expectedEndDate: DateTime(2026, 1, 10),
  );
  expect(plan.daysAhead(DateTime(2026, 1, 1)), 0);
});
```

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

```dart
  /// Finish date if the learner keeps the plan's pace from the next wird day.
  DateTime projectedEndDate(DateTime today) {
    final first = KhatmahSchedulingEngine.localDate(today);
    final start = isDailyTargetComplete(today)
        ? DateTime(first.year, first.month, first.day + 1)
        : first;
    return KhatmahSchedulingEngine.calculateEndDate(start, remainingWirdDays);
  }

  /// Whole days the projection beats the planned finish date; 0 otherwise.
  int daysAhead(DateTime today) {
    final planned = KhatmahSchedulingEngine.localDate(expectedEndDate);
    final projected = projectedEndDate(today);
    final diff = DateTime.utc(planned.year, planned.month, planned.day)
        .difference(DateTime.utc(projected.year, projected.month, projected.day))
        .inDays;
    return diff > 0 ? diff : 0;
  }
```

- [ ] **Step 4: PaceLine** — add `required this.ahead` (int). When `behind == 0 && ahead > 0` show `khatmahPaceAhead(ahead, localized)` with `Icons.trending_up_rounded` in `AppColors.success`; otherwise unchanged. Pass `ahead: plan.daysAhead(_cubit.displayDate)` at the call site. Widget test: a plan 3 days ahead shows the ahead text.

- [ ] **Step 5: Verify** + **Checkpoint** (analyze).

---

### Task 10: Catch-up sheet with previews (S3)

**Files:**
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (`_PaceLine.onRedistribute` → opens sheet; new private `_showCatchUpSheet`)
- Modify: ARB: `khatmahCatchUpTitle` "كيف تحب أن تعوّض؟" / "How would you like to catch up?", `khatmahCatchUpOption` "{pages} صفحة يومياً — الختم {date}" / "{pages} pages a day — finish {date}" (`pages: String, date: String`)
- Test: `khatmah_dashboard_page_test.dart`

**Interfaces:**
- Consumes: `KhatmahCubit.previewAdjustment`, `_adjust(KhatmahAdjustment)` (existing).

- [ ] **Step 1: Failing widget test** — with a behind plan (pages mode), tap `khatmah_dashboard_redistribute_button` → a bottom sheet with three `ListTile`s keyed `khatmah_catchup_calm`, `khatmah_catchup_mildBoost`, `khatmah_catchup_keepEndDate`, each subtitle containing the preview's pace; tapping `khatmah_catchup_calm` shows the existing preview dialog (`khatmah_adjust_preview`). For a juz plan only `khatmah_catchup_calm` exists.

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement**

```dart
  Future<void> _showCatchUpSheet() async {
    final choice = await showModalBottomSheet<KhatmahAdjustment>(
      context: context,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        String number(int v) => sheetContext.isArabic
            ? MushafHizbHelper.toArabicNumber(v)
            : '$v';
        final options = [
          for (final kind in KhatmahAdjustment.values)
            if (_cubit.previewAdjustment(kind: kind) case final preview?)
              (kind: kind, preview: preview),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(l10n.khatmahCatchUpTitle, style: AppTypography.titleMedium),
              ),
              for (final option in options)
                ListTile(
                  key: Key('khatmah_catchup_${option.kind.name}'),
                  title: Text(switch (option.kind) {
                    KhatmahAdjustment.calm => l10n.khatmahCalmAdjust,
                    KhatmahAdjustment.mildBoost => l10n.khatmahMildBoost,
                    KhatmahAdjustment.keepEndDate => l10n.khatmahRedistributeAction,
                  }),
                  subtitle: Text(l10n.khatmahCatchUpOption(
                    number(option.preview.targetPagesPerDay),
                    _formatDate(option.preview.expectedEndDate),
                  )),
                  onTap: () => Navigator.pop(sheetContext, option.kind),
                ),
            ],
          ),
        );
      },
    );
    if (choice != null && mounted) await _adjust(choice);
  }
```

Wire `_PaceLine(onRedistribute: _adjusting ? null : _showCatchUpSheet)`. The existing calm/boost buttons stay (direct access for users who already know them).

- [ ] **Step 4: Verify** + **Checkpoint**.

---

### Task 11: Juz map on the dashboard (S4)

**Files:**
- Create: `lib/features/khatmah/presentation/widgets/khatmah_juz_map.dart`
- Modify: `lib/features/khatmah/domain/entities/khatmah_plan.dart` (`juzProgress`, `firstUnreadPageInJuz`)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart` (insert map after the wird card)
- Modify: ARB: `khatmahJuzMapTitle` "خريطة الختمة" / "Khatmah map", `khatmahJuzMapCell` "الجزء {juz}: {read} من {total} صفحة" / "Juz {juz}: {read} of {total} pages" (all `String`)
- Test: `khatmah_plan_test.dart`, `test/features/khatmah/presentation/widgets/khatmah_juz_map_test.dart` (create)

**Interfaces:**
- Consumes: `MushafJuzTable` (Task 8).
- Produces: `({int read, int total}) KhatmahPlan.juzProgress(int juz)`; `int KhatmahPlan.firstUnreadPageInJuz(int juz)` (juz start page when fully read); `KhatmahJuzMap({required KhatmahPlan plan, required ValueChanged<int> onOpenPage, bool enabled = true})`.

- [ ] **Step 1: Failing tests**

```dart
test('juz progress and first unread page', () {
  final plan = KhatmahPlan(
    id: 'p', title: KhatmahPlan.defaultTitle,
    completedPages: {for (var p = 1; p <= 21; p++) p, 22, 30},
    targetPagesPerDay: 5, targetDays: 121,
    startDate: DateTime(2026, 1, 1), expectedEndDate: DateTime(2026, 5, 1),
  );
  expect(plan.juzProgress(1), (read: 21, total: 21));
  expect(plan.juzProgress(2), (read: 2, total: 20));
  expect(plan.firstUnreadPageInJuz(2), 23);
  expect(plan.firstUnreadPageInJuz(1), 1);
});
```

Widget test: pump `KhatmahJuzMap` for the plan above; 30 cells; tapping cell 2 (`Key('khatmah_juz_cell_2')`) calls `onOpenPage(23)`; `enabled: false` → tap does nothing; the semantics label of cell 1 contains "21".

- [ ] **Step 2: Run** → FAIL.

- [ ] **Step 3: Implement entity helpers**

```dart
  ({int read, int total}) juzProgress(int juz) {
    final range = MushafJuzTable.range(juz);
    var read = 0;
    for (var page = range.start; page <= range.end; page++) {
      if (completedPages.contains(page)) read++;
    }
    return (read: read, total: range.end - range.start + 1);
  }

  int firstUnreadPageInJuz(int juz) {
    final range = MushafJuzTable.range(juz);
    for (var page = range.start; page <= range.end; page++) {
      if (!completedPages.contains(page)) return page;
    }
    return range.start;
  }
```

- [ ] **Step 4: Widget** (`dart format` it):

```dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/mushaf_hizb_helper.dart';
import '../../domain/entities/khatmah_plan.dart';

/// Thirty juz cells filled by the share of pages already read.
class KhatmahJuzMap extends StatelessWidget {
  const KhatmahJuzMap({
    super.key,
    required this.plan,
    required this.onOpenPage,
    this.enabled = true,
  });

  final KhatmahPlan plan;
  final ValueChanged<int> onOpenPage;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = context.tokens.accent;
    String number(int v) =>
        context.isArabic ? MushafHizbHelper.toArabicNumber(v) : '$v';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.l10n.khatmahJuzMapTitle, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.xs,
          crossAxisSpacing: AppSpacing.xs,
          children: [
            for (var juz = 1; juz <= 30; juz++)
              Builder(
                builder: (context) {
                  final progress = plan.juzProgress(juz);
                  final share = progress.read / progress.total;
                  final done = progress.read == progress.total;
                  return Semantics(
                    button: enabled,
                    label: context.l10n.khatmahJuzMapCell(
                      number(juz),
                      number(progress.read),
                      number(progress.total),
                    ),
                    excludeSemantics: true,
                    child: InkWell(
                      key: Key('khatmah_juz_cell_$juz'),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      onTap: enabled
                          ? () => onOpenPage(plan.firstUnreadPageInJuz(juz))
                          : null,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(color: accent.withValues(alpha: 0.3)),
                          color: accent.withValues(alpha: 0.08 + 0.6 * share),
                        ),
                        child: done
                            ? Icon(Icons.check_rounded, size: 16, color: context.tokens.textPrimary)
                            : Text(number(juz), style: AppTypography.labelSmall),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
```

(If `AppSpacing.radiusSm` does not exist, use `AppSpacing.radiusMd`.) Contrast: the digit sits on at most `0.68` alpha accent — verify it stays readable in dark theme in the widget test by pumping with the dark theme once (no crash) and by eye during manual QA.

- [ ] **Step 5: Dashboard** — after the wird card:

```dart
                    const SizedBox(height: AppSpacing.md),
                    KhatmahJuzMap(
                      plan: plan,
                      enabled: plan.status == KhatmahStatus.active,
                      onOpenPage: (page) =>
                          context.push('/quran/page/$page?mode=khatmah'),
                    ),
```

- [ ] **Step 6: Verify** + **Checkpoint**.

---

### Task 12: "Same settings" restart and history stats (S5)

**Files:**
- Create: `lib/features/khatmah/presentation/khatmah_setup_prefill.dart`
- Create: `lib/features/khatmah/domain/entities/khatmah_history_stats.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_setup_page.dart` (optional `prefill`)
- Modify: `lib/core/router/app_router.dart` (pass `state.extra` to setup)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_completion_page.dart` (new button)
- Modify: `lib/features/khatmah/presentation/pages/khatmah_history_page.dart` (stats header)
- Modify: ARB: `khatmahRepeatSameSettings` "ختمة جديدة بنفس الإعدادات" / "New khatmah, same settings"; `khatmahHistoryStats` "{count} ختمات • المتوسط {avg} يوماً • الأسرع {fastest} يوماً" / "{count} khatmahs • average {avg} days • fastest {fastest} days" (all `String`)
- Test: `test/features/khatmah/domain/entities/khatmah_history_stats_test.dart` (create), setup page test, completion page test, history page test

**Interfaces:**
- Produces: `class KhatmahSetupPrefill { final int pagesPerDay; final int? targetDays; final KhatmahWirdUnit wirdUnit; factory KhatmahSetupPrefill.fromPlan(KhatmahPlan) }`; `KhatmahSetupPage({KhatmahSetupCubit? cubit, KhatmahSetupPrefill? prefill})`; `KhatmahHistoryStats? KhatmahHistoryStats.from(List<KhatmahHistoryEntry>)` (null when < 2 entries) with `count`, `averageDays`, `fastestDays`.

- [ ] **Step 1: Failing stats test**

```dart
test('stats need at least two completions', () {
  KhatmahHistoryEntry e(int days) => KhatmahHistoryEntry(
    id: '$days', khatmahNumber: 1, title: 't',
    startDate: DateTime(2026, 1, 1), completedDate: DateTime(2026, 1, days),
    totalDays: days,
  );
  expect(KhatmahHistoryStats.from([e(30)]), isNull);
  final stats = KhatmahHistoryStats.from([e(30), e(20), e(25)])!;
  expect(stats.count, 3);
  expect(stats.averageDays, 25);
  expect(stats.fastestDays, 20);
});
```

- [ ] **Step 2: Implement stats** (pure Dart, `dart format`):

```dart
import 'khatmah_history_entry.dart';

class KhatmahHistoryStats {
  const KhatmahHistoryStats({
    required this.count,
    required this.averageDays,
    required this.fastestDays,
  });

  final int count;
  final int averageDays;
  final int fastestDays;

  /// Null below two completions (D12).
  static KhatmahHistoryStats? from(List<KhatmahHistoryEntry> entries) {
    if (entries.length < 2) return null;
    final days = entries.map((e) => e.totalDays).toList();
    final total = days.fold(0, (sum, d) => sum + d);
    return KhatmahHistoryStats(
      count: entries.length,
      averageDays: (total / entries.length).round(),
      fastestDays: days.reduce((a, b) => a < b ? a : b),
    );
  }
}
```

- [ ] **Step 3: Prefill** (`dart format`):

```dart
import '../domain/entities/khatmah_plan.dart';

/// Setup choices carried from a finished khatmah (D11: no dedication).
class KhatmahSetupPrefill {
  const KhatmahSetupPrefill({
    required this.pagesPerDay,
    this.targetDays,
    this.wirdUnit = KhatmahWirdUnit.pages,
  });

  factory KhatmahSetupPrefill.fromPlan(KhatmahPlan plan) =>
      plan.wirdUnit == KhatmahWirdUnit.juz
          ? const KhatmahSetupPrefill(
              pagesPerDay: 21,
              targetDays: 30,
              wirdUnit: KhatmahWirdUnit.juz,
            )
          : KhatmahSetupPrefill(pagesPerDay: plan.targetPagesPerDay);

  final int pagesPerDay;
  final int? targetDays;
  final KhatmahWirdUnit wirdUnit;
}
```

Setup page: add `this.prefill` to the widget; in `initState` after cubit resolution:

```dart
    final prefill = widget.prefill;
    if (prefill != null) {
      _selectedPages = prefill.pagesPerDay;
      _selectedDays = prefill.targetDays;
      if (prefill.targetDays == null && !_presets.contains(prefill.pagesPerDay)) {
        _customController.text = '${prefill.pagesPerDay}';
      }
    }
```

Router: `builder: (context, state) => KhatmahSetupPage(prefill: state.extra is KhatmahSetupPrefill ? state.extra as KhatmahSetupPrefill : null),` (drop `const`).

Completion page: above the existing new-khatmah button add

```dart
                  FilledButton.icon(
                    key: const Key('khatmah_completion_repeat_button'),
                    onPressed: () => context.go(
                      AppRoutes.khatmahSetup,
                      extra: KhatmahSetupPrefill.fromPlan(plan),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(context.l10n.khatmahRepeatSameSettings),
                  ),
                  const SizedBox(height: AppSpacing.sm),
```

(match the surrounding button styling of `khatmah_completion_new_khatmah_button`).

History page: in `_HistoryList.build`, when `KhatmahHistoryStats.from(entries)` is non-null, render a first `Card` (key `khatmah_history_stats`) with `khatmahHistoryStats(...)` using localized numbers; shift item indices by one (same technique as `hasWarning`).

- [ ] **Step 4: Widget tests** — setup page with `prefill: KhatmahSetupPrefill(pagesPerDay: 7)` submits `pagesPerDay: 7`; completion page shows `khatmah_completion_repeat_button`; history page with 2 entries shows `khatmah_history_stats`, with 1 entry does not.

- [ ] **Step 5: Verify** + **Checkpoint**.

---

### Task 13: Full verification

- [ ] `flutter gen-l10n`
- [ ] `flutter analyze` → no new issues vs. baseline (compare against `git stash`-free baseline by running analyze on the edited file list; the full-tree run must show no issue in any edited file).
- [ ] `flutter test test/features/khatmah test/core test/features/certificate test/features/home test/features/quran test/assets test/integration`
- [ ] `flutter test` (full suite).
- [ ] `git diff --stat` — confirm no formatting noise in files that were only surgically edited.
- [ ] Manual QA checklist for the owner (run on device): Ramadan plan wird card shows "الجزء ١"; dedication to "الأم" shows no masculine dua; reminder after finishing today's wird does not fire today; juz map taps open the right page.

---

## Deferred (need their own spec)

| Item | Why deferred | Next step |
|------|--------------|-----------|
| Feminine/plural dedication dua **texts** | Religious content: must come verbatim from a reviewed source | Owner/scholar supplies `alive_female`, `deceased_female`, `sick_female` values with source + review evidence; code already reads them |
| Group / family khatmah (juz assignment) | New Supabase tables, RLS, RPCs, invites, contract checks | Brainstorm → spec → migration plan |
| Khatmah cloud sync & backup | Same sync architecture as `*_cloud_merge.dart`; migrations + contract | Spec after group khatmah design (shared tables) |
| Prayer-anchored / learned reminder time | Needs settings UI + prayer-time per day in the policy | Extend `KhatmahReminderPolicy.slots` with a per-day time resolver |
| Multiple recipients per khatmah | Model + certificate + dua composition changes | Spec with D1/D2 generalised to a list |
| Rub'/hizb "natural stop" snapping | Page-based progress cannot represent mid-page boundaries (D10) | Only if ayah-level progress is introduced |
| Dead code removal | D13 | Separate cleanup task |
