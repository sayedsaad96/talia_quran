# Functional flow audit — assigned scope

**Scope and method.** Read-only trace of the current source at HEAD `1eefc8ae46639cf4026b6d7c7328ff4d36d3a0d6`, using the current `inventory.md` only as a coverage map. I inspected router guards and recovery, onboarding/auth/account ownership, adult V2/daily-plan/listening/revision flows, kids/guardian/family, Khatmah, and progress/streak/XP event propagation. I did not run Flutter or device/UI commands, and did not inspect release configuration. Consequently, observations marked **verified** are source-level traces; device behavior, OS permissions, Supabase availability, and rendering remain **unverified**.

## Findings

### P2 Major — Quran search can render stale results for a newer query

- **Status:** Verified source defect.
- **Feature / flow:** Quran search → type/refine a query → choose a surah or ayah result.
- **Evidence:** Each debounce starts an independent asynchronous lookup (`lib/features/quran/presentation/pages/quran_search_page.dart:34-38`). `_search` saves the newer query, awaits the use case, and applies its result if the widget is mounted, with no request generation or check that the completing query is still `_query` (`quran_search_page.dart:41-61`). Result taps navigate directly to the displayed surah/page (`quran_search_page.dart:105-137`).
- **Reproduction / trace:** Start a lookup for query A, then type query B after A begins but before it completes. If B completes first and A completes last, A overwrites the results while `_query` remains B. The user sees and can open A’s results under B’s search term. This is deterministic with a delayed fake use case and is possible during slower initial dataset reads or a busy device.
- **Impact:** Search can send a reader to an ayah/surah unrelated to what they entered, undermining a primary Quran navigation path.
- **Recommended fix:** Assign a monotonically increasing request id (or compare a captured, trimmed query to `_query`) after `await`; discard completions that are no longer current. Preserve a separate error state so failed search is not represented as “no results.” Add a widget test for out-of-order A/B completions.

### P2 Major — Parent dashboard converts a settings-read failure into “create a PIN”

- **Status:** Verified source defect.
- **Feature / flow:** Signed-in guardian → Family dashboard → initial PIN gate.
- **Evidence:** `FamilyDashboardCubit.load` discards a failed `getSettings()` result with `getOrElse(() => const ParentSettings())`, then treats the default as proof that no PIN exists (`lib/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart:33-41`). The view presents the create-PIN form for that state (`lib/features/memorization_plus/presentation/pages/family_dashboard_page.dart:119-127`).
- **Reproduction / trace:** Cause `ParentAccessUsecase.getSettings()` to return `Left` (for example, temporarily unavailable/corrupt local settings). Open `/family-dashboard`. The user is offered a new PIN rather than an error/retry state; submitting it invokes `setPin` (`family_dashboard_cubit.dart:44-59`).
- **Impact:** A guardian is told the existing protection is absent when it could not be read. This is misleading and risks replacing a recoverable PIN configuration, while masking the actual storage failure.
- **Recommended fix:** Branch explicitly on `settingsResult`. Emit a recoverable error state on failure and reserve `FamilyDashboardNeedsPin` for a successful read of settings with no PIN. Retain the original settings failure in the UI and add a cubit/widget test for the failed-read path.

### P2 Major — A transient dashboard load failure after a correct PIN makes the parent start the unlock flow again

- **Status:** Verified source defect.
- **Feature / flow:** Guardian returns to dashboard → enters correct PIN → remote/local dashboard load fails → retry.
- **Evidence:** `unlock` moves to `FamilyDashboardLoading` before calling `refresh` (`lib/features/memorization_plus/presentation/cubits/family_dashboard_cubit.dart:76-92`). `refresh` preserves a screen only if its *previous* state was `FamilyDashboardLoaded`; from loading it emits `FamilyDashboardError` (`family_dashboard_cubit.dart:95-123`). The error widget’s only retry calls `load()` (`lib/features/memorization_plus/presentation/pages/family_dashboard_page.dart:113-117`), which returns to `FamilyDashboardLocked` whenever a PIN exists (`family_dashboard_cubit.dart:33-42`).
- **Reproduction / trace:** Set a PIN, enter it successfully, then make `GetFamilyDashboardUsecase` fail once (offline/cloud error). Tap Retry. The dashboard returns to the PIN prompt even though the PIN was already verified in this visit; repeating the failure repeats the cycle.
- **Impact:** A normal network interruption blocks the parent from retrying data retrieval and forces repeated secret entry. This is especially disruptive when the parent is pairing, reviewing a child, or recovering from an unreliable connection.
- **Recommended fix:** Keep an unlocked-but-error state (or preserve a verified-session flag) and retry `refresh()` directly. Only require the PIN again after an explicit lock, app/session expiry, sign-out, or configured inactivity timeout. Add a widget-level retry trace: correct PIN → failed load → retry → loaded, with no second PIN entry.

