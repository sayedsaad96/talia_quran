# Talia V1 — Minimum Safe Release Plan

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

**Decision:** the triage is complete and the reduced V1 scope is ready to implement. The application itself remains **NO-GO for publication** until every V1 release gate in this document passes and the qualified Islamic reviewer signs the frozen release candidate.

## Current Release Reality

### Verified directly against the current repository

| Area | Current reality | Release effect |
|---|---|---|
| Repository | Working tree was clean at review start; baseline commit is recorded above. | Suitable for a controlled V1 correction branch. |
| Quran asset | `assets/data/quran.json` contains 6,236 ayahs, 604 pages, 30 juz, and 114 surahs. Its reviewed SHA-256 is `09f09074b7341859d4770cc2b9d8768d6a7f7b00d0003123238e6e9949b3fa82`. | Structurally complete, but not yet release-approved. |
| Basmalah boundary | Ayah 1 contains an embedded basmalah in 112 surahs other than Al-Fatihah and At-Tawbah. | Blocking because memorization, search/detail, and QCF paths can disagree about ayah boundaries. |
| Memorization text | `QuranTextDisplayFormatter.cleanAyahForMemorization` removes markers, changes spacing, inserts word boundaries, and collapses whitespace; `QcfHifzVerseView` applies it to QCF and asset text. | Blocking: sacred text used for memorization is not guaranteed character-for-character exact. |
| Quran datasource | Missing `global`, `juz`, or `page` values are guessed rather than rejected. | Small but high-consequence fail-open behavior; include in the Quran correction batch. |
| Adhkar/dua asset | 85 records; no authenticity-grade or tier fields; 73 references are not resolvable to a numbered citation; duplicate-text groups exist. | Blocking for any record retained in V1 until reviewed, graded where applicable, cited, and approved. |
| Religious literals | Hand-typed verses/hadith/dua exist in tips, notifications, a certificate, settings, and home UI. Notification code can truncate religious text. | Blocking. Remove the nonessential output or source it from the approved corpus without mutation. |
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
2. **Human Islamic approval is the final authority.** Automation proves integrity and traceability; it does not replace the qualified reviewer.
3. **Protect user work before adding sophistication.** No known path may discard pending bookmarks or other core progress.
4. **Core journeys must degrade safely.** Reading, memorization, and Kids completion must have a usable offline/no-STT path.
5. **Prefer deletion and a narrow schema change over a platform.** V1 does not need generic evidence abstractions, an importer framework, or a reviewer portal.
6. **Verify the deployed system, not only migrations.** A correct SQL file does not prove the hosted database is correct.
7. **Preserve stable features.** Do not redesign navigation, scheduling, sync, rewards, or architecture unless required by a blocker below.

## Critical Findings

### CF-1 — Quran text and ayah boundaries are not release-safe

The local Quran asset embeds the basmalah in ayah 1 for 112 surahs, while the QCF Mushaf presents it structurally. Separately, the memorization formatter modifies Quran strings. A learner can therefore see or be graded against a representation that differs from the approved corpus or from another screen.

**V1 decision:** correct the frozen local corpus or its deterministic structural import, remove mutating formatting from sacred display paths, reject missing structural fields, and prove exact output with focused tests and a manifest hash. Do not build a general Quran importer.

### CF-2 — Shipped religious content is not fully traceable

The 85-record adhkar/dua file cannot represent mandatory grade/tier data, most references are not numerically resolvable, and several screens contain hand-typed religious content. Notifications can modify a dua through truncation.

