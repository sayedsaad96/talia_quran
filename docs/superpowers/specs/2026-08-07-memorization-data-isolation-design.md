# Memorization System: Master Sprint Reference

## Purpose and Control Rule

This document is the authoritative execution reference for all memorization-system changes. Work proceeds strictly in order from Sprint 1 through Sprint 6. A later sprint must not begin until the preceding sprint has passed every listed exit gate through automated tests and targeted manual verification. A discovered failure reopens the owning sprint; it is not deferred into a later sprint.

| Sprint | Priority | Objective | Entry rule | Exit gate |
| --- | --- | --- | --- | --- |
| 1 — Data Isolation | P0 | Isolate every memorization record by account and audience. | Approved architecture and migration design. | No cross-user or Adult/Kids data collision locally, in cloud, or in derived features. |
| 2 — Account Safety | P0 | Make account switching and logout safe. | Sprint 1 exit gate passed. | Logout, switch, queue, and restore tests prove no data can transfer between accounts. |
| 3 — Memorization Consolidation | P1 | Leave one active production feature: Memorization Plus. | Sprint 2 exit gate passed. | No production writes, routes, DI registrations, or reads use legacy Hifz. |
| 4 — Sync Integrity | P1 | Provide complete, idempotent, recoverable synchronization. | Sprint 3 exit gate passed. | Full restore, retry, conflict, and offline recovery tests pass for all plan and review data. |
| 5 — Cleanup | P2 | Remove superseded code and dependencies after proof of replacement. | Sprint 4 exit gate passed. | Static reachability audit and test suite prove removed paths have no consumers. |
| 6 — Production Verification | P0 | Certify release readiness of the consolidated system. | Sprint 5 exit gate passed. | End-to-end production-readiness audit has no release blockers. |

## Required Evidence at Every Gate

- A focused test suite for the sprint passes, including the regression tests added for its defects.
- Flutter static analysis passes for all changed production code.
- The migration and persistence behavior is manually exercised on a clean install and an upgraded installation where applicable.
- A source-level reachability check confirms that no forbidden path remains active.
- The next sprint is explicitly marked ready in this file only after the above evidence is recorded in its implementation plan and verified.

## Sprint 1 — Data Isolation

## Goal

Prevent any memorization data from crossing account or audience boundaries while preserving valid legacy data.

## Identity Contract

Every review record is identified by four immutable fields:

```text
userId + audience + surahId + ayahNumber
```

`audience` is `adult` or `kids`. A record for one identity must never be read, merged, scheduled, displayed, or synchronized as another identity.

## Boundaries

- Isar stores the full identity in its unique composite key and exposes identity-scoped reads and writes.
- Supabase uses the same four-column uniqueness contract. Its RPCs receive and return records only for `auth.uid()` and a requested audience.
- Sync merges only equal identities. Dirty flags and acknowledgement keys include the full identity.
- Smart Coach, Progress, Achievements, Daily Plan, and Kids Journey request records with the active profile's audience and authenticated user ID.
- The existing adult V2 and Kids Mode session flows remain unchanged except for passing the correct identity to review persistence.

## Legacy Migration

Existing records do not contain a user ID or reliable audience in every case. The migration runs once per installation before scoped reads are enabled:

1. Read each legacy Isar review row.
2. Classify `kidsMode` rows as `kids`; classify `v2Session` and repaired `hifz` rows as `adult`.
3. Attach the current authenticated user ID only when one is available.
4. Keep anonymous records in an explicitly local, non-syncable identity until the user chooses an account migration action.
5. Never overwrite a scoped record with the same identity; retain the newer review state according to the existing merge policy.
6. Mark migration complete only after the transaction and validation succeed.

## Failure Handling

- Missing authenticated user ID prevents cloud upload and prevents assigning data to an account.
- A cloud row with a different user ID or audience is rejected before merge.
- A failed migration leaves the old rows and completion flag intact for retry.
- All new behavior is covered by tests written and observed failing before production changes.

## Non-Goals

- Logout cleanup and queue clearing belong to Sprint 2.
- Legacy Hifz removal belongs to Sprints 3 and 5.
- Custom-plan and daily-plan sync belong to Sprint 4.

## Acceptance Criteria

