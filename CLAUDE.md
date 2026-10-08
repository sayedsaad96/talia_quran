# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Talia (تالية) is an offline-first Flutter app for Quran reading, memorization (Hifz) with spaced repetition and speech-based recitation checks, Azkar, prayer times/Adhan, Khatmah plans, and kids/guardian tracks. Supabase is used for optional cloud sync. The primary locale is Arabic (RTL).

Also read `AGENTS.md` (the pre-release audit workflow, severity scale P0–P4, reviewer roles) and `.agents/skills/talia-quran-engineer-skill/SKILL.md` (engineering constitution, completion status vocabulary).

## Islamic content policy (non-negotiable)

Read `docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md` before touching Quran text, ayah/surah numbering, tafsir, translations, recitations, hadith, azkar, duas, or fatwas. The key rules:
- Never generate or "fix" religious text from memory. Copy it verbatim from the approved source, and keep its reference, version, and license.
- Keep display text separate from normalized search text. Never strip diacritics or change the script in canonical text.
- An item without verified provenance or required scholarly review stays `blocked`. Don't fill gaps with generated content.
- Any credible risk of wrong Quran text, ayah numbering, or surah order is **P0**.
- **Quran canonical data must never be modified to satisfy UI/UX requirements. UI adapts to Quran data, not Quran data to UI.** `assets/data/quran.json` is the immutable, verbatim Tanzil text (license: no changes; attribution and a tanzil.net link are shown in Settings > Sources & licenses). It keeps the basmalah at the start of ayah 1 of every surah except Al-Fatihah (where it is ayah 1) and At-Tawbah (none); `lib/core/quran/quran_basmalah.dart` separates it at runtime, verbatim, without assuming every basmalah is Unicode-identical. `Ayah.text` is the runtime body; `Ayah.canonicalText` is the untouched record. `test/assets/corpus_integrity_test.dart` checks the file sha256 and a text-only digest against `content_manifest.json` and fails if any code writes to the file.

Canonical data lives in `assets/data/` (`quran.json`, `surahs.json`, `azkar_release.json`, `content_manifest.json`, …). Only `azkar_release.json` is bundled. `azkar.json` is the candidate set. `tools/promote_azkar_candidates.py --ids ... --review-set ...` copies records verbatim into the release file, and only for records that carry a source URL and human review evidence. `lib/core/content/approved_azkar_content.dart` fails closed, so unapproved or malformed records never reach notifications. `test/assets/` holds the corpus and azkar contract tests.

## Agent orchestration (Claude Code)

The main session (Opus) is the orchestrator: it owns scope, architecture decisions, integration, and the final verdict. The user has asked for complexity-based delegation to the project subagents in `.claude/agents/`, so delegating to them does not need a separate request each time. They are the Claude Code counterparts of the Codex roles in `.agents/skills/talia-quran-engineer-skill/core/model-delegation.md` (Luna → Haiku, Terra → Sonnet, Sol/Astra → Opus). The Codex audit fleet (`.codex/agents/`, `AGENTS.md`) is unchanged and still governs a requested pre-release audit.

| Work | Route to |
|---|---|
| Trivial edit, a single lookup, or anything where briefing costs more than doing it | Opus directly, no subagent |
| Locate files/symbols/references/DI wiring, summarize a small area | `haiku-explorer` (read-only) |
| Fully specified low-risk edit: typo, docs, ARB key pair, boilerplate | `haiku-quick-fix` |
| Feature, refactor, Cubit/repository/widget work, multi-file change with clear requirements | `sonnet-implementer` |
| Nontrivial bug, failing test, runtime error | `sonnet-debugger` |
| Writing or running targeted tests, coverage for a fix | `sonnet-test-engineer` |
| Architecture, ambiguous requirements, cross-layer design, security, failed Sonnet attempt with unknown cause | Opus directly (plan/decide first) |
| Independent review of a high-risk change before calling it done | `opus-architecture-reviewer` (read-only) |

High-risk areas (always get Opus review, from the main session or `opus-architecture-reviewer`): Quran/Islamic content and `assets/data/`, `lib/core/memorization/` (engine, SRS, outbox), `lib/core/sync/` and `*_cloud_merge.dart`, `supabase/`, `lib/core/identity/` and `lib/core/security/`, Isar schema changes, prayer delivery/notifications. Quran/religious content is never delegated for generation or "fixing".

Delegation rules:
- Hybrid tasks: explore (Haiku) → design and define interfaces (Opus) → implement independent parts (Sonnet, in parallel only when they touch disjoint files) → integrate and verify (Opus). Don't involve every agent in every task; normally at most three subagents at once.
- Brief each subagent with the goal, exact file paths, constraints, the facts already gathered, and the expected report. Don't make it re-explore what is already known.
- Escalate on evidence: Haiku → Sonnet when judgment is needed; Sonnet → Opus after two failed hypotheses or cross-layer cause. Change strategy instead of retrying the same approach.
- Only one agent runs `flutter test` at a time (shared TEMP on D:, C: is nearly full), and only one agent edits a given file at a time.
- Verification scales with risk: low → targeted analyze; medium → `flutter analyze` + relevant tests; high → also Opus review of critical paths, error handling, owner scoping, and regressions. Never report tests as passing unless they were run in this task.
- Final report to the user: what changed, which agent did the significant parts, what Opus reviewed, tests actually run with results (status words from the engineer skill), and remaining risks. No orchestration logs.

## Commands

```bash
flutter pub get
flutter gen-l10n                                            # regenerate lib/core/l10n/app_localizations*.dart from ARB
dart run build_runner build --delete-conflicting-outputs    # Isar schemas (*.g.dart) and mockito mocks
flutter analyze
flutter test
flutter test test/path/to/file_test.dart                    # single file
flutter test test/path/to/file_test.dart --plain-name "name" # single test by name
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
flutter build appbundle --release
```

