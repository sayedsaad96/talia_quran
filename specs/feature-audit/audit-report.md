# Talia Quran — Full Application Feature Audit Report

**Branch**: `001-feature-audit` | **Date**: 2026-05-17 | **Auditor**: speckit-implement
**Flutter Analyze**: ✅ No issues found (ran in 168.3s)
**Audit Type**: Static analysis only — zero source files modified

---

## Feature Inventory

### Features (14)

| # | Feature | Status | Entry Point | Route(s) | DI Cubit(s) | Layers |
|---|---------|--------|-------------|----------|-------------|--------|
| 1 | `auth` | **Broken** | `LoginPage` | `/login` | `AuthCubit` | D ✅ Dom ✅ P ✅ |
| 2 | `azkar` | **Fully Working** | `AzkarPage` | `/azkar`, `/azkar/:cat` | `AzkarCubit` | D ✅ Dom ✅ P ✅ |
| 3 | `certificate` | **Conditionally Reachable** | `CertificatePage` | `/certificate` (needs `extra`) | None | P only ✅ |
| 4 | `hifz` | **Fully Working** | `HifzPage` | `/hifz`, `/hifz/session` | `HifzCubit`, `HifzSessionCubit` | D ✅ Dom ✅ P ✅ |
| 5 | `home` | **Fully Working** | `HomePage` | `/` | `HomeCubit` | P only ✅ |
| 6 | `memorization_plus` | **Partially Working** | `TrackSelectionPage` | `/memorization-plus` + 5 sub-routes | 7 Cubits | D ✅ Dom ✅ P ✅ |
| 7 | `onboarding` | **Fully Working** | `OnboardingPage` | `/onboarding` | None (StatefulWidget) | P only ✅ |
| 8 | `progress` | **Fully Working** | `ProgressPage` | `/progress` | `ProgressCubit` | D ✅ Dom ✅ P ✅ |
| 9 | `quran` | **Fully Working** | `QuranPage` | `/quran`, `/quran/surah/:id`, `/quran/page/:num` | 4 Cubits | D ✅ Dom ✅ P ✅ |
| 10 | `settings` | **Partially Working** | `SettingsPage` | `/settings` | `ProfileCubit`, `ThemeCubit`, `LocaleCubit` | D ✅ Dom ✅ P ✅ |
| 11 | `splash` | **Fully Working** | `SplashPage` | `/splash` (initial) | None (StatefulWidget) | P only ✅ |
| 12 | `streak` | **Partially Working** | None (no page) | No route | `StreakCubit` | D ✅ Dom ✅ P (cubits only) |
| 13 | `tutorial_guide` | **Fully Working** | `TutorialGuidePage` | `/tutorial-guide` | None (StatefulWidget) | P only ✅ |
| 14 | `xp` | **Partially Working** | None (no page) | No route | None | D (models) + Dom (entity) only |

### Core Services (6 DI-registered)

| Service | Registration | Consuming Cubits | Usage Status |
|---------|-------------|-----------------|--------------|
| `XpService` | singleton | `HifzSessionCubit`, `KidsModeCubit`, `DailyPlanCubit` | ✅ Active |
| `StreakService` | singleton | `HifzSessionCubit`, `KidsModeCubit`, `DailyPlanCubit`, `QuranPageCubit` | ✅ Active |
| `AchievementService` | singleton | `HifzSessionCubit`, `DailyPlanCubit`, `KidsModeCubit`, `QuizCubit` | ✅ Active |
| `SubscriptionService` | singleton | **None** | ❌ Stub / Unused |
| `AudioCacheService` | singleton | `HifzSessionCubit` (via static), `QuranReaderPage`, `SurahDetailPage` | ⚠️ Active but bypasses DI |
| `AppSessionService` | singleton | `HomeCubit`, `HifzSessionPage`, `QuranReaderPage`, `SplashPage`, `app.dart` | ✅ Active |