**V1 decision:** remove nonessential tips/fallback religious notifications and other decorative literals. For the adhkar/dua feature that remains, add only the minimum direct fields needed for source, citation, authenticity grade, tier, dataset version, and review state; remove any record the reviewer cannot approve. Do not build a generic `ContentEvidence` system.

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
| V1-M2 | Minimal immutable content manifest | One checked-in manifest for Quran and adhkar/dua with source, edition/version, riwayah where relevant, license status, SHA-256, import/freeze date, and reviewer status. | S | Test recomputes hashes and rejects drift; frozen RC points to exact manifest and commit. |
| V1-M3 | Reviewed adhkar/dua corpus | Extend the existing record/model directly with resolvable source/citation, source type, authenticity grade where applicable, dua tier, dataset version, and review state. Deduplicate intentionally and remove unverifiable records. | Engineering M; Islamic review XL | Every shipped record passes schema rules and has a reviewer disposition; UI shows source and grade/tier as applicable. |
| V1-M4 | Remove ungoverned religious output | Delete daily religious tips and religious notification fallbacks unless sourced from the approved corpus; use generic localized reminder text; never truncate sacred text; remove or source certificate/settings/home literals. | M | Repository scan plus UI/notification/share tests show no unapproved literal and no ellipsis mutation of religious text. |
| V1-M5 | Bookmark-safe sign-out | Include bookmarks and every current dirty domain in the authoritative flush gate; preserve durable state on normal and forced exits. | S | Offline bookmark → failed push → sign-out blocked; force path retains recoverability; reconnect produces one correct cloud record. |
| V1-M6 | Guardian unlink contract | Add a least-privilege `revoke_guardian_link` migration, signature/authorization tests, contract check, and deploy it; alternatively hide unlink/remove-child in V1 if deployment cannot be proven. | S | Unauthorized counterpart rejected; both valid directions work; hosted RPC verified; UI result handled. |
| V1-M7 | Close critical database authority | Revoke `EXECUTE` on `prune_audit_logs()` from `authenticated`; ensure only a service/maintenance role can invoke it. | XS | Fresh-DB and hosted checks prove authenticated cannot execute and maintenance path still works. |
| V1-M8 | Offline/no-STT completion | Add localized manual/self-grade actions to Adult and Kids; permit a safe first-use offline route that does not require three successful remote audio plays. | M | Denied microphone, unavailable recognizer, airplane mode, and empty audio cache all reach a recorded completion/review outcome without a crash or false automatic score. |
| V1-M9 | Honest voice privacy | Replace the absolute on-device claim with accurate platform/provider wording, explain that Talia does not retain raw audio, and link the manual option. | XS | Arabic and English policy text matches implemented behavior and store privacy declarations. |
| V1-M10 | Reproducible release proof | Run clean dependency restore, code generation if applicable, analyzer, all tests, release build, backend checks, and physical-device smoke tests from the frozen commit. | M | Stored command logs, artifact identity, device checklist, and zero unresolved critical/high defects. |
| V1-M11 | Qualified Islamic review | Review the exact frozen RC content and journeys described below; record approve/reject per scope item. No post-approval content mutation. | External XL | Signed approval linked to commit, manifest hashes, app version, and reviewed artifact. |

### Implementation order inside the Must-Fix scope

1. Freeze baseline and add failing integrity/regression tests.
2. Correct Quran boundaries/rendering and create the manifest.
3. Remove unsafe religious surfaces; update and review the retained adhkar/dua corpus.
4. Fix bookmark sign-out, guardian RPC, and database privilege independently.
5. Add manual/offline progression and align privacy text.
6. Freeze RC, run engineering/backend/device gates, then conduct final Islamic review.
7. Build the unchanged approved artifact and perform store smoke/staged rollout.

## V1 Should Fix

These are included only when they remain within the stated effort and do not delay a Must-Fix item or invalidate Islamic review.

| ID | Item | Why now | Effort | Deferral rule |
|---|---|---|---:|---|
| V1-S1 | Separate configurable Kids acceptance threshold from the adult 92% setting. | Low effort and reduces inappropriate false failures; reviewer/product owner should approve the value. | XS | Defer if manual grading fully mitigates it and no value is approved. |
| V1-S2 | Localize critical new error, privacy, notification, and manual-grade strings in Arabic and English. | These strings are in release-blocking journeys. | S | Only secondary copy may defer; no hardcoded release-path string may remain. |
| V1-S3 | Make QCF/font failure visibly safe and fall back only to exact approved asset text. | Prevents a silent blank/modified memorization view. | S | Must be promoted to Must Fix if device smoke reveals a blank or altered view. |
| V1-S4 | Record free-tier provider budgets/alerts and verify the paginated review RPC is deployed. | Cheap protection against configuration drift and full 6,236-row fallback pulls. | S | Manual provider alert setup can occur immediately before staged rollout. |
| V1-S5 | Add a narrow lint/test list for the known religious-output surfaces. | Prevents regression during the short V1 correction window. | S | A broad semantic religious-literal linter is not required. |

