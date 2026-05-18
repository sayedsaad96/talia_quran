# Implementation Plan: Fix Memorization User Identity & Guardian-Linking Flow

**Branch**: `002-fix-memorization-identity` | **Date**: 2026-05-17 | **Spec**: [specs/002-fix-memorization-identity/spec.md](./spec.md)

**Input**: Feature specification from `specs/002-fix-memorization-identity/spec.md`

## Summary

Fix the memorization onboarding and guardian-linking flow. Introduces a mandatory one-time identity selection (Child vs. Adult), enforces guardian linking (or explicit opt-out) for children, entirely bypasses linking for adults, and ensures Smart Memorization configuration respects these core identities. 

## Technical Context

**Language/Version**: Flutter ≥ 3.22, Dart ≥ 3.4

**Primary Dependencies**: `flutter_bloc` (state), `get_it` (DI), `go_router` (routing), `dartz` (error handling)

**Storage**: `shared_preferences` (for MemorizationProfile and Settings flags), `isar` (for heavy structured data, though identity state will mostly fit in prefs/Isar Singletons).

**Testing**: `flutter_test`, `bloc_test`, `mocktail`

**Target Platform**: iOS, Android

**Project Type**: Mobile App

**Performance Goals**: Instant offline state retrieval (60 fps navigation).

**Constraints**: Clean Architecture strict adherence. Offline-capable.

**Scale/Scope**: Refactoring existing memorization onboarding, settings, and smart memorization flow.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **I. Clean Architecture**: Changes localized to `lib/features/memorization_plus/` and settings. Domain, Data, Presentation layers maintained.
- [x] **II. BLoC/Cubit**: UI state managed via Cubits (e.g., `MemorizationIdentityCubit`, `GuardianLinkingCubit`).
- [x] **III. Test-Driven Quality**: Unit tests will cover Cubits and use cases.
- [x] **IV. Offline-First**: User identity will be persistently stored locally.
- [x] **V. Localisation**: All new strings will be added to `.arb` files.

## Project Structure

### Documentation (this feature)

```text
specs/002-fix-memorization-identity/
├── plan.md              
├── research.md          
├── data-model.md        
└── contracts/           
```

### Source Code

```text
lib/
├── features/
│   ├── memorization_plus/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── memorization_profile.dart
│   │   │   │   ├── pairing_session.dart
│   │   │   │   └── smart_memorization_settings.dart
│   │   │   ├── usecases/
│   │   │   └── repositories/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── datasources/
│   │   │   └── repositories/
│   │   └── presentation/
│   │       ├── cubits/
│   │       └── pages/
│   └── settings/
│       └── presentation/
│           └── pages/
test/
└── features/
    └── memorization_plus/
        ├── domain/
        ├── data/
        └── presentation/
```

**Structure Decision**: The feature is mostly modifying existing paths in `lib/features/memorization_plus/` and `lib/features/settings/`. No new high-level architectural folders needed.

## Complexity Tracking

No violations. Standard Flutter clean architecture implementation.
