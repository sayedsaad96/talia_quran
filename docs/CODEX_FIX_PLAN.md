# 🛠️ Talia — Safe Implementation Plan

**Based on:** `docs/SENIOR_CODE_REVIEW_REPORT.md`  
**Created:** 2026-05-24  
**Status:** Awaiting approval — no code modified  

> [!IMPORTANT]
> Each task requires explicit "Start fixing" approval before implementation.
> Tasks within a phase should be executed in order. Never skip phases.

---

## Phase 1: Critical Production Bugs

### T1.1 — Wire Crash Reporting in TaliaLogger

**Report Ref:** C-01, H-01  
**Goal:** Ensure production errors are captured and reported instead of silently swallowed.

**Files Affected:**
- `lib/core/utils/talia_logger.dart`
- `pubspec.yaml` (add `firebase_crashlytics` or `sentry_flutter`)
- `lib/main.dart` (wire crash reporter init)

**Implementation Steps:**
1. Add crash reporting dependency to `pubspec.yaml` (Firebase Crashlytics recommended — already common in Flutter ecosystem)
2. In `talia_logger.dart`, remove the `if (kDebugMode)` guard from `e()` method
3. Add crash reporter call inside `e()`: `FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message)`
4. In `main.dart`, initialize Crashlytics inside `runZonedGuarded` — forward uncaught errors to Crashlytics
5. Keep `d()`, `i()`, `w()` debug-only — only `e()` needs release-mode logging

**Risk Level:** 🟢 Low — additive change, no existing logic modified  
**Rollback:** Remove the dependency and revert `talia_logger.dart` to debug-only logging  

**Testing Checklist:**
- [ ] App starts normally in debug mode
- [ ] Logger calls don't crash when Crashlytics is unavailable (offline)
- [ ] `TaliaLogger.e()` produces output in release build (verify via Crashlytics dashboard or Sentry)
- [ ] Existing `runZonedGuarded` error boundary still functions

---

### T1.2 — Add Critical Unit Tests for SM-2 and Streak Logic

**Report Ref:** Testing Gaps §8 — P0 items  
**Goal:** Protect the two most critical business logic systems from silent regressions.

**Files Affected (all new):**
- `test/features/memorization_plus/domain/usecases/schedule_next_review_test.dart`
- `test/features/hifz/data/models/ayah_progress_model_test.dart`
- `test/core/services/streak_service_test.dart` (extend existing)

**Implementation Steps:**
1. **`schedule_next_review_test.dart`** — Test `ScheduleNextReviewUsecase.schedule()`:
   - Excellent rating: strength +1, interval ×2.5, clamped to 180 days max
   - Average rating: strength unchanged, interval ×1.5, clamped to 90 days max
   - Weak rating: strength −1 (min 0), interval reset to 1 day
   - Edge case: strength at 0 with weak rating stays 0
   - Edge case: strength at 10 with excellent stays 10
   - Verify all dates are UTC
2. **`ayah_progress_model_test.dart`** — Test `advanceWithSpacedRepetition()`:
   - Verify interval follows `AppConstants.spacedRepetitionIntervals` array
   - After 5+ repetitions → status becomes `AyahStatus.memorized`
   - Verify `nextReviewDate` is UTC
   - Test `softPenalty()`: repetitions decrease by 1 (min 0), next review = tomorrow
   - Test `softPenalty()` on rep=0 → status = `learning`
3. **`streak_service_test.dart`** — Test `recordActivity()`:
   - Consecutive days increment streak
   - Skipping a day resets streak (unless freeze active)
   - UTC day boundary transitions are correct
   - Heatmap data persists correctly

**Risk Level:** 🟢 Zero — test-only, no production code modified  
**Rollback:** Delete test files  

**Testing Checklist:**
- [ ] `flutter test` passes with all new tests green
- [ ] No existing tests broken
- [ ] Tests cover all edge cases listed above

---

### T1.3 — Guard `dart:io` Import for Platform Safety