## Deferred — V1.1

| Item | Reason it can wait | Risk while deferred |
|---|---|---|
| Dead-letter UI, classification, and automatic pull recovery | Dead rows are durable; push kinds self-heal and pull stall generally recovers at login. | Cross-device pulls can stop silently until re-login after repeated failures. |
| Parent rewards outbox and monotonic merge | Current parent create is remote-first and reports failure; no ordinary hidden local-success path was proven. | Weaker offline UX and possible stale overwrite under unusual concurrency. |
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
- Navigation redesign or reduction of the existing five tabs.
- Large-file and dependency-graph refactors that do not correct a V1 defect.
- Performance budgets, scale/load suites, and full observability platform.
- Advanced personalization, adaptive pedagogy, and scheduler research work.
- Automated reviewer portal, signed content packages, and continuous corpus delivery.
- Cross-platform simultaneous launch machinery if V1 ships Android first.

## Dropped / Not Required

The following are intentionally not part of the minimum safe release:

- Replacing a **runtime** live Quran fetch: the application currently ships local assets; `scripts/fetch_quran.dart` is a developer script, not a runtime dependency.
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
| 2 | Religious-content evidence types and release policy | SIMPLIFY | Add minimum fields directly to the existing adhkar/dua model and a short policy/checklist. No generic evidence hierarchy. | M |
| 3 | Immutable corpus manifests and validation tooling | SIMPLIFY | One small manifest plus hash/schema tests. No general CLI or CI platform. | S |
| 4 | Auditable Quran import and exact corpus tests | PARTIAL | Produce/freeze one corrected approved local corpus and boundary tests. Full reusable importer is deferred. | M |
| 5 | Exact Quran rendering and fail-closed structure | KEEP | Required before release; limit change to sacred display, structural validation, and safe exact fallback. | M |
| 6 | Riwayah-safe text/audio/tajweed/identity | SIMPLIFY | Declare and pin one riwayah; reviewer verifies enabled reciters; disable any unverified combination. Full model migration later. | S |
| 7 | Reviewed adhkar/dua corpus | SIMPLIFY | Review only records actually shipped; add required direct metadata; remove unverifiable records. No importer framework. | Engineering M; review XL |
| 8 | Remove ungoverned religious output | KEEP | Delete optional tips/fallbacks; generic notifications; no sacred truncation; source or remove remaining literals. | M |
| 9 | Guardian unlink and hosted contract | KEEP | Add/deploy/verify RPC or hide the action. | S |
| 10 | Bookmark loss during sign-out | KEEP | Correct the all-domain gate and add the exact failure-path integration test. | S |
| 11 | Dead-letter visibility/recovery/classification | DEFER | V1.1. Preserve durable queue; document re-login recovery/support procedure for V1. | — |
| 12 | Queue parent rewards and monotonic merge | DEFER | V1.1. Current remote-first failure is visible; do not redesign sync before launch. | — |
| 13 | Database grants and hosted-schema gate | PARTIAL | Revoke global prune authority and verify critical tables/RPC/RLS in fresh staging and production. Broader hardening later. | M |
| 14 | STT privacy, manual recall, Kids pedagogy | PARTIAL | Manual Adult/Kids fallback, offline audio escape, truthful privacy, optional separate Kids threshold. Audio packs/on-device routing later. | M |
| 15 | Scheduling, weak evidence, protect-before-grow | DEFER | V1.2. Preserve the stable tested scheduler; correct external terminology if it overclaims canonical SM-2. | — |
| 16 | Localization, terminology, navigation, accessibility | PARTIAL | Translate only blocker-related and core release-path strings. Keep five tabs. Broader pass V1.1. | S |
| 17 | CI, real-service tests, performance, maintainability | PARTIAL | Add only critical regression tests and manually execute full release verification. CI/performance/refactors later. | M |
| 18 | Islamic reviewer packet and RC freeze | SIMPLIFY | A concise checklist, manifest, diff summary, artifact/version, and commit are sufficient. | S |
| 19 | Process Islamic review with traceability | KEEP | Mandatory manual qualified review of the frozen RC; no workflow automation needed. | External XL |
| 20 | Produce, verify, and roll out store release | PARTIAL | Signed release artifact, clean/upgrade smoke, internal track, then staged rollout. Automated publication and simultaneous platforms are optional. | M |

