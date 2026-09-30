# Azkar & Duas: review and improvement design

Date: 2026-09-29
Status: draft, awaiting owner review
Scope: `lib/features/azkar/`, its use of `AzkarTimeContext`, and the tests around it.

## 1. Intent

The owner wants the Azkar and Duas feature reviewed, improved for the user, and confirmed to work
without problems. The owner chose to cover stability, reading experience, and the duas library,
in that order, in one program of three deliverable phases.

Success means:
- Morning and evening azkar are chosen consistently everywhere (hub, smart wird, reminders).
- No user sees the same du'a twice, and nobody loses a favorite because of it.
- The reading screen is easier to navigate and use on small phones.
- Dead or half-wired features are either connected or removed.
- New tests fail if any of the above regress, and the existing 69 azkar/khatm-dua tests stay green.

Baseline before any change: `flutter test test/features/azkar test/core/content
test/features/khatmah/presentation/pages/khatm_dua_page_test.dart` passes (69 tests) and
`flutter analyze lib/features/azkar lib/core/content` is clean.

## 2. Constraints

- Islamic content policy (`docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`) applies. No text is
  added, edited, translated, or re-normalized in `assets/data/azkar_release.json`. Every
  improvement here works on presentation, ordering, and logic only.
- The release file stays byte-identical. Its sha256 in `content_manifest.json` must not change.
- The working tree holds the owner's uncommitted work, including `notification_service.dart`,
  `app_router.dart` and `injection.dart`. Edits to those files are limited to the minimum wiring
  needed and are listed in section 8.
- Format only the files edited here, never whole directories.
- New user-facing strings go into both `app_ar.arb` and `app_en.arb`, then `flutter gen-l10n`.
  Those ARB files are already modified in the tree, so only my keys are added.

## 3. Verified findings

Checked against the code and data on 2026-09-29. "Verified" means read in source or computed from
the release file; nothing here was observed on a device.

| # | Finding | Evidence |
|---|---|---|
| F1 | Five duas are stored twice (same text after diacritic normalization): `dq1`/`dua_quran_1`, `dq2`/`dua_quran_2`, `dp1`/`dua_prophet_1`, `dp2`/`dua_prophet_2`, `dp6`/`dua_prophet_3`. Both copies appear in the duas library. | Normalized-text comparison over `azkar_release.json`. |
| F2 | Period is decided two ways. `AzkarTimeContext.resolvePeriod` returns evening from 15:30. `ComposeSmartWirdUsecase` uses `periodOfDayPart`, which maps the `afternoon` day part (15:00 to 19:00) to morning. Between 15:30 and 19:00 the hub says evening and the smart wird serves morning azkar. | `azkar_time_context.dart`, `compose_smart_wird_usecase.dart`. |
| F3 | The reading-screen index shows `reference` as each row title. In the morning set, 17 of 22 rows are titled with a bare collection name (for example "سنن أبي داود" five times), so rows are indistinguishable. | `_openIndexSheet` in `azkar_category_page.dart`, data references. |
| F4 | Dead paths: no record has `timeHint`, `tier`, or `audioUrl`, so `timeHint` ordering in the smart wird never applies and the audio button is never shown. `AzkarPreferencesStore.quietNight` is stored and never read. | Field counts in release file; `grep quietNight`. |
| F5 | Audio play/pause icon reads `_audioService.state` inside a builder that only rebuilds on font-scale change, and no page registers `addListener`. Latent, because audio is never shown today. | `azkar_category_page.dart`, `smart_wird_page.dart`. |
| F6 | Favorites are keyed by record id. Removing or hiding one copy of a duplicate would strand a saved favorite. | `AzkarPreferencesStore.toggleFavorite`. |
| F7 | The smart wird appends all 38 general azkar, including situational ones (toilet, rain, wind, food, travel, illness), to a morning or evening wird. | `_compose` step 2 in `compose_smart_wird_usecase.dart`. |
| F8 | Smart-wird resume compares the fine `dayPart`. A user who starts at 09:50 and returns at 10:05 (`afterFajr` becomes `morning`) loses saved progress. | `saved.dayPart == wird.dayPart` in `smart_wird_page.dart`. |
| F9 | In the smart wird, tapping a row in the index sheet only sets `_currentCard`; the `PageView` is never moved, so navigation does nothing. | `_openIndexSheet` in `smart_wird_page.dart`. |
| F10 | The duas/general library card hard-codes Arabic favorite tooltips, passes `isDua: false` to the share card even for duas, and copies only the text (the reader also copies the reference and footer). | `_ZikrCard` in `general_azkar_page.dart`. |

