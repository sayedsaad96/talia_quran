# Memorization System Release — Implementation Tasks

Source: [`memorization_system_release_audit.md`](../audits/memorization_system_release_audit.md)

## Priority Legend

| Priority | Meaning | Release Gate |
| :--- | :--- | :--- |
| **P0** | Must fix before release | Blocks release |
| **P1** | Should fix before release | Strongly recommended |
| **P2** | Nice to have | Post-release acceptable |

## Complexity Legend

| Code | Meaning | Approx. Effort |
| :--- | :--- | :--- |
| **S** | Small | ≤ 2 hours |
| **M** | Medium | 2–4 hours (half day) |
| **L** | Large | 0.5–1 day |

---

## P0 — Must Fix Before Release

### T-01 — Create `MemorizationPathResolver` helper
- **Priority:** P0
- **Complexity:** M
- **Phase:** 0 — Single Source of Truth
- **Resolves:** H-2, C-1 (foundation)
- **Files:** `lib/core/memorization/memorization_path_resolver.dart` **[NEW]**
- **Description:** Implement a singleton-style helper exposing:
  - `Future<MemorizationProfile> currentProfile()`
  - `bool isKids(profile)` / `bool isAdult(profile)`
  - `Stream<void> changes` driven by a `ValueNotifier` triggered on path save/reset
- **Acceptance:** Resolver compiles, exposes required API, and unit test confirms cache + stream behavior.

### T-02 — Wire path mutations to resolver
- **Priority:** P0
- **Complexity:** M
- **Phase:** 0 — Single Source of Truth
- **Resolves:** H-2, C-1, P-2
- **Files:**
  - `lib/features/hifz/presentation/cubits/hifz_cubit.dart` **[MODIFY]**
  - `lib/features/memorization_plus/presentation/cubits/memorization_identity_cubit.dart` **[MODIFY]**
  - `lib/features/memorization_plus/presentation/cubits/track_selection_cubit.dart` **[MODIFY]**
  - `lib/features/memorization_plus/presentation/widgets/memorization_path_settings_sheet.dart` **[MODIFY]**
- **Description:** Each Cubit/widget that writes the active path must call `MemorizationPathResolver.notifyChanged()` after a successful save/reset. Legacy `mem_plus_track`, `mem_plus_is_parent_mode`, and `hifz_path_mode` writes remain untouched.
- **Acceptance:** Switching path from any entry point triggers a stream emission consumed by `HomeCubit`.

### T-03 — Make `HomeCubit` async + reactive to resolver
- **Priority:** P0
- **Complexity:** M
- **Phase:** 1 — Path-Aware Home Screen
- **Resolves:** H-2
- **Files:** `lib/features/home/presentation/cubits/home_cubit.dart` **[MODIFY]**
- **Description:**
  - Replace synchronous `getSelectedTrack()` with `await _memorizationRepository.getMemorizationProfile()`.
  - Subscribe to `MemorizationPathResolver.changes` and re-emit `HomeState` on each event.
  - Dispose the stream subscription on `close()`.
- **Acceptance:** No more sync preference reads; home state refreshes immediately on path change without manual reload.

### T-04 — Path-aware home layout (cards & sections)
- **Priority:** P0
- **Complexity:** L
- **Phase:** 1 — Path-Aware Home Screen
- **Resolves:** H-1, H-3, H-4
- **Files:**
  - `lib/features/home/presentation/pages/home_page.dart` **[MODIFY]**
  - `lib/features/home/presentation/pages/home_page_widgets.dart` **[MODIFY]**
- **Description:**
  - **Kids profile:** hide `_MemorizationPlusCard` and adult `_ActiveCustomPlanCard`; show `_KidsHubCard` (→ `/memorization-plus/kids-home`) and `_ParentDashboardShortcutCard`.
  - **Adult profile:** retain current cards.
  - Update `_NextBestActionCard` with kid-friendly captions and route to kids-home for child profiles.
  - Update `_ProgressSection` to display kids points only and hide the "0/6236 verses" stat for children.