**Report Ref:** C-02  
**Goal:** Replace direct `dart:io` usage with platform-safe alternatives.

**Files Affected:**
- `lib/features/certificate/presentation/pages/certificate_page.dart`

**Implementation Steps:**
1. Audit what `dart:io` is used for in the file (likely `File`, `Directory`, or `Platform`)
2. If used for `Platform.isAndroid/isIOS` → replace with `import 'package:flutter/foundation.dart'` and use `defaultTargetPlatform`
3. If used for file I/O → wrap with conditional import or `kIsWeb` guard
4. Verify notification_service.dart's `dart:io` usage is acceptable (it already guards with `Platform.isAndroid && Platform.isIOS`)

**Risk Level:** 🟢 Low — import swap only  
**Rollback:** Revert import  

**Testing Checklist:**
- [ ] Certificate page renders correctly on Android
- [ ] Certificate sharing/saving still works
- [ ] `flutter analyze` passes

---

## Phase 2: Broken / Incomplete User Flows

### T2.1 — Fix HifzPage In-Build Navigation Redirect

**Report Ref:** M-02  
**Goal:** Move the "no path selected → redirect to memorization-plus" logic from widget build into the GoRouter redirect layer.

**Files Affected:**
- `lib/features/hifz/presentation/pages/hifz_page.dart` (lines 65-77)
- `lib/core/router/app_router.dart` (add redirect guard)

**Implementation Steps:**
1. In `app_router.dart`, add a redirect guard on the `/hifz` route that checks if a memorization path is selected
2. If no path → redirect to `/memorization-plus`
3. Remove the `WidgetsBinding.instance.addPostFrameCallback` redirect from `hifz_page.dart`
4. Replace with a normal empty-state message or `SizedBox.shrink()`

**Risk Level:** 🟡 Medium — navigation change, must verify all entry points to Hifz  
**Rollback:** Re-add the `addPostFrameCallback` redirect to `hifz_page.dart`  

**Testing Checklist:**
- [ ] Opening Hifz tab with no path selected → redirects to MemorizationPlus
- [ ] Opening Hifz tab with path selected → shows surah list normally
- [ ] Deep link `/hifz` with no path → redirect works
- [ ] Back navigation from MemorizationPlus returns to correct tab
- [ ] Settings "Reset path" → next Hifz visit triggers redirect

---

### T2.2 — Fix Hardcoded Arabic Strings → Localization

**Report Ref:** M-03  
**Goal:** Replace all hardcoded Arabic UI strings with localized equivalents from `.arb` files.

**Files Affected:**
- `lib/features/settings/presentation/pages/settings_page.dart` (lines 139, 153, 167)
- `lib/features/settings/presentation/pages/settings_page_tiles.dart` (lines 191, 238)
- `lib/features/hifz/presentation/pages/hifz_page.dart` (lines 560, 583, 592, 605, 609, 621)
- `lib/core/l10n/app_ar.arb` (add missing keys if needed)
- `lib/core/l10n/app_en.arb` (add missing English equivalents)

**Implementation Steps:**
1. Audit existing `.arb` files — keys like `resetMemorizationPath`, `memorizationPathReset`, `parentGuardianMode` already exist
2. For each hardcoded string, find or create the matching l10n key
3. Replace hardcoded `'وضع ولي الأمر'` → `context.l10n.parentGuardianMode` (or new key)
4. Replace hardcoded `'مسار الحفظ'` → `context.l10n.memorizationPath` (verify/create)
5. Replace hardcoded `'الأطفال وولي الأمر'` → new l10n key `kidsAndParent`
6. Replace all dialog/bottom-sheet hardcoded strings in `hifz_page.dart` lines 560-621
7. Run `flutter gen-l10n` if using code generation for localizations
8. Verify all new keys exist in both `app_ar.arb` and `app_en.arb`

**Risk Level:** 🟢 Low — text substitution, no logic change  
**Rollback:** Revert to hardcoded strings  