Corrected during verification:
- All records with `sourceType: quran` match `quran.json` after removing diacritics and script
  variants. The only apparent mismatch (Ayat al-Kursi) came from a tatweel in the corpus text. No
  wrong Quran text was found. The script differs (Uthmani versus plain) between some records; that is
  a presentation-consistency matter, not a correctness error, and is left alone here.
- `dq4` (Ta-Ha 25:28) and `dua_quran_3` (Ta-Ha 25-26) cover different ranges. They are not
  duplicates and both stay.

## 4. Phase 1: stability and correctness

### 4.1 One period resolver (F2)

Add `AzkarPeriodResolver` in `lib/features/azkar/domain/services/`, pure Dart, constructed with an
optional prayer-times snapshot value:

```
AzkarPeriod resolve(DateTime now, {AzkarPrayerWindow? window})
```

- `AzkarPrayerWindow` is a small value holding `fajr` and `asr` for the day.
- With a window: morning is `[fajr, asr)`, evening is everything else. There is no gap.
- Without a window (prayer times disabled, no city, or lookup failed): the current fixed rule
  (04:00 to 15:30 morning), unchanged. This keeps behavior identical for users without a city.
- Boundaries are product ordering, not a religious ruling, as `AzkarTimeContext` already states.

Callers switch to it: `AzkarHubCubit` and `ComposeSmartWirdUsecase`. Reminders do not decide a
period (they fire at user-chosen times), so `notification_scheduler.dart` is not touched.
`AzkarDayPart` stays for sleep-first ordering at night only. `periodOfDayPart` is removed so a
second rule cannot come back. `SmartWird` gains a `period` field, and a saved smart-wird session
records its `period` so resume compares periods instead of day parts (F8).

The window is read from `PrayerTimesService.current`, already registered in DI. The resolver never
throws; any failure yields the fixed rule.

### 4.2 Duplicate-safe library (F1, F6), option A

The release file is not touched. Duplicates are hidden in the presentation layer.

- `AzkarDedupe` (domain service, pure): groups records inside one category by normalized text using
  `ArabicNormalizer` (already used by search). The canonical record is the first in dataset order;
  the others become aliases.
- The duas page and any list built from `state.sessions` render canonical records only.
- Favorites: `isFavorite(id)` is true if the canonical id or any alias id is saved.
  `toggleFavorite` writes the canonical id and removes alias ids. A one-time in-memory read fix, not
  a stored-data migration, so existing saved sets keep working and downgrade is safe.
- Counts shown on the hub use the deduplicated number.
- A contract test asserts that the set of hidden ids equals the five verified pairs today, so a
  future data change that adds or removes duplicates is noticed.

### 4.3 Dead code (F4, F5)

- Remove `timeHint` ordering from `ComposeSmartWirdUsecase` and the unused optional fields
  (`audioUrl`, `timeHint`, `tier` presentation) only where nothing reads them. The parsing in
  `ZikrModel` stays tolerant of these fields so a future approved dataset can carry them without a
  code change; the release file is not edited.
- The audio button and `ZikrAudioService` wiring stay in place but hidden when no `audioUrl`, as today.
  F5 is fixed by subscribing the icon to service state with a `ListenableBuilder`-style wrapper, so
  the feature is correct if audio data is ever approved.
- `quietNight` is left untouched. Its strings ("Quiet Night: flowing reading, no counter") show it
  was planned as a reading mode without a counter, never built. Building it changes what counts as
  completing a wird, which is a product decision, so it is reported, not implemented (see section 9).