### Triage result

- **KEEP:** 5 tasks (5, 8, 9, 10, 19).
- **SIMPLIFY:** 5 tasks (2, 3, 6, 7, 18).
- **PARTIAL:** 7 tasks (1, 4, 13, 14, 16, 17, 20).
- **DEFER:** 3 full tasks (11, 12, 15), plus the advanced portions of the partial tasks.
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
│   ├── minimal adhkar/dua schema + reviewed records
│   └── manifest/hash → content reviewer check
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
  → final qualified Islamic review against RC1 hashes
  → no-content-change signed artifact
  → internal store track → staged production rollout
```

The Quran and religious-content tracks require reviewer input and should start first. Data/backend and core-journey work can proceed independently in parallel. Any religious-content change after approval returns the candidate to reviewer check.

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
   - every retained record has required fields and a valid reviewer state;
   - source/citation and authenticity grade are present where applicable;
   - dua tier is one of the approved values;
   - manifest hash matches; record IDs are unique; duplicates are explicitly adjudicated.
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

## Minimal Islamic Review Scope

The qualified Islamic reviewer receives one frozen candidate, not a moving branch. The packet must contain the commit, app version/build, manifest, hashes, content diffs, and a short device/navigation checklist.

The reviewer must approve or reject:

1. Quran edition/riwayah declaration and source/license record.
2. Quran counts, surah/ayah boundaries, Al-Fatihah and At-Tawbah basmalah rules, and representative boundary samples including 2, 95, and 97.
3. Exact QCF and fallback rendering in reading, memorization, plan, search/detail, and share surfaces.
4. Every enabled reciter's compatibility with the declared text/riwayah; unverified reciters are disabled.
5. Every retained adhkar/dua record: Arabic text, count, source, resolvable citation, grade attribution, tier, translation, and transliteration.
6. All remaining religious content in home, settings, certificate, notifications, and sharing; absence of truncation or paraphrase presented as source text.
7. Kids wording, grading framing, encouragement, and manual self-assessment language.
8. The user-facing labels that distinguish sourced text, guidance, and product instructions.

**Approval rule:** one rejection blocks release until corrected and re-reviewed. A content/hash change invalidates the prior approval. A pure binary/code-signing change may avoid re-review only if reproducible evidence proves assets and rendered strings are unchanged.

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
| G0 — Scope freeze | Only V1 Must Fix and approved Should Fix items enter RC1. | Release manager | Remove scope creep or re-estimate. |
| G1 — Quran integrity | Correct boundaries, exact rendering, fail-closed fields, matching manifest hash, focused tests green. | Flutter/content engineering | NO-GO. |
| G2 — Religious content | No unapproved/truncated literals; all retained records satisfy schema and preliminary reviewer disposition. | Content engineering | NO-GO. |
| G3 — Data safety | Bookmark failure-path tests pass; no known core pending-data loss path. | Sync engineer | NO-GO. |
| G4 — Backend/security | Guardian action works or is hidden; pruning privilege revoked; fresh/staging/production contract passes. | Backend/security owner | NO-GO. |
| G5 — Core offline/privacy | Adult/Kids manual route works; first-use offline route works; AR/EN policy matches behavior. | Flutter/product | NO-GO. |
| G6 — Engineering verification | Fresh analyzer clean, complete suite green, release artifact builds, no unresolved P0/P1 in V1 scope. | Release engineer | NO-GO. |
| G7 — Device/store smoke | Clean install and upgrade checklist pass on target physical devices/internal track. | QA/release | NO-GO. |
| G8 — Islamic approval | Qualified reviewer signs exact commit/manifest/artifact content. | Islamic reviewer | NO-GO. |
| G9 — Artifact identity | Store artifact is built from approved commit; embedded content hashes match; no post-review content change. | Release manager | Rebuild and repeat affected gates. |

### Definition of Done for V1

V1 is done only when G0–G9 pass, the approved artifact is in the internal store track, staged rollout has an owner and rollback decision, and all deferred work is recorded without being misrepresented as completed.

## Estimated Effort

Scale: **XS <1 hour; S 1–3 hours; M 3–8 hours; L 1–2 days; XL >2 days.** Estimates exclude waiting for credentials/store review and assume the current architecture remains intact.

| Workstream | Engineering | External/review | Parallelism |
|---|---:|---:|---|
| Quran correction, exact rendering, manifest, tests | L | Reviewer M | Start first; blocks final content freeze. |
| Adhkar/dua metadata + unsafe-output removal | L | Islamic review XL | Can run in parallel with Quran engineering; likely calendar critical path. |
| Bookmark sign-out | S | — | Independent. |
| Guardian RPC + prune privilege + verifier | M | Production access S | Independent; deployment timing may block. |
| Manual/offline route + privacy/localization | M | Product/reviewer S | Independent of backend. |
| Full verification, device/store smoke, RC records | M | QA/store M | Starts after merge/freeze. |

**Expected engineering effort:** approximately 4–7 focused engineering days with parallel ownership, or 7–12 sequential working days for one engineer.  
**Expected qualified Islamic review:** XL, because every retained adhkar/dua record and all religious surfaces must be inspected; schedule 2–5 working days plus correction/re-review time.  
**Likely calendar critical path:** reviewed adhkar/dua disposition → frozen content hashes → final Islamic approval → store artifact.

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

The reduced plan removes most of the original architectural and automation work while retaining every correction that protects Quran exactness, religious traceability, user data, core offline use, privacy truthfulness, and backend authorization. It is the smallest defensible path to the user's stated final qualified Islamic review and subsequent store release.

### Explicit answers to the eight release questions

1. **What is the minimum safe V1?**  
   The existing application with no new features, after exact Quran/corpus correction, reviewed traceable retained religious content, removal of unsafe religious literals/truncation, bookmark-safe sign-out, working-or-hidden guardian unlink, revoked audit-prune authority, manual Adult/Kids offline grading, truthful privacy text, production backend proof, physical-device smoke, and signed Islamic approval.

2. **What are the five highest-value fixes before release?**  
   (1) Quran exactness/boundaries; (2) reviewed adhkar/dua plus removal of ungoverned output; (3) bookmark sign-out data-loss prevention; (4) guardian RPC/database privilege/hosted-contract verification; (5) offline/no-STT completion plus accurate privacy.

3. **Which original tasks should be cut, simplified, or deferred?**  
   Simplify Tasks 2, 3, 6, 7, and 18; partially execute 1, 4, 13, 14, 16, 17, and 20; defer 11, 12, and 15 plus the advanced portions of the partial tasks. Keep only the narrow release-critical results of 5, 8, 9, 10, and 19.

4. **What remains safe to ship once blockers are fixed?**  
   The current Mushaf reader/navigation/search, bookmarks after the gate fix, auth/guest/account isolation, Adult V2 memorization state machine, Smart Coach/current scheduling, progress/streak/XP/certificates, Kids UX with the new manual route, approved adhkar counter, audio cache behavior, and the existing five-tab navigation.

5. **What is the minimum Islamic review scope?**  
   The frozen Quran edition/hash/boundaries/rendering/audio compatibility; every retained adhkar/dua text/count/source/citation/grade/tier/translation; all religious UI, notification, certificate, and share output; and Kids religious/pedagogical wording, tied to the exact RC commit and artifact.

6. **What is the minimum backend verification?**  
   Fresh/staging/production proof of core table/RLS/anon posture, exact critical RPC signatures, guardian unlink authorization, pruning-function denial to authenticated users, CAS/paginated review functions, migration identity, and production configuration. No credentials means NO-GO.

7. **What is the minimum test/store proof?**  
   Focused integrity/data-loss/offline/backend tests, clean analyzer, the complete existing+new suite, a signed release build, clean-install and upgrade smoke on physical target devices, internal-store installation, then staged rollout with monitoring and rollback ownership.

8. **Is the project ready to publish now?**  
   **No.** The project is ready to begin a sharply reduced V1 implementation. It becomes publishable only after every binary gate passes and the qualified Islamic reviewer approves the unchanged frozen release candidate.