**Testing Checklist:**
- [ ] Settings page displays correctly in Arabic
- [ ] Settings page displays correctly in English
- [ ] Hifz page memorization settings bottom sheet renders in both languages
- [ ] All dialog titles/content display correctly
- [ ] No missing key crashes

---

### T2.3 — Fix Splash Page Router Internals Access

**Report Ref:** M-06  
**Goal:** Remove fragile dependency on GoRouter internal API.

**Files Affected:**
- `lib/features/splash/presentation/pages/splash_page.dart` (lines 51-53)

**Implementation Steps:**
1. Replace `AppRouter.router.routerDelegate.currentConfiguration.uri.path` with a simpler guard
2. Option A: Use a `_hasNavigated` boolean flag set after navigation
3. Option B: Check `mounted` state only — the `if (!mounted) return` on line 61 already handles this
4. Remove the direct router internals access

**Risk Level:** 🟢 Low — guard simplification  
**Rollback:** Revert to original check  

**Testing Checklist:**
- [ ] Cold start → splash → navigates to correct screen (onboarding or home)
- [ ] No double-navigation on slow devices
- [ ] Splash animation plays fully before navigation

---

## Phase 3: UX Improvements

### T3.1 — Parallelize HomeCubit.load() for Faster Startup

**Report Ref:** M-04, Performance §10  
**Goal:** Reduce home screen load time by running independent data fetches in parallel.

**Files Affected:**
- `lib/features/home/presentation/cubits/home_cubit.dart` (lines 34-83)

**Implementation Steps:**
1. Identify independent calls: `_getProgress()`, `_getHifzProgress()`, `_getQuranPage()`, `_getCustomPlan()` are all independent
2. Wrap them in `Future.wait()`:
   ```dart
   final results = await Future.wait([
     _getProgress(),
     _getHifzProgress(),
     _getQuranPage(pageNumber),
     _getCustomPlan(),
   ]);
   ```
3. Destructure results with proper casting
4. Keep `_memorizationRepository.getSelectedTrack()` and `getIsParentMode()` synchronous — they're already sync calls
5. Verify error handling: if one fails, the fold-based error handling still works

**Risk Level:** 🟢 Low — same calls, different execution order  
**Rollback:** Revert to sequential calls  

**Testing Checklist:**
- [ ] Home page loads all sections correctly (streak, wird, progress, azkar, heatmap)
- [ ] Error state shows if any data source fails
- [ ] Loading state displays during fetch
- [ ] "Continue Reading" chip still appears when applicable
- [ ] Measure: home screen loads faster than before

---

### T3.2 — Extract progress_page.dart into Widget Files

**Report Ref:** H-06  
**Goal:** Decompose the 1,539-line file into manageable, focused widget files.

**Files Affected:**
- `lib/features/progress/presentation/pages/progress_page.dart` (split)
- `lib/features/progress/presentation/widgets/` (new directory, new files)

**Implementation Steps:**
1. Create `lib/features/progress/presentation/widgets/` directory
2. Extract `_StreakCard` → `progress_streak_card.dart`
3. Extract `_StatCard` → `progress_stat_card.dart`
4. Extract `_DetailedProgressCard` + `_ProgressBarRow` → `progress_detailed_card.dart`
5. Extract `_AchievementsCategorized` → `progress_achievements.dart`
6. Extract `_CertificatesSection` → `progress_certificates.dart`
7. Extract `_SmartMemorizationCard` → `progress_smart_memorization.dart`
8. Keep `ProgressPage`, `_ProgressView`, `_ProgressContent` in the main file
9. Update all imports

**Risk Level:** 🟢 Low — file reorganization, no logic change  
**Rollback:** Revert file split, restore original monolith  

**Testing Checklist:**
- [ ] Progress page renders identically to before
- [ ] All sections visible: streak, stats, reading, memorization, smart memorization, certificates, achievements
- [ ] Dark/light theme correct on all extracted widgets
- [ ] Achievement category tabs still switch
- [ ] Certificate cards still navigate to certificate page
- [ ] `flutter analyze` passes

