# Phase 0: Research & Clarifications

## Technical Context Unknowns
No technical unknowns were present in the spec that required resolution. The tech stack is strictly constrained by the project Constitution (Flutter, BLoC, Isar, SharedPreferences).

## Key Architecture Decisions

### Decision 1: Single Source of Truth for Identity
- **Decision**: Introduce a `MemorizationProfile` entity to act as the single source of truth for the user's path, guardian link status, and parent role.
- **Rationale**: Spec requirement FR-013 states there must be a single shared source of truth. Previously, these settings were fragmented.
- **Alternatives considered**: Using multiple disconnected flags in `SharedPreferences`. Rejected because it leads to sync bugs (e.g., losing guardian status when changing smart memorization settings).

### Decision 2: Storage Mechanism
- **Decision**: Persist `MemorizationProfile` via local storage (`shared_preferences` for quick synchronous access, or local Isar if structured queries are needed).
- **Rationale**: Needs to be available instantly upon app load for route guarding and initial UI display without network dependency.
- **Alternatives considered**: Remote-only Supabase storage. Rejected because it violates the offline-first Constitution principle.

### Decision 3: Smart Memorization Settings Segregation
- **Decision**: Keep `SmartMemorizationSettings` entirely separate from `MemorizationProfile` at the storage layer.
- **Rationale**: Spec FR-014 requires that saving smart memorization settings does not overwrite identity state, and FR-010 requires identity reset to preserve smart memorization settings.