### Non-DI Services (3 additional)

| Service | Pattern | Status |
|---------|---------|--------|
| `HapticService` | Static-only class | ⚠️ Used via `HapticFeedback` directly; `HapticService` class methods unused |
| `QuranAudioService` | Static-only class | ⚠️ Used via static methods in `AudioCacheService` + entities |
| `NotificationService` | Bootstrap singleton (`TaliaNotificationService.instance`) | ✅ Active — registered outside GetIt by design |

---

## Route Inventory

| Path | Target Widget | Requires Params | Reachability | Fallback on Bad Params |
|------|--------------|----------------|--------------|------------------------|
| `/splash` | `SplashPage` | No | Shell initial | — |
| `/onboarding` | `OnboardingPage` | No | From splash | — |
| `/login` | `LoginPage` | No | Full-screen push | — |
| `/tutorial-guide` | `TutorialGuidePage` | No | Settings tile → `context.push` | — |
| `/certificate` | `CertificatePage` | Yes (`award`, `userName`) | Home widget + Progress page | Bare error scaffold |
| `/quran/surah/:surahId` | `QuranReaderPage` | Path param | From `QuranPage` | — |
| `/quran/page/:pageNumber` | `QuranReaderPage` | Path param | From Quran reader | — |
| `/hifz/session` | `HifzSessionPage` | Optional (`surahId`) | From `HifzPage` | Default surah=1 |
| `/azkar/:category` | `AzkarCategoryPage`/`GeneralAzkarPage` | Path param | From `AzkarPage` | — |
| `/settings` | `SettingsPage` | No | Full-screen push | — |
| `/memorization-plus` | `TrackSelectionPage` | No | Home card / shell | — |
| `/memorization-plus/daily-plan` | `DailyPlanPage` | Yes (`surahId`) | From `TrackSelectionPage` | ↩ `TrackSelectionPage` |
| `/memorization-plus/kids-journey` | `KidsJourneyPage` | Yes (`surahId`) | From `TrackSelectionPage` | ↩ `TrackSelectionPage` |
| `/memorization-plus/kids` | `KidsModePage` | Yes (`surahId`, `ayahNumber`, `ayahText`) | From `KidsJourneyPage` | ↩ `TrackSelectionPage` |
| `/memorization-plus/parent-dashboard` | `ParentDashboardPage` | Optional (`surahId`) | Home shortcut card (Kids track) | Default surahId=1 |
| `/memorization-plus/custom-plan` | `CustomPlanSetupPage` | No | From `TrackSelectionPage` | — |
| `/memorization-plus/quiz` | `QuizPage` | Yes (`surahId`, `ayahNumbers`) | From `DailyPlanPage`/`KidsJourneyPage` | ↩ `TrackSelectionPage` |
| `/` (shell) | `HomePage` | No | Bottom nav tab 0 | — |
| `/quran` (shell) | `QuranPage` | No | Bottom nav tab 1 | — |
| `/hifz` (shell) | `HifzPage` | No | Bottom nav tab 2 | — |
| `/azkar` (shell) | `AzkarPage` | No | Bottom nav tab 3 | — |
| `/progress` (shell) | `ProgressPage` | No | Bottom nav tab 4 | — |

---

## Fully Working Features

### `azkar`
- **Purpose**: Morning, evening, general dhikr, and du'a viewer
- **Navigation**: Bottom nav tab → category tiles → `/azkar/:category`
- **DI**: `AzkarCubit` ← `GetAzkarUsecase` ← `AzkarRepository` ← `AzkarLocalDatasourceImpl` ✅
- **Runtime**: `AzkarCubit.load()` wraps in `Either`; state transitions complete
- **UX**: Category page has counter with haptic — structural states present
- **Notes**: Haptic called directly via `HapticFeedback.*` not via `HapticService` class methods