---

### T3.3 — Add Bookmark Undo Action

**Report Ref:** L-05  
**Goal:** Add an "Undo" action to the bookmark toggle snackbar in Quran reader.

**Files Affected:**
- `lib/features/quran/presentation/pages/quran_reader_page.dart` (lines 534-555)

**Implementation Steps:**
1. Capture the `BookmarkEntry` before toggling
2. After `toggle()`, show snackbar with `SnackBar(action: SnackBarAction(label: 'تراجع', onPressed: ...))`
3. On undo, call `toggle()` again to reverse the operation
4. Use localized labels from l10n

**Risk Level:** 🟢 Low — additive UX improvement  
**Rollback:** Remove undo action from snackbar  

**Testing Checklist:**
- [ ] Long-press ayah → bookmark → snackbar appears with undo
- [ ] Tap undo → bookmark removed
- [ ] Long-press ayah → remove bookmark → snackbar with undo
- [ ] Tap undo → bookmark restored

---

## Phase 4: Code Quality & Architecture Cleanup

### T4.1 — Move Settings Page Logic into SettingsCubit

**Report Ref:** H-03  
**Goal:** Remove direct `getIt<>()` and repository access from the settings widget tree.

**Files Affected:**
- `lib/features/settings/presentation/cubits/settings_cubit.dart` (new)
- `lib/features/settings/presentation/cubits/settings_state.dart` (new)
- `lib/features/settings/presentation/pages/settings_page.dart` (refactor)
- `lib/core/di/injection.dart` (register new cubit)

**Implementation Steps:**
1. Create `SettingsCubit` with state holding: `selectedTrack`, `selectedHifzPath`, `isParentMode`, `memorizationProfile`
2. Move `_loadTrackAndParentMode()` logic into cubit's `load()` method
3. Move `_toggleParentMode()` into cubit method
4. Move `_resetMemorizationIdentity()` into cubit method
5. Inject `MemorizationPlusRepository` and `SharedPreferences` into cubit via DI
6. Register `SettingsCubit` as factory in `injection.dart`
7. Refactor `SettingsPage` from `StatefulWidget` → `StatelessWidget` wrapping `BlocProvider<SettingsCubit>`
8. Replace `setState()` calls with `BlocBuilder` reactions

**Risk Level:** 🟡 Medium — presentation refactor, must preserve all settings behaviors  
**Rollback:** Revert to direct `getIt<>()` access in StatefulWidget  

**Testing Checklist:**
- [ ] All settings sections render correctly
- [ ] Theme toggle works
- [ ] Language toggle works
- [ ] Parent mode toggle works and persists across restart
- [ ] Reset memorization path works with confirmation dialog
- [ ] Notification toggles work
- [ ] Account sign-in/sign-out works
- [ ] Profile settings accessible
- [ ] Back navigation works

---

### T4.2 — Register NotificationService in DI Container

**Report Ref:** H-05  
**Goal:** Replace manual singleton with DI-managed instance for testability.

**Files Affected:**
- `lib/core/services/notification_service.dart` (refactor constructor)
- `lib/core/di/injection.dart` (register service)
- `lib/main.dart` (update initialization)
- `lib/app.dart` (update references)
- All files referencing `TaliaNotificationService.instance`

**Implementation Steps:**
1. Remove `TaliaNotificationService._()` private constructor and `static final instance`
2. Add a normal public constructor: `TaliaNotificationService()`
3. Register as `lazySingleton` in `injection.dart`
4. Replace all `TaliaNotificationService.instance` → `getIt<TaliaNotificationService>()`
5. In `main.dart`, get instance from DI: `final notificationService = getIt<TaliaNotificationService>()`
6. Verify lifecycle: singleton ensures same instance throughout app

**Risk Level:** 🟡 Medium — touches multiple files, must verify all notification entry points  
**Rollback:** Restore manual singleton pattern  

