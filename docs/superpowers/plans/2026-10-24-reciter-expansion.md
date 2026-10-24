# Reciter expansion implementation plan

**Later instruction:** The project owner explicitly requested activation of the ten additions after receiving the preparation report. The six-only availability decision below is historical; current runtime state is sixteen available reciters, recorded separately as `enabledByOwner`, with licensing and audible-content review still unverified. See audit_artifacts/reciters_2026_10_24/activation.md.

**Approved specification:** User-approved plan in this chat, 2026-10-24.
**Goal:** Prepare ten additional reciters without exposing unverified recordings.
**Architecture:** Extend the existing enum, selectors and per-ayah player. An immutable availability policy separates existing legacy-enabled reciters from blocked candidates.
**Stack:** Existing Flutter/Dart, Cubit, SharedPreferences, just_audio; no new dependencies.

## Constraints and decisions

- Preserve original six enum entries, IDs, order, URLs, saved preference key and cache namespaces.
- Append maher, yasser, qatami, ajamy, shatri, hudhaify, ayyoub, akhdar, fares, basfar in that order.
- All ten candidates start blocked. No remote flag or successful HTTP probe approves content.
- Keep raw identity parsing/manifest recognition distinct from playback authorization.
- Reject blocked requests before mutating playback/download generation, active state, preference or resume data.
- Retain existing storage deletion and identity compatibility; no canonical Quran edits.
- Current unrelated working-tree edits belong to other work and must be preserved.

## Execution

- [x] Baseline existing focused audio tests: 46 passed.
- [x] Focused stronger-model review of availability, active playback, resume and durable-cache bypasses.
- [x] Tests first for candidate gating, state preservation and visible catalog; observed expected failures.
- [x] Implement sixteen catalog identities, six available legacy entries, guards and filtered selectors.
- [x] Run focused regressions and static analysis; review production and test diff. Integrated audio/Quran regression: 364 passed; selector tests with real cubit/player service: 4 passed.
- [x] Compare all 6,236 expected ayah filenames and record bounded HTTP sample results. Zero missing across ten candidates; 60 MP3-header samples passed.
- [x] Record provenance, unresolved rights/riwayah/segment/owner-review status and actual validation outcomes.

## Verification and release

Unit/widget tests cover persistence, resume suppression, playback/download rejection without interruption, durable-cache bypass, independent reciter caches, localized selectors and scrolling. Real audible Quran/ayah/riwayah validation remains a separate release requirement. Any unavailable network/device validation is reported, never inferred from automated tests.

## Evidence

Source records: docs/content/quran_reciter_sources.json.
External probe: scripts/verify_reciter_catalog.py; evidence audit_artifacts/reciters_2026_10_24/verification.json.
Publication of new recordings remains blocked until explicit reuse evidence and affected-content approval are documented.

Final evidence: audit_artifacts/reciters_2026_10_24/validation.md. Android build/runtime verification remains blocked by the Java/Gradle loopback connection failure; no app/project configuration was changed to work around it.