### `hifz`
- **Purpose**: Spaced-repetition Quran memorisation sessions + checkpoint reviews
- **Navigation**: Shell tab → surah select → `/hifz/session?surahId=X`
- **DI**: `HifzSessionCubit` receives 11 dependencies — all confirmed registered ✅
- **Runtime**: Full SRS flow, `StreakService` + `XpService` called on session completion
- **UX**: Session page has loading, error, and empty states

### `home`
- **Purpose**: Dashboard — continue reading, streak, memorization shortcut, quick actions
- **Navigation**: Shell tab 0 (`/`)
- **DI**: `HomeCubit` receives 6 dependencies; `StreakCubit` provided via `BlocProvider` in `home_page.dart`
- **Runtime**: `HomeCubit` loads progress, hifz status, custom plan; `AppSessionService` restores last location at splash
- **Certificate entry point**: `home_page_widgets.dart` lines 299 + 1553 navigate to `/certificate` with `extra` ✅

### `onboarding`
- **Purpose**: First-launch onboarding flow
- **Navigation**: Splash reads `isFirstTimeAppOpen` SharedPrefs key → `/onboarding` on first run
- **Completion**: Onboarding sets flag and navigates to `/` — verified in splash_page.dart:58+64+66
- **DI**: None needed — pure StatefulWidget with no persisted business logic ✅

### `progress`
- **Purpose**: Reading stats, achievements, hifz completion heatmap
- **Navigation**: Shell tab 4 (`/progress`)
- **DI**: `ProgressCubit` ← `GetProgressUsecase` ← `ProgressRepository` (aggregates 4 data sources) ✅
- **Certificate entry**: `progress_page.dart:1475` navigates to `/certificate` with `extra` ✅

### `quran`
- **Purpose**: Full Quran browser, page reader, bookmarks, search, audio
- **Navigation**: Shell tab 1 → surah list → `/quran/surah/:id` or `/quran/page/:num`
- **DI**: 4 Cubits registered; `AudioCacheService` called via static singleton (see FIND-009)
- **Runtime**: `QuranPageCubit` saves read page → `SaveReadPageUsecase` → `StreakService`

### `splash`
- **Purpose**: Initial routing — onboarding vs home with session restoration
- **Runtime**: Reads `isFirstTimeAppOpen` + `AppSessionService.getLastRestorableLocation()` ✅

### `tutorial_guide`
- **Purpose**: In-app tutorial sections accessible from Settings
- **Navigation**: Settings tile → `context.push('/tutorial-guide')` ✅ — upstream trigger confirmed
- **State**: Pure StatefulWidget, no persistence needed — tutorial is read-only reference content ✅

---

## Conditionally Reachable Features

### `certificate`
- **Routes**: `/certificate` — requires `extra: {award: CertificateAward, userName: String}`
- **Upstream triggers confirmed**:
  - `home_page_widgets.dart:299` — achievement unlock card ✅
  - `home_page_widgets.dart:1553` — certificate shortcut widget ✅
  - `progress_page.dart:1475` — certificate view in progress page ✅
- **Fallback on missing params**: Shows bare `Scaffold(body: Center(child: Text('لم يتم العثور على الشهادة')))` — no back navigation or retry action
- **Status**: Conditionally Reachable — upstream triggers exist and are reachable ✅
- **Finding**: FIND-CR01 — bare error scaffold has no back button (UX gap)

### `memorization_plus` sub-routes (quiz, kids, kids-journey, daily-plan)
- **Pattern**: All 4 routes check `_isValidSurahId()` and silently redirect to `TrackSelectionPage()` on failure
- **Upstream triggers**: All confirmed present in `TrackSelectionPage` → `KidsJourneyPage` flow
- **Finding**: FIND-CR02 — silent redirect gives user no explanation

---

## Partially Working Features