**Testing Checklist:**
- [ ] Notifications still scheduled on app startup
- [ ] Daily review reminder fires at configured time
- [ ] Streak protection alert fires correctly
- [ ] Morning/evening azkar notifications work
- [ ] Notification tap opens correct deep link
- [ ] `refreshNotifications()` still called on app resume

---

### T4.3 — Remove Direct Isar Access from Home Page

**Report Ref:** H-04  
**Goal:** Route `ActivityHeatmap` data through the cubit layer instead of raw Isar.

**Files Affected:**
- `lib/features/home/presentation/pages/home_page.dart` (line 240)
- `lib/features/home/presentation/cubits/home_cubit.dart` (add heatmap data)
- `lib/features/home/presentation/cubits/home_state.dart` (add field)
- `lib/core/widgets/activity_heatmap.dart` (change API to accept data, not Isar)

**Implementation Steps:**
1. In `HomeCubit.load()`, query heatmap data from Isar via a use case or service
2. Add `List<DateTime> activityDates` (or equivalent) to `HomeLoaded` state
3. Refactor `ActivityHeatmap` to accept processed data instead of raw `Isar` instance
4. Remove `getIt<Isar>()` from `home_page.dart`

**Risk Level:** 🟡 Medium — changes widget API contract  
**Rollback:** Revert to direct `Isar` injection  

**Testing Checklist:**
- [ ] Heatmap renders correctly with activity data
- [ ] Empty state (no activity) renders correctly
- [ ] Heatmap updates after completing a review session

---

### T4.4 — Add @immutable Annotations and Remove Redundant Constructors

**Report Ref:** L-02, L-03, L-04  
**Goal:** Static analysis hygiene — add missing annotations, remove dead code.

**Files Affected:**
- `lib/core/constants/app_constants.dart` (remove `const AppConstants._()`)
- `lib/core/theme/app_theme.dart` (remove `const AppTheme._()`)
- Multiple cubit state files (add `@immutable`)

**Implementation Steps:**
1. Remove `const AppConstants._()` — already `abstract class`
2. Remove `const AppTheme._()` — already `abstract class`
3. Grep for all `part '..._state.dart'` files → add `@immutable` annotation to state base classes
4. Run `flutter analyze` to verify no new warnings

**Risk Level:** 🟢 Zero — annotation-only, no logic change  
**Rollback:** Remove annotations  

**Testing Checklist:**
- [ ] `flutter analyze` passes with zero new warnings
- [ ] App compiles and runs normally

---

### T4.5 — Update analysis_options.yaml

**Report Ref:** M-05  
**Goal:** Ensure lint rules use the latest recommended package.

**Files Affected:**
- `analysis_options.yaml`
- `pubspec.yaml` (if lint package needs updating)

**Implementation Steps:**
1. Check current `flutter_lints` version in `pubspec.yaml`
2. If outdated, update to latest `flutter_lints` or migrate to `lints` package
3. Run `flutter analyze` — fix any new warnings surfaced by updated rules
4. Do NOT auto-fix — review each warning manually

**Risk Level:** 🟢 Low — config change  
**Rollback:** Revert `analysis_options.yaml`  

**Testing Checklist:**
- [ ] `flutter analyze` passes
- [ ] No behavior changes in app

---

## Phase 5: High-Impact New Features

### T5.1 — Migrate Review Records from SharedPreferences to Isar

**Report Ref:** C-03, Performance §10  
**Goal:** Eliminate the O(n) key scan by moving structured data to a proper database.

**Files Affected:**
- `lib/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart`
- `lib/features/memorization_plus/data/models/` (new Isar collection)
- `lib/core/di/injection.dart` (register Isar schema)
- `lib/main.dart` (add Isar schema to init)

