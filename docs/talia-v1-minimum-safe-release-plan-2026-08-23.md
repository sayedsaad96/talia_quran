# Talia V1 — Minimum Safe Release Plan

> **Policy update — 2026-08-31:** External sheikh/reviewer approval and signatures are no longer release requirements. The project owner is the final content authority and closed G8 by reviewing and approving the application. This update supersedes every external-review or signature requirement below; technical, backend, device, artifact, and Google Play gates remain unchanged.

**Date:** 2026-08-23  
**Decision type:** Release triage and scope reduction  
**Repository baseline reviewed:** `06827f40a45af0fe8a86e5cf9f9ad04f912c79dc` (`main`)  
**Scope:** Analysis and release planning only; this document does not implement a fix or approve publication.

## Summary

Talia is a mature development build with a real offline-first architecture, broad feature coverage, and a historically clean analyzer and passing test suite. It is **not currently safe to publish**, however, because a small set of high-impact defects remains in Quran exactness, religious-content provenance, sign-out data safety, the guardian backend contract, and the no-network/no-STT memorization journey.

The original 20-task final-readiness plan is technically thorough but larger than necessary for a safe first release. V1 should preserve the existing product and correct only risks that can cause:

- incorrect or transformed Quran display;
- untraceable, ungraded, or modified religious content;
- loss of user-created data;
- a guaranteed-broken exposed feature;
- a misleading privacy claim;
- failure of a core memorization journey on a supported real-world condition;
- or an unverifiable production backend/release artifact.

Everything else—generic governance platforms, full riwayah-domain migration, dead-letter UX, rewards outbox redesign, scheduler redesign, broad accessibility work, large-file refactors, performance budgets, and comprehensive CI—is deferred.

**Decision:** the triage is complete and the reduced V1 scope is ready to implement. G8 is closed through the project owner's recorded approval.

Publication remains **NO-GO** until the remaining technical, backend, device, artifact, and store gates pass.

## V1 Scope Hard Stop

**This section overrides every other scope statement in this document. If a task, estimate, acceptance condition, or implementation idea conflicts with it, this section wins.**

1. Do not rehabilitate content that can simply be removed from V1.
2. For Adhkar/Dua, ship only the smallest verified subset actually required by the existing V1 UX.
3. Any unverifiable or unnecessary religious record may be removed from V1 rather than repaired.
4. V1-S items are opportunistic only, not mandatory scope.
5. A V1-S item may be implemented only if all of the following remain true:
   - XS/S effort;
   - no architecture change;
   - no new abstraction;
   - no new migration;
   - no new external dependency;
   - no project-owner content reconfirmation is triggered;
   - and it does not delay any V1-M item.
6. If any proposed implementation begins expanding beyond the stated minimum, **STOP and report the expansion** instead of implementing it.
7. Do not create frameworks, portals, generic engines, reusable governance systems, or broad refactors for a one-time V1 requirement.
8. Prefer deletion, disabling, or hiding a non-critical feature over building infrastructure to preserve it.
9. Do not preserve existing content or features merely because they already exist.
10. The smallest safe V1 is preferable to a larger “more complete” V1.

### Enforcement rule

Every implementation task begins with a delete/disable/hide assessment. Preservation must be justified by a V1 core journey or a release-safety requirement. If the minimum implementation exceeds its stated effort ceiling, the engineer stops and reports the expansion; the default response is to remove or hide the non-critical surface, not to increase the scope.

## Current Release Reality

### Verified directly against the current repository

| Area | Current reality | Release effect |
|---|---|---|
| Repository | Working tree was clean at review start; baseline commit is recorded above. | Suitable for a controlled V1 correction branch. |
| Quran asset | `assets/data/quran.json` contains 6,236 ayahs, 604 pages, 30 juz, and 114 surahs. Its reviewed SHA-256 is `09f09074b7341859d4770cc2b9d8768d6a7f7b00d0003123238e6e9949b3fa82`. | Structurally complete, but not yet release-approved. |
| Basmalah boundary | Ayah 1 contains an embedded basmalah in 112 surahs other than Al-Fatihah and At-Tawbah. | Blocking because memorization, search/detail, and QCF paths can disagree about ayah boundaries. |
| Memorization text | `QuranTextDisplayFormatter.cleanAyahForMemorization` removes markers, changes spacing, inserts word boundaries, and collapses whitespace; `QcfHifzVerseView` applies it to QCF and asset text. | Blocking: sacred text used for memorization is not guaranteed character-for-character exact. |
| Quran datasource | Missing `global`, `juz`, or `page` values are guessed rather than rejected. | Small but high-consequence fail-open behavior; include in the Quran correction batch. |
| Adhkar/dua asset | 85 candidate records across four current categories; no authenticity-grade or tier fields; 73 references are not resolvable to a numbered citation; duplicate-text groups exist. | The 85 records are an input pool, not V1 scope. Retain only a smallest approved allowlist; delete the rest and hide any category left empty. |
| Religious literals | Hand-typed verses/hadith/dua exist in tips, notifications, a certificate, settings, and home UI. Notification code can truncate religious text. | Blocking. Delete or hide the nonessential output. An essential Quran surface may use only the already approved exact Quran corpus; do not create a preservation project. |
| Dataset governance | No pinned content manifest records source edition, riwayah, license, hashes, dataset version, or review status. | A small immutable manifest is required; a general governance framework is not. |
| Guardian unlink | Client code calls `revoke_guardian_link`; no migration defines that RPC. | Guaranteed-broken exposed action if the hosted schema follows the repository. |
| Bookmark sign-out | `flushBeforeSignOut` can return success without checking pending bookmark cloud work, then local account cleanup removes the bookmark state. | Blocking, reproducible data-loss path. |
| Database privilege | `prune_audit_logs()` is `SECURITY DEFINER` and executable by `authenticated`, allowing any signed-in user to invoke global retention deletion. | Blocking because the fix is small and removes cross-user destructive authority. |
| STT/privacy | Adult and Kids recognition do not request on-device recognition, while the Arabic policy promises processing exclusively on the device. | Blocking policy/code mismatch. |
| Offline completion | There is no manual/self-grade fallback. A clean first-use offline Kids journey also depends on successful remote audio repetitions. | Blocking for the stated core offline product promise. |
| Sync core | Owner-scoped durable Isar queue, dirty-state acknowledgement, CAS, account isolation, and retry machinery are materially strong. | Safe to preserve; broad sync redesign is unnecessary for V1. |
| Costs | Quran and adhkar are bundled locally; audio is external; backend calls are event-driven. Cost migrations already add pagination/summary limits in important paths. | No immediate architecture-driven launch-cost blocker, subject to production verification and provider alerts. |