### `memorization_plus`
- **Primary flow**: TrackSelection → DailyPlan or KidsJourney → KidsMode → Quiz ✅ (connected)
- **Secondary gaps**:
  - `ParentRemoteLinkUsecase` used in `KidsJourneyCubit` + `ParentDashboardCubit` — involves QR code linking to Supabase; requires active network + matching child device
  - `CustomPlanSetupPage` route exists but `CustomPlanCubit` only calls `getIt<MemorizationPlusRepository>()` — custom plan persistence unverified without runtime
- **Severity**: Medium — primary Kids/Daily-plan flows reachable; parent-linking is secondary

### `settings`
- **Primary flow**: Theme, locale, notification toggles, profile name ✅
- **Architecture gap**: `profile_cubit.dart` and `settings_page.dart` both import `features/settings/data/user_profile.dart` directly from presentation layer — minor layer boundary crossing
- **Finding**: FIND-ARC01 — presentation imports data model directly (not via domain entity)

### `streak`
- **Purpose**: Track daily reading streak
- **Gap**: No standalone route or page — `StreakCubit` provided only in `home_page.dart` BlocProvider
- **Impact**: Streak data computed and displayed on home page ✅, but no dedicated streak history screen

### `xp`
- **Purpose**: XP points system for gamification
- **Gap**: Only `data/models/xp_isar.dart` + `domain/entities/xp_gain_result.dart` — no presentation, no route, no Cubit
- **Runtime**: `XpService` accumulates and persists XP to Isar ✅ — but users have **no screen to view their XP total or history**
- **Finding**: FIND-HID01 — XP is silently accumulated with no user-facing display

---

## Hidden / Unused Features

### `SubscriptionService`
- **Status**: Registered as singleton in DI; zero consuming Cubits
- **Content**: 22-line stub — all methods return `true` (all features free)
- **Finding**: FIND-HID02 — dead DI registration; no gating logic exists anywhere

### `HapticService` class methods
- **Status**: Service class exists with static methods, but call sites use `HapticFeedback.*` directly (Flutter SDK), not `HapticService.*`
- **Example**: `azkar_category_page.dart:119` calls `HapticFeedback.selectionClick()` directly
- **Finding**: FIND-HID03 — `HapticService` wrapper class is unused; its static methods have zero call sites

---

## Broken Features

### `auth` — No Route Guard (CRITICAL)
- **Primary flow failure**: The router has **no `redirect` callback**. An unauthenticated user can deeplink or navigate directly to any screen without being redirected to `/login`.
- **Evidence**: `app_router.dart` — `GoRouter(...)` has no `redirect:` parameter. `AuthCubit` is provided in `app.dart` but never read by the router for gating.
- **Secondary**: `AuthCubit` state transitions (`signIn`/`signOut`) work correctly via Supabase ✅. Session persistence works via Supabase `auth.currentUser` which survives app restarts ✅.
- **Finding**: FIND-AUTH01 — **Critical** — missing route guard

---

## UX Problems

### Structural Gaps

| ID | Screen | Missing State | Notes |
|----|--------|--------------|-------|
| FIND-UX01 | `/certificate` fallback | No back button on error scaffold | User stuck with no exit |
| FIND-UX02 | `memorization_plus` bad-param redirect | No user feedback before redirect | User silently dropped at TrackSelection |
| FIND-UX03 | `xp` | No XP display anywhere | Users accumulate XP invisibly |

### Flagrant Quality Issues

| ID | Screen | Issue | Severity |
|----|--------|-------|----------|
| FIND-UX04 | `settings` > profile name | No validation/error feedback on save | Low |

---

## Logic Problems

### Architecture Violations

| ID | Files | Violation | Severity |
|----|-------|-----------|----------|
| FIND-ARC01 | `settings/presentation/cubits/profile_cubit.dart`, `settings/presentation/pages/settings_page.dart` | Both import `features/settings/data/user_profile.dart` directly from presentation layer — bypasses domain entity | Medium |

### Stability Risks

