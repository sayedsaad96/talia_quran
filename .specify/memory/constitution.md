# Talia Quran Constitution

## Core Principles

### I. Clean Architecture
All features MUST follow Clean Architecture with three distinct layers: Data, Domain, and Presentation. Each feature MUST be self-contained with its own entities, use cases, repositories, and presentation logic.

### II. Feature-First
Every feature starts as independent feature module under `lib/features/`. Modules must be self-contained, independently testable, and documented. Feature boundaries MUST be clear—no cross-feature domain logic.

### III. Test-First
TDD is RECOMMENDED for business logic: Tests written → Implementation → Verify pass. Integration tests REQUIRED for feature contracts, database operations, and Speech-to-Text verification.

### IV. Observability
Structured logging for all business operations. Error tracking MUST capture context for debugging. Performance metrics MUST be logged for audio playback and speech recognition.

### V. Simplicity & YAGNI
Start with minimal viable solution. Reject features without clear user value. Refactor when complexity exceeds benefit.

## Additional Constraints

- Code generation with build_runner required for Isar and GetIt bindings.
- All feature dependencies declared in pubspec.yaml.
- Localization via ARB files for all user-facing strings.
- Audio assets must be cached locally for offline playback.
- Speech recognition requires runtime permission handling.

## Development Workflow

- Feature branch per work item
- PR required for all changes
- Tests must pass before merge
- Clean Architecture layer rules enforced in PR

## Governance

Constitution supersedes all prior practices. Amendments require documentation, approval via PR. Version MUST increment per semver rules: MAJOR for removals, MINOR for additions, PATCH for clarifications.

**Version**: 1.0.0 | **Ratified**: 2026-04-30 | **Last Amended**: 2026-04-30