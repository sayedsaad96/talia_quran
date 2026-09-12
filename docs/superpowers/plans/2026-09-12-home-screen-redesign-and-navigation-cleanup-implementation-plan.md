# Home Screen Redesign & Navigation Cleanup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make "أكمل تلاوتك" strictly Khatmah-gated with an inviting start-Khatmah card in its place, eliminate all accidental `/progress` redirections, give every action tile and activity row a purposeful direct destination, and make the prayer chip an interactive six-prayer sheet.

**Spec:** `docs/superpowers/specs/2026-09-12-home-screen-redesign-and-navigation-cleanup-design.md` (Revised, incl. the six 2026-09-12 punch-list amendments)

**Architecture:** Correction pass over existing surfaces — no new features. One pure resolver joins the domain layer (`HomePrimaryActionResolver`); `PrayerTimesSnapshot` gains six fields; three presentation widgets are new (`HomeStartKhatmahCard`, `HomeAchievementSheet`, `HomePrayerTimesSheet`); the rest are surgical edits to existing widgets/cubit. `UnifiedJourneyEngine` and `JourneyFeatureFlags.unifiedJourneyEnabled` (default `true`) are untouched; the legacy flag-off card chain keeps working.

**Tech Stack:** Flutter/Dart, go_router, flutter_bloc, existing `adhan`-based `PrayerTimesService`, existing `XpService` level model. No new dependencies.

---

## Global Constraints

- **Localization:** Every new user-visible string goes into BOTH `lib/core/l10n/app_ar.arb` and `app_en.arb`, camelCase keys. Zero hardcoded Arabic in Dart.
- **Tokens:** Colors from `AppColors.*` / `HomeSkin.*`, spacing from `AppSpacing.*`, type from `AppTypography.*`. No inline hex.
- **A11y:** Every new tap target gets `Semantics(button: true, label: ...)`. Sheets dismissible via barrier tap and back. Respect `MediaQuery.disableAnimationsOf` in the prayer sheet stagger.
- **RTL/Arabic-first:** Prayer times render 12-hour with `ص/م` in Arabic, `AM/PM` in English (mirror `HomePrayerChip._formattedTime`).
- **Flag safety:** The flag-off path must keep `ResumeSessionCard`/`NextBestActionCard` working — `smart_coach_home_validation_test.dart` and `responsive_home_widgets_test.dart` must keep passing unmodified.
- **Cadence:** `dart analyze` clean after every task; `flutter test test/features/home` after Tasks 2, 3, 4, 5, 6, 8, 9; full `flutter test` at the end.

---

### Task 1: `PrayerTimesSnapshot` — expose all six times (core service)

**Files:**
- Modify: `lib/core/services/prayer_times_service.dart`
- Modify: `test/core/services/prayer_times_service_test.dart`

**Interfaces:**
- Produces: `PrayerTimesSnapshot` gains six `final DateTime` fields: `fajr, sunrise, dhuhr, asr, maghrib, isha`. Existing `nextName/nextTime/minutesUntil` fields and all public methods unchanged, so existing call sites compile untouched.
- Note: `PrayerTimesSnapshot` is constructed in exactly one lib site — `current()` in the same file — plus tests (verify with `grep -rn "PrayerTimesSnapshot(" lib test`).