- **Acceptance:** Home renders the correct card set for each profile; no adult-styled labels leak into kids UI.

### T-05 — Centralized `MemorizationPathRouterScreen`
- **Priority:** P0
- **Complexity:** M
- **Phase:** 2 — Centralized Path Routing Screen
- **Resolves:** R-3, R-4
- **Files:**
  - `lib/core/router/memorization_path_router.dart` **[NEW]**
  - `lib/core/router/app_router.dart` **[MODIFY]**
- **Description:**
  - Create a `StatelessWidget` that reads the active profile and returns the correct destination (kids-home, custom-plan, daily-plan, etc.).
  - Refactor `app_router.dart` redirects (`/memorization-plus`, `/hifz`, `/hifz/session`, kids-guard routes) to delegate to this screen.
- **Acceptance:** All scattered redirect rules are funneled through one widget; no duplicate guard logic remains.

---

## P1 — Should Fix Before Release

### T-06 — Defensive kids check in `HifzSessionCubit`
- **Priority:** P1
- **Complexity:** S
- **Phase:** 4 — Basic Memorization Isolation
- **Resolves:** U-2
- **Files:** `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart` **[MODIFY]**
- **Description:** Reject initialization of a basic session if the active profile is a child. Emit a `failure` state and trigger a redirect to `/memorization-plus/kids-home`.
- **Acceptance:** Direct navigation to `/hifz/session` with a kids profile is blocked at the Cubit level, not only at the router.

### T-07 — Adult-only `MemPlusBanner` on `HifzPage`
- **Priority:** P1
- **Complexity:** S
- **Phase:** 4 — Basic Memorization Isolation
- **Resolves:** H-1 (partial)
- **Files:** `lib/features/hifz/presentation/pages/hifz_page.dart` **[MODIFY]**
- **Description:** Render the `MemPlusBanner` (CTA to `/memorization-plus`) only when the active profile is adult; hide for kids.
- **Acceptance:** Banner disappears for child profiles and is visible for adults.

### T-08 — Smart path gates: defensive checks
- **Priority:** P1
- **Complexity:** S
- **Phase:** 3 — Smart Memorization Route Enforcements
- **Resolves:** R-3 (smart side)
- **Files:**
  - `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart` **[MODIFY]**
  - `lib/core/router/app_router.dart` **[MODIFY]**
- **Description:**
  - `DailyPlanPage`: render a fallback / empty state if loaded with a child profile.
  - `/memorization-plus` (and any ambiguous smart sub-routes) fall back to `MemorizationPathRouterScreen` when parameters are missing or invalid.
- **Acceptance:** Smart routes cannot be entered with a child profile or ambiguous state.

### T-09 — Add path-separation widget tests (Scenarios A–J)
- **Priority:** P1
- **Complexity:** L
- **Phase:** 9 — Verification & Testing
- **Resolves:** D-1
- **Files:**
  - `test/features/home/home_page_path_aware_test.dart` **[NEW]**
  - `test/core/router/memorization_path_router_test.dart` **[NEW]**
  - `test/features/hifz/hifz_session_kids_guard_test.dart` **[NEW]**
- **Description:** Cover at minimum:
  - **A** Child + Basic → Kids UI
  - **B** Child + Smart → Kids UI
  - **C** Adult + Basic → Adult Basic UI
  - **D** Adult + Smart → Adult Smart UI
  - **E/F** Path flip Kids ↔ Adult → Home re-evaluates
  - **G/H** Ayah completion updates only the matching progress model
  - **I** Opening a screen does not increment progress
  - **J** App restart restores active path and stores
- **Acceptance:** All 10 scenarios pass in CI; coverage for path-isolation widgets ≥ 80%.

### T-10 — Resolve "0/6236 verses" global stat for kids
- **Priority:** P1
- **Complexity:** S
- **Phase:** 1 — Path-Aware Home Screen (cleanup)
- **Resolves:** H-3, P-1
- **Files:**
  - `lib/features/home/data/repositories/progress_repository_impl.dart` **[MODIFY]**
  - `lib/features/home/presentation/pages/home_page_widgets.dart` **[MODIFY]**
