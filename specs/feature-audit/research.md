# Research: Full Application Feature Audit

**Feature**: feature-audit | **Branch**: 001-feature-audit | **Date**: 2026-05-17

All decisions below are based on static analysis of the live codebase.
No files were modified during this research phase.

---

## Research Methodology

1. Read `lib/core/router/app_router.dart` — full route inventory
2. Read `lib/core/di/injection.dart` — full DI registration inventory
3. Read `lib/main.dart` — bootstrap sequence and Supabase initialization
4. Read `pubspec.yaml` — dependency inventory
5. Inspected each `lib/features/<name>/` directory tree for layer completeness
6. Read `lib/core/services/subscription_service.dart` — stub detection

---

## Decision Log

### D-001: Audit tool approach

- **Decision**: Static code analysis (file-tree inspection + import tracing) rather than
  device-level runtime testing
- **Rationale**: Runtime testing requires a physical device and `.env` Supabase credentials
  not available in this environment. Static analysis is sufficient to detect all structural,
  DI, routing, and architecture-layer issues called for in the spec.
- **Alternatives considered**: Instrumented test runs — rejected due to environment
  constraints and the read-only audit scope

### D-002: Feature count

- **Decision**: 14 features confirmed — matches `lib/features/` directory listing:
  `auth`, `azkar`, `certificate`, `hifz`, `home`, `memorization_plus`, `onboarding`,
  `progress`, `quran`, `settings`, `splash`, `streak`, `tutorial_guide`, `xp`
- **Rationale**: Direct directory enumeration

### D-003: Core services in scope

- **Decision**: 6 DI-registered services are first-class audit entities:
  `XpService`, `StreakService`, `AchievementService`, `SubscriptionService`,
  `AudioCacheService`, `AppSessionService`
- **Additional observation**: 3 further services exist under `lib/core/services/` but are
  NOT registered via GetIt: `HapticService`, `QuranAudioService`, `NotificationService`
  (the last is registered as `TaliaNotificationService.instance` at bootstrap, not via GetIt)
- **Rationale**: Spec Q2 answer; DI registration is the boundary for first-class status

---

## Preliminary Findings (Pre-Audit Evidence)

These are concrete signals discovered during Phase 0 research. They are categorised
and will be detailed further in the audit report (research.md serves as evidence base).

### FIND-001: `SubscriptionService` — Stub, uninjected

- **Category**: Hidden/Unused (service level) + Dead Code
- **Severity**: Medium
- **Evidence**: `subscription_service.dart` is a 22-line stub. All methods return `true`.
  No Cubit in `injection.dart` receives `SubscriptionService` as a constructor parameter.
  It is registered as a singleton but never consumed.
- **Impact**: Subscription gating logic is completely absent at runtime. No premium
  enforcement exists anywhere in the feature tree.

### FIND-002: `xp` feature — Data layer only, no domain or presentation

- **Category**: Partially Working / Hidden
- **Severity**: Medium
- **Evidence**: `lib/features/xp/` has only a `data/models/` directory. No domain layer,
  no presentation layer, no Cubit registered for `xp` directly. XP logic lives entirely
  inside `XpService` (a core service) and is called directly from `HifzSessionCubit` and
  `KidsModeCubit` via DI injection of `XpService`. The `xp` feature directory is effectively
  a data-model-only module with no feature lifecycle of its own.
- **Impact**: XP accumulation works (via `XpService`) but there is no dedicated XP page,
  no XP display screen, no XP history. Users cannot view their total XP independently.

### FIND-003: `streak` feature — No presentation route

- **Category**: Partially Working
- **Severity**: Low
- **Evidence**: `lib/features/streak/` has `data/`, `domain/`, and `presentation/cubits/`
  but NO pages directory and no route in `app_router.dart`. `StreakCubit` is registered in
  DI and presumably consumed by `HomeCubit` or home page widgets, but there is no standalone
  Streak screen.
- **Impact**: Streak data is computed and available but not independently navigable.

### FIND-004: `auth` — No route guard in router

- **Category**: Broken (auth-gate per FR-012 / spec Q3)
- **Severity**: Critical
- **Evidence**: `app_router.dart` defines no `redirect` callback on `GoRouter`. All routes
  are publicly accessible without any authentication check. `AuthCubit` and `AuthRepository`
  are registered, and a `LoginPage` + `/login` route exist, but nothing enforces that
  unauthenticated users are redirected to `/login` before accessing feature screens.