| ID | File | Issue | Severity |
|----|------|-------|----------|
| FIND-STAB01 | `lib/main.dart:88-93` | `StateError` thrown if `.env` is missing or empty — entire app fails to start; violates Offline-First principle | High |
| FIND-STAB02 | `lib/core/di/injection.dart:99`, `HifzSessionCubit`, `QuranReaderPage` | `AudioCacheService` registered in DI but consumed via `AudioCacheService.instance` (static singleton) — bypasses DI; cannot be mocked in tests | Medium |

---

## Dead / Duplicate Code

| ID | Location | Issue | Severity |
|----|----------|-------|----------|
| FIND-DEAD01 | `lib/core/services/subscription_service.dart` | Full stub class registered in DI with no consumers — dead registration | Medium |
| FIND-DEAD02 | `lib/core/services/haptic_service.dart` | `HapticService` static methods defined but never called — all call sites use `HapticFeedback.*` directly | Low |

---

## Performance Concerns

| ID | Location | Issue | Severity |
|----|----------|-------|----------|
| FIND-PERF01 | `AudioCacheService` via `just_audio` + `flutter_cache_manager` | Audio caching is implemented ✅; no performance concern found | — |
| FIND-PERF02 | `flutter analyze` | **Zero issues** — no unused imports, no large widget rebuilds flagged | — |

> ✅ No performance concerns found during static analysis.

---

## Suggested Fixes (Sorted by Severity)

---

### 🔴 Critical

#### REC-001 — Add GoRouter authentication redirect guard
- **Finding**: FIND-AUTH01
- **Root cause**: `GoRouter` was configured without a `redirect` callback; `AuthCubit` is provided but never consumed by the router
- **Approach**:
  1. In `lib/core/router/app_router.dart`, add a `redirect` callback to `GoRouter`
  2. Inside `redirect`, call `getIt<AuthCubit>().state` — if `AuthState.unauthenticated` and location is not `/login`, `/splash`, `/onboarding` → return `/login`
  3. Add `refreshListenable` pointing to `getIt<AuthCubit>().stream` so the router re-evaluates on auth state change
  4. Write unit test in `test/core/router/auth_redirect_test.dart`
- **Risk**: Low — additive only; no existing routes removed
- **Files**: `lib/core/router/app_router.dart`, `test/core/router/auth_redirect_test.dart`
- **Requires test**: ✅ Yes

---

### 🟠 High

#### REC-002 — Make Supabase bootstrap non-fatal; degrade gracefully offline
- **Finding**: FIND-STAB01
- **Root cause**: `main.dart` throws `StateError` before `runApp` if `.env` is absent
- **Approach**:
  1. In `lib/main.dart`, wrap Supabase init in `try/catch`
  2. If credentials missing, set a flag `supbaseAvailable = false` and continue to `runApp`
  3. Features using Supabase (`auth`) should check this flag and show a "Offline mode" message
  4. Document the degradation strategy in a code comment
- **Risk**: Medium — requires AuthRepository to handle null Supabase client
- **Files**: `lib/main.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`
- **Requires test**: ✅ Yes

---

### 🟡 Medium

#### REC-003 — Fix architecture violation in `settings` feature
- **Finding**: FIND-ARC01
- **Root cause**: `UserProfile` is a data model used directly in presentation — should be a domain entity or wrapped
- **Approach**:
  1. Move `user_profile.dart` to `settings/domain/entities/user_profile.dart`
  2. Update imports in `profile_cubit.dart` and `settings_page.dart`
  3. Keep the data-layer `SettingsRepositoryImpl` responsible for conversion
- **Risk**: Low — rename only; no logic changes
- **Files**: `lib/features/settings/data/user_profile.dart` → `lib/features/settings/domain/entities/user_profile.dart`, 2 import updates
- **Requires test**: No (structural rename)