### P3 Minor — Progress UI silently reports zero XP / no heatmap when secondary local reads fail

- **Status:** Verified source defect.
- **Feature / flow:** Progress tab and subsequent XP event refreshes.
- **Evidence:** `ProgressCubit` deliberately catches heatmap and XP exceptions and substitutes `null` and `0` (`lib/features/progress/presentation/cubits/progress_cubit.dart:121-150`); the loaded state then renders those as an empty activity map and zero XP (`progress_cubit.dart:89-98`). XP-only updates repeat the same fallback (`progress_cubit.dart:106-118`). No failure marker is carried in `ProgressLoaded`.
- **Reproduction / trace:** Make `XpService.getTotalXp()` or the heatmap use case throw while the main `GetProgressUsecase` succeeds. Open or refresh Progress. The page stays “loaded” and represents the unavailable values as real zero/empty values.
- **Impact:** A user can conclude that achievements or activity disappeared after a storage/read failure, rather than understanding that part of the dashboard could not be loaded.
- **Recommended fix:** Model availability/error separately for optional cards; retain the last known values when available and show a small retry/status affordance otherwise. Add tests for failed XP and heatmap reads asserting that they are not rendered as confirmed zero activity.

## Coverage and evidence gaps

| Assigned area | Static trace result | Runtime / behavioral gap |
|---|---|---|
| Onboarding, audience selection, guest/sign-in continuation | Verified persistence of first-open, audience and path selection; route redirect and retry errors were traced in `onboarding_cubit.dart` and `app_router.dart`. | Unverified on fresh install, back/skip motion, locale and real offline persistence failure. |
| Quran search and settings | Verified local search debounce/result routing and Settings hub route/pushed-subpage composition. Search has the stale-response defect above; settings read/write failures still require device interaction coverage. | Unverified Arabic normalization at realistic data size, rapid typing on device, all setting persistence after restart, and denied notification/location permissions. |
| Auth, account switching, sign-out | Verified guarded family routes, account reset/flush paths and post-login route logic. Existing tests include account isolation and cloud merge. | Unverified Supabase reset-link, sign-in offline, interactive force-sign-out and actual cloud conflict/recovery. |
| Adult memorization V2, daily plan, practice/revision | Verified source states for loading/error/retry, leave confirmation, persistence rollback, event bus notifications and route validation. | Unverified full device session, microphone/audio interruption, kill-and-resume, repeated completion and sync after reconnection. |
| Listening review | Verified corpus load, not-enough-content and audio replacement paths in `listening_review_cubit.dart`; page/cubit tests exist. | Unverified speech permission denial, Arabic recognition availability, background interruption and real uncached/offline audio. |
| Kids, guardian linking and family | Verified kids/adult route guards, guardian polling/timeout, guest continuation, PIN recovery and child-detail fallback. | Unverified QR scanner/pairing across two accounts/devices, link expiry/revocation and return/back behavior on a physical device. |
| Khatmah and reader handoff | Verified mode-specific reading confirmation, retry and completion navigation (`quran_reader_page.dart:354-405`); Khatmah has broad unit/widget/integration test files. | Unverified reader gesture/timing, app background during a pending page confirmation, notification entry, and physical-device completion. |
| Progress/streak/XP/certificates | Verified progress-event subscriptions and local/cross-feature update paths; snapshot consistency integration test exists. | Unverified user-visible consistency after a real session, account switch, clock/time-zone change, and partial local-read failure (finding above). |

## Test coverage gaps worth closing

The repository has focused unit/widget/contract tests and four top-level integration tests (`test/integration/account_switch_isolation_test.dart`, `progress_snapshot_consistency_test.dart`, `offline_plan_sync_gate_test.dart`, and `cloud_pull_merge_integration_test.dart`). None are device-driven end-to-end tests for the assigned flows. Priority additions are:

1. Family dashboard failed-settings-read and verified-PIN/retry behavior described in the P2 findings.
2. Fresh-install adult and child onboarding through restart, plus guest-to-account upgrade and back navigation.
3. Adult V2 session interruption/resume after audio/speech failure and after process recreation.
4. Two-device guardian QR link, expired token, unlink, and account-switch isolation.
5. Khatmah reader timer/gesture → persisted page → background/resume → completion route.
6. Progress optional-data failure states, ensuring unavailable XP/activity never appears as confirmed zero.

No P0/P1 functional defect was established in this static review. All paths listed as runtime gaps remain **unverified**, rather than passing.