- **Impact**: Any user can deeplink to any screen without logging in.

### FIND-005: `certificate` feature — Conditionally Reachable, upstream trigger needs verification

- **Category**: Conditionally Reachable
- **Severity**: High (pending upstream verification)
- **Evidence**: The `/certificate` route requires `extra: {'award': CertificateAward, 'userName': String}`.
  If `extra` is null or `award` is null, a bare error scaffold is shown. No static button
  in the bottom-nav shell navigates to `/certificate`. Must be triggered from elsewhere
  (e.g., `AchievementService` callback or `HifzSessionCubit` completion event).
- **Impact**: If the upstream trigger is missing, users can never receive a certificate.

### FIND-006: `tutorial_guide` — Routed but no DI Cubit

- **Category**: Partially Working
- **Severity**: Medium
- **Evidence**: `TutorialGuidePage` has a route (`/tutorial-guide`) and a `presentation/`
  directory. No `TutorialGuideCubit` appears in `injection.dart`. Page likely manages its
  own state internally (StatefulWidget) — acceptable only if no business logic is required.
- **Impact**: If tutorial steps require persistence (tracking which steps the user completed),
  the lack of a persisted Cubit means progress is lost on navigation. Needs content review.

### FIND-007: `memorization_plus` routes with required params silently redirect

- **Category**: Conditionally Reachable
- **Severity**: Medium
- **Evidence**: Routes `/memorization-plus/daily-plan`, `/kids-journey`, `/kids`, `/quiz`
  all check `_isValidSurahId(surahId)` and fall back to `TrackSelectionPage()` on failure.
  This is a defensive pattern but means a bad deeplink silently drops the user at an
  unexpected screen with no error message.
- **Impact**: Poor UX on bad navigation; no user-facing explanation for the redirect.

### FIND-008: `Isar` schema missing `CertificateIsarSchema`

- **Evidence**: `Isar.open()` in DI opens schemas: `IsarAyahProgressSchema`,
  `StreakIsarSchema`, `XpIsarSchema`, `DailyActivityIsarSchema`. Certificate data is not
  persisted to Isar — `CertificateAward` appears to be a transient in-memory entity.
- **Severity**: Low — if certificate is not intended to be stored, this is correct by design.

### FIND-009: `HapticService`, `QuranAudioService` not registered in DI

- **Category**: Partially Working / Hidden
- **Severity**: Medium
- **Evidence**: `lib/core/services/haptic_service.dart` and `quran_audio_service.dart` are
  present but not registered via GetIt. If they are used, they are either accessed as
  static/singleton singletons outside the DI container or unused.
- **Impact**: Bypasses DI conventions; makes testing and mocking harder.

### FIND-010: Bootstrap throws `StateError` on missing `.env`

- **Severity**: High (deployment risk)
- **Evidence**: `main.dart` lines 88–93 throw `StateError('Missing Supabase configuration')`
  if `.env` is absent or empty. This would show `_StartupFailureApp` to end users if the
  `.env` file is accidentally omitted from a release build.
- **Impact**: Entire app unusable without Supabase credentials at startup. Offline-first
  principle (Constitution §IV) is violated at the bootstrap level.

---

## NEEDS CLARIFICATION: None

All technical unknowns have been resolved through direct codebase inspection.

---

## Summary Table

| Finding | Feature/Service | Category | Severity |
|---------|----------------|----------|----------|
| FIND-001 | SubscriptionService | Dead Code / Unused | Medium |
| FIND-002 | xp | Partially Working | Medium |
| FIND-003 | streak | Partially Working | Low |
| FIND-004 | auth | Broken (no gate) | **Critical** |
| FIND-005 | certificate | Conditionally Reachable | High |
| FIND-006 | tutorial_guide | Partially Working | Medium |
| FIND-007 | memorization_plus routes | Conditionally Reachable | Medium |
| FIND-008 | certificate/Isar | Design Intent | Low |
| FIND-009 | HapticService, QuranAudioService | Partially Working | Medium |
| FIND-010 | Bootstrap / .env | Broken (offline violation) | **High** |