- **Description:** `progress_repository_impl.dart:30` and `:144` must return a path-scoped value. For kids, return kids points / completed ayahs only; never the global 6236 denominator.
- **Acceptance:** Stats widget never shows "0/6236" for kids profiles; shows points/level instead.

---

## P2 — Nice to Have

### T-11 — Tag legacy SharedPreferences keys as deprecated
- **Priority:** P2
- **Complexity:** S
- **Phase:** 5 — Store De-Duplication
- **Resolves:** C-1 (doc-only)
- **Files:**
  - `lib/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart` **[MODIFY]**
- **Description:** Add inline `// LEGACY:` documentation comments on the `mem_plus_track`, `mem_plus_is_parent_mode`, and `kHifzPathMode` writers. Do not delete or stop writing the keys.
- **Acceptance:** Each legacy write site carries a clear deprecation tag pointing to the resolver.

### T-12 — Extract path-aware card factory
- **Priority:** P2
- **Complexity:** M
- **Phase:** 1 — Path-Aware Home Screen (refactor)
- **Resolves:** Maintainability of H-1
- **Files:** `lib/features/home/presentation/pages/home_page_widgets.dart` **[MODIFY]**
- **Description:** Replace scattered `if (isKids)` blocks with a `HomeCardsFactory.build(profile)` returning a typed list of card descriptors. Reduces future drift between kids and adult card sets.
- **Acceptance:** No inline profile checks remain inside individual card widgets.

### T-13 — Add `MemorizationPathResolver` instrumentation logs
- **Priority:** P2
- **Complexity:** S
- **Phase:** 0 — Single Source of Truth (observability)
- **Resolves:** Future debuggability
- **Files:** `lib/core/memorization/memorization_path_resolver.dart` **[MODIFY]**
- **Description:** Add a one-line debug log on each `notifyChanged()` (gated by `kDebugMode`) so QA can trace path switches.
- **Acceptance:** Logs visible in debug builds only; release builds remain silent.

### T-14 — Documentation: path-isolation architecture note
- **Priority:** P2
- **Complexity:** S
- **Phase:** Cross-cutting
- **Resolves:** Onboarding risk
- **Files:** `docs/architecture/memorization_paths.md` **[NEW]**
- **Description:** Short architecture note covering: the resolver, the centralized router screen, the card factory, and the testing matrix. Cite the audit and tasks file.
- **Acceptance:** Note renders correctly in repo docs; links to the audit + tasks.

---

## Cross-Reference: Audit Issue → Task

| Issue | Severity | Task(s) |
| :--- | :--- | :--- |
| H-1 | High | T-04, T-07 |
| H-2 | High | T-01, T-02, T-03 |
| P-1 | High | T-10 |
| C-1 | Medium | T-01, T-02, T-11 |
| H-3 | Medium | T-04, T-10 |
| H-4 | Medium | T-04 |
| P-2 | Medium | T-02, T-03 |
| U-2 | Medium | T-06 |
| R-3 | Medium | T-05, T-08 |
| R-4 | Medium | T-05 |
| D-1 | Medium | T-09 |

## Execution Order (dependency-respecting)

1. T-01 → T-02 → T-03 → T-04 → T-10 (Phase 0 → 1 path)
2. T-05 (Phase 2 — independent of T-04 but required before T-08)
3. T-08, T-06, T-07 (Phase 3 & 4 — all require T-05)
4. T-09 (tests — run after T-04, T-05, T-06, T-08 are in)
5. T-11, T-12, T-13, T-14 (P2 — anytime after P0/P1 land)

## Total Effort Estimate

| Priority | Count | Estimated Effort |
| :--- | :--- | :--- |
| P0 | 5 tasks | ~3.0 days |
| P1 | 5 tasks | ~2.0 days |
| P2 | 4 tasks | ~1.0 day |
| **Total** | **14 tasks** | **~6.0 days** |
