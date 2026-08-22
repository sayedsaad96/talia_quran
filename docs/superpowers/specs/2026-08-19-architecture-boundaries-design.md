# Architecture Boundaries Design

## Goal

Reduce coupling in the highest-risk architectural seams without changing user-visible behavior.

## Scope

- Move bookmark value types out of Quran data dependencies.
- Replace unused Memorization Plus use-case wrappers with narrow, consumed contracts.
- Separate cloud synchronization orchestration from `AuthCubit`.
- Remove unused direct package dependencies.

## Boundaries

`BookmarkEntry` becomes a Quran domain entity. Bookmark persistence maps directly to that entity.

`MemorizationPlusRepository` remains the compatibility facade during this change. New focused interfaces are consumed by presentation cubits/pages: identity, planning, review, kids progress, family, and cloud synchronization. The existing implementation supplies each interface through small adapters so persistence behavior is unchanged.

`CloudSyncCoordinator` owns pull/push ordering, queue recovery, and error containment. `AuthCubit` owns Supabase session observation, auth commands, and the resulting UI states; it delegates synchronization to the coordinator.

## Constraints

- Preserve existing routes, persistence keys, Isar schemas, and Supabase RPC calls.
- Do not change user-visible behavior or delete Hifz migration compatibility.
- New logic is covered by focused unit tests before implementation.
- Remove only dependencies with no application-source use.