### Key repository evidence anchors

- Quran mutation: `lib/core/utils/quran_text_display_formatter.dart:20-55`, called by `lib/core/widgets/qcf_hifz_verse_view.dart:159,263`.
- Ungoverned religious output: `lib/features/azkar/presentation/pages/azkar_page.dart:367-426`, `lib/core/services/notification_service.dart:49-53,839-842`, and `lib/features/certificate/presentation/widgets/certificate_widget.dart:438`.
- Bookmark gate inconsistency: `lib/features/auth/application/cloud_sync_coordinator.dart:137-151` omits the bookmark check that exists in the general pending-work path at `:386`.
- Missing guardian contract: client call at `lib/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart:365`; no `revoke_guardian_link` definition exists under `supabase/`.
- Unsafe maintenance grant: `supabase/migrations/0006_fsrs_and_audit_fixes.sql:207-219`.
- STT/privacy mismatch: `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart:425`, `kids_mode_cubit.dart:608`, and `lib/features/settings/presentation/pages/privacy_policy_content.dart:38`.
- Shared Adult/Kids evaluator: `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart:80,239`.
- Missing content metadata: searches across `lib/`, `assets/data/`, and `test/` find no production representation of `sourceCitation`, `authenticityGrade`, `datasetVersion`, `riwayahId`, or `reviewStatus`.

### Evidence that must be refreshed before release

The development audit records `flutter analyze` clean and all 916 tests passing. Those results are useful historical evidence, but they are **not a current release certificate**. Stale Dart/Flutter test processes exist on the review machine, so this triage did not claim a fresh full-suite execution.

Production Supabase was also not inspected: `TALIA_SUPABASE_FRESH_DB_URL`/`SUPABASE_DB_URL` were unavailable and `psql` was not installed. The local migration verifier correctly stopped for the missing fresh-database URL. Hosted-schema status is therefore **unknown**, not passing or failing.

### Readiness scorecard

| Lens | Current estimate | Why |
|---|---:|---|
| Flutter engineering maturity | 82/100 | Strong architecture and coverage; several large components and missing CI remain. |
| Production release readiness | 58/100 | Five blocking tracks remain and production backend/device evidence is absent. |
| Hifz experience | 67/100 | Strong state machine, progress, review, and Kids flow; exact text, offline completion, STT privacy, and Kids grading need correction. |
| Data integrity | 72/100 | Sync design is strong, but bookmark sign-out can destroy pending data. |
| Islamic review readiness | 45/100 | Corpus structure exists, but exact rendering, provenance, grade/citation metadata, and religious literals are not yet controlled. |

These are decision aids, not release gates. The binary gates later in this document take precedence.

## V1 Release Philosophy

1. **Sacred text is fail-closed.** Talia must show approved Quran/dua/dhikr text exactly. It may remove an unneeded religious surface, but it may not silently rewrite or truncate its content.
2. **Project-owner content approval is the final internal authority.** Automation proves integrity and traceability; the owner decides whether shipped religious content is accepted. External review and signatures are optional.
3. **Protect user work before adding sophistication.** No known path may discard pending bookmarks or other core progress.
4. **Core journeys must degrade safely.** Reading, memorization, and Kids completion must have a usable offline/no-STT path.
5. **Prefer deletion and a narrow schema change over a platform.** V1 does not need generic evidence abstractions, an importer framework, or a reviewer portal.
6. **Verify the deployed system, not only migrations.** A correct SQL file does not prove the hosted database is correct.
7. **Preserve stable core features.** Do not redesign navigation, scheduling, sync, rewards, or architecture unless required by a blocker below. Hiding an unsafe optional destination under the Hard Stop is allowed and is not a navigation redesign.
8. **Start optional religious content from an empty allowlist.** A record is added only when the current V1 UX needs it and the reviewer can verify it without remediation work.
9. **Should Fix is not Definition of Done.** Release gates cannot fail because an opportunistic V1-S item was skipped.

## Critical Findings

### CF-1 — Quran text and ayah boundaries are not release-safe

The local Quran asset embeds the basmalah in ayah 1 for 112 surahs, while the QCF Mushaf presents it structurally. Separately, the memorization formatter modifies Quran strings. A learner can therefore see or be graded against a representation that differs from the approved corpus or from another screen.