**Implementation Steps:**
1. Create an Isar collection class `AyahReviewRecordCollection` with `@Collection()` annotation
2. Define fields matching `AyahReviewRecordModel`: `surahId`, `ayahNumber`, `strengthLevel`, `intervalDays`, `lastReviewedAt`, `nextReviewDate`, `totalReviews`, `lastRating`
3. Add composite index on `(surahId, ayahNumber)` for O(1) lookups
4. Run `flutter pub run build_runner build --delete-conflicting-outputs`
5. In `memorization_plus_local_datasource.dart`, add new Isar-based implementations alongside SharedPreferences ones
6. Add a **migration bridge**: on first launch after update, read all `mem_plus_review_*` keys from SharedPreferences, write to Isar, then delete SharedPreferences keys
7. Update `getReviewRecord()` → Isar query by composite index
8. Update `getAllReviewRecords()` → `isar.collection.where().findAll()`
9. Update `saveReviewRecord()` → `isar.writeTxn()` 
10. Add unit tests for migration bridge

**Risk Level:** 🔴 High — data migration, must preserve all existing memorization progress  
**Rollback:**
1. Keep SharedPreferences read path as fallback
2. If migration fails, app falls back to SharedPreferences
3. Never delete SharedPreferences keys until Isar write is confirmed

**Testing Checklist:**
- [ ] Fresh install: review records save to Isar correctly
- [ ] Upgrade from old version: SharedPreferences data migrated to Isar
- [ ] After migration: SharedPreferences keys cleaned up
- [ ] `getAllReviewRecords()` returns same data as before
- [ ] `getReviewRecord(surahId, ayahNumber)` returns correct record
- [ ] Performance: `getAllReviewRecords()` is faster than before
- [ ] Offline mode still works
- [ ] No data loss during migration (count records before/after)

---

### T5.2 — Consolidate Dual SM-2 Implementations

**Report Ref:** M-01  
**Goal:** Establish a single, authoritative spaced repetition algorithm.

**Files Affected:**
- `lib/features/hifz/data/models/ayah_progress_model.dart`
- `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart`
- `lib/core/constants/app_constants.dart`
- Test files for both implementations

**Implementation Steps:**
1. **Decision required:** Choose which SM-2 variant is authoritative:
   - **Option A (recommended):** `ScheduleNextReviewUsecase` — more sophisticated, uses dynamic multipliers
   - **Option B:** `AyahProgressModel.advanceWithSpacedRepetition()` — simpler, fixed intervals
2. Write comprehensive tests for the chosen implementation FIRST
3. Refactor the non-chosen implementation to delegate to the chosen one
4. For Option A: refactor `AyahProgressModel.advanceWithSpacedRepetition()` to call `ScheduleNextReviewUsecase.schedule()` internally
5. Ensure both call sites produce identical behavior
6. Verify UTC consistency in both paths

**Risk Level:** 🔴 High — core business logic, affects all memorization data  
**Rollback:** Keep both implementations, add deprecation warning on the non-authoritative one  

**Testing Checklist:**
- [ ] All existing SM-2 tests pass
- [ ] New comprehensive tests pass for consolidated implementation
- [ ] Existing memorization progress not affected
- [ ] New reviews use correct intervals
- [ ] Penalty/weak rating uses correct reset logic
- [ ] `nextReviewDate` is always UTC

---

### T5.3 — Hash Parent PIN Before Storage

**Report Ref:** S-05  
**Goal:** Prevent plaintext PIN exposure on rooted/jailbroken devices.

**Files Affected:**
- `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`
- `pubspec.yaml` (add `crypto` package if not present)

**Implementation Steps:**
1. Add `crypto` package (or use `dart:convert` + `dart:typed_data` for SHA-256)
2. In `setParentPin()`: hash the PIN with SHA-256 before storing
3. In `verifyParentPin()`: hash the input and compare with stored hash
4. Add migration: on first verify after update, if stored value is unhashed (4 digits), re-hash and re-store it

**Risk Level:** 🟡 Medium — must handle migration from plaintext to hashed  
**Rollback:** Keep plaintext, add TODO for next release  

**Testing Checklist:**
- [ ] Set new PIN → stored as hash (verify in SharedPreferences)
- [ ] Verify correct PIN → access granted
- [ ] Verify wrong PIN → access denied
- [ ] Existing plaintext PIN → still works (migration on verify)
- [ ] After migration, PIN is now stored as hash

