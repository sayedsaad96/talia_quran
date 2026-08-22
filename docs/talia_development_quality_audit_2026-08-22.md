# Talia — Development-Stage Quality, Feature-Completeness & A→Z Project Audit

**Date:** 2026-08-22 (Rev 2 — 2026-08-23) · **Auditor:** ZCode engineering audit (evidence-based, repository-level)
**Mandate:** Development-stage audit. This report contains **no release verdict, no GO/NO-GO, no production-readiness score**. It classifies the actual engineering state of each area and provides a remediation backlog.

> **Rev 2 changelog (after external critique by Codex, re-adjudicated against code):** ARB key count corrected to **1,142** per locale (was miscounted as 1,146); achievements confirmed **already localized** via `localizedAchievementTitle/Description` — P1-7 rescoped to notifications/certificate-share/tutorial/errors; privacy policy confirmed **bilingual** (`getEnglishContent()` exists); dead-letter finding narrowed — **push kinds self-heal** via the local-change push path (`_performPendingPushes`), only **pull kinds** can stall until re-login — and backoff corrected to **≈2.1–2.6h** (was wrongly stated 7.5h); bookmark revision-downgrade downgraded to theoretical (server CAS prevents regression in the normal path); two missed findings added: **P1-9 STT `onDevice` not set vs privacy-policy claim** and **UX-11 no manual/self-grade fallback when STT unavailable**; basmalah fix guidance extended for the diacritic variants in surahs **95 & 97** (`بِّسْمِ` vs `بِسْمِ`). The 916/916 test pass and clean analyzer remain verified from this audit's own execution logs (Codex's environment could not re-run them).