**V1 decision:** correct the frozen local corpus or its deterministic structural import, remove mutating formatting from sacred display paths, reject missing structural fields, and prove exact output with focused tests and a manifest hash. Do not build a general Quran importer.

### CF-2 — Shipped religious content is not fully traceable

The 85-record adhkar/dua file cannot represent mandatory grade/tier data, most references are not numerically resolvable, and several screens contain hand-typed religious content. Notifications can modify a dua through truncation.

**V1 decision:** remove nonessential tips, religious notification fallbacks, and decorative religious literals. Start the Adhkar/Dua release allowlist empty, identify only the records required by the category cards that V1 will actually keep, and add a record only after it is directly verifiable. Hide any empty/unnecessary category, route, notification action, or card. Do not repair the rest of the 85 records and do not build a generic `ContentEvidence` system.

### CF-3 — Sign-out can lose a pending bookmark

Bookmark cloud work is omitted from the final sign-out flush decision. Successful sign-out then clears account-local bookmark data.

**V1 decision:** make a single all-domain pending-work decision authoritative and add an integration test covering failure, block/force behavior, reconnect, and exact-once cloud convergence.

### CF-4 — Backend contract contains an exposed broken action and unsafe privilege

Guardian unlink/remove-child calls a nonexistent RPC. Separately, any authenticated user can execute global audit pruning. The current contract verifier does not cover the missing guardian RPC, and hosted status is unknown.

**V1 decision:** implement and authorize the RPC or hide both exposed actions; revoking the unsafe function grant is mandatory. Extend the narrow verifier and run it on fresh staging and the actual production project.

### CF-5 — Memorization can block without STT/network and the privacy claim is inaccurate

Both memorization modes depend on platform STT with no manual fallback. Kids first-use offline completion also depends on remote audio loops. The privacy policy overstates on-device guarantees.

**V1 decision:** add a clearly labelled manual/self-grade route, allow safe progression when audio/STT is unavailable, and make the policy describe OS/provider-mediated speech accurately. On-device-only STT and downloadable audio packs are later work.

## V1 Must Fix

| ID | Deliverable | Minimum acceptable implementation | Effort | Acceptance evidence |
|---|---|---|---:|---|
| V1-M1 | Exact Quran corpus and display | Correct ayah-1 basmalah boundaries while preserving Al-Fatihah and At-Tawbah rules; remove sacred-text mutation; fail on absent structural metadata; keep basmalah as an approved unnumbered header where appropriate. | L | Counts/boundary/hash tests; exact-string tests through QCF and fallback paths; offline sample on device; reviewer approval. |
| V1-M2 | Minimal immutable content manifest | One checked-in manifest for the Quran asset and only the Adhkar/Dua subset actually shipped, with source, edition/version, riwayah where relevant, license status, SHA-256, freeze date, and reviewer status. | S | Test recomputes hashes and rejects drift; frozen RC points to the exact shipped files, manifest, and commit. |
| V1-M3 | Smallest verified Adhkar/Dua allowlist | Begin with zero records. Select only the minimum records required for the V1 category cards that remain; add direct citation/grade/tier fields only for those records; delete all other records and hide empty categories/routes/actions. If this exceeds M engineering effort, disable the Adhkar/Dua feature and report the scope expansion. | Engineering S/M; Islamic review M | Every shipped record is directly approved; no excluded record is bundled or reachable; no V1 gate requires repairing or reviewing all 85 candidates. |
| V1-M4 | Remove ungoverned religious output | Delete daily religious tips, religious notification fallbacks, decorative certificate/settings/home literals, and religious share output that is not essential. Use generic localized reminder text and never truncate sacred text. Do not move removed content into a new source. | S | Repository scan plus UI/notification/share tests show the removed surfaces are absent, no unapproved literal is reachable, and no sacred text is shortened or paraphrased. |
| V1-M5 | Bookmark-safe sign-out | Include bookmarks and every current dirty domain in the authoritative flush gate; preserve durable state on normal and forced exits. | S | Offline bookmark → failed push → sign-out blocked; force path retains recoverability; reconnect produces one correct cloud record. |
| V1-M6 | Guardian unlink contract | Add a least-privilege `revoke_guardian_link` migration, signature/authorization tests, contract check, and deploy it; alternatively hide unlink/remove-child in V1 if deployment cannot be proven. | S | Unauthorized counterpart rejected; both valid directions work; hosted RPC verified; UI result handled. |
| V1-M7 | Close critical database authority | Revoke `EXECUTE` on `prune_audit_logs()` from `authenticated`; ensure only a service/maintenance role can invoke it. | XS | Fresh-DB and hosted checks prove authenticated cannot execute and maintenance path still works. |
| V1-M8 | Offline/no-STT completion | Add localized Arabic/English manual/self-grade actions to Adult and Kids; permit a safe first-use offline route that does not require three successful remote audio plays. | M | Denied microphone, unavailable recognizer, airplane mode, and empty audio cache all reach a recorded completion/review outcome without a crash or false automatic score. |
| V1-M9 | Honest voice privacy | Replace the absolute on-device claim with accurate Arabic/English platform/provider wording, explain that Talia does not retain raw audio, and link the manual option. | XS | Both policy languages match implemented behavior and store privacy declarations. |
| V1-M10 | Reproducible release proof | Run clean dependency restore, code generation if applicable, analyzer, all tests, release build, backend checks, and physical-device smoke tests from the frozen commit. | M | Stored command logs, artifact identity, device checklist, and zero unresolved critical/high defects. |
| V1-M11 | Project-owner content approval | Record the owner's decision for the shipped religious content and journeys. No unrecorded post-approval content mutation. | Owner XS | Completed owner-attestation record linked to the content manifest and hashes; no external signature required. |