---

## Phase 6: Monetization & Premium Features

### T6.1 — Implement Subscription Infrastructure

**Report Ref:** TODO in `subscription_service.dart`, `premium_gate.dart`  
**Goal:** Replace stub implementations with real purchase flow when ready.

**Files Affected:**
- `lib/core/services/subscription_service.dart`
- `lib/core/widgets/premium_gate.dart`
- `pubspec.yaml` (add `purchases_flutter` / RevenueCat)
- `lib/core/di/injection.dart`

**Implementation Steps:**
1. **Pre-requisite:** Define which features will be premium (requires product decision)
2. Add `purchases_flutter` (RevenueCat) to `pubspec.yaml`
3. Implement `SubscriptionService` with RevenueCat SDK:
   - `isPremium()` → check entitlements
   - `purchaseMonthly()` → trigger monthly subscription
   - `purchaseYearly()` → trigger yearly subscription
   - `restorePurchases()` → restore from App Store / Play Store
4. Update `PremiumGate` widget to check `SubscriptionService.isPremium()`
5. Show paywall UI when non-premium user hits gated feature
6. Add subscription status to app state (cubit or service)

**Risk Level:** 🔴 High — monetization, requires App Store/Play Store setup, legal compliance  
**Rollback:** Revert to stub (all features free)  

**Testing Checklist:**
- [ ] Free users see paywall on gated features
- [ ] Premium users see all features
- [ ] Purchase flow completes (sandbox testing)
- [ ] Restore purchases works
- [ ] Subscription status persists across app restart
- [ ] Offline mode: cached subscription status used
- [ ] No crash if RevenueCat SDK unavailable

---

### T6.2 — Implement Supabase RLS Policies

**Report Ref:** Phase 4 in report  
**Goal:** Ensure multi-user data isolation at the database level.

**Files Affected:**
- Supabase Dashboard (SQL policies)
- `lib/features/auth/data/repositories/auth_repository_impl.dart` (verify queries)

**Implementation Steps:**
1. Audit all Supabase tables used by the app
2. For each table, add RLS policy: `auth.uid() = user_id`
3. Enable RLS on all tables
4. Test that User A cannot read/write User B's data
5. Verify cloud sync functions still work with RLS enabled

**Risk Level:** 🔴 High — database security, could break sync if policies are wrong  
**Rollback:** Disable RLS policies (not recommended for production)  

**Testing Checklist:**
- [ ] Authenticated user can read/write own data
- [ ] Authenticated user cannot access other users' data
- [ ] Unauthenticated requests are rejected
- [ ] Cloud sync still works after RLS enabled
- [ ] Offline-first flow unaffected

---

## Summary — Phase Dependencies

```
Phase 1 (Critical) ─── no dependencies, start immediately
    │
Phase 2 (User Flows) ─── can run in parallel with Phase 1
    │
Phase 3 (UX) ─── after Phase 1 + 2 are stable
    │
Phase 4 (Architecture) ─── after Phase 3, before Phase 5
    │
Phase 5 (Features) ─── after Phase 4 architecture is clean
    │
Phase 6 (Monetization) ─── after Phase 5, requires product decisions
```

## Estimated Effort

| Phase | Tasks | Estimated Time | Risk |
|-------|-------|---------------|------|
| Phase 1 | 3 tasks | 1-2 days | 🟢 Low |
| Phase 2 | 3 tasks | 1 day | 🟢 Low |
| Phase 3 | 3 tasks | 1-2 days | 🟢 Low |
| Phase 4 | 5 tasks | 2-3 days | 🟡 Medium |
| Phase 5 | 3 tasks | 3-5 days | 🔴 High |
| Phase 6 | 2 tasks | 5-7 days | 🔴 High |

**Total: ~13-20 days** for full execution across all phases.

---

> **No code has been modified. This plan awaits explicit approval before any implementation begins.**