- [ ] **Step 1: Extend the snapshot class.** Add the six nullable `DateTime` fields as named optional constructor params with doc comments ("computed times for the selected city/date").
- [ ] **Step 2: Populate them in `current()`.** The `upcoming` list already computes `times.fajr … times.isha`; fill all six fields when constructing the snapshot.
- [ ] **Step 3: Unit tests.** Enabled + known city → all six non-null and ordered `fajr < sunrise < dhuhr < asr < maghrib < isha`, all on the computation date. `nextName/nextTime/minutesUntil` semantics unchanged (next = first time after `now`; wrap to tomorrow's fajr after isha). Disabled → `current()` still returns null.

---

### Task 2: `ContinueRecitationMapper` — strict Khatmah gating

**Files:**
- Modify: `lib/features/home/domain/services/continue_recitation_mapper.dart`
- Modify: `test/features/home/domain/services/continue_recitation_mapper_test.dart`

**Interfaces:**
- Produces: `map(...)` returns non-null **only** when `activeKhatmah != null && activeKhatmah.status == KhatmahStatus.active`; otherwise `null`. The `heroAction`, `lastRestorableLocation`, `dailyWirdPageDetail`, `confirmedReadPages` parameters stay in the signature for now (callers keep compiling) but no longer influence the result; a follow-up cleanup may drop them.

- [ ] **Step 1: Strip the fallback chain.** Delete from `map(...)`: the `hasOpenedMushaf` block, the `dailyWirdPageDetail != null` → `_fromPage` branch, and the trailing `confirmedReadPages`-based `ContinueRecitation(...)`. Delete the now-unused `_fromPage` and `_quranPageFrom` helpers. Keep `_fromKhatmah` exactly as is (route `/quran/page/${plan.nextUnreadPage}?mode=khatmah`). Update the class docstring, which currently promises "confirmed read pages or an active khatmah daily target" — it is now khatmah-only.
- [ ] **Step 2: Update the mapper tests.** Keep active-khatmah tests. Remove tests asserting `_fromPage`/`confirmedReadPages` outputs. Add regression tests per spec §4: random page opened (`lastRestorableLocation = '/quran/page/42'`, any confirmedReadPages, no khatmah) → `null`; `confirmedReadPages > 0` without khatmah → `null`; paused khatmah → `null`; completed khatmah → `null`.
- [ ] **Step 3: Verify knock-on behavior.** The only rendering site is `home_page.dart:233` (`continueRecitation != null → HomeContinueCard`); non-khatmah users now fall to the Task 3 resolver. Run `flutter test test/features/home`.

---

### Task 3: `HomePrimaryActionResolver` — pure hero-contract resolver (domain) + wiring

**Files:**
- Create: `lib/features/home/domain/services/home_primary_action_resolver.dart`
- Create: `test/features/home/domain/services/home_primary_action_resolver_test.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

**Interfaces:**
- Produces:

```dart
enum HomePrimaryActionKind { khatmahContinue, journeyHero, startKhatmah }

class HomePrimaryActionResolver {
  const HomePrimaryActionResolver();

  /// Pure decision for the home primary slot (spec §3.2 as amended).
  /// [heroPriority] must be null only when there is no hero action.
  HomePrimaryActionKind resolve({
    required bool unifiedJourneyEnabled,
    required bool hasContinueRecitation,
    required UnifiedJourneyPriority? heroPriority,
  }) {
    if (hasContinueRecitation) return HomePrimaryActionKind.khatmahContinue;
    final p = heroPriority;
    final hasLearningCritical =
        p != null && p.index <= UnifiedJourneyPriority.p4SmartPlan.index;
    if (unifiedJourneyEnabled && hasLearningCritical) {
      return HomePrimaryActionKind.journeyHero;
    }
    return HomePrimaryActionKind.startKhatmah;
  }
}
```

- `p.index <= p4SmartPlan.index` uses the enum's descending-priority ordering (`p1=0 … p6=5`) to mean p1–p4, per spec §3.2 as amended.
- Flag-off (`unifiedJourneyEnabled == false`): when there is no active khatmah, `_PrimaryAction` (not the resolver) keeps the legacy chain `lastRestorableLocation → ResumeSessionCard` / else `NextBestActionCard` — the flag-off behavior is a presentation concern, so the resolver stays three-valued and pure.

- [ ] **Step 1: Implement the resolver** exactly as above; no `BuildContext`, no DI, no service calls.
- [ ] **Step 2: Resolver tests** (`home_primary_action_resolver_test.dart`): hasContinueRecitation → `khatmahContinue` regardless of flag or hero priority; flag on + p1ActiveSession / p2CriticalAlert / p3ReviewBacklog / p4SmartPlan → `journeyHero`; flag on + p5DailyGoal / p6FreeExploration / null → `startKhatmah`; flag off + no continue → `startKhatmah` (the legacy chain is applied downstream in the widget).
- [ ] **Step 3: Wire into `home_page.dart`.** Rewrite `_PrimaryAction` (lines 398–432) to call the resolver once per build and switch on the kind:
  - `khatmahContinue` → `HomeContinueCard(recitation: state.continueRecitation!, skin: ...)`. Move this branch INTO `_PrimaryAction` and delete the outer ternary at line 233 (single decision point; do both edits in the same commit to avoid a double card).
  - `journeyHero` + flag on → the existing `HomeHeroSection` block (today's lines 407–421) moved verbatim, including `onMore` alternatives sheet.
  - `journeyHero` + flag off → legacy chain (today's lines 423–431) moved verbatim.
  - `startKhatmah` + flag off → legacy chain as above (flag-off users keep current behavior).
  - `startKhatmah` + flag on → `HomeStartKhatmahCard` (Task 5) in the hero slot.
- [ ] **Step 4: Start-Khatmah card below the journey hero.** When the kind is `journeyHero` (flag on) AND the user has no active khatmah, render `HomeStartKhatmahCard` in a second `SliverToBoxAdapter` immediately after the primary slot so the Khatmah invitation is still visible. Sliver ordering after this task: [primary slot] → [start-khatmah below hero, when journeyHero && no continueRecitation] → [contextual slot] → … rest unchanged. `HomeContinueCard` and `HomeStartKhatmahCard` are mutually exclusive.
- [ ] **Step 5: Run** `flutter test test/features/home` — the two legacy suites must pass unmodified.

---

### Task 4: `HomeActionTiles` — purposeful direct actions

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_action_tiles.dart`
- Create: `test/features/home/presentation/widgets/home_action_tiles_test.dart`

**Interfaces:**
- No public API change. Consumes existing `HomeLoaded` fields: `audioResume`, `ayahOfDay`, `lastRestorableLocation`. No cubit changes.

- [ ] **Step 1: Implement §3.5 per-tile behavior** in the `tiles` list construction (lines 30–57) and `onTap` (lines 58–66):
  - **استمع (Listen):** `audioResume != null` → existing body verbatim: `getIt<QuranContinuousPlayerService>().playAyah(audio.surahId, audio.ayahNumber, reciter: audio.reciter, scope: audio.scope)`. Else `ayahOfDay != null` → `playAyah(ayahOfDay.surahId, ayahOfDay.ayahNumber, scope: PlayScope.singleAyah)`. Else → `context.push(AppRoutes.quran)`.
  - **راجع (Review):** `context.push(AppRoutes.memorizationV2Session)` — unconditionally (replaces `TodayTask.review?.route ?? memorizationHub`).
  - **احفظ (Memorize):** `context.push(AppRoutes.hifzPracticeSurah)` — unconditionally.
  - **اقرأ (Read):** `lastRestorableLocation?.startsWith('/quran/page/') == true` → push it verbatim; else → `context.push(AppRoutes.quran)`.
- [ ] **Step 2: Keep the layout guard.** The `LayoutBuilder` single-column rule (`maxWidth < 300 || textScale > 1.3`) and the existing `Semantics(button: true, label: '$title. $hint')` stay exactly as is — this task changes destinations only, not copy or layout.
- [ ] **Step 3: Widget tests** (`home_action_tiles_test.dart`):
  - Listen + audioResume → no route pushed; fake `QuranContinuousPlayerService` (registered in getIt in test setup) receives the play call with `audioResume`'s surah/ayah.
  - Listen + ayahOfDay → play call with the ayah's surah/ayah, `PlayScope.singleAyah`.
  - Listen + neither → pushes `AppRoutes.quran`.
  - Review → `memorizationV2Session`; Memorize → `hifzPracticeSurah`.
  - Read + `/quran/page/42` → pushes that exact URI; Read + non-page location (e.g. `/hifz/…`) → pushes `AppRoutes.quran` (the guard rejects non-page locations).
  - Text scale 1.6 / narrow width → single-column layout still renders four tappable tiles.

---

### Task 5: `HomeStartKhatmahCard` — the no-khatmah invitation

**Files:**
- Create: `lib/features/home/presentation/widgets/home_start_khatmah_card.dart`
- Create: `test/features/home/presentation/widgets/home_start_khatmah_card_test.dart`
- Modify: `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb` (keys: `homeStartKhatmahTitle`, `homeStartKhatmahSubtitle`, `homeStartKhatmahCta`)

**Interfaces:**
- Produces: `HomeStartKhatmahCard({required HomeSkin skin, required bool isDark, VoidCallback? onStart})` — `onStart` defaults to `context.push(AppRoutes.khatmahSetup)`.

- [ ] **Step 1: Build the card.** `GlassPanel` matching `HomeSkin`; inviting Quranic icon (auto_stories); headline from `homeStartKhatmahTitle`; subtitle from `homeStartKhatmahSubtitle`; `AppButton` (core widget, high-emphasis) labeled `homeStartKhatmahCta` → `AppRoutes.khatmahSetup`. Whole panel tappable via `InkWell` (tap = same as CTA); `Semantics(button: true, label: headline)` on the panel.
- [ ] **Step 2: Text-scale resilience.** Wrap content in `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.4)` (mirroring `_TopRow` in `home_night_header.dart`) so the panel doesn't overflow at 1.6–2.0 scale.
- [ ] **Step 3: Widget tests.** Renders headline + CTA from arb values (test both locales via the l10n harness used in `home_night_goldens_test.dart`); CTA tap pushes `AppRoutes.khatmahSetup`; text scale 2.0 → no overflow exceptions; whole-panel tap triggers `onStart`.

---

### Task 6: `HomeAchievementSheet` + chip fallback replacement

**Files:**
- Create: `lib/features/home/presentation/widgets/home_achievement_sheet.dart`
- Modify: `lib/features/home/presentation/widgets/home_context_bar.dart` (`HomeAchievementChip` onTap fallback, line 247; add `totalXp` constructor param)
- Modify: `lib/features/home/presentation/widgets/home_night_header.dart` (pass `state.totalXp` into the chip — the chip's single construction site, line 31)
- Create: `test/features/home/presentation/widgets/home_achievement_sheet_test.dart`

**Interfaces:**
- Produces: `showHomeAchievementSheet(BuildContext context, {required OverallProgress progress, required int totalXp, required bool isKids})` — top-level show-function matching the codebase convention (`showHomeAlternativesSheet`).
- Consumes: `OverallProgress` (achievements: `isUnlocked`, category, `targetValue`/`currentValue` for badge progress); `totalXp` → level via `XpService.getCurrentLevel(totalXp)` and its exposed `progressToNextLevel` — do NOT re-derive thresholds from `XpConstants` in the widget (spec §3.7 as amended).

- [ ] **Step 1: Sheet scaffold.** `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, showDragHandle: true)` with the same container styling as the existing home alternatives sheet. Content scrollable (`SingleChildScrollView`).
- [ ] **Step 2: Level header.** Localized level name from `getCurrentLevel(totalXp)`, XP count `'${totalXp} ${context.l10n.xpLabel}'` (same pattern as `home_momentum_strip.dart:111`), and a `LinearProgressIndicator` bound to the service's progress-to-next-level value (verify its 0–1 normalization at implementation time; if it is not normalized, compute the fraction in a small domain helper — not in the widget).
- [ ] **Step 3: Badges list.** Reuse the chip's `_highest()` selection logic to pick the shown achievement per category; progress bars from `currentValue/targetValue`; locked badges muted; titles via `context.localizedAchievementTitle` (localization_helpers).
- [ ] **Step 4: Chip fallback swap.** In `HomeAchievementChip.onTap`: keep the certificate branch (push `AppRoutes.certificate`) verbatim; replace `context.go(AppRoutes.progress)` (line 247) with `showHomeAchievementSheet(context, progress: progress, totalXp: totalXp, isKids: isKids)`. Add `required this.totalXp` to the chip's constructor.
- [ ] **Step 5: Widget tests.** Level header shows the localized level title and XP count for a known XP (e.g. 420 resolved against `XpConstants.levels`); unlocked vs locked badges visually distinguishable (key-based finders); chip with no certificates → tapping shows the sheet and does NOT push `/progress`; chip with a certificate → still pushes `AppRoutes.certificate`.

---

### Task 7: `HomePrayerTimesSheet` + chip `onTap` wiring

**Files:**
- Create: `lib/features/home/presentation/widgets/home_prayer_times_sheet.dart`
- Modify: `lib/features/home/presentation/widgets/home_night_header.dart` (`HomePrayerChip` gains `onTap`; `Semantics` gains `button: true`)
- Create: `test/features/home/presentation/widgets/home_prayer_times_sheet_test.dart`

**Interfaces:**
- Produces: `showHomePrayerTimesSheet(BuildContext context, {required PrayerTimesSnapshot snapshot, required String hijriLabel, required bool isDark})`.
- Consumes: Task 1's six snapshot fields; `state.hijriLabel` (already on `HomeLoaded`, threaded from the call site in `home_night_header.dart`); city name via `context.isArabic ? city.nameAr : city.nameEn`.

- [ ] **Step 1: Sheet scaffold** — same modal convention as Task 6.
- [ ] **Step 2: Header.** Weekday (from `snapshot.nextTime.weekday`; use the app's existing weekday l10n helper if one exists, else add an arb key) + full Hijri date (`hijriLabel`) + city name.
- [ ] **Step 3: Six prayer rows.** Iterate the six (name-key, DateTime) pairs. Each row: localized prayer name (existing `prayerFajr…prayerIsha` keys — same switch as `HomePrayerChip._localizedName`), 12-hour formatted time, and state styling:
  - past → muted (opacity ~0.55) + soft checkmark icon;
  - current/next → gold border + glow + countdown badge (`homePrayerChip` l10n pattern, `minutesUntil`);
  - upcoming → normal.
- [ ] **Step 4: Staggered entrance.** `AnimationController` + per-row `Interval` (index * ~60ms, `Curves.easeOutCubic`) slide+fade; skip the stagger when `MediaQuery.disableAnimationsOf(context)` is true (rows render immediately).
- [ ] **Step 5: Chip wiring.** `_HeroChip` already accepts `onTap` — pass `onTap: () => showHomePrayerTimesSheet(context, snapshot: snapshot, hijriLabel: state.hijriLabel, isDark: ...)`. Upgrade the chip's `Semantics(label: …)` to `Semantics(button: true, label: …)`; the label string itself is unchanged.
- [ ] **Step 6: Widget tests.** Sheet shows weekday, Hijri label, city name, six localized rows; next prayer highlighted with countdown; past prayers muted with checkmark; `disableAnimations` → rows render immediately; chip tap opens sheet; chip `Semantics` reports `button: true`.

---

### Task 8: Contextual slots & momentum strip — eliminate the remaining `/progress` links

**Files:**
- Modify: `lib/features/home/domain/entities/home_contextual_slot.dart` (remove the `weeklyReflection` enum value)
- Modify: `lib/features/home/presentation/widgets/home_contextual_slot.dart` (remove the two `weeklyReflection` switch cases, lines 42/53)
- Modify: `lib/features/home/presentation/cubits/home_cubit.dart` (remove the candidate block, lines 590–595)
- Modify: `lib/features/home/presentation/widgets/home_momentum_strip.dart` (de-redirect line 50)
- Modify: `test/features/home/presentation/cubits/home_cubit_test.dart` (new regression test)

**Interfaces:**
- `HomeSlotKind.weeklyReflection` is **removed** (not deprecated) — verified: the only references in `lib/` are the enum value, the cubit candidate, and the widget's two switch cases; the exhaustive switch makes the compiler enforce all sites.
- `HomeMomentumStrip` becomes informative-only.

- [ ] **Step 1: Remove `weeklyReflection` at all three sites in one commit.** Delete the enum value; delete the cubit's `if (today.weekday == friday || saturday)` candidate; delete the two widget switch cases. Compile errors guide you to any site missed.
- [ ] **Step 2: Momentum strip.** Remove `onTap: () => context.go(AppRoutes.progress)` (line 50) and the `InkWell`/button `Semantics` wrapper; keep `Semantics(label: context.l10n.streakTerm)` for the streak stats. No state changes needed — the strip already reads `StreakCubit` internally and `state.streakRisk`; per spec §3.3 as amended, streak celebration is covered by `HomeAchievementSheet`.
- [ ] **Step 3: Cubit regression test.** In `home_cubit_test.dart`: pump the cubit with `now` on a Friday and again on a Saturday (the old candidate fired Fri/Sat only); assert `state.activeSlot` is null or a non-`weeklyReflection` kind (the kind no longer exists — assert no crash and correct next-priority resolution).
- [ ] **Step 4: Sweep check.** `grep -rn "AppRoutes.progress" lib/features/home/` → expect only the activity-feed site (removed in Task 9) remains at this point. `grep -rn "weeklyReflection" lib/` → zero.

---

### Task 9: `HomeActivityFeed` — direct deep links + "عرض الكل" removal

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_activity_feed.dart`
- Create: `test/features/home/presentation/widgets/home_activity_feed_test.dart`

**Interfaces:**
- No public API change; the widget already receives `HomeLoaded state` (needed for the khatmah fallback via `state.activeKhatmah?.nextUnreadPage`).

- [ ] **Step 1: Remove "عرض الكل".** Delete the `Flexible/FittedBox/TextButton` block (lines 44–65, incl. `onPressed: () => context.go(AppRoutes.progress)` at line 52); the title `Expanded flex:3` becomes plain `Expanded`.
- [ ] **Step 2: Rows become InkWells with §3.4 routing.** Wrap each `_ActivityRow` in `InkWell` + `Semantics(button: true, label: '$kindLabel. $title')`:
  - `reading`: `event.pageNumber != null` → `/quran/page/${event.pageNumber}`; else `event.surahId != null` → `/quran/surah/${event.surahId}`; else → `AppRoutes.quran`.
  - `khatmah`: `/quran/page/${event.pageNumber ?? state.activeKhatmah?.nextUnreadPage ?? 1}?mode=khatmah` (spec §3.4 as amended — never silently jump to Al-Fatiha).
  - `memorize`: `event.surahId != null` → `${AppRoutes.hifzPracticeSurah}?surahId=${event.surahId}` — **verify at implementation time** whether the route consumes a `surahId` query param (check `app_router.dart`; if ignored, route without the param — the practice page resolves today's plan); else → `AppRoutes.memorizationHub`.
  - `review`: `AppRoutes.memorizationV2Session`.
- [ ] **Step 3: Feed tests.** Reading with pageNumber 42 → `/quran/page/42`; reading with surahId only → `/quran/surah/5`; reading with neither → `AppRoutes.quran`; khatmah without pageNumber → falls back to `state.activeKhatmah.nextUnreadPage` with `?mode=khatmah`; memorize with surahId → practice route (per router verification); memorize without → hub; review → V2 session; the header no longer contains "عرض الكل" (`homeActivityViewAll` finder finds nothing); each row is tappable and pushes the right route (use the same router-fake harness as Task 4's tests).

---

### Task 10: `HomeQuickAccess` — remove the redundant Khatmah chip (§3.6)

**Files:**
- Modify: `lib/features/home/presentation/widgets/home_quick_access.dart`
- Create: `test/features/home/presentation/widgets/home_quick_access_test.dart`

**Interfaces:**
- No public API change. The spec (§3.6) keeps the bookmarks chip and the dynamic time-of-day azkar chip, keeps Friday Kahf on Fridays before 18:00, and excludes the Khatmah chip ("handled in Hero").
- Interpretation note: today azkar and Kahf are mutually exclusive (`if (isFridayKahf) … else (azkar)`); the spec lists them as separate chips (2 and 3), so on Fridays both render — azkar is a daily devotion, Kahf is a Friday-specific addition. If product intent is to keep them exclusive, this is the one line to flip.

- [ ] **Step 1: Remove the Khatmah chip** — delete the `(Icons.auto_stories_rounded, context.l10n.khatmahStartAction, AppRoutes.khatmahDashboard)` item; the start-Khatmah invitation now lives in the hero slot (Task 5), which is the spec's rationale.
- [ ] **Step 2: Make the azkar chip unconditional** with its existing time-of-day routing (`< 12` → morning, `>= 16` → evening, else general) and add the Kahf chip as an extra item on Fridays before 18:00 (keep the current `isFridayKahf` condition). Result: 2 chips normally, 3 on Friday mornings.
- [ ] **Step 3: Keep the bookmarks chip** (`state.recentBookmarkRoute ?? AppRoutes.quranBookmarks`) and the existing chip `Semantics(button: true, …)` + `Wrap` layout untouched.
- [ ] **Step 4: Widget tests.** Default day → exactly bookmarks + azkar chips, correct time-of-day azkar route per `now`; Friday before 18:00 → Kahf chip present (and azkar still present); no Khatmah chip in any scenario (`khatmahStartAction` finder finds nothing).

---

## Sequence & Dependencies

```
Task 1 (snapshot fields) ──→ Task 7 (sheet consumes fields)

Task 2 (mapper gating) ──→ Task 3 (resolver + page wiring) ──→ Task 5 (start-khatmah card)

Task 4 (tiles)            ── independent
Task 6 (achievement)      ── independent
Task 8 (slots/momentum)   ── independent
Task 9 (activity feed)    ── independent
Task 10 (quick access)    ── independent (logically after Task 5: the hero must own the Khatmah invitation first)
```

Recommended execution order for a single implementer: **1 → 2 → 3 → 5 → 4 → 6 → 7 → 8 → 9 → 10** (domain first, then the hero path end-to-end, then the parallel presentation lanes).

**Definition of Done (whole plan):**
- [ ] `dart analyze` → zero issues.
- [ ] Full `flutter test` green, including goldens and the untouched legacy suites (`smart_coach_home_validation_test.dart`, `responsive_home_widgets_test.dart`).
- [ ] Deterministic greps all return zero matches:
  - `grep -rn "AppRoutes.progress" lib/features/home/`
  - `grep -rn "weeklyReflection" lib/`
  - `grep -rn "hasOpenedMushaf" lib/features/home/`
- [ ] No `memorizationHub` fallback remains in `home_action_tiles.dart`, and no Khatmah chip remains in `home_quick_access.dart` (read-verify; the hub and khatmahDashboard routes themselves are still legitimately used elsewhere, e.g. checklist routes built by the cubit).
- [ ] Manual device pass (Android): prayer sheet animation at normal and reduced motion, start-Khatmah card at text scale 2.0, activity-row deep links with mixed activity history, achievement chip fallback with no certificates.
- [ ] Update the spec's Status line to "Implemented" with the date.