### Adhkar/Dua allowlist selection protocol

1. Start the V1 allowlist empty; the 85 existing records have no presumption of inclusion.
2. Remove tips, religious notification fallbacks, and decorative religious output before selecting any record.
3. For each currently visible category, ask whether that category is necessary to the V1 UX. Hide it when the answer is no.
4. For a necessary category, the project owner selects and accepts the coherent set to ship. Engineering adds only the direct metadata and display changes required by those selected records.
5. Do not open correction work for a rejected, ambiguous, duplicate, weakly cited, or unnecessary candidate; exclude it.
6. If no coherent subset can be approved within the V1-M3 S/M engineering ceiling, hide the category. If no category qualifies, hide the entire Adhkar/Dua destination for V1.
7. Record the final allowlisted IDs and shipped-asset hash. Anything not on the list must be absent from the release bundle or unreachable by the release UI.

There is deliberately no numerical record target. Safety and coherence determine the small allowlist; completeness does not.

### Implementation order inside the Must-Fix scope

1. Freeze baseline and add failing integrity/regression tests.
2. Correct Quran boundaries/rendering and create the manifest.
3. Delete unsafe religious surfaces; create an empty Adhkar/Dua allowlist, add only the smallest directly verified subset, and hide empty categories.
4. Fix bookmark sign-out, guardian RPC, and database privilege independently.
5. Add manual/offline progression and align privacy text.
6. Freeze RC and run the remaining engineering, backend, device, artifact, and store gates. Owner content approval is already recorded.
7. Build the unchanged approved artifact and perform store smoke/staged rollout.

## V1 Should Fix

V1-S items are **not release scope and are not part of Definition of Done**. Skip them by default. An item may be accepted only when it is XS/S, changes no architecture, adds no abstraction, migration, or dependency, triggers no project-owner content reconfirmation, and delays no V1-M item. If any condition becomes false, defer the item immediately without replacing it.

| ID | Item | Why now | Effort | Deferral rule |
|---|---|---|---:|---|
| V1-S1 | Separate the Kids threshold with a direct constant/config value only. | Low effort and reduces inappropriate false failures. | XS | Implement only if the value is already accepted before RC review and the change is truly local; otherwise V1.1. |
| V1-S2 | Record free-tier provider budgets/alerts. | Manual operational protection without product or schema work. | XS/S | Defer if access/setup is not immediate; it cannot block RC work. |

Critical Arabic/English copy, exact QCF fallback behavior, and regression checks belong to their V1-M acceptance criteria; they are not optional V1-S work.

## Deferred — V1.1

| Item | Reason it can wait | Risk while deferred |
|---|---|---|
| Dead-letter UI, classification, and automatic pull recovery | Dead rows are durable; push kinds self-heal and pull stall generally recovers at login. | Cross-device pulls can stop silently until re-login after repeated failures. |
| Parent rewards outbox and monotonic merge | Current parent create is remote-first and reports failure; no ordinary hidden local-success path was proven. | Weaker offline UX and possible stale overwrite under unusual concurrency. |
| Separate Kids grading threshold, if V1-S1 is skipped | Manual grading removes the V1 completion blocker. | Automatic Kids grading remains as strict as the adult path. |
| Revoke residual direct DML on streaks/XP/daily activity | RLS limits writes to the caller's own rows; this is integrity/gamification abuse, not cross-user exposure. | A user can bypass monotonic RPC semantics for their own gamification data. |
| Full Flutter CI plus fresh-DB CI | Manual release gates can safely cover one V1 candidate. | More dependence on disciplined human execution after V1. |
| Audio download/offline pack management and prefetch wiring | Manual/offline progression removes the release blocker. | First-use offline users cannot listen to uncached recitation. |
| On-device-only STT capability routing | Availability varies by OS/device; accurate policy plus manual fallback is safer for V1. | Recognition may be processed by the platform/provider under its terms. |
| Kids log/reward pagination and retention enforcement | Initial scale and existing parent-summary limits make it noncritical. | Cost and latency grow with long-lived child histories. |
| Crash reporting/operational dashboards | No crash SDK exists; store staged rollout and support monitoring can cover V1. | Slower diagnosis of rare field failures. |
| Wider localization and accessibility pass | Critical new paths are covered in V1; no release-blocking accessibility defect was proven. | Secondary screens may remain less polished for English and assistive users. |
| Broader religious-literal CI lint | The narrow V1 scan/test covers known surfaces. | A future developer could add a new ungoverned surface. |

## Deferred — V1.2

| Item | Reason it can wait | Risk while deferred |
|---|---|---|
| Full riwayah-aware identity across text/audio/tajweed/progress | V1 can explicitly support and pin one approved riwayah and disable unverified reciters. | Adding a second riwayah before this work would be unsafe. |
| Scheduler/weak-evidence/protect-before-grow redesign | Current scheduler and Smart Coach are stable and well tested; no corruption defect was demonstrated. | The experience may be less pedagogically optimal than the target design. |
| Comprehensive Islamic content importer/reviewer workflow | A signed manifest and manual qualified review are sufficient for one frozen V1. | Content updates remain slower and more manual. |
| Advanced source-aware share/certificate templates | V1 removes or narrowly sources unsafe outputs. | Fewer decorative religious outputs and less sharing richness. |
| Full database contract generation from client calls | A narrow critical contract list covers launch. | New RPC drift can escape unless maintainers update the list. |

