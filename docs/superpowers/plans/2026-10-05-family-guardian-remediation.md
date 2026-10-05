# Family / Guardian remediation plan — 2026-10-05

Source: guardian & family dashboard review (2026-10-05), re-verified against the
code and the live `Talia_Quran` Supabase project the same day.

## Product decisions

| Topic | Decision |
|---|---|
| Gift "claim" | The child sends a **receipt request**; the guardian **approves** it. |
| Children per device | **One child per device** in this phase. Multi-child on one device is out of scope. |
| Guardian session on the child device | 10 minutes of inactivity, or leaving the app for more than 2 minutes, ends the session and returns to the same child journey. |
| Inbound refresh on the child device | Always on pull-to-refresh and when the kids home opens; on app resume when the last inbound pull is older than 5 minutes. |

## Verified status of the review findings

| # | Finding | Status |
|---|---|---|
| 1 | Gift cycle has no unlock/claim UI | Confirmed |
| 2 | New missions not pulled on child refresh/resume | Confirmed (also applies to guardian policies) |
| 3 | No temporary guardian session; path reset does not revoke the link | Confirmed |
| 4 | One local child per device | Confirmed; accepted for this phase (decision above) |
| 5 | App ignores `activity_snapshot`; never publishes it | Confirmed against live RPC |
| 6 | Tracked ayahs use review count | Confirmed against live RPC only: live `review_count = SUM(total_reviews)`, new `tracked_count = COUNT(*)` |
| 7 | Network failure hides remote children | Confirmed (`memorization_family_service.dart`, remote error swallowed) |
| 8 | Sequential per-child mission/policy reads | Confirmed |

Additional findings:

- **P1** Live migration `20261004132950_family_activity_and_parent_recovery` was missing from `supabase/migrations/`. **Fixed in Phase 0.**
- **P2** Live dashboard certificates now come only from the activity snapshot, which the app never publishes → always empty.
- **P2** PIN recovery RPCs exist on the server with no client.
- **P3** Child-side `unlinkGuardian()` has no use case or UI.
- **P3** Parent dashboard mission read failure renders as an empty list.
- **P3** Hard-coded Arabic strings in the data layer (`'طفلي'`, `'طفل تالية'`).
- **P3** `family_dashboard_page.dart` (1124 lines), `child_detail_page.dart` (944), `memorization_kids_cloud_sync_service.dart` (857) exceed the 500-line rule; new UI goes into extracted widgets.

## Phase 0 — schema drift (done)

- [x] Add the deployed migration verbatim (MD5 matches `schema_migrations.statements`).
- [x] `verify_supabase_contract.ps1`: new tables, five new RPCs, security-definer/search-path, table privileges, dashboard `tracked_count`/`activity_snapshot`.
- [x] Drift guard: every deployed migration since `20260912035000` must exist in the repository.
- [x] `test/supabase/family_activity_and_parent_recovery_contract_test.dart`.

## Phase 1 — data correctness and delivery (P1/P2)

### 1.1 Dashboard contract (done)
- [x] `buildProductionSummaryFromAggregates`: `totalAyahsTracked` ← `tracked_count ?? review_count`; `reviewsCompleted` ← `review_count`.
- [x] Parse `activity_snapshot` into `RemoteChildActivity` (on `RemoteChildSummary.activity`); streak and active days fall back to it when the legacy rows are empty. Certificates already arrive through the dashboard `certificates` field.
- [x] Null activity = "no data received yet" (`ChildActivitySummary` panel in child detail, linked children only).
- [x] `MemorizationFamilyService` keeps the activity via `RemoteChildSummary.copyWith`.
- [x] Tests: `remote_children_dashboard_mapper_test.dart`, `child_activity_summary_test.dart`.
- Note: the panel stays "not received" until 1.2 publishes snapshots.