> **Rev 3 changelog (2026-08-23 — reviewed against the project's Islamic knowledge base `.agents/talia_islamic_knowledge_skill`):** Quran-content and adhkar/dua findings re-graded using the KB's own rule IDs. P0-2 fix guidance aligned with KB rules (QUR-01/QUR-03, `01_quran_foundations` basmalah convention). **CO-3 sajdah count reframed** per KB: 14 agreed + 1 disputed (Al-Hajj 22:77 vs Ṣād 38:24) — never assert a single 14/15. **CO-4 upgraded P3→P2**: azkar dataset lacks `authenticityGrade` (HAD-01 = Critical/Blocking in KB) and 12/22 dua references carry no hadith number (HAD-02 requires `Collection, Number`). **New CO-8 (P1)**: `azkar_page.dart:367-426` hardcodes **hand-typed Quran verses** (HAL-01/QUR-01 violation) and **unsourced/ungraded hadith** (HAD-01/HAD-03) directly in UI code — the exact pattern KB `14_content_validation.md` prescribes a CI lint for. **New CO-9**: duas category lacks the `tier` field (quranic/prophetic/guidance) required by `09_dua.md`. The 6,236 integrity check is now qualified as the Hafs/Kufi convention per KB `01_quran_foundations`.

> Note: `docs/talia-full-project-quality-islamic-content-audit-2026-08-22.md` (written earlier today under a different mandate) reaches release conclusions. This report deliberately does not, per its audit charter; where the two overlap on facts, this report re-verifies them independently.

---

# 1. Executive Summary

Talia is at a **high level of implementation maturity for a development-stage project**. The skeleton is genuine Clean Architecture (dartz `Either` + use cases + repository interfaces + get_it + go_router + Cubits), the offline-first sync system is unusually sophisticated (kind-level durable queue, acknowledgement-based dirty-flag clearing, CAS with revision, explicit conflict surfacing), and the backend has RLS on every table with anon fully revoked. Static analysis is **completely clean** (`flutter analyze`: 0 issues) and the **entire test suite passes (916/916)**. The codebase has **zero TODO/FIXME/HACK markers and zero dead buttons** — rare at this stage.

The most important defects found:

1. **P0 — Guardian unlink is broken end-to-end.** The client's only path for `unlinkGuardian()`/`removeChild()` calls an RPC `revoke_guardian_link` that **does not exist in any migration** — every attempt will fail with `PGRST202`. Verified first-hand.
2. **P0 — Basmalah is concatenated into ayah 1 of 112 surahs** in `assets/data/quran.json` (everyayah convention). The memorization/daily-plan/long-press text pipeline shows basmalah-prefixed "ayah 1" while the rendered QCF mushaf page shows it as a separate unnumbered header — the app's core domain (memorization text) is internally inconsistent. Verified programmatically.
3. **P0 — Permanent bookmark loss path on sign-out.** `flushBeforeSignOut` does not include bookmark pending-work in its gate; a failed bookmark push lets sign-out proceed, after which `AccountDataReset` wipes the local bookmark store.
4. **P1 — Sync dead-letters are invisible; pull kinds can stall until re-login.** After 8 failed attempts (≈2.1–2.6h cumulative backoff) a queue kind parks. **Push kinds self-heal**: any later local mutation or full sync retries dirty pushes directly and `markSuccess` deletes even dead rows. But **pull kinds** (review/bookmark/streak/kids pulls) only run inside a full `run()`, and `resumeIfNeeded` skips when `hasPending()` is false — so once pull rows are dead and nothing else re-triggers a full sync, **cloud changes from other devices stop arriving until the next login**, with no user-visible signal. `recoverDeadLetter` is never called by app code.
5. **P1 — Demonstrated live-database drift.** The remediation migration was committed but not applied to the hosted project (the `supabase/apply_bookmark_functions.sql` hotfix documents a real `PGRST202` incident), and the contract-verification script does not check `revoke_guardian_link` — the exact class of bug that produced finding #1.
6. **P1 — Parent rewards bypass the outbox** (direct RPC writes, no queue kind, no dirty flag) and the pull path **overwrites local rewards wholesale** with the remote list.
7. **P1 — Privacy policy claims on-device voice processing, but STT never sets `onDevice: true`.** Both STT call sites pass only `localeId`/`pauseFor`/`listenFor` (`memorization_session_cubit.dart:425`, `kids_mode_cubit.dart:608`); the plugin default routes recognition through the OS speech service, while the policy states "تتم معالجة الصوت فورياً داخل جهازك ولا يتم تسجيله أو نقله" (`privacy_policy_content.dart:38`). The legal text is currently unverifiable from the code (see P1-9).
8. **P1 — Hand-typed Quran verses and unsourced hadith hardcoded in UI code (Rev 3, KB-critical).** The daily-tip list in `azkar_page.dart:367-426` contains 9 Quran verses typed by hand (unverifiable against the vetted dataset — HAL-01/QUR-01) and 9 hadith items with no source or grade (HAD-01/HAD-03) — the exact pattern the project's own Islamic knowledge base prescribes a CI lint against (CO-8).

Biggest architectural risks: presentation-layer erosion (SharedPreferences treated as a global bag, pages calling repositories/services via `getIt` directly), God widgets/cubits (1,780- and 1,765-line files; 13-dependency `HomeCubit`), and three parallel localization mechanisms (~300 hardcoded Arabic strings, 78 `isArabic ?` ternary systems, plus AppLocalizations) — which together mean **English-language users currently receive Arabic notification, certificate/share, tutorial, and error content** (achievements and the privacy policy *are* localized — see rescoped P1-7).

Biggest testing gaps: streak and XP tests validate **local re-implementations** of the algorithms instead of the real services; Quran asset integrity (114 surahs / 6,236 ayahs) has **no automated test**; bookmark cloud CAS is untested on the Dart side; there is **no Flutter analyze/test CI** (only a Supabase-contract workflow).

Performance and content are otherwise strong: Quran metadata integrity is perfect (114/6236/pages 1–604/juz 1–30, all verified), heavy JSON parsing is isolate-based, audio is cached, and no evidence-based frame-level bottleneck was found — remaining items are listed with triggers in §11.

---

# 2. Audit Scope

**Inspected:** entire repository — `lib/` (351 Dart files, ~78k LOC incl. generated), `test/` (139 test files), `supabase/` (12 migrations + config + hotfix SQL), `assets/data/` (quran.json, surahs.json, azkar.json), `scripts/`, `.github/workflows/`, root docs (`README.md`, `ArchitectureSpec.md`, `ProductSpec.md`, `PRODUCT.md`, `DESIGN.md`, `fix_production_restore.md`), `docs/` (20 files), `pubspec.yaml`, `analysis_options.yaml`, `third_party/`, `tools/`.

**Executed:** `flutter analyze` (clean, 11.8s) and `flutter test` (full suite: **All tests passed, +916**, including 4 real-Isar integration tests and 1 golden suite). First-hand verification of the `revoke_guardian_link` contract break and the basmalah content issue (programmatic check of `quran.json`).

**Not performed:** interactive on-device/emulator runtime sessions (cold start, STT, audio playback, camera QR linking, background Workmanager delivery on Android). Runtime conclusions in §18 are inferred from code + passing widget/integration tests and are marked accordingly.

**Working-tree caveat:** the tree contains uncommitted onboarding rework (onboarding pages/cubits, l10n regeneration removing ~30 keys, `QuranWarmupService`, `.impeccable/` briefs). The audit covers the working tree as-is; onboarding conclusions match the new brief.

---

# 3. Project Architecture Assessment

**Actual architecture (as built):**

- **Startup:** `main.dart` (`runZonedGuarded` + error hooks) → `TaliaApp` two-phase shell (splash-only router pre-init) → `AppInitializer.initialize()` inside `SplashPage`: Supabase init (dart-define from `.env` via launch config) → `getIt.reset()` + `configureDependencies()` → notifications → `BackgroundSyncScheduler` → one-time `HifzMigrationService`.
- **DI:** get_it, single global, one 560-line `configureDependencies()`; mixed eager/lazy singletons + factories; only one `dispose` hook (`CloudSyncCoordinator`). `AuthCubit` is an eager singleton while `getIt.reset()` runs on re-init — fragile combination.
- **Navigation:** go_router with global auth-gated redirect (only `/family-dashboard` is remote-protected — consistent with offline-first), `StatefulShellRoute.indexedStack` with 5 bottom-nav branches, async per-route guards in `MemorizationRouteGuard` (845-line router file).
- **State:** flutter_bloc, **Cubits only** (21 Cubits, 0 Blocs). All inspected states model loading/error variants.
- **Persistence:** Isar (7 schemas: hifz progress, review records, V2 sessions, streaks, XP, daily activity, sync queue) + SharedPreferences (reading progress, azkar counters, profile/theme/locale, notification prefs) + flutter_secure_storage (parent PIN, encrypted account prefs). `lib/core/persistence/` exists but is **empty**.
- **Sync:** durable kind-level Isar queue (`CloudSyncQueue`) + feature-level dirty flags + Workmanager one-off background tasks + foreground `CloudSyncCoordinator` on auth events/2s-debounced local changes/5min-debounced resume.
- **Error handling:** dartz `Either<Failure, T>` (35 files), `Failure` hierarchy in `core/error/app_failure.dart`, `TaliaLogger` abstraction.

**Declared vs actual — mismatches:**

| # | Declared | Actual | Evidence |
|---|----------|--------|----------|
| A-1 | README: "strict Clean Architecture, UI→BLoC→UseCases→Repositories" | Pages routinely skip cubits/usecases, calling repositories/services via `getIt` directly; 12 presentation files import SharedPreferences | `home_page_widgets.dart:307,927,1296`; `login_page.dart:104`; `quran_reader_page.dart:133`; `settings_notification_tiles.dart:63-88` |
| A-2 | README diagram: prefs/Isar touched only by Data layer | `StreakService`/`XpService` (core/services) hold raw Isar handles; application-layer cubits read/write SharedPreferences | `streak_service.dart:13`, `xp_service.dart:11`, `azkar_cubit.dart:22-104` |
| A-3 | README: "State Management: BLoC" | Cubits only | 21 `extends Cubit<`, 0 `extends Bloc<` |
| A-4 | ArchitectureSpec:187 "no duplication without adapter" | Three per-ayah persistence systems registered simultaneously (hifz `IsarAyahProgress`, `IsarAyahReviewRecord`, `IsarV2Session`); migration adapter exists but legacy layer remains permanently registered | `injection.dart:108-116,283` |
| A-5 | ArchitectureSpec:155 feature flag `enable_memorization_v2` | No such flag; actual flags: `JourneyFeatureFlags.unifiedJourneyEnabled`, `CloudSyncFeatureFlags` | `journey_feature_flags.dart`, `cloud_sync_feature_flags.dart` |
| A-6 | README: build_runner generates "Isar schemas & GetIt locators" | DI is strictly manual; build_runner only for isar_generator/Mockito | `injection.dart` |

**Architecture Health Matrix:**

| Area | Current Implementation | Intended Architecture | Alignment | Problem | Recommendation |
|------|----------------------|----------------------|-----------|---------|----------------|
| Layering | Clean skeleton intact; erosion at presentation edge | Strict layer boundaries | PARTIAL | prefs/`getIt` shortcuts in UI | Introduce presentation-facing view-model services; enforce via lint/architecture tests |
| DI | get_it manual, one 560-line function | Manual registration | PARTIAL | `getIt.reset()` + eager `AuthCubit` singleton; testability | Split registration into feature modules; avoid reset at runtime |
| State mgmt | Cubits, complete states | Cubit/BLoC | ALIGNED | dependency bloat (13/11/10 ctor deps) | Extract collaborators into sub-services |
| Persistence | Isar core + prefs periphery | Isar source of truth | PARTIAL | reading progress/bookmarks/counters in prefs; `core/persistence/` empty | Migrate per-user data to Isar or document the split as intentional |
| Sync | Kind-queue + dirty flags + CAS | Offline-first outbox | ALIGNED (strong) | dead-letter invisibility; rewards bypass; bookmarks gate gap | See §9 findings |
| Navigation | go_router shell + guards | go_router | ALIGNED | 845-line router w/ business logic in guards | Extract guard logic; split route definitions |
| Error handling | dartz + Failure + logger | dartz | ALIGNED | ~40 methods collapse all exceptions to `CacheFailure(e.toString())` | Typed failures + logger at data boundaries (copy `auth_repository_impl` pattern) |
| Localization | gen-l10n + 2 hand-rolled systems | Single arb pipeline | PARTIAL | 3 parallel i18n mechanisms | Consolidate into arb (see §12) |

---

# 4. Feature Inventory & Completeness

| Feature | Purpose | Implementation | Functional State | UX | Data | Offline | Sync | Tests | Issues |
|---------|---------|----------------|------------------|----|------|---------|------|-------|--------|
| memorization_plus | Core hifz workflow (V2 sessions, SM-2 review, plans, kids, family) | Full 3-layer + core/memorization domain | **MOSTLY_COMPLETE** (FSRS intentionally shadow-mode) | Good | Isar+cloud | Strong | Strong (queue+CAS) | Strong | Basmalah text (P0-2); reward sync bypass (P1-6); giant files |
| hifz (legacy) | Old hifz system | Data+domain only; writes retired by design (`hifz_repository_impl.dart:40-48`) | **RETIRED-BY-DESIGN** (migration source) | n/a | Isar | Local-only | Via migration only | Retirement guard test | Legacy layer still registered (debt) |
| progress | Unified stats/achievements | Full | **COMPLETE** | Good | Review records + read pages | Strong | Reads only | Good | 52 hardcoded AR strings (P1-7) |
| xp | XP/levels | Data+domain; displayed via Home | **MOSTLY_COMPLETE** (2 award events only — thin by design?) | OK | Isar | Strong | `upsert_xp` | **Mirror-test only** | Untested real service (P2) |
| streak | Streaks/freezes/heatmap | Full | **COMPLETE** | Good | Isar | Strong | `upsert_streak` | **Mirror-test only** | Untested real service (P2) |
| azkar | Morning/evening/general/duas | Full | **COMPLETE** | Good | Asset + prefs counters | Local-only by design | None (by design) | None (no test dir) | No test coverage; counters device-local |
| certificate | Certificates for milestones | Domain+presentation | **COMPLETE** | Good | Prefs + cloud | Strong | Push/pull | Strong | PDF is PNG-in-PDF (raster); 50 hardcoded AR strings |
| auth | Email/password + guest | Full | **COMPLETE** | Good | Supabase + local | Strong (offline sign-out reset) | Push/pull on login | Good | 896-line repo; AR error strings |
| home | Dashboard, journey, coach | Full | **COMPLETE** | Good | Aggregates | Strong | n/a | Good | 1780-line widget file; 13-dep cubit |
| onboarding | First-run flow | Presentation-only (being reworked in tree) | **COMPLETE** (matches new brief) | Good | Prefs | Local | None (by design) | Strong (flow + goldens) | — |
| quran | Reading, pages, bookmarks, reciters | Full | **COMPLETE** | Good | Asset + prefs bookmarks | Strong | Bookmark CAS | Local-only tests | Basmalah mismatch; cloud CAS untested; sign-out wipe gap (P0-3) |
| settings | Prefs, account, notifications, parent PIN | Full | **COMPLETE** | Good | Prefs/secure | Local | Identity push (ungated) | Good | 776-line widget w/ scheduling logic |
| splash | Bootstrap gate | Presentation | **COMPLETE** | Good (init-error retry) | — | — | — | Covered via onboarding tests | AR-only retry copy |
| tutorial_guide | Static usage guide | Presentation | **COMPLETE** (static by design) | OK | — | — | — | 1 file | 13 hardcoded AR strings |

**Feature purpose validation (does each accomplish its intent?):**
- **Memorization**: yes — V2 state machine (Learning→Memorizing→Reciting→Remediation→BlockReview→Completed), crash-safe session resume, STT with hint-level mapping, double-award prevention. **Except** the ayah-1 text shown/plan-ed for surahs ≠ 1/9 includes the basmalah (P0-2) — the memorized "ayah 1" text is wrong for 112 surahs in the text pipeline.
- **Review/SRS**: works (SM-2 with clamps, overdue compensation, leech detection, weak→soft-lapse). FSRS fully implemented but deliberately off the write path pending product sign-off (documented at `memorization_plus_usecases.dart:95-101`).
- **Kids**: coherent — journey unlock gating, points/streak/XP/certificates awarded together, parent-PIN gate, audio loop ≤3. Weakest link: parent rewards cloud path (P1-6).
- **Parent/guardian**: linking works (hashed-token pairing, one-active-guardian constraint), dashboard works (aggregate RPC + legacy fallback). **Unlink/remove-child broken** (P0-1).

---

# 5. Critical Functional Findings (P0/P1)

### P0-1 — Guardian unlink / remove-child calls a nonexistent RPC — BROKEN
- **Category:** CURRENT_DEFECT · backend contract · **Severity:** P0 · **Status:** BROKEN
- **Location:** `lib/features/memorization_plus/data/repositories/collaborators/memorization_parent_access_service.dart:364-367` (callers `unlinkGuardian()` :166, `removeChild()` :374)
- **Evidence:** client calls `.rpc('revoke_guardian_link', …)`; `grep -r "revoke_guardian_link" supabase/` → **no match in any migration or SQL file**. No RLS policy/table grant allows client-side revocation either.
- **Impact:** every unlink/remove-child attempt throws `PGRST202`. A guardian can never remove a child; a child can never unlink a guardian. Feature exists in UI but cannot fulfill its purpose.
- **Root cause:** migration for this RPC was never written; `scripts/verify_supabase_contract.ps1` doesn't check it, so nothing failed.
- **Fix:** add `revoke_guardian_link(p_counterpart_user_id uuid)` SECURITY DEFINER RPC (verify active link either direction; set `status='revoked'`, `revoked_at=now()`; enforce the one-active-guardian partial index semantics), add it to the contract-verify script, ship a migration + apply to hosted DB.
- **Verification:** link a child → call unlink in UI → expect success and `parent_child_links.status='revoked'` row; re-link must work; contract script passes.

### P0-2 — Basmalah embedded in ayah 1 of 112 surahs (core-domain text inconsistency) — INCORRECT
- **Category:** CONTENT_PROBLEM / CURRENT_DEFECT · **Severity:** P0 (core purpose) · **Status:** INCORRECT
- **Location:** `assets/data/quran.json` (source: `scripts/fetch_quran.dart` from alquran.cloud/everyayah convention); consumers: `memorization_daily_plan_service.dart:107,153` (plan text), `quran_reader_page.dart:206-224` `_resolveAyah` (long-press sheet), search & ayah models; contrast: qcf package page render shows basmalah as unnumbered header (`basmallahBuilder`).
- **Evidence (verified programmatically this audit):** e.g. S2V1 = `بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ الٓمٓ` (basmalah + "الم"); same pattern for all surahs 2–114 except At-Tawba (correct: starts `براءة`). Al-Fatiha correctly counts basmalah as ayah 1 (7 ayahs).
- **Impact:** memorization plan cards, ayah detail sheet, and any text built from the local datasource present "ayah 1" with the basmalah glued on — mismatching both the mushaf image and the QCF text; STT comparison for ayah 1 in those surahs is also affected (reciter won't say basmalah as part of ayah 1 → mismatch penalty).
- **Root cause:** dataset convention (everyayah keeps audio alignment) imported without a stripping layer; only the BOM is stripped (`quran_local_datasource.dart:100`).
- **Fix:** strip the S1V1-equivalent prefix from ayah 1 of all surahs except 1 and 9 at parse time in `QuranLocalDatasource`, matching **both diacritic variants** (`بِسْمِ` standard form and the `بِّسْمِ` variant in surahs 95 & 97 — compare after normalizing harakat, and preserve the alef-wasla `ٱ`), or regenerate the asset with a header field; keep raw text for audio alignment if needed via a separate field. The basmalah must still be **rendered as an unnumbered header** (as the QCF mushaf page does), never deleted from display.
- **KB alignment (Rev 3):** the fix *restores* riwayah-correct verse boundaries rather than modifying them — KB `01_quran_foundations`: "Al-Fatiha has 7 ayahs (Basmalah counted as ayah 1 — this is specific to Al-Fatiha; elsewhere the Basmalah at the start of a surah is not numbered as a separate ayah)", and its Common Mistakes names this exact bug class ("Basmalah handling differs across data sources — common cause of off-by-one ayah bugs"). QUR-03 forbids mixing numbering conventions from different datasets — the current state (everyayah-convention text vs QCF-convention rendering) is precisely that violation. After the change, QUR-01 requires a character-for-character diff of rendered text against the vetted dataset before shipping.
- **Verification:** unit test: `getAyahsBySurah(2)[0].text` starts with `الم` not basmalah; S1V1 unchanged; S9V1 unchanged; golden of daily-plan card for a surah-2 plan.

### P0-3 — Sign-out can permanently destroy unpushed bookmarks — DATA LOSS
- **Category:** CURRENT_DEFECT · sync · **Severity:** P0 · **Status:** data-loss path
- **Location:** `lib/features/auth/application/cloud_sync_coordinator.dart:137-160` (`flushBeforeSignOut` checks `memorization.hasPendingCloudWork()` and `authRepository.hasPendingCloudPush()` but **not** `bookmarkService`); wipe: `lib/core/identity/account_data_reset.dart:48-84,224-237` (clears `quran_bookmarks*` + encrypted store).
- **Evidence:** bookmark push failure → `hasPendingCloudPush` (auth-side) can still be false → `AuthCubit.signOut` proceeds (blocked only on the two checked domains, `auth_cubit.dart:337-358`) → local bookmarks wiped → cloud never received them.
- **Impact:** user-created bookmarks made offline are irrecoverably lost if sign-out happens after a failed bookmark push.
- **Fix:** include `bookmarkService.hasPendingCloudWork` (and any other dirty domain — identity, certificates) in the flush gate; ideally derive the gate from a single `hasPendingSyncWork` covering all queue kinds + dirty flags.
- **Verification:** offline: create bookmark → come online but sabotage RPC → attempt sign-out → expect `AuthSignOutBlockedPendingData`; after forced sign-out + re-login, bookmark must reappear from queue-completed push or remain locally.

### P1-4 — Sync dead-letters: invisible, and pull kinds stall until re-login
- **Category:** CURRENT_DEFECT · sync · **Severity:** P1 · **Status:** partial stall + zero visibility
- **Location:** `lib/core/sync/cloud_sync_queue.dart` (`enqueue` refuses to reset dead rows; `hasPending()`/`dueItems()` exclude them; `recoverDeadLetter` used only by tests); `lib/features/auth/application/cloud_sync_coordinator.dart:119-133` (`resumeIfNeeded` skips when nothing non-dead is pending).
- **Evidence & precise scope (corrected in Rev 2):** cumulative backoff over 8 attempts is ≈2.1–2.6h (30+60+120+240+480+960+1920+3600s, +jitter ≤25%). **Push kinds are NOT permanently stalled**: `_performPendingPushes()` (2-s debounce after any local change) pushes dirty state directly, and `markSuccess()` deletes even a dead row on success — so pushes self-heal on the next mutation or full sync. **Pull kinds are**: pulls run only inside a full `run()` (login, or `resumeIfNeeded` — which returns early when all rows are dead, since `hasPending()` is false); `enqueue` won't touch a dead row. Result: once pull rows dead-letter and no new login occurs, **incremental cloud reconciliation stops** — changes made on another device never arrive — with no user-visible signal.
- **Impact:** silent cross-device staleness (pulls) + invisible failure state (all kinds). No data loss (dirty local data is retained).
- **Root cause:** recovery API exists but is unwired to any UI; lifecycle sync deliberately never re-arms dead letters (documented intent) without providing the "explicit recovery action" it references.
- **Fix:** surface dead-letter state (settings banner / sync status screen) with a manual "retry now" wired to `recoverDeadLetter(kind)` + `run()`; optionally re-arm pull kinds on app-resume `force`. Classify retryable vs non-retryable errors before burning attempts (see SY-5).
- **Verification:** simulate 8 pull failures → banner appears → recover → pull succeeds; make a change on device B → device A (dead-lettered, recovered) receives it.

### P1-5 — Demonstrated live-DB drift; verification script has blind spots
- **Location:** `supabase/apply_bookmark_functions.sql` (manual hotfix documenting `PGRST202: pull_quran_bookmarks not found` on the remote DB); remediation migration header admits identity RPC "referenced by the client but never deployed"; `scripts/verify_supabase_contract.ps1` covers 14 tables/9 RPCs but **not** `revoke_guardian_link`, `xp_history`, `child_link_requests`.
- **Impact:** repo migrations and hosted schema can diverge silently — this already happened once and produced P0-1's class of failure.
- **Fix:** single source of truth: run contract script in CI against the hosted DB (the linked-security workflow exists but is secret-gated); add every client-referenced RPC/table to the script (generate the list from `grep ".rpc('/.from('" lib/`).

### P1-6 — Parent rewards bypass the outbox; pull overwrites local wholesale
- **Location:** `memorization_kids_cloud_sync_service.dart:273-423` (direct RPC create/unlock/claim; no dirty flag/queue kind); `:91-99` `saveParentRewards` overwrites local rewards with remote list.
- **Impact:** offline/signed-out reward actions live only in the local variant and never reach the cloud; a mid-request failure on the online path desyncs local vs remote, and the next pull clobbers local state.
- **Fix:** route through queue kind (e.g. `parentRewalsPush`) + revision/ack like bookmarks, or make pull merge by id+status transitions.

### P1-7 — English users receive Arabic content in several core surfaces (rescoped in Rev 2)
- **Category:** UX_PROBLEM / INCOMPLETE_IMPLEMENTATION · **Severity:** P1 · **Status:** partial
- **Already localized (excluded from this finding):** achievement titles/descriptions are mapped to arb via `localizedAchievementTitle/Description` (`lib/core/l10n/localization_helpers.dart:60+`; all 24 built-in IDs covered; the Arabic `titleKey` in `progress_repository_impl.dart:159-291` is a fallback for unknown IDs only); the privacy policy has a full English version (`privacy_policy_content.dart:88 getEnglishContent()`); surah and juz display names localized (`localization_helpers.dart:16-30`).
- **Still Arabic-only in EN (evidence):** notification bodies/titles (`notification_service.dart:50-66` — `NotificationScheduler` builds them without a BuildContext, so they cannot use arb as-is); certificate celebration + juz-ordinal strings (`certificate_widget.dart:13-17,189-199`); share-card copy deck (`social_share_copy.dart`, 135-line parallel i18n); tutorial guide labels (`tutorial_guide_quick_start_card.dart:14-38`, `tutorial_guide_section_card.dart:169-203`); splash retry button (`splash_page.dart:189`); appearance-tile language names; data-layer Arabic failure messages surfaced to UI (`memorization_kids_cloud_sync_service.dart:163,280,388…`; `auth_repository_impl.dart:412`).
- **Impact:** with EN locale selected, notifications, certificate celebration/share, tutorial, and several error toasts render in Arabic.
- **Root cause:** notification copy is produced in a service layer with no context; share/tutorial copy grew outside the arb pipeline; error messages carry display text instead of codes (CQ-2).
- **Fix:** pass resolved localized strings (or a locale) into `NotificationScheduler`; move share/tutorial/certificate copy into arb keys; switch data-layer failures to codes mapped in presentation.
- **Verification:** EN-locale screenshot sweep of notification tray, certificate celebration, share sheet, tutorial, error toasts — zero Arabic strings; architecture test bans new raw Arabic literals in presentation.

### P1-9 — Privacy policy claims on-device voice processing; STT never requests `onDevice` (added in Rev 2)
- **Category:** DOCUMENTATION_DRIFT / privacy · **Severity:** P1 · **Status:** policy-vs-code mismatch (does not prove cloud upload, but makes the claim unverifiable)
- **Location:** `memorization_session_cubit.dart:415-429` and `kids_mode_cubit.dart:595-612` — `SpeechListenOptions(localeId: kArabicSpeechLocaleId, pauseFor/listenFor: …)` with **no `onDevice` flag**; plugin default (`speech_to_text` 7.4.0) is `onDevice: false`, i.e. recognition may be routed through the OS speech service (on Android typically Google's recognizer). Policy text: `privacy_policy_content.dart:38` — "تتم معالجة الصوت فورياً داخل جهازك ولا يتم تسجيله أو نقله… إطلاقاً".
- **Impact:** the strongest privacy statement in the policy (voice never leaves the device) is not enforced by the implementation; on some devices/ROMs audio may be processed by a third-party recognizer.
- **Root cause:** `onDevice` support is conditional (not all engines offer on-device recognition), and the default was left unchanged.
- **Fix (either, decided explicitly):** (a) set `onDevice: true` with availability check (`speechToText.onDeviceRecognitionAvailable`) plus a fallback path and updated policy wording for the fallback; or (b) rewrite the policy to accurately describe OS-mediated recognition. Pair with UX-11 (manual grading) so the flow degrades gracefully.
- **Verification:** on a device with on-device recognition: enable airplane mode → STT still recognizes Arabic; on a device without: fallback path works and policy wording matches behavior.

### P1-8 — `prune_audit_logs()` executable by any authenticated user
- **Location:** `supabase/migrations/0006_fsrs_and_audit_fixes.sql:218-219` (grant EXECUTE to `authenticated`; SECURITY DEFINER; deletes **all users'** `xp_history` >90d and `kids_session_logs` >180d; not called by the app).
- **Impact:** any signed-in user can truncate global audit data. Unnecessary attack surface.
- **Fix:** revoke EXECUTE from `authenticated` (ops-only, like the earlier `prune_kids_session_logs` in 0004).

---

# 6. Code Quality Findings

**Strengths (verified):** zero TODO/FIXME/HACK; zero `print()` (proper `TaliaLogger`); zero no-op buttons; zero `UnimplementedError` in lib; complete stream-subscription cleanup in all 6 listening cubits; `use_build_context_synchronously` active with 57 mounted guards; XP values centralized; credentials via dart-define only.

| ID | Severity | Finding | Location | Evidence |
|----|----------|---------|----------|----------|
| CQ-1 | P2 | ~198 catch blocks, ~70 `catch (_)`; 5 fully-empty; ~40 repo methods collapse all exceptions to `CacheFailure(e.toString())` (leaks English exception text into user-visible failures, loses stack) | worst: `memorization_production_sync_service.dart:165,241,290,570,621,674`; `bookmark_service.dart:55,189,211`; `heatmap_repository_impl.dart:49` | silent degraded returns in sync-critical paths |
| CQ-2 | P2 | Fragile error contract via Arabic-substring matching between data and presentation | `login_page.dart:535-544` `message.contains('فشل إنشاء الحساب')` vs `auth_repository_impl.dart` message strings | renaming a message silently breaks error UX |
| CQ-3 | P2 | Magic event-key strings for XP (`'v2_block_completed'`) — typo = silently 0 XP | `session_adapters.dart:305`, `kids_mode_cubit.dart:439` vs `xp_constants.dart:23-26` | no compile-time link |
| CQ-4 | P2 | SRS interval ladders duplicated with **divergent values**: `[1,3,7,14,30,90]` vs `[1,3,7,14,30,60,120]` | `app_constants.dart:8` vs `hifz_migration_service.dart:278` | same concept, two truths |
| CQ-5 | P3 | Table/RPC names as raw strings scattered across 12 files (3 names triplicated); everyayah base URL duplicated 7× | `quran_reciter.dart:6-36`, `app_constants.dart:17` | no constants file |
| CQ-6 | P3 | Dead code: `AppTextField`, `CelebrationOverlay`, `AyahListenButton` (full audio widget), `GetSurahDetailUsecase` (unwired — callers hit repository directly); vestigial `third_party/mobile_scanner`; empty `tools/` | grep-verified unreferenced | safe deletions |
| CQ-7 | P3 | Force-unwraps concentrated: `memorization_session_cubit.dart` 21×, `quran_reader_page.dart` 14×, `auth_repository_impl.dart` 11×; 273 `as`-casts in data/core (mostly idiomatic fromJson) | per-file counts | crash surface on malformed cloud rows |
| CQ-8 | P2 | `'النص غير متوفر'` sentinel compared by `==` across cubit/page/service boundaries | `kids_mode_cubit.dart:118,128` | sentinel-string anti-pattern |
| CQ-9 | P3 | Fix-tracker comments used instead of issue tracking (`BUG-NEW-001 FIX`, `RISK-5 FIX`, `ARCH-001 FIX`, `IS-5`, `BUG-5`) | e.g. `quran_page_cubit.dart:73`, `kids_mode_cubit.dart:342` | organizational, not runtime |
| CQ-10 | P3 | Stale repo-root artifacts: `analyze_out.txt`, `test_output.txt`, `test_run_out.txt` (Aug 1, old machine path, reference deleted test file) | repo root | delete |

---

# 7. Architecture Findings

| ID | Severity | Finding | Evidence |
|----|----------|---------|----------|
| AR-1 | P2 | SharedPreferences reachable everywhere via `getIt` — 12 presentation files + 6 application-layer cubits use it directly, bypassing repositories | `quran_reader_page.dart:133`, `login_page.dart:119-120`, `home_page_widgets.dart:1028-1329`, `settings_memorization_tiles.dart:297-316`, `azkar_cubit.dart:22-104` |
| AR-2 | P2 | Pages/widgets call repositories & services via `getIt` directly, skipping cubit/usecase boundary | `home_page_widgets.dart:307,927,1296`; `login_page.dart:104`; `custom_plan_setup_page.dart:193`; `memorization_hub_page.dart:43,61,85`; `azkar_page.dart:30` |
| AR-3 | P2 | God units: `MemorizationPlusRepositoryImpl` (implements 3 interfaces, wires 11 collaborator services + raw prefs), `KidsModeCubit` (11 ctor deps), `HomeCubit` (13), `AuthRepositoryImpl` (896 lines), `MemorizationSessionCubit` (10 deps) | `memorization_plus_repository_impl.dart:34-115`; `injection.dart:482-496` |
| AR-4 | P2 | Giant widget files embed persistence/audio/scheduling logic: `home_page_widgets.dart` 1780 lines/38 classes, `custom_plan_setup_page.dart` 1765, `settings_notification_tiles.dart` 776 (schedules notifications + writes prefs inside widget), `_AyahOptionsSheetState` owns an `AudioPlayer` | `quran_reader_page.dart:704-748` |
| AR-5 | P3 | Legacy hifz data layer permanently registered after migration (only `HifzMigrationService` needs read access) | `injection.dart:283` |
| AR-6 | P3 | Reading progress/bookmarks/azkar counters in SharedPreferences while the architecture calls Isar the source of truth; `core/persistence/` empty placeholder | `injection.dart:211-213` |
| AR-7 | P3 | Router file contains business logic (async guards calling repositories) | `app_router.dart:138-293` |
| AR-8 | P3 | `getIt.reset()` at runtime + eager `AuthCubit` singleton fragile across re-init | `app_initializer.dart:62-64` |

---

# 8. Backend & Database Findings

**Overall:** 12 migrations in coherent order; RLS on all 16 final tables; anon revoked; SECURITY DEFINER RPCs with `search_path=public`; parent↔child authorization enforced server-side (link checks in RPCs **and** parent-read policies). Contract matching was verified call-by-call: **all signatures match except P0-1** (`revoke_guardian_link`). Client defense-in-depth (explicit `eq user_id` even under RLS) is present.

| ID | Severity | Finding | Evidence |
|----|----------|---------|----------|
| BD-1 | P0 | `revoke_guardian_link` missing (see P0-1) | `memorization_parent_access_service.dart:365` |
| BD-2 | P1 | Live-DB drift pattern (see P1-5) | `apply_bookmark_functions.sql`; remediation header |
| BD-3 | P2 | Residual direct-DML grants on `streaks`, `xp`, `daily_activities`, `xp_history` let a user bypass monotonic RPC guards (own-row only) | migration 0001:96 (remediation revoked these for plans/rewards/bookmarks but not these) |
| BD-4 | P1 | `prune_audit_logs()` granted to `authenticated` (see P1-8) | 0006:218-219 |
| BD-5 | P2 | `pull_ayah_review_records_since` 2-arg stale overload still granted/exposed alongside 3-arg composite-cursor version | 0004 vs 0009 |
| BD-6 | P3 | Orphans: `update_updated_at()` trigger fn never attached; `xp_history` table written by nobody; `child_link_requests` client-untouched (by design) | migration scan |
| BD-7 | P3 | `config.toml` enables `db.seed` → `./seed.sql` which does not exist (local `supabase db reset` fails) | `supabase/config.toml` |
| BD-8 | P2 | Client reads `revision` columns that exist only in the remediation migration with **no coded fallback** (unlike RPC fallbacks elsewhere) — pull breaks against a pre-remediation DB | `memorization_production_sync_service.dart:220,259` |
| BD-9 | P3 | Link-token entropy: 12-hex-char (48-bit) token accepted as SHA-256 hash within 10-min window — impractical to brute force via PostgREST, below the 64-char hash's implied strength | `memorization_parent_access_service.dart:295-300` |
| BD-10 | P3 | `get_remote_children_dashboard` legacy fallback per-table reads retained (cost audit addressed via aggregate shape; fallback keeps old cost profile when RPC missing) | `memorization_kids_cloud_sync_service.dart:181-271` |

---

# 9. Offline & Synchronization Findings

**Architecture summary (verified):** durable Isar queue keyed by (kind, ownerUserId) — a *kind-level retry marker*, not a per-mutation outbox; payloads live in feature dirty-state. Max 8 attempts, 30s→1h exponential backoff + jitter. Sync triggers: login/cold-start (auth stream), app-resume (5-min debounce), any `ProgressEventsBus` event (2-s debounce push), every enqueue (foreground + Workmanager one-off with network constraint). Pull-before-push ordering on full sync. Conflict handling: review records whole-record LWW by `lastReviewedAt` + server CAS on `sync_version`; plans true CAS with surfaced conflicts (`keepLocal`/`acceptCloud`); bookmarks per-row revision CAS; streaks/XP/activities GREATEST/union merges. Guest data: review records claimable via explicit dialog (only if account fresh); bookmarks auto-claim legacy blob; gamification merges implicitly via max/union. Account switch wipes all owned data incl. queue (no orphans).

**Mutation Coverage Matrix:**

| Mutation | Local-first | Queue kind | Cloud path | Offline verdict |
|----------|------------|-----------|------------|-----------------|
| Review records | ✅ Isar `cloudDirty` | productionPush | `upsert_ayah_review_records_v2` (500-chunk, CAS) | ROBUST |
| Daily plan | ✅ dirty flag | productionPush | `compare_and_swap_daily_plan` | ROBUST (conflict surfaced) |
| Custom plan | ✅ dirty flag | productionPush | `compare_and_swap_custom_plan` | ROBUST |
| Kids progress | ✅ | kidsProgressPush | `upsert_kids_progress_cloud` | ROBUST (GREATEST merge) |
| Kids session logs | ✅ dedup per ayah | kidsProgressPush | batch RPC w/ ack | ROBUST |
| Streak / XP / daily activities | ✅ | authPush | `upsert_*` batch | ROBUST (monotonic) |
| Reading progress | ✅ | authPush | `upsert_reading_progress` (union) | ROBUST |
| Quran bookmarks | ✅ revision/tombstones | bookmarkPush | `upsert_quran_bookmark` CAS | GOOD — **but sign-out gate gap (P0-3)** |
| Certificates | ✅ | certificatePush | upsert `ignoreDuplicates` | ROBUST |
| **Parent rewards** | ❌ split-brain | **none** | direct RPCs | **WEAK (P1-6)** |
| **Memorization identity** | ✅ dirty flag | **none** (piggybacks full push) | `upsert_memorization_identity` | WEAK (P2-12) |
| Azkar counters / settings / V2 sessions / hifz legacy | ✅ | none | none | LOCAL-ONLY (by design; wiped on logout) |

**Findings:**

| ID | Severity | Finding | Evidence |
|----|----------|---------|----------|
| SY-1 | P0 | Sign-out flush gate omits bookmarks → wipe loses unpushed bookmarks | `cloud_sync_coordinator.dart:137-160` + `account_data_reset.dart:224-237` (P0-3) |
| SY-2 | P1 | Dead-letter invisibility; **pull kinds stall until re-login, pushes self-heal** (P1-4, Rev 2 scope) | `cloud_sync_queue.dart` + `cloud_sync_coordinator.dart:119-133` |
| SY-3 | P1 | Rewards outbox bypass + wholesale overwrite on pull (P1-6) | `memorization_kids_cloud_sync_service.dart:91-99,273-423` |
| SY-4 | P2 | Identity push not queue-backed: if identity is the only dirty item, nothing schedules a sync; failure only logged | `cloud_sync_coordinator.dart:336-342,383-390` |
| SY-5 | P2 | `markFailure` doesn't classify errors — non-retryable 4xx burns 8 attempts (≈2.1–2.6h) then dead-letters | `cloud_sync_queue.dart:160-177` |
| SY-6 | P2 | Unknown queue kinds "succeed" silently: `default: return true` deletes the row without doing work | `cloud_sync_coordinator.dart:458-459` |
| SY-7 | P2 | No connectivity awareness (`connectivity_plus` absent) — retry cadence purely time-based; captive-portal "connected" networks burn attempts | pubspec + `auth_repository_impl.dart:865-868` substring detection |
| SY-8 | P3 | Bookmark pull: `local.isSynced` unconditionally accepts remote — a stale remote read could theoretically downgrade a higher local revision; server-side CAS prevents revision regression in the normal path, so this is a defense-in-depth hardening item, not an active defect (downgraded in Rev 2) | `bookmark_service.dart:144-150` |
| SY-9 | P2 | Silent catches in sync paths drop conflict rows / cursor staleness / plan state without surfacing | `memorization_production_sync_service.dart:165,241,290,570,621,674` |
| SY-10 | P3 | Guest claim is one-shot & only for fresh accounts — second-login or populated accounts silently strand guest review records | `memorization_review_records_storage.dart:285-346` (documented behavior; UX decision needed) |
| SY-11 | P3 | Corrupt local bookmark JSON reads as "no bookmarks" and can then be overwritten by pull | `bookmark_service.dart:55,189,211` |
| SY-12 | P3 | Account deletion retains queue rows under a dead owner (never executable, by-design comment) | `account_data_reset.dart:114-167` |

---

# 10. UI / UX Findings

Audited at code level (no interactive device session — see §2). Empty/loading/error states are consistently modeled in cubit states; onboarding/splash error-recovery tested.

| ID | Screen / Journey | Problem | User Impact | Severity |
|----|------------------|---------|-------------|----------|
| UX-1 | Notifications, certificate celebration/share, tutorial, some errors (EN locale) | Arabic-only content in these surfaces (P1-7 rescoped — achievements & privacy policy ARE localized) | EN users see mixed-language product | P1 |
| UX-2 | Long-press ayah sheet vs rendered page (surahs ≠1/9, ayah 1) | Basmalah-prefixed text vs header-rendered page (P0-2) | Visible contradiction in the core reading surface | P0 |
| UX-3 | Settings → sign out (offline edge) | Bookmark-loss path (P0-3); blocked-sign-out messaging exists for other domains only | Silent data loss | P0 |
| UX-4 | Guardian management | Unlink/remove-child always errors (P0-1) | Feature-present-but-broken; likely surfaced as generic error toast | P0 |
| UX-5 | Any synced feature after persistent sync failure | No sync-status surface anywhere; dead-letters invisible (P1-4) | User believes data is safe / cross-device changes stop arriving | P1 |
| UX-6 | Notifications | Egyptian-dialect copy (`'عندك 5 آيات مستنية مراجعتك النهاردة..'`) vs MSA register elsewhere | Tone inconsistency | P3 |
| UX-7 | Reader hizb/page labels | Hizb = page-midpoint approximation → label can be wrong near boundaries (CO-2) | Minor factual inaccuracy on a religious-precision surface | P2 |
| UX-8 | Login errors | Arabic-substring remapping (CQ-2) → untranslated/unmappable failures shown raw | Error UX fragility | P2 |
| UX-9 | Certificate export | "PDF" is a PNG wrapped in PDF — text not selectable/scalable | Quality polish | P3 |
| UX-10 | Kids daily-plan card (surahs ≠1/9) | Plan ayah-1 text includes basmalah (P0-2 symptom) | Confusing memorization target | P0 |
| UX-11 | Memorization session when STT unavailable/denied (added Rev 2) | No manual/self-grade fallback: `V2SpeechIssue` states only render messages (retry / open-settings / unavailable); grep finds no manualGrade/selfGrade path, and recitation phases gate progression on STT evaluation | Journey blocked on devices/ROMs without Arabic speech recognition; contradicts nothing in the docs because none promised a fallback — an INCOMPLETE_IMPLEMENTATION of graceful degradation | P2 |
| UX-12 | Azkar page daily tip (added Rev 3) | Tip rotates through hand-typed Quran verses + unsourced hadith (CO-8); no source/grade shown, no link to the vetted dataset | User receives religious content with no traceability — the KB's core trust requirement (`validation_rules.md` §1 Transparency) is broken on this surface | P1 |

**Functional-UI sweep:** zero dead buttons, zero no-op tabs found (grep-verified `onPressed: () {}` = 0). All routes in the 5-branch shell resolve; `/hifz` intentionally redirects to the hub with a retirement test guarding it.

---

# 11. Performance Findings

No frame-level profiling was performed (no device session). Evidence-based findings only:

| ID | Location | Bottleneck | Trigger | Impact | Fix |
|----|----------|-----------|---------|--------|-----|
| PF-1 | `auth_repository_impl.dart:554-725` | Full pull of streaks/XP/activities/read-pages on **every** login + resume-with-pending (no cursor) | Each login/resume | Extra round-trips; fine at current scale, grows with activity table | Cursor or `updated_at` filter later |
| PF-2 | `bookmark_service.dart` pull | Full bookmark pull (no cursor) | Every full sync | Same as above at smaller scale | Acceptable now; note for scale |
| PF-3 | `home_page_widgets.dart` (1780 ln) / `custom_plan_setup_page.dart` (1765 ln) | Monolithic build trees; setState granularity coarse (16 setStates in one page) | Home/custom-plan interaction | Rebuild churn risk (unquantified — needs profiling) | Split widgets; profile with DevTools |
| PF-4 | `memorization_kids_cloud_sync_service.dart:181-271` | Legacy dashboard fallback issues per-table queries per child when RPC missing (PGRST202 path) | Remote-drift scenario | N-per-child queries | Keep RPC present (ties to BD-2) |
| PF-5 | `quran.json` 1.79MB | Parsed on isolate (`compute`) once with per-surah/per-page indexes — **already correct**; warmup service pre-loads fonts post-launch | First Quran open | Already mitigated | None |
| PF-6 | Audio | Cached (flutter_cache_manager, 30d/500 files), prefetched; `everyayah.com` is the single host — availability depends on one CDN, and 7 duplicated base URLs | Recitation playback | Latency on first play; host SPOF | Keep; consider secondary host constant |

**Explicitly not claimed:** no evidence of unnecessary rebuild storms, image-memory problems, or expensive sync work on the UI isolate was found in code review; confirming requires a profiling session.

---

# 12. Localization Findings

- **Arb parity is perfect:** **1,142** message keys in both `app_ar.arb` and `app_en.arb`, key sets identical (verified by set-diff; count corrected in Rev 2 — the original 1,146 figure over-counted); Arabic is template/default locale; RTL correct via MaterialApp; privacy policy is fully bilingual (`getEnglishContent()`); `untranslated.json` is stale (lists `homeActionQuran`, which now exists in EN) — safe to clear.
- **L1 (P1, rescoped):** ~300 hardcoded Arabic literals bypass arb in the surfaces listed in P1-7 (notifications, certificate celebration/share, tutorial, splash, language tiles, data-layer error messages). **Not** a finding: achievement titles/descriptions (localized via `localization_helpers.dart`) and the privacy policy (bilingual).
- **L2 (P2):** Three parallel i18n mechanisms coexist: gen-l10n, `isArabic ? '…' : '…'` ternaries (78 occurrences), and `SocialShareCopy` (a 135-line self-rolled copy deck). Invisible to l10n tooling.
- **L3 (P3):** EN pluralization handled for exactly 1 key (`bookmarksCountItem`); count labels elsewhere are static ("5 ayahs" vs "1 ayahs" risk in EN).
- **L4 (P3):** Numeral policy inconsistent: Latin digits in most Arabic UI vs hardcoded `١٠ صفحات`-style strings; `toArabicNumber` exists but used only twice (hizb/page labels).
- **L5 (P3):** No Hijri calendar anywhere (Gregorian only; AM/PM hand-swapped to ص/م). Product decision, not a defect — flagged as a gap for an Arabic-first Islamic app.
- **L6 (P3):** App title hardcoded (`'تالية'` in `app.dart` twice, no `onGenerateTitle`).

---

# 13. Islamic / Quran Content Findings

**Integrity — all verified programmatically this audit:**
- Surahs = **114** ✓ · total ayahs = **6,236** ✓ per the **Hafs/Kufi counting convention** (KB `01_quran_foundations` warns this figure is riwayah-dependent — the app is Hafs-only, so it is correct here, but any future second riwayah needs its own count) · (sum of metadata = records in `quran.json`, global numbering contiguous 1→6236) · per-chapter numbering contiguous 1..N for all 114, zero mismatches vs metadata ✓ · pages cover **1–604, none missing** ✓ · juz = {1..30}, `juzStartPages` table matches per-ayah data at every boundary ✓ · surah start pages vs first-ayah pages: 0 mismatches ✓ · spot checks pass (Fatiha 7/p1, Baqarah 286/p2, Nisa 176/p77, Kawthar 3/p602, Nas 6/p604, Kahf 293, Tawba starts p187 — all canonical Madani values). Source dataset (`scripts/fetch_quran.dart` ← alquran.cloud) is listed in KB `18_references.md` as a **primary-tier** Quran text candidate ✓.

| ID | Finding | Confidence | Severity |
|----|---------|-----------|----------|
| CO-1 | **Basmalah concatenated into ayah 1 of all surahs except 1 & 9** in `quran.json` (P0-2). Rev 2 note: surahs **95 (التين) and 97 (القدر)** use a diacritic variant — `بِّسْمِ` (shadda+kasra under the ب) instead of `بِسْمِ` — so the stripper must match both variants (normalized-letter comparison), or exactly those two surahs will be missed | High (verified incl. variants) | P0 |
| CO-2 | **Hizb boundaries are page-midpoint approximations** (`mushaf_hizb_helper.dart:59-68`) while exact 240-entry rubʿ-el-hizb data ships **unused** inside qcf_quran_plus (`quarters.dart`). **KB violation (Rev 3):** `01_quran_foundations` Practical Rules forbid computing juz/hizb/page "on the fly from unreliable heuristics" — hizb (60) and rubʿ (240) must be *sourced required fields*; the qcf quarters count (240) matches the KB's canonical figure | High | P2 |
| CO-3 | **No sajdah metadata** — sajdah verses are unmarked anywhere (lib + assets). **KB framing (Rev 3):** the count is **14 agreed + 1 disputed** (Al-Ḥajj 22:77 vs Ṣād 38:24; Ḥanafī count 14, Shāfiʿī/Ḥanbalī often 15) — per `01_quran_foundations`, Talia must tag sajdah verses *with the counting tradition* rather than assert a single 14/15, and the data must come from a vetted Mushaf dataset, not be hand-entered | High (absence verified) | P2 (MISSING feature; implement per KB convention) |
| CO-4 | Azkar dataset (`azkar.json`, 85 entries): every entry has a `reference`, but **book-name only** — `12/22` dua references carry no hadith number at all, and **no entry has an `authenticityGrade` field** (grep: grade/tier fields absent; `صحيح` appears 41× as part of book names only). **KB violations (Rev 3):** HAD-01 ("authenticity grade is mandatory", *Critical/Blocking*), HAD-02 (citation must be `Collection, Number` — resolvable), and the `08_adhkar.md` Required Metadata Schema (which the file otherwise matches: id/text/transliteration/translation/count/reference). UI does display the reference (`azkar_category_page.dart:196,283,575`) — so fixing the data fixes the surface | High | **P2 (upgraded from P3 per KB)** |
| CO-5 | Datasource fallback heuristics are incorrect if ever triggered (missing `juz` → surah-start juz; missing `page` → `surah.page + i/15`) — dormant with current data; also contradicts KB `01` Engineering Implications (structural fields must be sourced, never derived) | High | P3 |
| CO-6 | Tajweed rendering present via qcf `isTajweed` (color-coded); no app-side tajweed instruction content (no claim made — not a defect). KB `04_tajweed`/`18_references` would require a tajweed-tagged Mushaf dataset if instruction content is ever added | — | — |
| CO-7 | Audio: 6 reciters, all from `everyayah.com` (Uthmani-aligned per-ayah files, consistent with the text dataset) | High | info |
| CO-8 | **Hand-typed Quran verses and unsourced hadith hardcoded in UI code (Rev 3, KB-critical).** `azkar_page.dart:367-426` `_DailyTipState._tips`: 9 items of verbatim/paraphrased hadith with **no source and no grade** (e.g., "من قرأ آية الكرسي دبر كل صلاة…", "أقرب ما يكون العبد من ربه وهو ساجد") + **9 Quran verses typed by hand inside ﴿…﴾** (lines 380-388: البقرة 186, 152, الطلاق 2-3, 286, الشرح 6, البقرة 45, آل عمران 8, 35, 4, الضحى 5). **KB violations:** HAL-01/QUR-01 (Quran text must come from the vetted Mushaf dataset — hand-typed verses are unverifiable and can silently differ from the dataset), HAD-01/HAD-03 (hadith shown without grade/source), and KB `14_content_validation.md` Engineering Implications explicitly prescribes a CI lint against *exactly* this pattern ("religious-content string literals added directly in UI code") | High (Critical per KB risk table) | **P1** |
| CO-9 | Duas category (22 items inside `azkar.json`) has **no `tier` field** — KB `09_dua.md` requires every dua record to be tiered `quranic / prophetic / guidance` (non-nullable, drives display + sourcing rules); currently Quranic duas, prophetic duas, and guidance content are indistinguishable in the model | Medium | P3 |

No invented corrections: basmalah handling for surahs 1/9 is **correct** in the data; all other content checks passed canonical values.

---

# 14. Testing & Verification Gaps

**Inventory:** 139 test files — ~114 unit, 25 widget, 4 real-Isar integration (temp-dir IsarCore), 1 golden suite. Suite passes: **+916, 0 failed**. No credentials in tests; `.env`-not-bundled even asserted. Real-Isar pattern is clean (unique DB names, `deleteFromDisk`).

| # | Flow | Verdict |
|---|-------|---------|
| 1 | Sync queue retry/backoff/dead-letter/owner-scoping | **COVERED (strong)** |
| 2 | Guest→login review-record claim | **COVERED (strong, real Isar)** |
| 3 | SM-2 due calc & rescheduling (boundaries, clamps, lapses) | **COVERED (strong)** |
| 4 | Streak service | **GAP — mirror test**: `streak_service_test.dart:21-39` re-implements the algorithm and tests the copy; real `StreakService` never instantiated |
| 5 | XP service | **GAP — mirror test** (`xp_service_test.dart:11-29` tests constants + local re-implementation) |
| 6 | Quran asset integrity (114/6236/pages) | **GAP — no test**; `scripts/test_surahs.dart` only prints the count. Rev 3/KB: per QUR-01 the check must go beyond counts — a **character-for-character hash of the bundled dataset against the pinned upstream version** (alquran.cloud edition, version-pinned per KB `18_references.md` Engineering Implications), with the 6,236 assert qualified as Hafs/Kufi |
| 7 | Auth flows incl. sign-out-blocked-pending-data | **COVERED (good; mocked repo + real-Isar offline reset)** |
| 8 | Onboarding completion & routing | **COVERED (strong, updated for the rework + goldens)** |
| 9 | Progress stats correctness | **COVERED (good)** |
| 10 | Certificate thresholds/idempotency/cloud push | **COVERED (strong)** |
| 11 | Bookmark cloud CAS (`pushToCloud`/`pullFromCloud`) | **GAP — zero Dart-side test references** (DB-side verified by PowerShell script only) |
| 12 | Production sync push/pull round-trip | **PARTIAL** — gating & merge rules covered; live round-trip stops at the Supabase boundary |

Additional quality findings: one tautological mock test (`auth_repository_sync_test.dart` mocks the call then asserts the mock); two source-scanning "verification" tests (structural, brittle-by-intent); ~150-line `_FakeMemPlusDatasource` copy-pasted across ≥3 files and already diverging; two mild race patterns (`Future.delayed(10ms)` ordering, `Duration.zero` flush); stale Aug-1 output artifacts at root reference a deleted test file; **no test for STT-unavailable degradation** (manual-grade fallback doesn't exist to test — see UX-11/P1-9).

---

# 15. Technical Debt Register

| ID | Area | Debt | Why it exists | Risk | Action |
|----|------|------|---------------|------|--------|
| TD-1 | hifz legacy | Full legacy data layer registered permanently post-migration | Migration service needs read access | Harmless now; schema/registration creep | Gate registration behind migration-needed check, then remove |
| TD-2 | i18n | 3 localization mechanisms; ~385 hardcoded strings | Feature velocity | Accumulating (every new screen adds more) | Consolidate into arb; add lint/architecture test banning raw Arabic literals in presentation |
| TD-3 | presentation | prefs + `getIt` shortcuts; 1,700+-line widget files | Same | Accumulating | Extract view-model services; split files |
| TD-4 | cubits | 10–13 constructor dependencies | Organic growth ("RISK-5 FIX" bolt-ons) | Rising | Decompose collaborators |
| TD-5 | backend | Stale 2-arg RPC overload; orphan trigger fn; dead `xp_history` | Migration iteration | Harmless | Drop in next migration |
| TD-6 | tooling | No Flutter CI (analyze/test); contract script blind spots | Only Supabase workflow exists | Dangerous (regressions ship silently) | Add workflow (see roadmap) |
| TD-7 | tests | Mirror tests for streak/XP; duplicated fake boilerplate | Speed | Dangerous (false confidence in two gamification pillars) | Rewrite against real services; extract shared fakes |
| TD-8 | docs | Checklist/README drift (§16) | Docs age | Mild | Refresh pass |
| TD-9 | content | hizb approximation vs unused exact data; missing sajdah metadata | Helper written before quarters data discovered | Mild | Switch helper to qcf quarters; add sajdah flags |
| TD-10 | repo hygiene | Stale root artifacts; `fix_production_restore.md` status stale; `untranslated.json` stale; empty `tools/`; vestigial `third_party/mobile_scanner` | Housekeeping | None | Delete/refresh |

---

# 16. Documentation Drift

| Doc claim | Reality |
|-----------|---------|
| README: SRS intervals "1, 3, 7, 14, 30, 90 days" | Code is SM-2 ease-factor with caps 180/90 + soft-lapse — the fixed ladder is legacy (`memorization_plus_usecases.dart:61-70`) |
| README: build_runner generates "GetIt locators" | DI is manual; build_runner only for Isar/Mockito |
| Technical Guide: prescribed features `memorization_engine/ adult_journey/ kids_journey/ parent_dashboard/` | None exist; actual layout is `memorization_plus` + core-heavy domain |
| `docs/backend/supabase_runtime_readiness_checklist.md` | References dropped tables (`ayah_progress`, `bookmarks`, `certificates`), dropped RPC `upsert_ayah_progress`, and a `supabase_schema.sql` that doesn't exist; predates migrations 0006–0011 |
| ArchitectureSpec: feature flag `enable_memorization_v2` | Flag doesn't exist (actual: `unifiedJourneyEnabled`, cloud-sync flags) |
| PRODUCT.md: "Portrait-only native mobile (Android/iOS)" | linux/macos/web/windows platform folders all present in repo |
| README feature directory list | Omits azkar, home, onboarding, settings, splash, streak, certificate, xp — all exist |
| `fix_production_restore.md` | Working-notes plan whose migrations (0011 + remediation) largely landed; item statuses stale; should move to docs/ or close |
| **Accurate (verified):** STT threshold 0.92 (`recitation_evaluator.dart:17`), SessionEngine location, Cubit-only state mgmt, offline-first claims, stack list, `delete_current_user` deep-link contract | — |

---

# 17. Cross-Feature Consistency

| Concept | Inconsistency | Shared root cause |
|---------|---------------|-------------------|
| Ayah-1 text | memorization/daily-plan/long-press use basmalah-prefixed text; qcf page render doesn't | Single dataset convention + no normalization layer (P0-2) |
| SRS intervals | Two divergent ladders (CQ-4); README states a third | No single scheduling-rules module |
| Localization | 3 mechanisms produce mixed AR/EN surfaces (P1-7, L2) | No enforcement of arb-only in presentation |
| Error surfaces | Data-layer Arabic messages + presentation substring matching (CQ-2) + `e.toString()` leaks (CQ-1) | No typed error-code contract between layers |
| Sync gating | Sign-out gate covers 2 of 4+ dirty domains (P0-3); identity unqueued (SY-4) | No single `hasPendingSyncWork` aggregation |
| Date handling | Consistent UTC day-keys in streak/sync (good); no shared date service; Hijri absent | Minor |
| User/owner IDs | Consistent `RecordOwnerProvider` scoping across all local rows (good) | — |
| Numerals | Mixed Latin/Arabic-Indic in Arabic UI (L4) | No numeral policy helper |

---

# 18. User Journey Results

*Traced through code + passing tests; no interactive device session (see §2).*

| Journey | Verdict | Break points |
|---------|---------|--------------|
| 1 · First launch → onboarding → mode/guest/auth → home | **PASSES** (strong test coverage incl. RTL/LTR, back-nav, failure recovery; splash init-error retry works) | Splash retry copy Arabic-only (minor) |
| 2 · Home → Quran → surah → ayah → progress → resume | **PASSES** (page clamp 1–604, warmup, font-guard shimmer, time-gated read confirmation → streak) | Long-press ayah-1 text mismatch (P0-2); bookmark sign-out loss path (P0-3) |
| 3 · Select → memorize → record → review → completion → persistence | **PASSES on STT-capable devices** (V2 state machine, crash-safe resume, double-award guard, XP/streak/cert awarded via adapters) | Ayah-1 memorization text wrong for 112 surahs (P0-2); **journey blocks when STT unavailable/denied — no manual/self-grade fallback** (UX-11); `onDevice` not requested vs privacy claim (P1-9) |
| 4 · Due items → review → result → reschedule → persistence | **PASSES** (SM-2 verified incl. midnight boundary; leech/weak handling; cloud CAS) | FSRS shadow-only (intentional) |
| 5 · Child → mission → activity → reward → XP/progress → next stage | **PASSES** (journey unlock gating, PIN gate, loop ≤3, points/streak/XP/certs coherent) | Parent-reward cloud desync path (P1-6) |
| 6 · Parent → link child → view progress → cloud → refresh | **PASSES for link+view** (hashed pairing, one-guardian constraint, aggregate dashboard + fallback) | **Unlink/remove-child broken (P0-1)** |
| 7 · Online → mutate → offline → continue → reconnect → sync → verify | **PASSES for all queued domains** (queue+Workmanager+ack; monotonic merges) | Dead-letter stall (P1-4); bookmarks gate gap (P0-3); rewards bypass (P1-6); no connectivity signal (SY-7) |

---

# 19. Remediation Roadmap

### Immediate (before continuing dependent development)
1. **P0-1:** Add `revoke_guardian_link` RPC migration + apply to hosted DB + add to contract script.
2. **P0-2:** Strip/flag basmalah in ayah-1 text at datasource parse (keep S1/S9 untouched); add regression test.
3. **P0-3:** Include bookmarks (and all dirty domains) in the sign-out flush gate; integration test for the offline-bookmark sign-out path.
4. **P1-5/BD-2:** Run `verify_supabase_contract.ps1` against the hosted DB; auto-generate the checked RPC/table list from client code.

### High priority
5. **P1-4/SY-2:** Dead-letter surfacing + recovery path; error classification before attempt burn (SY-5).
6. **P1-6/SY-3:** Queue parent-rewards mutations; merge (not overwrite) on pull.
7. **P1-7/L1-2:** Migrate notifications/certificate-share/tutorial copy into arb (achievements & privacy policy already localized); delete the `SocialShareCopy` ternary layer; add a presentation-l10n guard test.
8. **P1-9 + UX-11:** Make an explicit STT decision — enforce `onDevice: true` with availability check, or rewrite the privacy-policy voice paragraph to match actual behavior — and add a manual/self-grade path when STT is unavailable (especially the kids flow).
9. **P1-8/BD-4 + BD-3:** Revoke `prune_audit_logs` from authenticated; revoke residual direct DML on streaks/xp/daily_activities (RPC-only).
10. **TD-6:** Add Flutter CI (analyze + test) alongside the Supabase workflow.

### Medium priority
11. **TD-7:** Replace streak/XP mirror tests with real-service tests (real Isar, like the sync tests).
12. Quran asset integrity test (114/6236-Hafs/604/30 asserts + **QUR-01 character-for-character dataset pin** — see §14 row 6).
13. Bookmark CAS Dart-side tests (push/pull/conflict/tombstone).
14. Consolidate SRS interval constants (CQ-4); typed error codes between data and presentation (CQ-1/CQ-2); XP event-key constants (CQ-3).
15. Switch hizb helper to qcf `quarters.dart` data (CO-2); add sajdah metadata **tagged by counting tradition** (14 agreed + 1 disputed) from a vetted dataset (CO-3, KB `01`).
16. Split `home_page_widgets.dart` / `custom_plan_setup_page.dart`; decompose `HomeCubit`/`KidsModeCubit` dependencies.

### KB-compliance workstream (Rev 3 — from `.agents/talia_islamic_knowledge_skill`)
17. **CO-8 (P1):** Move the `azkar_page.dart` `_tips` list out of UI code into the sourced dataset: Quran verses pulled verbatim from `quran.json` by reference (never hand-typed), hadith items with `sourceCitation` (Collection, Number) + `authenticityGrade` — per HAL-01/HAD-01/HAD-03 and the `08_adhkar.md` schema. Add the CI lint KB `14_content_validation.md` prescribes: flag any religious-content string literal added directly in UI code.
18. **CO-4:** Upgrade `azkar.json` to the full `08_adhkar.md` Required Metadata Schema — add `authenticityGrade` (from the source dataset's own grading, not inferred) and make every `reference` resolvable (`Collection, Number`; 12/22 dua refs currently have no number). KB `18_references.md` names **Dorar's الجامع الصحيح في الأذكار والأدعية** as the primary-tier candidate purpose-built for graded adhkar (grade attached), preferred over community Hisnul-Muslim dumps.
19. **CO-9:** Add the non-nullable `tier` field (quranic/prophetic/guidance) to the duas category per `09_dua.md`; drive display treatment and sourcing rules from it.
20. Version-pin religious content datasets (quran.json edition + azkar source) so updates are reviewable — KB `18` Engineering Implications.

### Low priority
21. Delete dead code (CQ-6), stale artifacts (CQ-10), `untranslated.json`; fix `seed.sql` config; drop stale RPC overload + orphan trigger fn.
22. Doc refresh pass (§16 list); retire or gate hifz legacy registration (TD-1).
23. EN plural cards; numeral policy helper; `onGenerateTitle`.

### Future improvements (not defects)
24. Connectivity awareness for smarter retry cadence; cursor-based pulls for streaks/activities; Hijri calendar option; second audio CDN; vector PDF certificates.

---

# 20. Verification Plan (key remediations)

```text
1. revoke_guardian_link
   Fix: new migration + apply.
   Verify: link child → unlink in UI → row status='revoked'; re-link succeeds;
   child-side unlink same; contract script includes the RPC and passes.

2. Basmalah normalization
   Fix: parse-time strip for surahs ∉ {1,9}.
   Verify: unit tests — S2V1 starts 'الم'; S1V1 and S9V1 unchanged; all 112 stripped;
   daily-plan card golden for a Baqarah plan shows no basmalah in ayah-1 text.

3. Sign-out bookmark gate
   Fix: flush gate includes bookmarkService (all dirty domains).
   Verify: offline → create bookmark → block RPC → sign out → expect
   AuthSignOutBlockedPendingData; force path keeps queue row; after relogin +
   network, exactly one cloud bookmark row and local/cloud consistent.

4. Dead-letter recovery
   Verify: simulate 8 failures → banner/status visible → recover → item syncs;
   resumeIfNeeded no longer skips when dead letters exist.

5. Rewards queueing
   Verify: offline reward unlock → local state → online → queue drains →
   pull merge preserves local transition; no wholesale overwrite.

6. Localization consolidation
   Verify: EN locale screenshot sweep — achievements/certificates/notifications
   fully English; architecture test fails on new raw Arabic literals in presentation.

7. Real streak/XP tests
   Verify: mutate real StreakService with real Isar across UTC midnight;
   XpService award/idempotency against real store.

8. STT onDevice / privacy alignment (Rev 2)
   Fix: onDevice: true + availability check + fallback, or policy rewrite.
   Verify: airplane-mode recognition works on on-device-capable device;
   on incapable device: manual-grade fallback completes the session;
   policy text matches observed behavior in both locales.

9. Manual-grade fallback (Rev 2)
   Fix: self-assessment path (excellent/average/weak → same hint-rating
   mapping as session_adapters.dart:63-67) when V2SpeechIssue != null.
   Verify: disable STT (revoke mic permission) → session completable;
   XP/streak/cert still awarded; kids flow has the same escape hatch.

10. Religious-content KB compliance (Rev 3)
   Fix: sourced dataset for azkar tips + graded azkar schema (roadmap 17-20).
   Verify: no Quran/hadith string literal in presentation layer (CI lint green);
   every azkar item renders with resolvable citation + grade; the 9 tip verses
   byte-match quran.json entries; dataset versions pinned in a sourcing log
   (KB 18 Future Extensions).
```

---

# Project Health (no release verdict — development-state classification)

### Functional Completeness
- **Strong:** memorization V2 + SM-2 review, kids journey, progress stats, streaks, azkar, certificates, auth+guest, onboarding, reader.
- **Incomplete (intentional):** FSRS in shadow mode awaiting sign-off; EN content layer for achievements/notifications; sajdah metadata.
- **Broken:** guardian unlink/remove-child (P0-1); ayah-1 text pipeline for 112 surahs (P0-2).

### Code Quality
- **Strong:** zero marker debt, clean analyzer, logger discipline, subscription hygiene, centralized XP constants.
- **Weak:** silent-catch density, error-contract fragility, sentinel strings, magic keys.

### Architecture
- **Strong:** genuine Clean-Architecture skeleton; the sync subsystem design; owner-scoped identity.
- **Risks:** presentation-edge erosion, God units, dual persistence split-brain (prefs vs Isar).

### UX
- **Strong:** state completeness (loading/error/empty), recovery paths, tested onboarding.
- **Problems:** bilingual consistency (AR leaks into EN), sync-invisibility, dialect register mix.

### Performance
- **Strong:** isolate parsing, audio caching, warmup, O(1) page index.
- **Bottlenecks (evidenced, mild):** full pulls per login/resume, monolithic build trees (profile before acting).

### Data Integrity
- **Strong:** monotonic merges, ack-based dirty clearing, CAS with surfaced conflicts, account-switch isolation (tested with real Isar).
- **Risks:** bookmark sign-out wipe (P0-3), rewards desync (P1-6), corrupt-store-as-empty reads.

### Offline/Sync
- **Strong:** queued mutation coverage for 9 domains, background retry, pull-before-push.
- **Risks:** dead-letter stall, no connectivity signal, unqueued identity/rewards.

### Content
- **Strong:** verified-perfect structural metadata (114/6236/604/30, boundaries), sourced azkar with visible references, correct 1/9 basmalah handling, Quran text from a KB-listed primary-tier source (alquran.cloud).
- **Problems:** basmalah-in-ayah-1 (CO-1), hizb approximation vs KB's sourced-fields rule (CO-2), missing sajdah metadata with KB-mandated count framing (CO-3), azkar schema missing grade/numbered citations (CO-4), **hand-typed Quran verses + unsourced hadith in UI code (CO-8, KB-critical)**, un-tiered duas (CO-9).

### Testing
- **Strong:** 916 passing incl. real-Isar integration tests; sync/SM-2/claim/cert flows genuinely covered.
- **Gaps:** mirror tests (streak/XP), asset integrity, bookmark cloud CAS, no Flutter CI.

---

# Top 10 Engineering Actions

1. **Add and deploy the `revoke_guardian_link` RPC** — guardian unlink/remove-child is currently guaranteed-broken (P0-1).
2. **Normalize basmalah out of ayah-1 text** in the quran datasource for surahs other than 1 and 9, with regression tests (P0-2).
3. **Close the sign-out data-loss gate** to cover bookmarks and all dirty domains (P0-3).
4. **Make sync failures visible and recoverable**: dead-letter surfacing + error classification in `CloudSyncQueue.markFailure` (P1-4, SY-5).
5. **Route parent-rewards through the sync queue and merge on pull** instead of direct RPC + wholesale overwrite (P1-6).
6. **Run the contract-verification script against the hosted DB in CI and auto-generate its checklist from client code** — live-drift already caused two incident classes (P1-5, BD-8).
7. **Complete the English content layer for the remaining surfaces**: notifications, certificate celebration/share, tutorial, and error copy into arb (achievements and privacy policy are already localized); delete the parallel ternary i18n (P1-7).
8. **Make the STT privacy claim true or change the claim**: enforce `onDevice: true` with availability check + manual-grade fallback (UX-11), or rewrite the policy voice paragraph — and add the manual/self-grade path regardless so the core journey survives STT-less devices (P1-9).
9. **Bring religious content in line with the project's own Islamic knowledge base**: move the hand-typed verses/hadith in `azkar_page.dart` into the sourced dataset, add `authenticityGrade` + resolvable `Collection, Number` citations (Dorar adhkar is the KB-preferred source), add the dua `tier` field, and add the CI lint against religious string literals in UI code (CO-4/CO-8/CO-9).
10. **Harden the database grants**: revoke `prune_audit_logs` from authenticated; revoke residual direct DML on streaks/xp/daily_activities (P1-8, BD-3) — plus add Flutter CI (analyze + test) to complement the Supabase workflow, then start the decomposition pass on the 1,700+-line widget files and 11–13-dependency cubits (TD-6, TD-3/4).