## Deferred — V2

- General `ContentEvidence`/content-policy domain and reusable governance engine.
- Multi-riwayah, multi-edition, and multi-reciter compatibility matrix.
- Sophisticated Quran importer with upstream-diff adjudication and automated licensing workflow.
- Navigation redesign. Hiding one unsafe optional destination under the Hard Stop is a scoped removal, not a redesign project.
- Large-file and dependency-graph refactors that do not correct a V1 defect.
- Performance budgets, scale/load suites, and full observability platform.
- Advanced personalization, adaptive pedagogy, and scheduler research work.
- Automated reviewer portal, signed content packages, and continuous corpus delivery.
- Cross-platform simultaneous launch machinery if V1 ships Android first.

## Dropped / Not Required

The following are intentionally not part of the minimum safe release:

- Replacing a **runtime** live Quran fetch: the application currently ships local assets; `scripts/fetch_quran.dart` is a developer script, not a runtime dependency.
- Repairing, grading, citing, translating, or re-reviewing all 85 Adhkar/Dua candidates. Only the smallest approved allowlist ships.
- Keeping all four current Adhkar/Dua category cards. An empty or unnecessary category is hidden rather than populated for completeness.
- Rebuilding all repositories/services into a new architecture before launch.
- Migrating all local persistence to one storage engine.
- Eliminating every large widget/cubit before V1.
- Rewriting the working sync engine.
- Building a generic CLI or portal to process a one-time reviewed corpus.
- Adding new product features to increase perceived V1 completeness.
- Proving that every possible STT provider is on-device; V1 instead states the truth and provides a no-STT route.
- Shipping a religious tip merely because it can be sourced. Nonessential content is safer to omit.
- Treating 100% code coverage, golden coverage, or automated store publication as a release criterion.

## 20-Task Triage

The labels below apply to the original `Talia Final Review Readiness Implementation Plan`.

| # | Original task | Triage | V1 decision | Effort before V1 |
|---:|---|---|---|---:|
| 1 | Reproducible baseline and audit reconciliation | PARTIAL | Record the frozen commit and run fresh release commands. Do not reopen or rewrite historical audits. | XS |
| 2 | Religious-content evidence types and release policy | DEFER | Do not create the evidence domain in V1. Task 7 may add only direct fields needed by the tiny shipped allowlist. | — |
| 3 | Immutable corpus manifests and validation tooling | SIMPLIFY | One small manifest plus hash/schema tests. No general CLI or CI platform. | S |
| 4 | Auditable Quran import and exact corpus tests | PARTIAL | Produce/freeze one corrected approved local corpus and boundary tests. Full reusable importer is deferred. | M |
| 5 | Exact Quran rendering and fail-closed structure | KEEP | Required before release; limit change to sacred display, structural validation, and safe exact fallback. | M |
| 6 | Riwayah-safe text/audio/tajweed/identity | SIMPLIFY | Declare and pin one riwayah; reviewer verifies enabled reciters; disable any unverified combination. Full model migration later. | S |
| 7 | Reviewed adhkar/dua corpus | SIMPLIFY | Start from an empty allowlist; add only the smallest directly verified subset; delete the rest and hide empty categories. Disable the feature if preservation exceeds M effort. | Engineering S/M; review M |
| 8 | Remove ungoverned religious output | KEEP | Delete optional tips, fallbacks, decorative literals, and unsafe share output. Do not rehabilitate or relocate them. | S |
| 9 | Guardian unlink and hosted contract | KEEP | Add/deploy/verify RPC or hide the action. | S |
| 10 | Bookmark loss during sign-out | KEEP | Correct the all-domain gate and add the exact failure-path integration test. | S |
| 11 | Dead-letter visibility/recovery/classification | DEFER | V1.1. Preserve durable queue; document re-login recovery/support procedure for V1. | — |
| 12 | Queue parent rewards and monotonic merge | DEFER | V1.1. Current remote-first failure is visible; do not redesign sync before launch. | — |
| 13 | Database grants and hosted-schema gate | PARTIAL | Revoke global prune authority and verify critical tables/RPC/RLS in fresh staging and production. Broader hardening later. | M |
| 14 | STT privacy, manual recall, Kids pedagogy | PARTIAL | Manual Adult/Kids fallback, offline audio escape, and truthful privacy only. Kids threshold is opportunistic V1-S1; audio packs/on-device routing wait. | M |
| 15 | Scheduling, weak evidence, protect-before-grow | DEFER | V1.2. Preserve the stable tested scheduler; correct external terminology if it overclaims canonical SM-2. | — |
| 16 | Localization, terminology, navigation, accessibility | PARTIAL | Translate only strings introduced or changed by V1-M work. Do not redesign navigation; permit hiding an unsafe optional content destination. Broader pass V1.1. | S |
| 17 | CI, real-service tests, performance, maintainability | PARTIAL | Add only critical regression tests and manually execute full release verification. CI/performance/refactors later. | M |
| 18 | Owner approval record and RC freeze | SIMPLIFY | A concise owner-attestation record, manifest, hashes, artifact/version, and commit are sufficient. | S |
| 19 | Preserve owner content approval with traceability | KEEP | Keep the owner decision and content hashes; no external reviewer or signature workflow is required. | Owner XS |
| 20 | Produce, verify, and roll out store release | PARTIAL | Signed release artifact, clean/upgrade smoke, internal track, then staged rollout. Automated publication and simultaneous platforms are optional. | M |