- Supabase config comes from `--dart-define` (`lib/core/config/supabase_config.dart`), not from `.env` at runtime. Without it, `isConfigured` is false and the app runs local-only.
- Run `build_runner` after editing any Isar model or mockito-annotated test. `build.yaml` whitelists the files each builder processes (`generate_for`), so a **new** Isar model or `@GenerateMocks` test must be added there, or nothing is generated.
- `l10n.yaml` uses `app_ar.arb` as the template. Add new keys to both `app_ar.arb` and `app_en.arb`.
- Native Android prayer/Adhan code in `android/app/src/main/kotlin/.../prayer/` has JVM unit tests: `cd android && ./gradlew :app:testDebugUnitTest`.
- Full release gate (Windows PowerShell): `./scripts/verify_v1_release.ps1 [-BuildAndroidRelease]`. It runs `pub get --enforce-lockfile` (and fails if `pubspec.lock` changes), gen-l10n, build_runner, analyze, the full test suite, the Supabase migration/contract checks, and optionally the AAB build. Evidence logs go to `build/release-evidence/v1/<runId>/`.
- Supabase: `supabase/migrations/` is the complete schema source of truth, applied in lexical order. Validate with `scripts/verify_supabase_migrations.ps1` (CI runs this on `supabase/**` changes) and `scripts/verify_supabase_contract.ps1` against a migrated DB.

## Architecture

**Layout.** `lib/features/<feature>/{data,domain,presentation}` follows Clean Architecture. Repositories return `dartz` `Either`, and presentation state uses `flutter_bloc` Cubits. `lib/core/` holds the cross-feature systems, and much of the important logic lives there rather than in features.

**Bootstrap & DI.** `main.dart` sets up the error zones and runs `TaliaApp` (`app.dart`). All wiring is manual `get_it` registration in `lib/core/di/injection.dart` (no code-gen locator). Services, repositories, and cubits are all registered there, so look there first to see how anything is constructed. The single Isar instance is opened in `lib/core/storage/app_isar.dart`.

**Routing.** `go_router` is set up in `lib/core/router/app_router.dart` (route constants in `AppRoutes`), with the shell and bottom navigation in `lib/core/widgets/app_shell.dart`. Splash/onboarding redirects live in the router.

**Persistence.** Isar holds the high-volume records (ayah progress, review records, V2 sessions, review-evidence events, the review-effect outbox, XP, streaks, activity events, prayer companion records, the cloud sync queue). SharedPreferences and `flutter_secure_storage` hold settings and account-scoped secrets (`lib/core/security/`). Records are owner-scoped through `lib/core/identity/record_owner_provider.dart`, and switching accounts must not leak data (see `test/integration/account_switch_isolation_test.dart`).

**Memorization engine** (`lib/core/memorization/`):
- `v2/session_engine.dart` is a pure, synchronous state machine (no Flutter imports) that moves between `V2SessionPhase`s. `MemorizationSessionCubit` in `features/memorization_plus` wraps it and performs the side effects through `session_adapters.dart`.
- `v2/recitation_evaluator.dart` and `recitation_word_diff.dart` score speech-to-text recitation against the ayah text.
- Outcomes go through `review_outcome_committer.dart` into review records plus an outbox (`review_effect_outbox_processor.dart`) that applies downstream effects (XP, streak, progress). The two paths are kept separate so effects are idempotent.
- SRS scheduling and mastery live in `review_due_evaluator.dart`, `review_mastery_policy.dart`, and `review_classification.dart`. Recommendations come from `smart_coach_engine.dart`.
- Product rules the engine implements are in `docs/memorization_v2_product_rules.md`.

**Cloud sync.** The app is offline-first. Local writes enqueue into `lib/core/sync/cloud_sync_queue.dart`, and `workmanager` flushes the queue (`background_sync_scheduler.dart`). Pulls merge through the per-domain `*_cloud_merge.dart` files in `core/memorization/` (daily plan, custom plan, kids progress, review records), which use cursors, dirty keys, and acknowledgements. Server writes use compare-and-swap RPCs (`compare_and_swap_daily_plan`, `upsert_memorization_identity`, …) whose signatures and grants are part of the checked Supabase contract. Feature flags are in `cloud_sync_feature_flags.dart` and `kids_hifz_feature_flags.dart`.

**Prayer & notifications.** Times are computed with `adhan` in `core/services/prayer_times_service.dart`. `lib/core/prayer_delivery/` builds scheduled events, and `android_prayer_delivery_scheduler.dart` hands them to the native Android `AdhanPlaybackService`/`AdhanClipResolver` for Adhan audio. General local notifications go through `notification_service.dart` and `notification_scheduler.dart`.

**Quran rendering.** Mushaf pages render with `qcf_quran_plus`. Text, search, and metadata come from `assets/data/quran.json` through `features/quran/data/datasources/quran_local_datasource.dart`. Audio uses `just_audio` + `audio_service`, with caching in `core/services/audio_cache_service.dart`.

## Testing notes

- `test/` mirrors `lib/`. `test/integration/` holds cross-module flow tests that run under `flutter test`, not device tests. `test/assets/` validates the bundled data files.
- Mocks use both `mockito` (generated `*.mocks.dart`, listed in `build.yaml`) and `mocktail`. Match whichever the neighbouring test uses.
- The lints `unawaited_futures`, `avoid_print` (use `TaliaLogger`), and `prefer_final_locals` are enabled. Generated `*.g.dart` files and `third_party/` are excluded from analysis.