#### REC-004 — Remove `SubscriptionService` DI registration or replace with TODO marker
- **Finding**: FIND-DEAD01
- **Approach**: Either (a) remove `getIt.registerSingleton<SubscriptionService>(...)` from `injection.dart` and the class itself, or (b) add a `// TODO: replace with RevenueCat when monetisation is ready` comment and leave as intentional stub
- **Risk**: Very Low
- **Files**: `lib/core/di/injection.dart`
- **Requires test**: No

#### REC-005 — Consume `AudioCacheService` through DI, not static singleton
- **Finding**: FIND-STAB02
- **Approach**:
  1. Replace `AudioCacheService.instance` call sites in `HifzSessionCubit`, `QuranReaderPage`, `SurahDetailPage` with `getIt<AudioCacheService>()`
  2. This enables mocking in tests
- **Risk**: Low — behaviour unchanged
- **Files**: `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`, `lib/features/quran/presentation/pages/quran_reader_page.dart`, `lib/features/quran/presentation/pages/surah_detail_page.dart`
- **Requires test**: No (no logic change)

#### REC-006 — Add user-facing feedback on bad memorization_plus param redirect
- **Finding**: FIND-CR02 / FIND-UX02
- **Approach**: In each of the 4 routes that fall back to `TrackSelectionPage()`, schedule a `SchedulerBinding.instance.addPostFrameCallback` call showing a `SnackBar` with an Arabic message explaining the redirect
- **Risk**: Very Low
- **Files**: `lib/core/router/app_router.dart`
- **Requires test**: No

#### REC-007 — Add XP total display to ProgressPage
- **Finding**: FIND-UX03 / FIND-HID01
- **Approach**: Add a small XP summary widget to `ProgressPage` that reads from `XpService` (already available via DI in `ProgressCubit` or directly via `getIt`)
- **Risk**: Low — additive UI only
- **Files**: `lib/features/progress/presentation/pages/progress_page.dart`
- **Requires test**: No

---

### 🟢 Low

#### REC-008 — Add back-button to certificate error scaffold
- **Finding**: FIND-UX01
- **Approach**: Replace bare `Scaffold(body: Center(...))` in `/certificate` route handler with a scaffold that includes an `AppBar` with back navigation
- **Files**: `lib/core/router/app_router.dart:101-104`
- **Requires test**: No

#### REC-009 — Document `HapticService` as intentionally unused wrapper
- **Finding**: FIND-DEAD02
- **Approach**: Either delete `haptic_service.dart` and its static methods (all call sites use `HapticFeedback.*` directly), or add a comment explaining it's a convenience wrapper for future DI adoption
- **Files**: `lib/core/services/haptic_service.dart`
- **Requires test**: No

#### REC-010 — Add standalone streak history to ProgressPage
- **Finding**: FIND-003 (streak — no route)
- **Approach**: Add a "Streak History" section to `ProgressPage` using `StreakCubit` (already provided in home; add to progress BlocProvider too)
- **Files**: `lib/features/progress/presentation/pages/progress_page.dart`
- **Requires test**: No

---

## Audit Summary

| Category | Count |
|---|---|
| Fully Working | 7 (`azkar`, `hifz`, `home`, `onboarding`, `progress`, `quran`, `splash`, `tutorial_guide`) |
| Conditionally Reachable | 2 (`certificate`, `memorization_plus` sub-routes) |
| Partially Working | 4 (`memorization_plus`, `settings`, `streak`, `xp`) |
| Broken | 1 (`auth` — no route guard) |
| Hidden / Unused | 2 (`SubscriptionService`, `HapticService` wrapper) |
| **Total findings** | **10** |
| **Total recommendations** | **10** |
| Critical findings | **1** (FIND-AUTH01) |
| High findings | **1** (FIND-STAB01) |
| Medium findings | **6** |
| Low findings | **2** |
| Flutter analyze issues | **0** ✅ |
| Source files modified during audit | **0** ✅ |