### 1.2 Publish activity from the child device — done 2026-10-05
- Implemented: `family_activity_publisher.dart`, inputs resolved lazily in `core/di/family_activity_inputs_loader.dart`, published inside `syncKidsProgressToCloud` (transient failure → `Left`, so the coordinator's `kidsProgressPush` queue retries; "Child account required"/"Invalid family activity" are terminal). Unchanged snapshots are not re-sent. A confirmed reading page notifies `ProgressChangedReason.kidsProgress`, which triggers the debounced kids push.
- Tests: `family_activity_publisher_test.dart`, `kids_reading_receipt_store_test.dart` (`allPages`, `onRecorded`).
- Stable per-install `device_id`; revision only grows, persisted per owner; server limits enforced in `buildSnapshot`.
- Not verified on a device against the live server yet.

### 1.3 Inbound missions and policies — done 2026-10-05
- `pullKidsInboundFromCloud()` (gifts + home missions + policy) split out of the progress pull; `pullKidsProgressFromCloud` now runs it even when the progress part fails. Exposed through the small `KidsInboundRepository` interface (no change to `MemorizationPlusRepository`, so existing fakes are untouched).
- `KidsInboundRefresher` (app-lifetime singleton): forced on kids-home open and pull-to-refresh; resume pulls only when the last successful pull is older than 5 minutes; concurrent calls share one pull; a failed pull does not start the throttle.
- `KidsJourneyCubit.refreshFromGuardian` / `refresh`: reload in place (no loading flash); a load generation counter stops an older load from overwriting a newer one. The policy controller reloads through the existing `onKidsPolicyChanged` hook and on every home load.
- `resumeIfNeeded` doc comment and log message corrected (resume only pushes pending local work).
- Tests: `kids_inbound_refresher_test.dart`, `kids_journey_cubit_guardian_refresh_test.dart`, new "guardian refresh" group in `kids_gamified_home_page_test.dart`.
- Not verified on a device against the live server yet.

### 1.4 Gift cycle (request → approve) — done 2026-10-05
- Migration `20261005170359_parent_reward_request_approval.sql`: status `requested` + `requested_at`; `request_parent_reward` (child, `unlocked → requested`) and `approve_parent_reward` (guardian, `requested → claimed`), both idempotent, row-locked, link-checked; `unlock_parent_reward` idempotent for requested/claimed; `claim_parent_reward` now only files a request. Verifier entries + `parent_reward_request_approval_contract_test.dart`.
- Applied to the live project on 2026-10-05 (version `20261005170359`, file renamed to match for the drift guard). Verified live: constraint includes `requested`, `requested_at` exists, all four RPCs are security definer with empty search_path, executable by `authenticated` only (not `anon`); the one existing gift stays `locked`. Not run on a fresh database (no Docker/psql locally).
- `ParentRewardStatus.requested` is appended (stored by index); unknown indexes read as locked.
- `ParentRewardRepository` + `ParentRewardUsecase` (separate interface, existing fakes untouched). Request goes remote when a cloud user is signed in; unlock/approve go remote only for a linked child. Guardian steps no longer write into the device's local gift cache.
- Guardian UI: `ChildRewardsPanel` in child detail (requested first; unlock / confirm hand-over; busy guard). Child UI: gifts section in «كنوزي» (`KidsGiftCard`, request button for unlocked gifts only, double-tap guard, snackbar on refusal).
- Tests: `parent_reward_transitions_test.dart`, gift groups in `kids_treasures_cubit_test.dart`, `family_dashboard_cubit_test.dart`, `kids_treasures_page_test.dart`, `remote_children_dashboard_mapper_test.dart`, plus `child_rewards_panel_test.dart`.
- Not verified on a device against the live server yet.

### 1.5 Offline dashboard — done 2026-10-05
- `FamilyDashboard.remoteStatus`: `live` / `cached` (with `remoteFetchedAt`) / `unavailable` / `notConnected` (signed out or no cloud config; no banner).
- `RemoteChildrenDashboardCache` (SharedPreferences, key per guardian account) keeps the raw `get_remote_children_dashboard` payload after each successful read; a failed read re-parses it. Another account on the device never reads it. The legacy row-by-row path is not cached.
- A saved copy skips the mission/policy reads and flags both unavailable (`homeMissionsUnavailable` is new; a failed live mission read is flagged too).
- UI: `FamilyRemoteStatusBanner` (time of the saved copy, retry); a failed read with no children shows the banner and the add-child tile, never the "no children" placeholder. Child detail shows "couldn't load home missions" instead of an empty list.
- Tests: `family_dashboard_offline_test.dart`, new "offline" group in `family_dashboard_page_test.dart`, a missions-unavailable case in `child_detail_page_test.dart`.
- Not verified on a device in airplane mode yet.

## Phase 2 — shared device and the link (P2)

### 2.1 Temporary guardian session — done 2026-10-05
- `application/guardian_session_controller.dart`: ends after 10 minutes without interaction, or on resume after more than 2 minutes in the background; remembers the kids location it was opened from.
- Entry: "Guardian area" tile in the kids settings sheet, only for an **unlinked** child with a PIN (a linked child's guardian manages from their own account; local writes there would diverge from the server). PIN once, no second gate in the dashboard (`FamilyDashboardCubit.guardianSessionActive`).
- Router: `parentDashboardRedirect` lets a child profile in only during a session (signed in or not); `redirectForAuth(guardianSessionActive:)` skips the sign-in requirement for the dashboard routes during a session. A session never lets a signed-out adult skip login.
- Data: on a child-profile device the dashboard shows the device's child from local data and skips the remote read (`notConnected`, no banner). "Link New Child" is hidden during a session.
- `GuardianSessionScope`: activity on the dashboard and child detail keeps the session alive; the dashboard owns it (lifecycle, end on leave). Timeout/background → back to the same kids route. "Back to child" button in the dashboard app bar.
- Tests: `guardian_session_controller_test.dart`, `guardian_session_scope_test.dart`, router guard matrix + `redirectForAuth`, cubit, dashboard page flow, settings-sheet tile, child-device service read.
- Not verified on a device yet.

### 2.2 Separate path switching from the link — done 2026-10-05
- `resetMemorizationIdentity()` and `selectMemorizationPath(adult)` in the repository first revoke the child's own link (`MemorizationParentAccessService.revokeOwnGuardianLink`, shared with `unlinkGuardian`). Any failure (offline, signed out, no counterpart id) returns `guardianUnlinkBeforePathChangeFailed` and changes nothing locally. Unlinked children and adults are unaffected; a guardian's own links to their children are kept.
- The kids settings sheet warns a linked child that changing the path removes the link and needs a connection; reset failures in the sheet and the custom-plan switch are now shown through `localizedCubitMessage`.
- Identity sync: reset marks identity dirty, and `pullIdentityFromCloud` skips while there is no path and the flag is set, so the old cloud path cannot come back before a new one is chosen (the new choice then wins by `updated_at`).
- Tests: repository group "leaving the kids path with a guardian link" (offline reset/adult blocked and link kept, unlinked child and adult reset, dirty flag), sheet warning + failure message.
- Not unit-tested: the successful server revoke and the pull skip (both need a Supabase client).

### 2.3 PIN recovery — done 2026-10-05
- RPCs were already live (migration `20261004132950`); no schema change.
- Data: `ParentPinRecoveryRepository` (small interface on the repository impl) backed by `collaborators/parent_pin_recovery_service.dart`. Device id shared with the activity publisher through `datasources/install_device_id.dart` (same prefs key). The new PIN is written with `setParentPin` only after `consume_parent_pin_recovery` returns true; codes are normalised (12 hex, spaces/dashes dropped) and malformed ones are never sent.
- Child: "Forgot the code?" in the kids-sheet PIN dialog, only for a **linked** child (recovery goes through the guardian). `ParentPinRecoveryDialog` + `PinRecoveryRequestCubit`: request → code from the guardian + new 4-digit PIN → on success the original action continues (the code proves guardianship like the PIN).
- Guardian: `ChildPinRecoveryPanel` + `PinRecoveryApprovalCubit` at the top of a linked child's detail page, hidden without open requests; approving shows the one-time code (grouped `XXXX-XXXX-XXXX`) and its expiry. Approving again issues a fresh code (server replaces the hash).
- Server limits stay authoritative: 10-minute request, 5 wrong attempts, active link required on both approve and consume.
- Tests: service (RPC params, parsing, error mapping, no call offline/bad code), both cubits, dialog + panel widgets, sheet forgot flow (linked only).
- Not covered: the kids listening page's own PIN prompt (`kids_gamified_listen_page.dart`) has no recovery link yet; end-to-end against live not run.

### 2.4 Child-side unlink — done 2026-10-05
- Hosted check (read-only): `revoke_guardian_link` is security definer, `authenticated` only (not `anon`), active links only, with the child-caller branch. **Drift fixed (approved):** live had `search_path=public` and lacked 0012's self-counterpart check; `20261005194008_harden_revoke_guardian_link.sql` re-applies 0012's definition. Verified live: security definer, `search_path=""`, self check present, `authenticated` only (not `anon`/`service_role`).
- `UnlinkGuardianUsecase` (any failure → `guardianUnlinkFailed`, nothing changes locally). "Remove guardian link" tile in the kids sheet for a linked child: explanation → guardian PIN (recovery allowed) → server revoke → local unlink.
- After unlink: received (claimed) gifts stay as history; locked/unlocked/requested gifts are dropped from the device (server rows untouched, they return on relink). Server-sourced home missions already drop on the next pull (RLS needs an active link; the merge drops missing server ids).
- Fix found on the way: the inbound pull replaced the whole gift list with server rows even for an unlinked child, wiping gifts made in the 2.1 guardian area. Gifts are now mirrored only while linked.
- `_GuardianPinDialog` moved to `widgets/guardian_pin_dialog.dart` (`verifyGuardianPin`) so the sheet stays under the size limit.
- The old "no unlink before hosted proof" contract test now forbids direct `unlinkGuardian(`/`removeChild(` calls in pages/widgets and pins the child unlink to `guardian_unlink_tile.dart`; guardian-side removal stays hidden.
- Tests: use case mapping, gift pruning, sheet tile (linked only, confirm + PIN, failure, wrong PIN), contract test.
- Not unit-tested: the inbound-pull gate and the pruning after a real revoke (need a Supabase client).

## Phase 3 — improvements (P3/P4) — partly done 2026-10-05

- **Done:** per-child mission/policy reads run in batches of `maxParallelChildReads` (4), kept in server order; each child's two reads run together. Linked children appear as soon as the dashboard RPC returns (`detailsLoading`); missions and policy fill in per batch. A later refresh drops the older stream. Cached/offline copies arrive in one event without loading marks. A throwing detail read flags that child instead of leaving it spinning.
- **Done:** «كنوزي» lists every open guardian mission (new first, oldest first, then reported and waiting), independent of the daily-suggestions slots, with "I did it!" on new ones (`KidsHomeMissionsUsecase`, `KidsHomeMissionCard`). When the guardian turns home missions off, the section shows a note instead of the list. The home card is unchanged (still one mission, still subject to the slot limit).
- **Done:** the child-name fallbacks («طفلي», «طفل تالية») left the data layer: unnamed children carry an empty name and the UI shows `familyChildUnnamed` (`FamilyChildName.shownName`). Names saved in the offline dashboard cache before this change keep the old text until the next live read.
- **Done:** the files that were over 500 lines are split into `part` libraries (same private API): `family_dashboard_page.dart` (cards, PIN/QR), `child_detail_page.dart` (sections, dialogs), `memorization_plus_repository_impl.dart` (identity and family mixins), `custom_plan_setup_page.dart` (range fields, selectors, form body, shared widgets). Some methods inside those types are still longer than 50 lines. Remaining Arabic literals in `memorization_production_sync_service.dart`, `memorization_cloud_gateway.dart` and the `'النص غير متوفر'` sentinel are outside the guardian flow.
- **Done:** `test/integration/guardian_session_gift_cycle_test.dart` covers one child device end to end, using the real repository, use cases, cubits, session controller and route guard:
  - with no session, the dashboard route is closed and the cubit stays locked;
  - in a session, the guardian adds a gift and unlocks it;
  - the session ends, and the child requests the gift;
  - an idle-expired session is locked again, and the PIN reopens it for the approval;
  - the child then sees the gift as claimed;
  - approving before the child asks is refused;
  - a long stay in the background ends the session.

  Two-device cloud delivery is still covered only by the manual matrix.

## Verification gates per phase

- Unit + widget tests for every change; integration test for the guardian session and gift cycle.
- `flutter analyze`, `flutter test`, `scripts/verify_v1_release.ps1`.
- `scripts/verify_supabase_migrations.ps1` on a fresh DB for every new migration; contract script against the live project after deployment.
- Manual two-device matrix (review section 7, minus multi-child-same-device) before release sign-off.
