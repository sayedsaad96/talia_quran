# Architecture Boundaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce high-risk coupling while preserving all existing Flutter application behavior.

**Architecture:** Promote bookmarks to the Quran domain, introduce focused Memorization Plus contracts behind the existing implementation, and move cloud-sync orchestration behind a dedicated coordinator. The existing repository remains a compatibility facade during migration.

**Tech Stack:** Flutter, Dart, flutter_bloc, get_it, Isar, SharedPreferences, Supabase.

**Spec:** `docs/superpowers/specs/2026-08-19-architecture-boundaries-design.md`

## Global Constraints

- Preserve routes, persistence keys, Isar schemas, and Supabase RPC calls.
- Preserve Hifz migration compatibility.
- Use test-first changes and retain existing user-visible behavior.
- Remove only direct dependencies with no application-source use.

---

### Task 1: Promote bookmark value type to domain

**Files:**
- Create: `lib/features/quran/domain/entities/bookmark_entry.dart`
- Modify: `lib/features/quran/data/datasources/bookmark_service.dart`
- Modify: `lib/features/quran/domain/bookmark_reader_location.dart`
- Test: `test/features/quran/bookmark_service_test.dart`

**Produces:** `BookmarkEntry` in the Quran domain, with all bookmark callers independent of data-source types.

- [ ] Write a failing test importing `BookmarkEntry` from the domain and persisting it through `BookmarkService`.
- [ ] Run `flutter test test/features/quran/bookmark_service_test.dart` and confirm the import fails before the entity exists.
- [ ] Create an immutable domain `BookmarkEntry` and update `BookmarkService` plus `bookmarkReaderLocation` to consume it.
- [ ] Run the focused test and confirm bookmark serialization and reader location still pass.

### Task 2: Introduce focused memorization contracts

**Files:**
- Create: `lib/features/memorization_plus/domain/repositories/memorization_identity_repository.dart`
- Create: `lib/features/memorization_plus/domain/repositories/memorization_cloud_repository.dart`
- Modify: `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/memorization_plus/data/memorization_plus_repository_impl_test.dart`

**Produces:** focused identity and cloud-sync contracts implemented by the existing repository implementation.

- [ ] Write failing compile-level tests that type `MemorizationPlusRepositoryImpl` as each focused interface.
- [ ] Run the focused test and confirm the implementation does not yet satisfy the interfaces.
- [ ] Add focused interfaces matching existing method signatures and implement them on the existing repository class without changing persistence code.
- [ ] Register focused interface bindings in DI and run the focused test.

### Task 3: Extract cloud synchronization coordinator

**Files:**
- Create: `lib/features/auth/application/cloud_sync_coordinator.dart`
- Modify: `lib/features/auth/presentation/cubits/auth_cubit.dart`
- Modify: `lib/core/di/injection.dart`
- Test: `test/features/auth/cloud_sync_coordinator_test.dart`

**Produces:** `CloudSyncCoordinator.run()` and `CloudSyncCoordinator.resumeIfNeeded()`.

- [ ] Write failing tests for pull-before-push ordering, queue recovery, and containment of unexpected failures.
- [ ] Run `flutter test test/features/auth/cloud_sync_coordinator_test.dart` and confirm it fails because the coordinator does not exist.
- [ ] Move sync orchestration from `AuthCubit` into the coordinator, preserving current queue kinds and public cubit methods.
- [ ] Run coordinator and auth lifecycle tests.

### Task 4: Remove unused dependencies and wrapper layer

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart`
- Test: existing feature tests

**Produces:** no direct unused `cupertino_icons` or `cached_network_image` dependencies and no unused identity-wrapper use cases.

- [ ] Confirm no application source imports either dependency and no production source references the wrapper types.
- [ ] Remove only those dependency entries and unconsumed wrapper declarations.
- [ ] Run `flutter pub get` and focused Flutter tests.