- An adult and child can record the same ayah without either record changing the other.
- Two users can record the same ayah without local or cloud collision.
- Smart Coach, Progress, Achievements, and Kids Journey read only their own audience and user identity.
- Sync upload, pull, and merge preserve the four-part identity.
- Legacy migration is idempotent and never uploads anonymous or unassigned records.

## Sprint 1 Exit Gate

- Isar review-record identity, cloud uniqueness, sync merge, and all dirty/acknowledgement keys use userId + audience + surahId + ayahNumber.
- The active Adult and Kids flows have integration coverage for identical ayahs under the same account and under different accounts.
- Smart Coach, Progress, Achievements, Daily Plan, and Kids Journey are identity-scoped and cannot consume another audience's or user's review data.
- Migration is transactional, retryable, idempotent, and leaves unassigned legacy records non-syncable.
- No Sprint 2 work begins before all Sprint 1 evidence passes.

## Sprint 2 — Account Safety

### Scope

- Implement a real logout and account-switch boundary for Memorization Plus.
- Clear or securely partition in-memory session state, review records, legacy local data, and sync-queue entries belonging to the departing account.
- Prevent any upload, merge, retry, or restore from operating under a different authenticated user.
- Validate logout during offline work, app restart, failed sync, and account switching.

### Exit Gate

- Switching from account A to account B never displays, schedules, uploads, or rewards data owned by A.
- A queued mutation always carries its immutable owner identity and is rejected if the active session differs.
- Login restore retrieves only the signed-in account's scoped data.
- Automated logout, switch, queue-recovery, and restore tests pass.

## Sprint 3 — Memorization Consolidation

### Target Architecture

```text
Memorization Plus
├── Adult: Daily Plan, Custom Plan, Review, Smart Coach
└── Kids: Journey, Missions, Rewards, Parent Dashboard
```

### Scope

- Remove legacy Hifz production writes, APIs, repositories, data sources, routes, preferences, and expired migration paths only after their replacement is proven.
- Route all visible memorization experiences through Memorization Plus, preserving the separate Adult and Kids business flows.
- Remove duplicate state-management and storage access paths that would allow parallel execution.

### Exit Gate

- Source reachability confirms a single active memorization write/read/sync path through Memorization Plus.
- Adult Daily Plan, Custom Plan, Review, and Smart Coach work through that path.
- Kids Journey, Missions, Rewards, and Parent Dashboard work through that path without using Adult state.
- No legacy Hifz code remains reachable in a production build.

## Sprint 4 — Sync Integrity

### Scope

- Synchronize custom plans and daily plans alongside review records.
- Implement durable dirty flags, delta sync, deterministic conflict resolution, retry queue recovery, idempotency, and complete login restore.
- Validate cloud schema/RPC contracts and client merge behavior against the Sprint 1 identity contract.

### Exit Gate

- Offline create/update/delete, reconnect, retry, duplicate delivery, and conflict tests preserve exactly one correct result per scoped identity.
- A fresh login restores reviews, daily plans, custom plans, and derived memorization state needed by the Home screen, Smart Coach, and Parent Dashboard.
- Failed cloud operations remain recoverable without cross-account or cross-audience effects.

## Sprint 5 — Cleanup

### Scope

- Remove the obsolete Hifz implementation, completed migration services, dead widgets, repositories, use cases, packages, DI registrations, feature flags, and debug pages after validated replacement.
- Remove obsolete tests only when equivalent coverage exists for the retained production behavior.

### Exit Gate

- Static analysis, dependency search, route search, DI search, and build verification show no references to removed components.
- No duplicate persistence, scheduling, reward, or sync implementation remains.
- The full test suite passes after removal.

## Sprint 6 — Production Verification

### Scope

- Independently verify source reachability, all visible flows, routing, persistence, sync/restore, resource lifecycle, and security boundaries.
- Run Adult and Kids end-to-end journeys, parent monitoring, account switching, offline recovery, and upgraded-data migration tests.

### Exit Gate

- No dead memorization code, duplicate logic/storage, legacy production path, memory leak, security issue, or release blocker remains.
- Every visible memorization feature has a verified execution path and persistence/synchronization proof.
- The final audit answers yes to: one Memorization Plus system; full Adult/Kids and user isolation; no legacy behavior affecting production; complete restore and conflict-safe synchronization.
