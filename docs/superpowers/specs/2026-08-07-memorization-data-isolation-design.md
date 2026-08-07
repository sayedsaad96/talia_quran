# Memorization Sprint 1: Data Isolation Design

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