### Triage result

- **KEEP:** 5 tasks (5, 8, 9, 10, 19).
- **SIMPLIFY:** 4 tasks (3, 6, 7, 18).
- **PARTIAL:** 7 tasks (1, 4, 13, 14, 16, 17, 20).
- **DEFER:** 4 full tasks (2, 11, 12, 15), plus the advanced portions of the partial tasks.
- **DROP:** no whole original task; several overbuilt sub-deliverables are dropped under `Dropped / Not Required`.

The 20 row labels are mutually exclusive; deferred sub-deliverables inside `PARTIAL` rows are described in the row decision.

## Dependency Graph

```text
Frozen baseline
├── Quran track
│   ├── failing boundary/exactness tests
│   ├── corrected corpus + exact rendering + fail-closed parsing
│   └── manifest/hash → Quran reviewer check
├── Religious-content track
│   ├── remove optional literals/truncation
│   ├── empty allowlist → smallest verified subset only
│   ├── hide empty categories/routes/actions
│   └── shipped-subset manifest/hash → content reviewer check
├── Data/backend track
│   ├── bookmark-safe sign-out
│   ├── guardian RPC or hidden action
│   └── prune grant revoke → fresh/staging/production contract checks
└── Core-journey track
    ├── manual Adult/Kids grade
    ├── first-use offline escape
    └── accurate AR/EN privacy copy

All four tracks green
  → freeze Release Candidate 1
  → clean analyze + full tests + release build
  → physical-device clean-install/upgrade/offline smoke
  → retain the recorded owner approval and verify the shipped content hashes
  → no-unrecorded-content-change store artifact
  → internal store track → staged production rollout
```

The Quran and religious-content tracks require reviewer input and should start first. Data/backend and core-journey work can proceed independently in parallel. Any religious-content change after approval returns the candidate to reviewer check. If the religious-content track expands beyond its S/M engineering ceiling, stop it and disable the affected optional feature or category.

## Minimal Test Plan

### Automated tests required before RC1

1. **Quran integrity**
   - exactly 114 surahs, 6,236 ayahs, pages 1–604, juz 1–30;
   - contiguous global ayah numbers and valid surah-local boundaries;
   - Al-Fatihah ayah 1 retains its approved basmalah convention;
   - At-Tawbah has no inserted basmalah;
   - all other ayah-1 records contain only the approved numbered ayah, with basmalah handled structurally;
   - runtime SHA-256 equals the frozen manifest.
2. **Exact sacred rendering**
   - known samples, including surahs 2, 9, 95, and 97, remain character-for-character equal through datasource, QCF view, and fallback view;
   - missing global/page/juz data fails closed;
   - no notification/share helper truncates Quran/dua/dhikr text.
3. **Adhkar/dua contract**
   - only allowlisted retained IDs are bundled and reachable;
   - every retained record has required fields and a valid reviewer state;
   - source/citation and authenticity grade are present where applicable;
   - dua tier is one of the approved values;
   - manifest hash matches; record IDs are unique; duplicates are explicitly adjudicated.
   - empty/excluded categories, routes, notification actions, and cards are hidden;
   - no test requires excluded candidates to be repaired or preserved.
4. **Bookmark sign-out integration**
   - pending offline bookmark plus failed cloud push blocks normal sign-out;
   - forced path does not silently discard recoverable durable state;
   - reconnect/re-login converges to exactly one correct local/cloud bookmark.
5. **Guardian/database contract**
   - valid guardian/child link can be revoked from allowed direction(s);
   - unrelated/unauthenticated users cannot revoke;
   - `authenticated` cannot execute global audit pruning;
   - verifier includes the critical client RPC signatures.
6. **Manual/offline memorization**
   - Adult and Kids can choose manual grade when microphone is denied, STT is unavailable, or recognition errors;
   - empty-cache airplane-mode Kids can progress without required remote audio success;
   - completion, progress, review scheduling, and rewards are not double-awarded.
7. **Regression suite**
   - `flutter analyze` returns zero issues;
   - all existing and new Flutter tests pass from a clean process;
   - release build succeeds with production defines and without `.env` bundled.

### Tests explicitly not required for V1

- full golden coverage of every screen;
- 100% unit coverage;
- load testing at theoretical large scale;
- automated store publication;
- complete real-service end-to-end automation for every feature;
- performance refactoring without a measured release failure.

## Project-Owner Content Approval Scope

The project owner is the final internal content authority. The approval record identifies the manifest and content hashes. A frozen artifact is still required by G9 for release reproducibility, but no external reviewer or signature is required.

The project owner confirms the content actually shipped, covering:

1. Quran edition/riwayah declaration and source/license record.
2. Quran counts, surah/ayah boundaries, Al-Fatihah and At-Tawbah basmalah rules, and representative boundary samples including 2, 95, and 97.
3. Exact QCF and fallback rendering in reading, memorization, plan, search/detail, and share surfaces.
4. Every enabled reciter's compatibility with the declared text/riwayah; unverified reciters are disabled.
5. Every retained allowlisted adhkar/dua record: Arabic text, count, source, resolvable citation, grade attribution, tier, translation, and transliteration. Removed candidates do not require rehabilitation or individual review.
6. All remaining religious content in home, settings, certificate, notifications, and sharing; absence of truncation or paraphrase presented as source text.
7. Kids wording, grading framing, encouragement, and manual self-assessment language.
8. The user-facing labels that distinguish sourced text, guidance, and product instructions.