### 4.4 Safety tests

- New test in `test/assets/`: every `sourceType: quran` record in `azkar_release.json` is contained
  in `quran.json` after a consonant-skeleton comparison that ignores tatweel and script variants.
  It reports the record id on failure and never rewrites text.
- Resolver tests: with and without a prayer window, exactly at fajr, asr, midnight rollover, and
  the two cases that disagreed before (16:00 and 18:30).
- Store tests: day rollover while the page is open, corrupt stored values, two accounts on one
  device keep separate counters if the store is owner-scoped today (verify before adding).

Phase 1 exit: baseline suite plus new tests green, analyzer clean on touched files.

## 5. Phase 2: reading experience

- Index sheet row title becomes the first 40 characters of the zikr text (display text, not
  normalized), with the reference as subtitle. Text is truncated for display only.
- Rows for unfinished azkar are visually distinct from finished ones; the current row scrolls into
  view when the sheet opens.
- Header: on width below 360 dp, the five icon buttons collapse into the font-size button plus an
  overflow menu (auto-advance, index) so the title is never squeezed to zero.
- Completion screen: keep the undo action reachable for a few seconds after the final tap (today the
  screen switches immediately and undo is unreachable).
- Smart wird page shares the same index sheet, and tapping a row now moves the `PageView` (F9).
- Smart wird selection (F7): situational general azkar (toilet, mosque, home, food, distress, rain,
  travel, illness, gathering, wind, anger, clothing, ruqyah) are left out of the composed wird and
  stay reachable in the general azkar page. Sleep azkar join only in the evening period, waking azkar
  only in the morning period. Records with an empty subcategory are kept. This only selects and orders
  existing records; no text changes.

## 6. Phase 3: duas library

- Category chips show a per-chip count.
- Card fixes (F10): localized favorite tooltips, `isDua` follows the page category, and copy uses the
  same text as the reader (text, reference, footer) through one shared helper.
- Already present, so not built: search over text, reference, subcategory, transliteration and
  translation; the empty-search state with a clear button; the favorites empty state.
- Dropped: highlighting the search match (splitting Arabic words across text spans can break letter
  joining) and a grade badge (no record carries a grade, so it would never show).

## 7. Testing strategy

Test-first for the resolver, dedupe, favorites merge, and quran contract. Widget tests for the index
row text, small-width header, undo-after-completion, and the dedupe-aware library. Existing tests
that assert old behavior (for example counts of 34 duas) are updated in the same change with the
reason recorded in the commit message.

Final gate per phase: `flutter analyze` on touched paths, the azkar/khatm-dua test set, and
`flutter test test/assets`. Before release, the full `scripts/verify_v1_release.ps1` is the owner's
call; this program does not run it unasked.

## 8. Files touched outside `lib/features/azkar/`

- `lib/core/di/injection.dart`: register `AzkarPeriodResolver` and pass the prayer window supplier to
  `AzkarHubCubit`. A few lines near the existing azkar registrations.
- `lib/core/l10n/app_ar.arb`, `app_en.arb` and generated localization files: new strings only.
- `lib/core/services/notification_scheduler.dart`: only if the reminder chooser has its own
  period rule; checked in phase 1 and reported before editing.
- Tests under `test/features/azkar/` and `test/assets/`.

## 9. Out of scope

Adding new azkar or duas, changing any religious text or reference, audio recitations,
translations, scholarly grading, the khatm-dua screen, and the "Quiet Night" reading mode.

## 10. Open items for the owner

Not blocking; recorded for a later decision:
1. **Quiet Night mode:** should reading without a counter count toward completing the wird? Until
   answered it stays unbuilt.
2. **XP for the smart wird** is keyed by day part, so one morning can award up to three times
   (`afterFajr`, `morning`, `forenoon`). Left as is; it is an XP-economy choice, not a defect in this
   feature.

Choices made on the owner's behalf, recorded for reversal:
1. Period uses Fajr and Asr when a city is set; otherwise the existing fixed hours.
2. The smart-wird selection rule in section 5.
