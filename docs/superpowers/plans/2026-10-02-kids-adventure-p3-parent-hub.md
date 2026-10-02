# Kids Adventure P3 — Parent Hub: Home Missions and Child Policies — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- **Home missions.** The guardian assigns them, the child reports them done, and the guardian acknowledges them. This works on the child's device (PIN) and from the guardian's own account.
- **Per-child policies.** Reduce motion, number of daily suggestions, home missions on/off, and session goal minutes. Each policy has a version, so a newer setting is never silently replaced by an older one.

**Architecture:**
- **Home missions mirror the `parent_rewards` path end to end.**
  - Local list in `memorization_kids_storage.dart`.
  - SECURITY DEFINER RPCs for every remote transition.
  - The child pulls inside `pullKidsProgressFromCloud` and pushes pending reports inside `syncKidsProgressToCloud`, so there is no new queue kind.
- **Policies.**
  - They live on `ParentSettings`, plus a `policyVersion`.
  - Remotely they are a single row per child, changed only through `compare_and_swap_child_policy` (same CAS style as `compare_and_swap_daily_plan`).
  - The kids UI reads them through a `KidsPolicyController` (a `ValueNotifier`, same pattern as P1's world controller).

**Tech Stack:** Flutter, flutter_bloc, get_it, SharedPreferences, Supabase (Postgres RPC + RLS), PowerShell contract scripts, flutter_test.

**Spec:**
- [Roadmap & decisions](2026-10-02-talia-adventure-v1-roadmap.md)
- [Adventure design §4 (mixed missions), §8, §9, §12, §13.4, §13.6](../specs/2026-09-30-talia-adventure-design.md)
- Depends on [P2](2026-10-02-kids-adventure-p2-missions-treasures.md) (`KidsDailyMissionKind.home`, `resolveKidsDailyMissions`).

## Global Constraints

- P1 and P2 Global Constraints apply.
- Home mission text is **written by the guardian** (1–120 characters, trimmed) or chosen from the built-in **non-religious** suggestions below. No religious instruction text in v1.
- States: `assigned → reported → acknowledged`.
  - Only the child reports; only the guardian acknowledges.
  - Acknowledgement is labelled «اطّلع ولي الأمر» ("Seen by guardian"), never "verified".
- The PIN never leaves the device. Remote calls authorize through `auth.uid()` and an `active` row in `parent_child_links`.
- New SQL goes in a **new** migration `supabase/migrations/<UTC yyyyMMddHHmmss>_kids_home_missions_and_policies.sql`.
  - Every function is `SECURITY DEFINER SET search_path = ''` with schema-qualified names (pattern: `20260929195346_guardian_child_identity.sql`).
  - Revoke direct `INSERT/UPDATE/DELETE` from `authenticated`.
  - Never edit existing migrations.
- Policy limits: `max_daily_suggestions` 1–3 (default 3); `session_goal_minutes` NULL or 1–60; `reduce_motion` default false; `home_missions_enabled` default true.
- One child per device (owner decision 2026-09-29). No sibling switcher.

**Built-in suggestions** (ARB keys; Arabic / English):

| Key | ar | en |
|---|---|---|
| `kidsHomeMissionSuggestTidy` | رتّب غرفتك | Tidy your room |
| `kidsHomeMissionSuggestHelp` | ساعد في تجهيز المائدة | Help set the table |
| `kidsHomeMissionSuggestKind` | قل كلمة طيبة لأحد أفراد أسرتك | Say something kind to a family member |
| `kidsHomeMissionSuggestShare` | شارك لعبتك مع غيرك | Share your toy with someone |

## Review Focus

1. **The child reports while offline, then the guardian acknowledges from their phone before the report syncs:** the server refuses `acknowledge` on `assigned`. The guardian sees the mission still assigned. After the child syncs, the acknowledgement works. Pinned in Task 2 (SQL contract) and Task 4.
2. **The guardian edits the policy on their phone while the child's device (offline) edits it under PIN:** the second CAS fails with a version conflict. The device shows «تغيّرت الإعدادات من جهاز آخر» and reloads, with no silent overwrite. Pinned in Task 6.
3. **Link revoked:** all RPCs raise `Child link is not active`, the child's pull stops listing the guardian's missions, and the local copy is kept read-only. Pinned in Tasks 2 and 4.
4. **Policy `reduce_motion = true`:** every kids looping animation (world scene, Talia, rings, wave) stops even when the OS setting is off. Pinned in Task 7.
5. **`max_daily_suggestions = 1`:** only the learning card shows, and the home mission card is hidden even with assigned missions. Pinned in Task 7.

---

### Task 1: Home mission entity, local storage and repository API (unlinked child)

**Files:**
- Create: `lib/features/memorization_plus/domain/entities/kids_home_mission.dart`
- Modify:
  - `data/datasources/memorization_kids_storage.dart` (`getHomeMissions` / `saveHomeMissions`, mirroring `getParentRewards` / `saveParentRewards` at `:271-320`, key base `_kHomeMissions`)
  - `memorization_plus_local_datasource.dart` (interface)
  - `domain/repositories/memorization_plus_repository.dart`
  - `memorization_plus_repository_impl.dart`
  - `collaborators/memorization_kids_local_service.dart`
- Modify: `lib/core/error/app_failure.dart` (add `class ValidationFailure extends Failure { const ValidationFailure([super.message = CubitMessageCodes.errorUnknown]); }`, following `ParseFailure`; message code `'kids_home_mission_invalid_title'`)
- Test: `test/features/memorization_plus/data/kids_home_missions_local_test.dart`

**Interfaces:**
- Produces:

```dart
enum KidsHomeMissionStatus { assigned, reported, acknowledged }
final class KidsHomeMission extends Equatable {
  final String id; final String title; final KidsHomeMissionStatus status;
  final DateTime createdAt; final DateTime? reportedAt; final DateTime? acknowledgedAt;
  final bool pendingReportSync;   // reported locally, not yet on the server
  Map<String, dynamic> toJson(); factory KidsHomeMission.fromJson(Map<String, dynamic> json);
}
// repository
Future<Either<Failure, List<KidsHomeMission>>> getHomeMissions();
Future<Either<Failure, List<KidsHomeMission>>> addLocalHomeMission(String title);   // guardian, PIN-gated by caller
Future<Either<Failure, List<KidsHomeMission>>> reportHomeMission(String id);        // child
Future<Either<Failure, List<KidsHomeMission>>> acknowledgeLocalHomeMission(String id); // guardian
```

- [ ] **Step 1: Write the failing tests.**
  - Adding a mission → `assigned`, with the title trimmed. Titles of `''` or 121 characters → `Left(ValidationFailure)`.
  - Report → `reported` with `reportedAt`. Reporting again leaves it unchanged (idempotent).
  - Acknowledging an `assigned` mission → `Left`. Acknowledging a `reported` one → `acknowledged`.
  - Owner B sees no missions from owner A.
  - JSON round-trip, including `pendingReportSync`.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** Generate ids as `'local-${microsecondsSinceEpoch}'`.
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 2: Supabase — `kids_home_missions` and `kids_child_policies`

**Files:**
- Create: `supabase/migrations/<timestamp>_kids_home_missions_and_policies.sql`
- Modify: `scripts/verify_supabase_contract.ps1` (add both tables to the list at `:247`, and RPC checks next to `:265`)
- Create: `test/supabase/kids_home_missions_and_policies_contract_test.dart` (pattern: `guardian_child_identity_contract_test.dart`)

**Schema and RPC contract:**

```sql
-- table
public.kids_home_missions(id bigint generated always as identity primary key,
  parent_user_id uuid not null references public.profiles(id) on delete cascade,
  child_user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  status text not null default 'assigned' check (status in ('assigned','reported','acknowledged')),
  created_at timestamptz not null default now(), reported_at timestamptz, acknowledged_at timestamptz)
-- table
public.kids_child_policies(child_user_id uuid primary key references public.profiles(id) on delete cascade,
  reduce_motion boolean not null default false,
  max_daily_suggestions smallint not null default 3 check (max_daily_suggestions between 1 and 3),
  home_missions_enabled boolean not null default true,
  session_goal_minutes smallint check (session_goal_minutes between 1 and 60),
  version bigint not null default 0, updated_by uuid, updated_at timestamptz not null default now())
-- RPCs (all SECURITY DEFINER SET search_path = '', EXECUTE granted to authenticated only)
create_kids_home_mission(p_child_user_id uuid, p_title text) returns setof public.kids_home_missions   -- caller = parent with active link
report_kids_home_mission(p_mission_id bigint) returns setof public.kids_home_missions                    -- caller = child; assigned→reported; reported→no-op
acknowledge_kids_home_mission(p_mission_id bigint) returns setof public.kids_home_missions               -- caller = parent with active link; reported→acknowledged; else raise 'Invalid mission transition'
compare_and_swap_child_policy(p_child_user_id uuid, p_expected_version bigint, p_reduce_motion boolean,
  p_max_daily_suggestions integer, p_home_missions_enabled boolean, p_session_goal_minutes integer) returns jsonb
  -- caller = the child itself OR parent with active link; returns {"applied": bool, "version": bigint, "policy": row-json};
  -- missing row is created at version 1 when p_expected_version = 0
```

RLS: `SELECT` on both tables for `child_user_id = auth.uid()`, or for a parent with an active link to that child. No other policies.

- [ ] **Step 1: Write the failing contract tests** (static checks on the migration text, normalized like the identity test).
  - 4 functions, each with `security definer set search_path = ''`.
  - `revoke insert, update, delete on public.kids_home_missions from authenticated` (and the same for policies).
  - Every parent-side RPC checks `status = 'active'` on `public.parent_child_links`.
  - `acknowledge` requires `status = 'reported'`.
  - The CAS compares `version = p_expected_version` and increments it.
  - `verify_supabase_contract.ps1` mentions all four signatures.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Write the migration and update the verifier.**
- [ ] **Step 4: Run** `flutter test test/supabase`, then `pwsh scripts/verify_supabase_migrations.ps1`. Expected: both pass. If a local Supabase is available, also run `scripts/verify_supabase_contract.ps1`; otherwise record it as not run.

---

### Task 3: Remote home missions — guardian side

**Files:**
- Modify:
  - `collaborators/memorization_kids_cloud_sync_service.dart` (`createRemoteHomeMission`, `acknowledgeRemoteHomeMission`, `getRemoteHomeMissions(childUserId)`, mirroring `saveRemoteParentReward` at `:340-370`)
  - Repository interface and impl
  - `memorization_cloud_mappers.dart` (`homeMissionFromCloud`)
  - `presentation/cubits/family_dashboard_cubit.dart` (`addHomeMission(String title, {String? childId})`, `acknowledgeHomeMission(String id, {String? childId})`, mirroring `addReward` at `:253-300`)
  - `presentation/pages/child_detail_page.dart`: a «المهمات المنزلية» panel under Rewards. It has an add button (suggestion chips + free text via the existing `_TextInputDialog`), a list with status chips, and «اطّلعت» on reported items. Edit surgically.
  - The family dashboard's local child: the same panel through the local repository API (Task 1).
- Modify: ARB keys
  - `childDetailHomeMissions`: «المهمات المنزلية» / "Home missions"
  - `childDetailAddHomeMission`: «أضف مهمة» / "Add mission"
  - `kidsHomeMissionAssigned`: «بانتظار الطفل» / "Waiting for child"
  - `kidsHomeMissionReported`: «أخبرنا الطفل أنه أنجزها» / "Child says it's done"
  - `kidsHomeMissionAcknowledged`: «اطّلع ولي الأمر» / "Seen by guardian"
  - `kidsHomeMissionAcknowledgeAction`: «اطّلعت» / "Mark as seen"
- Test: `test/features/memorization_plus/presentation/cubits/family_dashboard_cubit_test.dart`, `.../pages/child_detail_page_test.dart`, and a sync service test following the existing parent-reward remote tests

- [ ] **Step 1: Write the failing tests.**
  - Cubit `addHomeMission('رتّب غرفتك', childId: 'c1')` calls the RPC `create_kids_home_mission` with `{'p_child_user_id': 'c1', 'p_title': 'رتّب غرفتك'}`, then refreshes.
  - Without `childId` it goes through the local API.
  - `acknowledgeHomeMission` on an assigned mission is not offered: the button is absent.
  - An RPC failure → `FamilyDashboardFeedback.failure`.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus`. Expected: PASS.

---

### Task 4: Home missions — child side (card, report, offline sync)

**Files:**
- Modify: `memorization_kids_cloud_sync_service.dart`
  - In the pull at `:55-80`, also select `kids_home_missions` where `child_user_id = user.id` and merge: server status wins unless the local copy is `pendingReportSync` and the server is still `assigned`.
  - In the push, call `report_kids_home_mission` for each `pendingReportSync` and clear the flag on success.
- Modify: `domain/services/kids_daily_missions.dart` (P2): add the parameter `KidsHomeMission? homeMission` (the oldest mission that is not acknowledged). It emits the `home` card with id `'$dayKey:home:${mission.id}'`. Status is `completed` when `reported` or `acknowledged`.
- Modify:
  - `kids_journey_cubit.dart` (loader `homeMissionsLoader`)
  - `kids_daily_mission_tile.dart` (home tile with a «أنجزتها!» button, `ValueKey('kids-home-mission-report')`)
  - `kids_gamified_home_page.dart`
- Modify: ARB key `kidsHomeMissionReportAction`: «أنجزتها!» / "I did it!"
- Test: `kids_daily_missions_test.dart`, `kids_journey_cubit_test.dart`, `kids_gamified_home_page_test.dart`, and the sync service test

- [ ] **Step 1: Write the failing tests.**
  - Resolver: with an assigned home mission the cards are `[learning, reading, home]`; with `maxMissions: 2`, there is no home card.
  - Home: tapping report calls `reportHomeMission(id)` and the tile shows `kidsHomeMissionReported`. Talia shows `happy`.
  - Sync: an offline report keeps `pendingReportSync`. The next push calls the RPC once and clears the flag. A pull that returns `assigned` while pending keeps `reported` locally.
  - A pull after link revocation (the RPC raises) leaves the local missions untouched.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** Linked child: `reportHomeMission` saves locally with `pendingReportSync: true`, then `enqueue(CloudSyncQueueKind.kidsProgressPush)`. Unlinked child: local only, no flag.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus`. Expected: PASS.

---

### Task 5: Policy fields on `ParentSettings` and `KidsPolicyController`

**Files:**
- Modify: `domain/entities/parent_dashboard.dart` (`ParentSettings` gains `kidsReduceMotion` (bool, false), `maxDailySuggestions` (int, 3), `homeMissionsEnabled` (bool, true), `policyVersion` (int, 0), plus `copyWith`/props) and the model's `toJson`/`fromJson` (missing keys → defaults)
- Create: `lib/features/memorization_plus/presentation/world/kids_policy_controller.dart`
- Modify: `injection.dart`
- Test: `test/features/memorization_plus/domain/parent_settings_policy_test.dart`, `.../world/kids_policy_controller_test.dart`

**Interfaces:**
- Produces:

```dart
final class KidsChildPolicy extends Equatable {
  const KidsChildPolicy({this.reduceMotion = false, this.maxDailySuggestions = 3, this.homeMissionsEnabled = true,
    this.sessionGoalMinutes, this.version = 0});
  factory KidsChildPolicy.fromSettings(ParentSettings s);
}
class KidsPolicyController extends ValueNotifier<KidsChildPolicy> {
  KidsPolicyController({required Future<KidsChildPolicy> Function() load});
  Future<void> reload();
}
```

- [ ] **Step 1: Write the failing tests.**
  - Old JSON without the new keys → defaults.
  - Round-trip of all four fields.
  - `maxDailySuggestions` outside 1–3 is clamped on read.
  - The controller's `reload` updates `value`; a load error keeps the previous value.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run the tests to verify they pass.**

---

### Task 6: Policy editing and sync (CAS)

**Files:**
- Modify:
  - `memorization_kids_cloud_sync_service.dart` (`pullChildPolicy()` for the child: select its own row and replace the local fields when `remote.version > local.policyVersion`; `casChildPolicy({required String childUserId, required KidsChildPolicy policy, required int expectedVersion})` → `Either<Failure, KidsChildPolicy>`, where `Left(PolicyConflictFailure)` means `applied == false`)
  - The repository
  - `lib/core/error/app_failure.dart` (add `class PolicyConflictFailure extends Failure` with message code `'kids_policy_conflict'`, mapped to `kidsPolicyConflict` in `localizedCubitMessage`)
  - `family_dashboard_page.dart` (the existing `sessionGoalMinutes` section at `:263-279` gains the three new controls)
  - `child_detail_page.dart` (the same controls for a remote child)
- Modify: ARB keys
  - `kidsPolicyReduceMotion`: «تقليل الحركة» / "Reduce motion"
  - `kidsPolicyMaxSuggestions`: «عدد مهمات اليوم» / "Missions per day"
  - `kidsPolicyHomeMissions`: «المهمات المنزلية» / "Home missions"
  - `kidsPolicyConflict`: «تغيّرت الإعدادات من جهاز آخر» / "Settings changed on another device"
- Test: sync service test, `family_dashboard_cubit_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - Linked child device: an edit calls `compare_and_swap_child_policy` with `p_expected_version = local.policyVersion`. On `applied: true`, the local settings store the returned version. On `applied: false`, it returns a conflict, the UI shows `kidsPolicyConflict`, it reloads from the server, and the local settings are unchanged by the edit.
  - Unlinked device: an edit is local only and `policyVersion` increments by 1.
  - Pull: a remote version 5 over local 3 → replaced. Remote 2 over local 3 → ignored.
  - Guardian phone: an edit for `childId` uses the CAS with the version from `getRemoteChildren` (add `policyVersion` to `RemoteChildSummary`).
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.** Call `pullChildPolicy` from `pullKidsProgressFromCloud`. After any change, call `getIt<KidsPolicyController>().reload()`.
- [ ] **Step 4: Run** `flutter test test/features/memorization_plus test/supabase`. Expected: PASS.

---

### Task 7: Apply policies in the kids UI

**Files:**
- Modify: `presentation/widgets/kids_ui.dart` (`KidsBackground`: when `KidsPolicyController` is registered and `value.reduceMotion`, wrap the subtree in `MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true))`)
- Modify: `kids_journey_cubit.dart` (pass `maxMissions: policy.homeMissionsEnabled ? policy.maxDailySuggestions : min(policy.maxDailySuggestions, 2)` to `resolveKidsDailyMissions`)
- Modify: the session-goal reader (`memorization_navigation_resolver.dart:155-180`) to prefer `policy.sessionGoalMinutes` when non-null (falling back to today's behaviour)
- Test: `.../world/kids_background_test.dart`, `kids_journey_cubit_test.dart`, `kids_gamified_listen_page_test.dart`

- [ ] **Step 1: Write the failing tests.**
  - With the policy `reduceMotion: true` and the OS setting off, the session page with `isRecording: true` has `tester.hasRunningAnimations` false.
  - `maxDailySuggestions: 1` → only the learning card.
  - `homeMissionsEnabled: false` with an assigned mission → no home card.
  - `sessionGoalMinutes: 10` → the completion page's goal note uses 10.
- [ ] **Step 2: Run them to verify they fail.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Full verification.**
  - Run `flutter gen-l10n`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` → `No issues found!`, `flutter test` → `All tests passed!`, and `pwsh scripts/verify_supabase_migrations.ps1` → pass.
  - Optionally run `./scripts/verify_v1_release.ps1`.
  - Hand off to the owner for commit. **Deploying the migration to the live project needs the owner's explicit approval.**

---

## Carried over from P2 (non-blocking, triaged in the P2 final review)

- **Task 4 here must clamp the cap.** `resolveKidsDailyMissions` does not clamp `maxMissions` to `kKidsMaxDailyMissions`. Clamp it when adding the home card (P3 Task 4).
- `resolveKidsDailyMissions` also uses `now` without `toLocal()`, and `dayGoalReached` is unused (implied by `learning == null`).
- **Day rollover:** the missions list and the reader's confirmed pages are fixed at load. A home screen or reader left open past local midnight keeps the previous day until it refreshes.
- **Reader tap feedback:** tapping «قرأت هذه الصفحة» while the page is loading does nothing silently. Also add `Semantics(liveRegion: true)` on the confirmation toast/chip, and move `KidsReaderConfirmation` out of the page file.
- **«كنوزي» loading state:** it uses a bare Scaffold instead of `KidsBackground`, so it flashes. The journey cubit also calls `getSurahs()` on every load and could cache it.