**Approval rule:** the owner's 2026-08-31 approval closes G8. A later religious-content/hash change requires owner reconfirmation of the affected part and updated hashes. External review or signature does not become mandatory. Pure binary/code-signing changes do not reopen G8 when reproducible evidence proves religious assets and rendered strings are unchanged.

## Minimal Backend Verification

Run the repository migrations against a disposable fresh Supabase/Postgres database, then run the same critical read-only/transaction-safe checks against staging and production.

Minimum contract:

- all core tables exist with RLS enabled;
- anonymous access is revoked;
- client RPC names and parameter signatures used by auth, bookmarks, review records, identity, parent dashboard, and guardian unlink exist;
- `revoke_guardian_link` enforces active-link membership and cannot target unrelated users;
- `prune_audit_logs` is not executable by `authenticated`;
- bookmark/review CAS and paginated review-pull functions are deployed;
- migration/version identity matches the release record;
- parent/child reads do not cross an unapproved guardian link;
- production secrets are supplied through build/runtime configuration and no `.env` asset is bundled.

If production access cannot be provided, the result is **NO-GO**. A locally passing migration is not a substitute for hosted verification.

## Minimal Store Smoke Test

Perform on at least one supported physical Android device and one additional Android version/form factor. If iOS is part of V1, repeat the same scope on a physical iPhone before that platform launches.

### Clean-install path

- install the signed release artifact from the internal store track;
- Arabic and English onboarding, guest start, sign-in, reset path, and account switch;
- open Mushaf, navigate first/last pages, search, bookmark, play cached/online audio, and resume;
- complete one Adult and one Kids memorization session with STT;
- repeat both with microphone denied/manual grade;
- empty-cache airplane-mode reading and memorization progression;
- adhkar counter, source/grade display, reset behavior, and background/resume;
- only approved Adhkar/Dua categories and records are visible; removed/empty categories and notification actions are unreachable;
- guardian link/unlink or verify the action is intentionally hidden;
- offline mutation, reconnect, sync, sign-out block, and re-login recovery;
- notification displays generic localized text and never truncated religious text;
- no crash, blank Quran text, mixed account data, or duplicate rewards.

### Upgrade path

- upgrade the latest distributed pre-V1 build without clearing data;
- bookmarks, memorization progress, plans, streak/XP, Kids data, settings, and owner isolation survive;
- corrected Quran/content assets load without migration loops or stale-cache mismatch;
- sign-out/account switch still protects pending data.

### Rollout

Internal track → small staged percentage → observe store vitals, auth/backend errors, support reports, and quota usage → expand only while gates remain green. Keep a kill switch/hide option for the guardian action and any unverified reciter/content surface.

## Release Gates

| Gate | Pass condition | Owner | Failure result |
|---|---|---|---|
| G0 — Scope hard stop | Only V1-M items enter the committed RC plan. A V1-S item is accepted only if every Hard Stop condition still holds. Any expansion stops for a report; optional content/features are deleted, disabled, or hidden rather than rescued. | Release manager | Remove scope expansion; do not re-estimate upward without an explicit new user decision. |
| G1 — Quran integrity | Correct boundaries, exact rendering, fail-closed fields, matching manifest hash, focused tests green. | Flutter/content engineering | NO-GO. |
| G2 — Religious content | No unapproved/truncated literals; only the smallest approved allowlist ships; all other candidates and empty categories are absent or unreachable. | Content engineering | Delete/hide the affected optional content; NO-GO only if unsafe content remains reachable. |
| G3 — Data safety | Bookmark failure-path tests pass; no known core pending-data loss path. | Sync engineer | NO-GO. |
| G4 — Backend/security | Guardian action works or is hidden; pruning privilege revoked; fresh/staging/production contract passes. | Backend/security owner | NO-GO. |
| G5 — Core offline/privacy | Adult/Kids manual route works; first-use offline route works; AR/EN policy matches behavior. | Flutter/product | NO-GO. |
| G6 — Engineering verification | Fresh analyzer clean, complete suite green, release artifact builds, no unresolved P0/P1 in V1 scope. | Release engineer | NO-GO. |
| G7 — Device/store smoke | Clean install and upgrade checklist pass on target physical devices/internal track. | QA/release | NO-GO. |
| G8 — Content approval | Project owner records acceptance of the religious content; external review/signature optional. | Project owner | `PASS — OWNER ATTESTATION (2026-08-31)`. |
| G9 — Artifact identity | Store artifact is built from approved commit; embedded content hashes match; no post-review content change. | Release manager | Rebuild and repeat affected gates. |

### Definition of Done for V1

V1 is done only when G0–G9 pass, the approved artifact is in the internal store track, staged rollout has an owner and rollback decision, and all deferred work is recorded without being misrepresented as completed. No V1-S item is required for this definition.

## Estimated Effort

Scale: **XS <1 hour; S 1–3 hours; M 3–8 hours; L 1–2 days; XL >2 days.** Estimates exclude waiting for credentials/store review and assume the current architecture remains intact.

