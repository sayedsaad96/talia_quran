# Data Model: Audit Report Entities

**Feature**: feature-audit | **Date**: 2026-05-17

This document defines the schema for all entities produced by the audit report.
These are *report* entities, not application data models — they describe the structure
of the audit output document, not the Talia Quran app's own data.

---

## Entity: FeatureEntry

Represents one audited feature module or core service in the report.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Short identifier, e.g. `auth`, `xp`, `streak` |
| `type` | enum | `feature` or `core_service` |
| `status` | enum | `fully_working`, `partially_working`, `broken`, `hidden_unused`, `conditionally_reachable` |
| `purpose` | string | One-sentence description of what this feature does |
| `entry_point` | string | Primary widget or page class name |
| `navigation_path` | string | Route path(s) or `none` if no route |
| `di_registered` | boolean | Whether a Cubit/service is in `injection.dart` |
| `layer_completeness` | object | `{ data: bool, domain: bool, presentation: bool }` |
| `dependencies` | string[] | Other features or services this depends on |
| `findings` | string[] | IDs of associated Finding records |

**Status Definitions** (per spec FR-002 / Q5):
- `fully_working`: Primary and all secondary flows complete without error
- `partially_working`: Primary flow works; one or more secondary flows fail or are missing
- `broken`: Primary user flow cannot be completed (crash, silent failure, or disconnected logic)
- `hidden_unused`: Code exists but no navigation path or DI consumer exists
- `conditionally_reachable`: Only reachable when upstream action supplies required runtime params

---

## Entity: Finding

Represents a specific problem detected during the audit.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Sequential ID, e.g. `FIND-001` |
| `feature_id` | string | ID of the affected FeatureEntry |
| `category` | enum | `broken`, `partially_working`, `hidden_unused`, `conditionally_reachable`, `ux_structural`, `ux_quality`, `architecture_violation`, `dead_code`, `performance` |
| `severity` | enum | `critical`, `high`, `medium`, `low` |
| `title` | string | Short summary (≤10 words) |
| `description` | string | Full description of the problem |
| `affected_files` | string[] | Relative file paths |
| `root_cause` | string | Why the problem exists |
| `recommendation_id` | string | ID of the linked Recommendation |

**Severity Definitions**:
- `critical`: App unusable, data loss risk, or security gap (e.g. no auth gate)
- `high`: Primary feature flow broken or major UX failure affecting most users
- `medium`: Secondary flow broken, stub detected, or architectural smell
- `low`: Minor gap, cosmetic issue, or design-intent ambiguity

---

## Entity: Recommendation

One actionable, production-safe fix suggestion per Finding.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | e.g. `REC-001` |
| `finding_id` | string | Linked Finding ID |
| `severity` | enum | Mirrors linked Finding severity |
| `problem_summary` | string | Brief restatement of the problem |
| `root_cause` | string | Root cause (may copy from Finding) |
| `approach` | string | Step-by-step safe fix description |
| `risk_level` | enum | `low`, `medium`, `high` |
| `affected_files` | string[] | Files to be modified |
| `requires_test` | boolean | Whether a test MUST be written first (per Constitution §III) |

---

## Entity: RouteEntry

Represents one registered route in `app_router.dart`.

| Field | Type | Description |
|-------|------|-------------|
| `path` | string | Route path string, e.g. `/memorization-plus/quiz` |
| `target_widget` | string | Widget class built by the route |
| `requires_params` | boolean | Whether runtime `extra` or path params are required |
| `reachability` | enum | `shell_tab`, `push_full_screen`, `conditionally_reachable`, `unreachable` |
| `feature_id` | string | Associated FeatureEntry |
| `fallback_on_bad_params` | string | Widget shown on missing/bad params, or `none` |

---

## Entity: CoreServiceEntry

Extends FeatureEntry for DI-registered core services.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | e.g. `subscription_service` |
| `registration_type` | enum | `singleton`, `lazy_singleton`, `factory` |
| `consuming_cubits` | string[] | Cubit IDs that receive this service via constructor |
| `usage_status` | enum | `active`, `stub`, `unused` |
| `has_tests` | boolean | Whether unit tests exist for this service |

---

## Report Structure

The audit report (`tasks.md` phase output or a separate `audit-report.md`) is organised as:

```text
## Feature Inventory          — one FeatureEntry per module + core service
## Fully Working Features      — FeatureEntry list (status = fully_working)
## Conditionally Reachable     — FeatureEntry list + RouteEntry details
## Partially Working Features  — FeatureEntry list + Finding references
## Hidden / Unused             — FeatureEntry list + Finding references
## Broken Features             — FeatureEntry list + Finding references
## UX Problems                 — Finding list (category = ux_*)
## Logic Problems              — Finding list (category = architecture_violation)
## Dead / Duplicate Code       — Finding list (category = dead_code)
## Performance Concerns        — Finding list (category = performance)
## Suggested Fixes             — Recommendation list sorted by severity desc
```
