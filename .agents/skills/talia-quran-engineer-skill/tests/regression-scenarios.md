# Regression Scenarios

These are stable regression targets to instantiate against the real Talia repository when the relevant systems are affected.

## Quran restore and mapping
Persist a verified reading location, kill/restart, restore the exact canonical location, and verify related bookmark/page/surah/ayah mappings.

## Memorization progress persistence
Start/update a memorization session, exit/restart, restore progress without silent reset, complete, and verify downstream state.

## Revision scheduling
Given deterministic mastery/weakness/due inputs, verify schedule ordering, completion, overdue behavior, and persistence across restart/migration.

## Audio sync and lifecycle
Play/seek/transition ayat, background/resume/interruption, and confirm player state remains synchronized with the highlighted canonical ayah.

## RLS allow/deny
Verify the intended owner/auth path succeeds and an unauthorized/non-owner path is denied.

## Upgrade from existing local data
Install/run with old persisted state, apply the new app/schema path, and verify reading position, memorization/revision/bookmarks remain compatible.

## Arabic and English layout
Exercise Arabic RTL and English LTR with long strings, realistic text scaling, small screens, navigation, loading/error states, and directional icons.

## Performance claim integrity
Ensure static review alone cannot produce a measured-improvement claim; require comparable baseline and after measurements or report `Not measured`.