| Workstream | Engineering | External/review | Parallelism |
|---|---:|---:|---|
| Quran correction, exact rendering, manifest, tests | L | Owner accepted | Content approval recorded; technical verification remains. |
| Adhkar/Dua release allowlist + unsafe-output deletion | S/M | Owner accepted | The current 109-record release file is approved; future content changes require owner reconfirmation. |
| Bookmark sign-out | S | — | Independent. |
| Guardian RPC + prune privilege + verifier | M | Production access S | Independent; deployment timing may block. |
| Manual/offline route + privacy/localization | M | Product/owner | Independent of backend; owner acceptance recorded. |
| Full verification, device/store smoke, RC records | M | QA/store M | Starts after merge/freeze. |

**Expected engineering effort:** approximately 3–6 focused engineering days with parallel ownership, or 5–9 sequential working days for one engineer. V1-S work is excluded.

**Owner content approval:** complete as of 2026-08-31. No external review wait or signature is included in the release schedule.

**Likely calendar critical path:** freeze the current shipped content hashes → complete technical/backend/device verification → build and verify the store artifact.

## Risk of Deferring

| Deferred area | Severity if it occurs in V1 | Likelihood at initial scale | Mitigation in V1 |
|---|---|---|---|
| Dead pull remains parked | Medium | Low–Medium | Durable state, retry/re-login support procedure, monitor sync reports. |
| Parent reward offline failure/overwrite | Medium | Low | Show failure; require connectivity for parent reward mutation; do not claim offline support for it. |
| Own-row XP/streak direct DML abuse | Low–Medium | Low | RLS prevents cross-user access; prioritize V1.1 revoke migration. |
| No full Flutter CI | Medium | Medium | Recorded clean manual release execution from frozen commit. |
| No audio packs/on-device-only STT | Medium UX impact | Medium | Manual grade and offline progression; accurate privacy disclosure. |
| Limited accessibility/localization pass | Medium | Medium | Cover critical AR/EN paths; publish known limitations internally. |
| No generic content governance | High on future content changes | Low for frozen V1 | Immutable hashes and a rule forbidding post-review content changes. |
| Scheduler remains unchanged | Low safety impact | Medium product impact | Avoid unsupported claims; collect post-launch evidence. |
| Limited observability | Medium | Low–Medium | Staged rollout, store vitals, backend dashboard, support channel, rollback owner. |

None of these deferrals permits adding a second riwayah, new religious content, or a new backend domain without reopening its corresponding control.

## Final Recommendation

### GO — READY TO IMPLEMENT V1 SCOPE

This is a **GO to implement the reduced V1 correction scope**, not a GO to publish the current application. Publication remains **NO-GO** until V1-M1 through V1-M11 are complete and release gates G0 through G9 pass.

The reduced plan removes most of the original architectural and automation work while retaining every correction that protects Quran exactness, the traceability of religious content that actually ships, user data, core offline use, privacy truthfulness, and backend authorization. Optional content starts excluded and earns inclusion; it is never repaired merely for completeness. This is the smallest defensible path to the owner-approved content baseline and subsequent store release.

### Explicit answers to the eight release questions

1. **What is the minimum safe V1?**  
   The existing core application with no new features, after exact Quran/corpus correction, only a smallest verified Adhkar/Dua allowlist (or the feature hidden), deletion of unsafe religious output, bookmark-safe sign-out, working-or-hidden guardian unlink, revoked audit-prune authority, manual Adult/Kids offline grading, truthful privacy text, production backend proof, physical-device smoke, and recorded project-owner content approval.

2. **What are the five highest-value fixes before release?**  
   (1) Quran exactness/boundaries; (2) delete ungoverned religious output and ship only a smallest verified Adhkar/Dua allowlist; (3) bookmark sign-out data-loss prevention; (4) guardian RPC/database privilege/hosted-contract verification; (5) offline/no-STT completion plus accurate privacy.

3. **Which original tasks should be cut, simplified, or deferred?**  
   Defer Tasks 2, 11, 12, and 15; simplify 3, 6, 7, and 18; partially execute 1, 4, 13, 14, 16, 17, and 20. Keep only the narrow release-critical results of 5, 8, 9, 10, and 19. Drop the repair of excluded religious records and the preservation of empty/unnecessary content categories.

4. **What remains safe to ship once blockers are fixed?**  
   The current Mushaf reader/navigation/search, bookmarks after the gate fix, auth/guest/account isolation, Adult V2 memorization state machine, Smart Coach/current scheduling, progress/streak/XP/certificates, Kids UX with the new manual route, the counter for only retained approved Adhkar/Dua content, and audio cache behavior. Navigation remains unchanged unless the Hard Stop requires hiding an unsafe optional content destination; optional religious categories need not ship.

5. **What is the minimum owner content-approval scope?**

   The frozen Quran edition/hash/boundaries/rendering/audio compatibility; every record in the small retained Adhkar/Dua allowlist; all religious UI, notification, certificate, and share output that remains reachable; and Kids religious/pedagogical wording, tied to the exact RC commit and artifact. Removed candidates require no repair or individual approval.

6. **What is the minimum backend verification?**  
   Fresh/staging/production proof of core table/RLS/anon posture, exact critical RPC signatures, guardian unlink authorization, pruning-function denial to authenticated users, CAS/paginated review functions, migration identity, and production configuration. No credentials means NO-GO.

7. **What is the minimum test/store proof?**  
   Focused integrity/data-loss/offline/backend tests, clean analyzer, the complete existing+new suite, a signed release build, clean-install and upgrade smoke on physical target devices, internal-store installation, then staged rollout with monitoring and rollback ownership.

8. **Is the project ready to publish now?**  
   **No.** G8 content approval is complete, but the project becomes publishable only after the remaining technical, backend, device, artifact, signing, and store gates pass.
