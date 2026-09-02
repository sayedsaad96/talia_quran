# Talia Full-Project Quality & Islamic-Content Audit

> **Historical-policy notice — 2026-08-31:** Findings in this audit remain historical evidence, but references to mandatory external Islamic review/signature no longer define release policy. The project owner is the final content authority; see docs/release/v1/islamic-review-packet.md.

**Audit date:** 2026-08-22  
**Audit basis:** Current working tree, including uncommitted user changes  
**Decision:** **No-Go for production release until the Blocker phase is complete**

## 1. Summary

Talia has a substantial, polished base: its main Mushaf reader is offline-capable and reverent, active-recall memorization is implemented, Smart Coach usually protects due work before growth, Adult and Kids have distinct flows, and the local-first synchronization/security work is thoughtful. The biggest opportunity is to join that engineering strength to a formal Islamic-content supply chain and to make the review engine conform to the product's stated SM-2 and protect-before-grow rules. The biggest risk is trust and textual correctness: memorization rendering currently rewrites Quran text, while an 85-item Adhkar/Dua corpus and daily religious notifications can be displayed or shared without verifiable source type, hadith grade, grader, dataset provenance, or review status. The project is directionally on track, but it is not release-ready against its own Constitution and KB until those religious-content blockers are closed.

| Audit lens | Score | Assessment |
|---|---:|---|
| Production readiness | **56/100** | **No-Go** — strong local-first/security base, but religious-content blockers and an unverified current build/test state remain. |
| Hifz experience | **67/100** | Strong session mechanics and Coach prioritization; SM-2 semantics, direct-plan ordering, review UX, Kids tolerance, and offline fallback need correction. |
| UX quality | **72/100** | Visually mature and generally reverent; constitutional navigation drift, accessibility gaps, and incomplete companion behavior reduce coherence. |

## 2. Scope

### Reviewed

- The complete Islamic knowledge base, read in the required order: `.agents/talia_islamic_knowledge_skill/00_system_prompt.md`, `validation_rules.md`, `knowledge_index.md`, then modules `01_quran_foundations.md` through `18_references.md` in full.
- All feature areas under `lib/features/`: **345 Dart files** across `auth` (10), `azkar` (11), `certificate` (4), `hifz` (8), `home` (8), `memorization_plus` (101), `onboarding` (3), `progress` (14), `quran` (24), `settings` (16), `splash` (1), `streak` (8), `tutorial_guide` (5), and `xp` (3).
- Cross-cutting code in `lib/core/`, including Quran rendering/audio, Smart Coach, navigation, notifications, synchronization, security, localization, dependency injection, and initialization.
- Bundled content assets: `assets/data/quran.json` (**6,236 records**) and `assets/data/azkar.json` (**85 records**).
- Supabase migrations and verification scripts, `pubspec.yaml`, README/product documentation, and the test tree: **145 Dart test files** (57 core, 82 feature, 4 integration, 1 Supabase migration-history test, plus the remaining top-level tests).
- The current dirty working tree. No existing modification was reverted or overwritten; this audit adds only this report.

### Implemented-domain map

| Locked bounded context | Current implementation | Status |
|---|---|---|
| Quran | `features/quran`, Quran services/widgets in `core` | Substantial: reader, page/juz navigation, search, bookmarks, audio, visual tajweed. |
| Learning | Mainly `features/memorization_plus` and `core/memorization/v2` | Substantial, but not a distinct boundary. |
| Assessment | V2/Kids Cubits, speech-to-text and recitation evaluators | Substantial, but coupled to Learning. |
| Review | Scheduler, review records, daily plans, filters | Substantial, but coupled and behaviorally inconsistent in some entry paths. |
| Guidance / Smart Coach | `core/memorization/smart_coach_*`, Home/Hub cards | Implemented; deterministic guidance rather than a separate context. |
| Progress | `features/progress`, `streak`, `xp`, `certificate` | Substantial. |
| Family | Kids/guardian/parent-dashboard code inside `memorization_plus` | Substantial, but not a distinct boundary. |
| Synchronization | `core/sync`, auth application coordination, repository collaborators | Substantial and actively being hardened. |

Supporting areas are Auth, Settings, Onboarding, Splash, Tutorial, and the extra Adhkar/Dua feature. Tafsir, a dedicated hadith feature, multi-riwayah selection, a content-review registry, and the KB's monthly/annual whole-passage review sweeps are not implemented. Tajweed is visually supplied by `qcf_quran_plus`; no separate tappable tajweed-teaching layer was found.

### Verification limitation

`dart analyze` and `flutter test --reporter compact` were attempted without changing code. Both remained blocked while two pre-existing `flutter_tester` processes, started at 2026-08-21 21:06, were still active; even `dart --version` then blocked. Those processes were not terminated because they may belong to the user's ongoing work. Consequently, this report does **not** claim the current dirty snapshot compiles or that its suite passes. Static inspection of test coverage and SQL contracts was still completed.

## 3. Findings

Severity follows `validation_rules.md` §13: **Blocker = Critical**, **High = High**, **Medium = Medium**, and **Nice-to-have = Low**.

### A. Quran display, structure, and riwayah handling

#### QUR-01 — Memorization rendering mutates the Quran string

- **Severity:** Blocker
- **What:** `cleanAyahForMemorization` removes markers/numbers, rewrites punctuation spacing, collapses whitespace, and heuristically inserts spaces before an Arabic definite article. Widget tests explicitly require the rewritten form. This is not a byte-preserving sacred-text render path.
- **Where:** `lib/core/utils/quran_text_display_formatter.dart:20-39,51-76`; callers in `lib/core/widgets/qcf_hifz_verse_view.dart:159,263`; behavior codified in `test/core/widgets/qcf_hifz_verse_view_test.dart:214-253`.
- **Against:** `validation_rules.md` **HAL-02**, **QUR-01**, **QUR-04**; `01_quran_foundations.md` text-integrity rules. QUR-04 is Mandatory Review.
- **Why it matters:** A display convenience can change sacred text or word boundaries, creating the highest possible correctness and trust failure in a memorization product.

#### QUR-02 — The bundled Quran corpus is not tied to a verifiable release manifest

- **Severity:** Blocker
- **What:** All 6,236 asset rows have chapter/verse/text/page/juz/global fields, but none carries a source, version, license, checksum, riwayah, or review record. `scripts/fetch_quran.dart` downloads a live API response directly into the production asset without a pinned version, checksum, schema gate, or scholarly approval artifact. No test reads `quran.json` to prove exact corpus integrity.
- **Where:** `assets/data/quran.json`; `scripts/fetch_quran.dart:7-48`; absence confirmed across `test/`; README assertions at `README.md:31-32` are not backed by a manifest.
- **Against:** `validation_rules.md` **QUR-01**, **HAL-04**; `18_references.md` dataset licensing/versioning requirements; `01_quran_foundations.md` verification guidance.
- **Why it matters:** The repo cannot reproduce or independently prove which Quran dataset shipped, even though the UI and README call it verified.

#### QUR-03 — Riwayah is not a first-class field on text, audio, or tajweed

- **Severity:** High
- **What:** `Ayah`, `AyahModel`, `QuranReciter`, and audio URL construction have no `riwayahId`. Six reciter URLs can be selected, but code cannot enforce that text, numbering, visual tajweed, and recitation use the same riwayah. This finding does not assert that any present reciter is mismatched; the repo simply cannot prove or prevent it.
- **Where:** `lib/features/quran/domain/entities/quran_entities.dart:29-48`; `lib/features/quran/data/models/ayah_model.dart:3-31`; `lib/core/services/quran_reciter.dart:1-50`; `lib/core/services/quran_audio_service.dart:4-15`; `assets/data/quran.json`.
- **Against:** `validation_rules.md` **QUR-03**; `01_quran_foundations.md`; `04_tajweed.md`; `05_qiraat.md`; `18_references.md`. QUR-03 is Mandatory Review.
- **Why it matters:** A future reciter/dataset change could silently produce text/audio/numbering drift, damaging memorization accuracy.

#### QUR-04 — Missing Quran structure is silently guessed

- **Severity:** High
- **What:** The local loader computes a global ayah number if absent, substitutes a surah-level juz, and estimates page by `surah.page + (i ~/ 15)`. Current rows contain global/page/juz, so these paths are dormant today, but a corrupt or partial future asset would be silently accepted. The domain also omits hizb, rub, sajdah, and riwayah.
- **Where:** `lib/features/quran/data/datasources/quran_local_datasource.dart:85-110`; `lib/features/quran/domain/entities/quran_entities.dart:29-48`.
- **Against:** `validation_rules.md` **QUR-01**, **QUR-03**; `01_quran_foundations.md` (do not infer Quran structure heuristically).
- **Why it matters:** Silent structural fabrication makes data corruption look valid and can schedule, navigate, or label the wrong passage.

#### QUR-05 — QCF integration has a fragile internal API and fail-open font behavior

- **Severity:** Medium
- **What:** The page view imports `package:qcf_quran_plus/src/services/get_page.dart`, an internal package path. Separately, a font-load error sets `_isFontLoaded = true` and renders the Quran page anyway rather than surfacing a safe failure state.
- **Where:** `lib/features/quran/presentation/widgets/app_quran_page_view.dart:4`; `lib/features/quran/presentation/widgets/quran_page_font_guard.dart:43-60`.
- **Against:** `validation_rules.md` **QUR-01**, **PRD-02**; `13_islamic_ux.md` Quran-font and graceful-failure guidance.
- **Why it matters:** A package upgrade or font failure can produce broken glyph rendering on the app's central screen.

#### QUR-06 — Quran-specific accessibility controls are incomplete

- **Severity:** Medium
- **What:** The reader provides RTL, dark mode, focus mode, static Mushaf pages, and appropriate QCF fonts, but no working Quran font-size control was found despite tutorial copy claiming one. No explicit Quran semantics/screen-reader contract or accessibility test exists.
- **Where:** `lib/features/quran/presentation/pages/quran_reader_page.dart`; `lib/features/quran/presentation/widgets/app_quran_page_view.dart`; claim in `lib/core/l10n/app_ar.arb:1442`; no Quran `Semantics` or text-scale test under `test/`.
- **Against:** `validation_rules.md` **PRD-05**; `13_islamic_ux.md` accessibility and Quran-specific scaling guidance.
- **Why it matters:** Low-vision users and screen-reader users cannot be shown to have reliable access to the core content.

### B. Hadith, Adhkar, and Dua content/features

#### DEV-01 — The 85-item devotional corpus has no enforceable provenance or grading schema

- **Severity:** Blocker
- **What:** Every record has display text, transliteration, translation, count, and a free-text reference, but **0/85** has `sourceType`, structured `sourceCitation`, `authenticityGrade`/`grade`, `gradedBy`, dua `tier`, dataset version, or license. Only **12/85** free-text references contain a number. The model cannot represent the missing evidence.
- **Where:** `assets/data/azkar.json`; `lib/features/azkar/domain/entities/azkar_entities.dart:5-27`; `lib/features/azkar/data/models/zikr_model.dart:3-29`.
- **Against:** `validation_rules.md` **HAL-04**, **HAD-01**, **HAD-02**, **HAD-03**, **PRD-03**, and source-type requirements in §6; `08_adhkar.md`; `09_dua.md`; `10_hadith.md`; `18_references.md`.
- **Why it matters:** Sunnah-derived content can be presented as devotional guidance without the minimum evidence needed for user trust or scholarly verification.

#### DEV-02 — Daily Dua notifications introduce and truncate untracked religious text

- **Severity:** Blocker
- **What:** Three fallback duas are hardcoded directly in Dart without source metadata. Loaded records are reduced to `item['text']`, discarding even their free-text reference, then whitespace-normalized and cut at character 177 with an ellipsis. The feature defaults to enabled and schedules 16 days.
- **Where:** `lib/core/services/notification_service.dart:48-52,623-653,782-818`; `lib/core/services/notification_scheduler.dart:48-49,149-164`; `lib/core/services/app_initializer.dart:123-157`.
- **Against:** `validation_rules.md` **HAL-02**, **HAL-04**, **HAL-07**, **QUR-01**, **QUR-04**, **HAD-01**, **HAD-03**, **PRD-03**; `09_dua.md`; `13_islamic_ux.md`; `18_references.md`.
- **Why it matters:** Unverified or cropped religious wording can be pushed outside the app without context, attribution, or an opportunity for the user to inspect the source.

#### DEV-03 — UI copy makes source claims the dataset cannot substantiate

- **Severity:** High
- **What:** English labels the corpus as Duas from Quran and Sunnah; Arabic additionally names a Quran-completion dua. The underlying records do not encode source type, tier, grade, or review status, so those claims cannot be checked programmatically or from repository evidence.
- **Where:** `lib/core/l10n/app_en.arb:298`; `lib/core/l10n/app_ar.arb:301`; `assets/data/azkar.json`.
- **Against:** `validation_rules.md` **HAL-04**, **HAL-07**, **HAD-01**, **HAD-03**; `09_dua.md`; `10_hadith.md`; `18_references.md`.
- **Why it matters:** Product copy can convert an uncertain record into an apparently authoritative attribution.

#### DEV-04 — Copy/share surfaces distribute content without its evidence

- **Severity:** High
- **What:** Adhkar/Dua screens copy raw text, and social-share data includes only the text, free-text reference, and optional translation. There is no source type, grade, grader, tier, or review status to display or preserve.
- **Where:** `lib/features/azkar/presentation/pages/azkar_category_page.dart:196-199,561-575`; `lib/features/azkar/presentation/pages/general_azkar_page.dart:316-354`; `lib/core/widgets/social_share/social_share_model.dart:231-241`.
- **Against:** `validation_rules.md` **HAL-04**, **HAD-01**, **HAD-02**, **HAD-03**; `08_adhkar.md`; `09_dua.md`; `10_hadith.md`.
- **Why it matters:** Unverified content can spread beyond any future in-app warning or correction mechanism.

#### DEV-05 — Translation and transliteration provenance is absent

- **Severity:** Medium
- **What:** All 85 records include transliteration/translation fields, but the repo does not identify who produced them, whether they came from the same vetted source as the Arabic, or whether a reviewer approved them.
- **Where:** `assets/data/azkar.json`; `lib/features/azkar/domain/entities/azkar_entities.dart:17-24`.
- **Against:** `validation_rules.md` **HAL-06**, **HAL-04**; `08_adhkar.md`; `09_dua.md`; `18_references.md`. HAL-06 is Mandatory Review.
- **Why it matters:** A correct Arabic record can still misteach users through an inaccurate translation or transliteration.

### C. Tafsir and interpretive content

No tafsir route, repository, dataset, or displayed interpretive content was found. Only dormant localization keys exist (`lib/core/l10n/app_en.arb:91`, `app_ar.arb:94`). Therefore no present TAF-01/02/03 violation is asserted. Tafsir must remain behind a sourced, clearly attributed content gate if activated; this report does not propose or generate tafsir text.

### D. Overall religious-content governance

#### GOV-01 — There is no content manifest, approval record, or CI release gate

- **Severity:** Blocker
- **What:** The repo has no content-source registry, reviewer/approval status, dataset version/license manifest, checksum lock, or CI test enforcing Quran exactness and devotional metadata. Before this audit report was added, searches found none of `sourceType`, `authenticityGrade`, `gradedBy`, `riwayahId`, `datasetVersion`, or scholarly review fields in production code, content assets, tests, or existing project documentation.
- **Where:** Repository-wide; especially `assets/data/`, `.github/`, and `test/`.
- **Against:** `validation_rules.md` **HAL-04**, **HAL-07**, **QUR-01**, **HAD-01**, **HAD-03**, **PRD-03**, and §3-§8; `18_references.md`.
- **Why it matters:** The same high-risk defects can recur on every content update because release safety currently depends on informal memory.

#### GOV-02 — Religious-content failures fail open to less-governed content

- **Severity:** High
- **What:** If the devotional asset cannot be read, notification scheduling silently switches to hardcoded religious fallbacks. If Quran structure fields are missing, loader heuristics synthesize replacements. Both paths prioritize continuity over evidence.
- **Where:** `lib/core/services/notification_service.dart:784-806`; `lib/features/quran/data/datasources/quran_local_datasource.dart:85-110`.
- **Against:** `validation_rules.md` **HAL-07**, **QUR-01**, **HAD-03**, **PRD-03**; §14 uncertainty protocol.
- **Why it matters:** A corrupted release does not stop safely; it can silently show content with weaker provenance.

#### GOV-03 — No disagreement/review state can be represented

- **Severity:** Medium
- **What:** Existing content models have no field for disputed grading, weak-narration disclosure, reviewer status, blocking review, or scholarly notes. No fiqh/fatwa feature was found, so this is a governance capability gap rather than a claim of a current ruling violation.
- **Where:** `lib/features/azkar/domain/entities/azkar_entities.dart`; `lib/features/quran/domain/entities/quran_entities.dart`; repository-wide content schema.
- **Against:** `validation_rules.md` **HAD-04**, **HAD-06**, **DIS-01**, **DIS-04**, **FAT-03**; `10_hadith.md`; `14_fiqh_awareness.md`.
- **Why it matters:** The product cannot disclose uncertainty or block sensitive records without removing them entirely or encoding warnings as unstructured copy.

### E. Memorization mechanics, Smart Coach, and spaced repetition

#### MEM-01 — The production scheduler is labeled SM-2 but does not implement the KB's SM-2 contract

- **Severity:** High
- **What:** Review state stores strength, interval, ease, and lapses but no repetition count. A weak result applies a soft 50%/30% interval reduction rather than resetting repetitions; successful early reviews do not implement the canonical first 1-day then 6-day sequence. Tests label and lock this custom V3.2 behavior as SM-2.
- **Where:** `lib/features/memorization_plus/domain/entities/ayah_review_record.dart:76-102`; `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart:19-90`; `test/features/memorization_plus/schedule_next_review_usecase_test.dart:155-266`.
- **Against:** `06_memorization_science.md` SM-2 rules; locked Constitution decision to use an SM-2-based scheduler.
- **Why it matters:** Review dates and lapse recovery can diverge from the learning model the product promises, affecting retention and user trust in the Coach.

#### MEM-02 — “Weak” is inferred from one latest rating, not rolling evidence

- **Severity:** High
- **What:** Smart Coach classifies a due non-memorized ayah as weak when `lastRating == weak`. The record has no recent-grade history from which to calculate the KB rule: average of the last three grades below 3 with at least three attempts.
- **Where:** `lib/core/memorization/smart_coach_engine.dart:39-49`; `lib/features/memorization_plus/domain/entities/ayah_review_record.dart`.
- **Against:** `06_memorization_science.md` weak-ayah classification and practical rules.
- **Why it matters:** One bad recitation can overreactively label an ayah weak, while a fluctuating pattern can be missed.

#### MEM-03 — Review recommendations enter a learning-first journey

- **Severity:** High
- **What:** Weak, near, far, and memorized-due Coach recommendations all route to `/memorization-v2/session`. Every fresh V2 session initializes at Learning, then Memorizing, then Reciting; there is no review intent that starts with recall before exposure.
- **Where:** `lib/core/memorization/smart_coach_engine.dart:39-112,208-235`; `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart:232-312`; `lib/core/memorization/v2/session_engine.dart:25-44`.
- **Against:** `06_memorization_science.md` active recall; `07_revision_methodology.md`; `16_product_knowledge.md` protect-before-grow and active-recall pillars.
- **Why it matters:** Showing/listening to the target before a due review weakens retrieval practice and makes the resulting grade less diagnostic.

#### MEM-04 — Scheduler tests validate implementation behavior, not the KB/Constitution contract

- **Severity:** Medium
- **What:** The scheduler has extensive deterministic tests, which is a strength, but no contract test asserts repetition reset, first/second intervals, rolling-three weak classification, or protect-before-grow across all entry paths.
- **Where:** `test/features/memorization_plus/schedule_next_review_usecase_test.dart`; `test/core/memorization/smart_coach_engine_test.dart`; missing contract coverage under `test/`.
- **Against:** `06_memorization_science.md`; `07_revision_methodology.md`; `15_feature_design_guidelines.md` validation checklist.
- **Why it matters:** A well-tested custom behavior can remain consistently wrong relative to product policy.

### F. Review / muraja'ah scheduling and priority ordering

#### REV-01 — The daily-plan contract and UI put new work before due review

- **Severity:** High
- **What:** `requiredAyahs` is ordered new → near → far; the pending resolver documents and follows that order; the Daily Plan screen renders New before Near/Far. Smart Coach's global priorities partly compensate, but direct plan entry and continuation can still begin with growth.
- **Where:** `lib/features/memorization_plus/domain/entities/daily_plan.dart:51-58`; `lib/core/memorization/pending_ayah_resolver.dart:129-136`; `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart:153-173`.
- **Against:** `07_revision_methodology.md` priority order; `16_product_knowledge.md` protect-before-grow.
- **Why it matters:** Due memory can decay while the user spends limited time on new ayahs.

#### REV-02 — Plan generation stops at the first surah with any work

- **Severity:** High
- **What:** Generation loads all adult records, filters them to one current surah, creates at most three optional memorized-retention items from that surah, and breaks as soon as that plan has any item. It does not build one globally ranked review queue across the learner's memorized portfolio.
- **Where:** `lib/features/memorization_plus/data/repositories/collaborators/memorization_daily_plan_service.dart:38-43,69-78,143-177`.
- **Against:** `07_revision_methodology.md` overdue/weak-first ordering; `06_memorization_science.md`; `16_product_knowledge.md` protect-before-grow.
- **Why it matters:** A heavily overdue ayah in another surah may not appear in the daily plan even though the repository already loaded it.

#### REV-03 — Whole-passage consolidation sweeps are absent

- **Severity:** Medium
- **What:** No monthly/annual whole-surah or whole-juz sweep was found. The system is strong at ayah/block review but lacks a separate passage-level consolidation layer.
- **Where:** `lib/core/memorization/`, `lib/features/memorization_plus/`; no corresponding scheduler/entity/route found.
- **Against:** `06_memorization_science.md`; `07_revision_methodology.md` periodic comprehensive review.
- **Why it matters:** Individual ayah strength can look healthy while transitions and long-passage fluency decay.

### G. Kids Mode vs Adult Mode, motivation, and gamification

#### KID-01 — Kids uses the Adult 92% evaluator with no forgiving or bypass policy

- **Severity:** High
- **What:** Kids has a separate Cubit and screens, which correctly preserves a distinct experience, but its own comments state that it uses the same Adult evaluator and ≥92% threshold. No child-specific tolerance or speech-recognition bypass was found.
- **Where:** `lib/features/memorization_plus/presentation/cubits/kids_mode_cubit.dart:79-84,238-246`.
- **Against:** `12_islamic_education.md` Kids pedagogy and STT-bypass guidance; `validation_rules.md` **PRD-04**. PRD-04 is Mandatory Review.
- **Why it matters:** Arabic child speech and device recognition variability can turn a supportive journey into repeated false failure.

#### KID-02 — Core memorization cannot guarantee offline completion

- **Severity:** High
- **What:** Adult and Kids completion depend on platform speech recognition with no manual/self-grade fallback when recognition is unavailable. Quran audio is remote and only becomes offline-capable after opportunistic caching; `prefetchSession` has no caller. A first-time offline session can therefore lose listening and assessment.
- **Where:** `lib/features/memorization_plus/presentation/cubits/memorization_session_cubit.dart:184-207,380-431`; `kids_mode_cubit.dart:547-685`; `lib/core/services/audio_cache_service.dart:20-69`; no `prefetchSession` call found.
- **Against:** Locked offline-first decision; `validation_rules.md` **PRD-06**; `12_islamic_education.md`; `13_islamic_ux.md`. PRD-06 is Mandatory Review.
- **Why it matters:** Core memorization/review can block in low-connectivity MENA conditions or on devices without usable on-device Arabic STT.

#### KID-03 — Motivation sometimes shifts from worship/consistency to streak pressure

- **Severity:** Medium
- **What:** Rewards are deterministic and no random loot-box mechanics were found, which is good. However, streak fire imagery and urgent “protect the streak” notification framing are enabled by default, while the companion/teacher framing is weak in the core journey.
- **Where:** streak notification copy/actions in `lib/core/services/notification_service.dart`; streak/XP features and social-share templates.
- **Against:** `12_islamic_education.md` intrinsic-over-extrinsic motivation; `13_islamic_ux.md` notification tone; `16_product_knowledge.md` companion philosophy.
- **Why it matters:** Users, especially children, can optimize for a metric rather than durable Quran engagement.

### H. UX reverence, RTL, dark mode, animation, audio, notifications, offline, accessibility

#### UX-01 — The app ships five primary tabs, contradicting the locked four-tab navigation

- **Severity:** High
- **What:** Home, Quran, Memorization, Azkar, and Progress are all primary destinations in both bottom navigation and wide-screen rail. The router likewise has five indexed shell branches.
- **Where:** `lib/core/widgets/app_shell.dart:21-30,94-100`; `lib/core/router/app_router.dart:691-755`.
- **Against:** Locked Product Constitution decision: Home, Quran, Memorization, Progress; `16_product_knowledge.md`; `15_feature_design_guidelines.md` navigation consistency.
- **Why it matters:** It is direct constitutional drift and dilutes the core memorization companion hierarchy. The Adhkar feature can remain accessible without being a fifth primary tab.

#### UX-02 — Offline claims exceed guaranteed behavior

- **Severity:** High
- **What:** Quran text and local plans work offline, and sync queues are durable, but tutorial/README language implies broader offline capability than the uncached audio/STT-dependent memorization flow can guarantee.
- **Where:** `README.md:6,33,133`; `lib/core/l10n/app_ar.arb:1452,1569`; runtime paths cited in KID-02.
- **Against:** Locked offline-first decision; `validation_rules.md` **PRD-06**; `13_islamic_ux.md`.
- **Why it matters:** Users may discover the limitation only during a session, when connectivity is unavailable.

#### UX-03 — Accessibility has no enforceable regression suite

- **Severity:** Medium
- **What:** No golden tests, semantic-accessibility tests, large-text tests, or Quran screen-reader tests were found. There are 24 files containing widget tests, but none exercises `SemanticsTester`, text scaling, or focus order.
- **Where:** `test/` (0 `matchesGoldenFile`, no semantics/text-scale coverage); Quran, Kids, and Daily Plan presentation layers.
- **Against:** `validation_rules.md` **PRD-05**; `13_islamic_ux.md`; `15_feature_design_guidelines.md` accessibility checklist.
- **Why it matters:** RTL/layout polish can regress for users who rely on large text, screen readers, or keyboard/focus navigation without CI noticing.

#### UX-04 — English Quran screens leak hardcoded Arabic labels

- **Severity:** Medium
- **What:** Meccan/Medinan chips and reader Juz/Hizb headers are hardcoded Arabic even when English is active, despite localized keys existing. The Quran total is displayed as a universal 6,236 without a riwayah qualifier.
- **Where:** `lib/features/quran/presentation/pages/quran_page.dart:206-208,493`; `quran_reader_page.dart:495,584`; localized alternatives in `lib/core/l10n/app_en.arb`/`app_ar.arb`.
- **Against:** `11_islamic_terminology.md`; `17_glossary.md`; `13_islamic_ux.md`; `validation_rules.md` **QUR-03** for the unqualified count.
- **Why it matters:** Mixed-language sacred navigation feels unfinished and hides the fact that numbering is riwayah-dependent.

#### UX-05 — Fixed-time devotional reminders lack context-aware restraint

- **Severity:** Nice-to-have
- **What:** Morning/evening/daily reminders use fixed local hours and there is no prayer-time integration. The current generic reminder copy is mostly restrained; this is an enhancement, not a current correctness claim.
- **Where:** `lib/core/services/notification_scheduler.dart`; no prayer-time feature found.
- **Against:** `13_islamic_ux.md` prayer-aware notification guidance.
- **Why it matters:** Better timing can reduce interruption and increase usefulness without increasing notification volume.

No ads SDK or ad placement was found. The main Mushaf page is static, RTL, dark-mode aware, and uses dedicated Quran fonts; those are material strengths against `13_islamic_ux.md`.

### I. Product philosophy alignment

#### PROD-01 — The eight bounded contexts are implemented as responsibilities, not boundaries

- **Severity:** High
- **What:** Learning, Assessment, Review, Guidance, Family, and parts of Synchronization are concentrated inside 101-file `memorization_plus`, with additional review/guidance logic in `core/memorization`. Focused interfaces are beginning to appear in the dirty worktree, but the locked context map is not reflected in module ownership.
- **Where:** `lib/features/memorization_plus/`; `lib/core/memorization/`; `lib/core/sync/`; `lib/features/auth/application/`.
- **Against:** Locked eight-bounded-context decision; `16_product_knowledge.md`; current architecture remains within Flutter/Cubit/Clean/GetIt and does not require a stack migration.
- **Why it matters:** Changes to one domain can leak into others, and ownership/tests cannot cleanly enforce the Constitution.

#### PROD-02 — The “companion, not tool” pillar is mostly branding

- **Severity:** Medium
- **What:** Companion language appears in Splash/share copy, and a Talia character asset is used mainly in social-share compositions. No persistent state-aware companion behavior was found in Home, Quran, Adult memorization, or review. Kids has an avatar, but its tap callback is currently empty.
- **Where:** `lib/core/widgets/social_share/`; `lib/features/splash/presentation/pages/splash_page.dart`; `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart:171`; no core-flow character behavior found.
- **Against:** `16_product_knowledge.md` companion-experience and teacher-scaffolding pillars.
- **Why it matters:** The experience can feel like a collection of high-quality tools rather than one relationship that helps the learner choose, recover, and continue.

#### PROD-03 — Smart Coach chooses well more often than it teaches

- **Severity:** Medium
- **What:** Coach priority explanations are coded and global due ordering is a genuine strength. However, recommendations mostly deep-link into existing flows; they do not expose the evidence behind a decision, adjust workload after repeated difficulty, or scaffold teacher escalation.
- **Where:** `lib/core/memorization/smart_coach_engine.dart`; `smart_coach_recommendation.dart`; Home/Hub recommendation cards.
- **Against:** `16_product_knowledge.md` teacher-scaffolding AI coach; `06_memorization_science.md` adaptation principles.
- **Why it matters:** Users receive a task but limited understanding of why it matters or how the plan changed in response to performance.

#### PROD-04 — Legacy and current product documentation disagree with the locked philosophy

- **Severity:** Medium
- **What:** README markets fixed interval sequences and precise AI error detection that do not match the current custom scheduler/string-similarity implementation. `docs/memorization_v2_product_rules.md` repeatedly says Kids and Adult logic should be identical, while the locked decision and Islamic-education KB require separate experiences/pedagogy.
- **Where:** `README.md:31-42,136-143`; `docs/memorization_v2_product_rules.md:198-251,738-748`.
- **Against:** Locked product decisions; `12_islamic_education.md`; `16_product_knowledge.md`; `15_feature_design_guidelines.md` definition/measurement checks.
- **Why it matters:** Teams can implement against contradictory sources and reintroduce already-decided product drift.

### J. Data-model fields implied by the KB

#### DATA-01 — Islamic-content models cannot carry required evidence

- **Severity:** High
- **What:** The Zikr model lacks `sourceType`, structured citation, authenticity grade, `gradedBy`, dua tier, reviewer, and dataset fields. Quran/Ayah and Reciter lack `riwayahId` and dataset provenance. These are domain omissions, not merely missing JSON keys.
- **Where:** `lib/features/azkar/domain/entities/azkar_entities.dart:5-27`; `lib/features/quran/domain/entities/quran_entities.dart:29-48`; `lib/core/services/quran_reciter.dart:39-50`.
- **Against:** `validation_rules.md` **HAL-04**, **HAD-01**, **HAD-02**, **QUR-03**; `08_adhkar.md`; `09_dua.md`; `10_hadith.md`; `18_references.md`.
- **Why it matters:** UI, sharing, notifications, search, and release tooling cannot preserve information the domain refuses to represent.

#### DATA-02 — Review records lack the history required by product rules

- **Severity:** High
- **What:** `AyahReviewRecord` has aggregate counts and the latest rating, but no repetitions field or rolling grade/attempt history sufficient for canonical SM-2 transitions and three-grade weak classification.
- **Where:** `lib/features/memorization_plus/domain/entities/ayah_review_record.dart:76-126`; corresponding Isar/cloud serialization.
- **Against:** `06_memorization_science.md`; `07_revision_methodology.md`.
- **Why it matters:** Correct scheduling cannot be added reliably without a data migration and explicit backward-compatibility policy.

### K. Major-feature checklist (`15_feature_design_guidelines.md`)

| Existing major feature | Purpose / states | Source & correctness | Offline / error | Measurement / accessibility | Result |
|---|---|---|---|---|---|
| Quran reader/search/bookmarks | Clear; loading/focus/audio states present | **Fail:** manifest/riwayah/integrity gates missing; memorization renderer mutates text | Text passes; audio cache partial | Reading metrics present; accessibility unproven | **Block** |
| Adhkar/Dua counter | Clear categories/counter states | **Fail:** source type/grade/tier/reviewer absent | Bundled offline; fallback governance unsafe | Completion measured; evidence not exposed | **Block** |
| Adult V2 memorization | Strong phased active-recall flow | Quran render issue; scheduler contract drift | Local state strong; STT/audio fallback absent | Many unit/widget tests; a11y unproven | **Partial** |
| Smart Coach / Daily Plan | Clear next action and strong global due priorities | Weak-history and direct-plan ordering drift | Local plan/cache/sync strong | Explanations exist; adaptation limited | **Partial** |
| Kids Journey | Distinct UI/Cubit, guardian path, deterministic rewards | Adult threshold reused | STT/audio can block offline | Child tolerance/a11y not proven | **Partial** |
| Progress/Streak/XP/Certificates | Clear achievements and summaries | Definitions depend on unqualified 6,236/Hafs assumptions | Local-first and sync-aware | Extensive tests; motivation balance mixed | **Partial** |
| Family/Guardian | Clear roles, linking, rewards, PIN | No religious-content issue found | Local/remote sync complex but hardened | Parent visibility strong | **Pass with remote verification pending** |
| Notifications | Clear settings/actions | **Fail:** untracked/truncated religious text | Scheduling resilient but fails open | Defaults can create pressure | **Block** |
| Social sharing | Polished category templates | **Fail for devotional content:** evidence not carried | Local rendering | Visually covered; no golden suite | **Partial** |
| Auth/Sync | Clear account boundaries and durable queue | Not a religious-content surface | Strong local-first design | Runtime DB contract unverified | **Pass with verification pending** |

#### FEAT-01 — Critical feature invariants are not release gates

- **Severity:** High
- **What:** There are no automated corpus-integrity, devotional-metadata, navigation-count, offline-memorization, review-intent, or accessibility gates. The test tree is broad, but the highest-risk product/Islamic invariants are absent.
- **Where:** `.github/`; `test/`; 0 tests read `quran.json`/`azkar.json`, 0 golden tests, and no semantics/text-scale tests.
- **Against:** `15_feature_design_guidelines.md`; `validation_rules.md` **QUR-01**, **HAD-01**, **HAD-03**, **PRD-05**, **PRD-06**.
- **Why it matters:** High test volume can produce false confidence when the release-defining invariants are not among the assertions.

### L. Terminology consistency

#### TERM-01 — Adhkar terminology has three competing English/code forms

- **Severity:** Medium
- **What:** The feature/route/localization use `azkar`, the domain entity is `Zikr`, while the KB/glossary use Adhkar/Dhikr. Arabic is consistent, but English UI, code, analytics keys, and documentation lack one declared convention.
- **Where:** `lib/features/azkar/`; `lib/core/l10n/app_en.arb:7,284-298`; `README.md:46-49`; `11_islamic_terminology.md`; `17_glossary.md`.
- **Against:** `11_islamic_terminology.md`; `17_glossary.md`.
- **Why it matters:** Search, documentation, event naming, and future content imports become harder to align.

#### TERM-02 — Localization files contain duplicate top-level keys

- **Severity:** Medium
- **What:** Both English and Arabic ARB files define four parent-dashboard keys twice: `parentDashboardChildLinked`, `parentDashboardReminderSaved`, `parentDashboardRemoteRewardAdded`, and `parentDashboardRewardAdded`. JSON parsing silently keeps the latter value.
- **Where:** `lib/core/l10n/app_en.arb`; `lib/core/l10n/app_ar.arb`.
- **Against:** `11_islamic_terminology.md`; `17_glossary.md`; normal localization correctness.
- **Why it matters:** Copy changes can appear to have no effect and English/Arabic meanings can drift silently.

#### TERM-03 — Marketing overstates assessment precision

- **Severity:** Medium
- **What:** README calls the speech matcher “AI Voice Verification” that identifies errors precisely, while runtime uses platform STT plus normalized text similarity and a threshold. It does not produce tajweed or scholarly recitation diagnosis.
- **Where:** `README.md:19,36-38,136-138`; `lib/core/memorization/v2/recitation_evaluator.dart`; `lib/core/utils/arabic_normalizer.dart`.
- **Against:** `11_islamic_terminology.md`; `16_product_knowledge.md` teacher-scaffolding boundary; `04_tajweed.md` (do not infer tajweed rules from generic AI).
- **Why it matters:** Users may treat a technical similarity pass as authoritative recitation validation.

### M. Technical architecture, security, performance, and tests

#### TECH-01 — Analyzer strictness is below production-grade settings

- **Severity:** Medium
- **What:** `flutter_lints` is enabled with useful async/style rules, but strict casts, strict inference, and strict raw types are not enabled; dynamic calls are explicitly tolerated.
- **Where:** `analysis_options.yaml`.
- **Against:** General Flutter/Dart production quality.
- **Why it matters:** JSON/content and Supabase payload code can hide runtime type failures that stricter analysis would catch earlier.

#### TECH-02 — Several presentation and orchestration files are oversized

- **Severity:** Medium
- **What:** Non-generated files include `home_page_widgets.dart` (1,780 lines), `custom_plan_setup_page.dart` (1,765), `quran_reader_page.dart` (967), `auth_repository_impl.dart` (896), `memorization_hub_page.dart` (881), `family_dashboard_page.dart` (873), and `app_router.dart` (845).
- **Where:** Named files under `lib/`.
- **Against:** Clean Architecture maintainability and normal Flutter review standards.
- **Why it matters:** Reviewability, targeted testing, rebuild isolation, and bounded-context ownership deteriorate as unrelated behavior accumulates.

#### TECH-03 — Some Quran failures are swallowed or replaced with placeholder data

- **Severity:** Medium
- **What:** Daily-plan generation swallows lookup failures and inserts a “text unavailable” placeholder; Kids similarly catches Quran lookup failures without logging. The font guard also suppresses the underlying error.
- **Where:** `lib/features/memorization_plus/data/repositories/collaborators/memorization_daily_plan_service.dart:80-108,148-154`; `kids_mode_cubit.dart:115-129`; `quran_page_font_guard.dart:52-60`.
- **Against:** General error-handling quality; `validation_rules.md` **QUR-01**, **HAL-07** where Quran content is involved.
- **Why it matters:** Data corruption or package failures become invisible and can reach users as a degraded sacred-content screen.

#### TECH-04 — Test breadth is good, but release-critical test depth is uneven

- **Severity:** Medium
- **What:** The repo has 145 test files, strong scheduler/Coach/account-isolation/sync tests, 24 widget-test files, four integration tests, parent-PIN tests, and a migration-history test. It has no content corpus tests, golden tests, accessibility tests, or end-to-end device test proving offline reading + memorization + review.
- **Where:** `test/`; `test/integration/`; `test/supabase/migration_history_test.dart`.
- **Against:** General QA standards; `15_feature_design_guidelines.md`; `validation_rules.md` **PRD-05**, **PRD-06**.
- **Why it matters:** The riskiest failures are cross-layer and device-dependent, beyond the current unit-heavy safety net.

#### TECH-05 — Current build and runtime database status are not proven

- **Severity:** High
- **What:** The working tree contains broad in-progress auth/sync/security/migration changes. Static SQL inspection shows RLS, owner checks, explicit revokes, SECURITY DEFINER search paths, PBKDF2 parent PINs, secure storage, durable owner-scoped queues, and network-constrained background retry — all positive. However, the fresh-database verifier requires an external database URL, the remote migration state was not available, and the blocked Dart toolchain prevented current compile/test confirmation.
- **Where:** current `git status`; `supabase/migrations/`; `scripts/verify_supabase_contract.ps1`; `lib/core/security/`; `lib/core/sync/`.
- **Against:** General production-readiness and security verification.
- **Why it matters:** Strong-looking client/SQL controls can still fail if migrations are unapplied, signatures differ remotely, or the current dirty snapshot does not compile.

## 4. Prioritized Roadmap

Each phase is independently shippable and retains the locked Flutter/Cubit/Clean/GoRouter/GetIt/Supabase/Isar stack, SM-2 direction, separate Kids/Adult experiences, offline-first commitment, eight contexts, and four-tab navigation.

### Phase 0 — Release safety gate (Blockers)

1. Remove all sacred-text mutation from display paths. Render one vetted Quran source exactly; keep STT normalization in comparison-only code. Add exact-output tests from dataset/package boundary to widget.
2. Quarantine the Adhkar/Dua corpus from authoritative source claims, external sharing, and religious-text notifications until each record has approved evidence. Do **not** fill missing content internally; create a sourcing/review task against `18_references.md` (**HAL-07**).
3. Replace hardcoded religious notification fallbacks with a non-religious, localized navigation reminder that fails closed. Never character-truncate Quran/Hadith/Dua text.
4. Create a release-blocking Quran/content manifest: source, exact version, license, riwayah, checksum, import timestamp, reviewer/approval state, and corpus invariants. Pin the fetch/import process and reject missing/changed rows.
5. Re-run analyzer, full tests, content gates, and a clean-device smoke test before release.

**Ship condition:** No Quran string transformation; no unreviewed religious text emitted; manifests/checksums and mandatory metadata gates pass.

### Phase 1 — Governed Islamic-content foundation (Blocker/High)

1. Extend the content domain with `sourceType`, structured citation, `authenticityGrade`, `gradedBy`, dua tier, language provenance, dataset version/license, review status, and reviewer notes.
2. Source a vetted replacement/verification dataset through the authorities and licensing process in `18_references.md`; route Mandatory Review items to the project owner for the final internal decision.
3. Add `riwayahId` to Quran text, numbering, tajweed, reciter/audio, bookmarks, review records where identity depends on the passage, and cache keys.
4. Make corrupt/missing Quran structure a blocking data error; remove page/juz/global heuristics.
5. Update UI/share/notification surfaces to carry approved attribution and required grade disclosures.

**Ship condition:** Every religious record has machine-enforceable provenance and review state; text/audio/numbering alignment is explicit.

### Phase 2 — Learning and review correctness (High)

1. Specify the exact SM-2-based contract within the locked decision: grade mapping, repetition state, first/second intervals, lapse reset, fuzzing, overdue handling, and migration from existing records. Add contract tests before changing implementation.
2. Store sufficient attempt history for the rolling-three weak rule and adaptive workload decisions.
3. Create a review intent that starts with hidden-text recall, not Learning/Listening. Keep remediation available only after the attempt.
4. Build one globally ranked due queue for daily review; order weak/overdue/near/far before new work on every entry path. Make retention required when due rather than an optional three-item same-surah appendix.
5. Give Kids its own pedagogical policy: shorter blocks, more forgiving recognition, and a safe bypass when STT is unreliable, while preserving the separate experience.

**Ship condition:** All entry paths satisfy protect-before-grow and active recall; SM-2 and Kids policies are testable, migrated, and consistent.

### Phase 3 — Offline, Constitution, and UX coherence (High/Medium)

1. Guarantee an offline assessment path for Adult and Kids. Add explicit audio-pack/prefetch management and a non-network active-recall fallback; test on a device with Arabic STT unavailable.
2. Restore four primary tabs; keep Adhkar/Dua as a reviewed secondary Home/More destination rather than deleting the feature.
3. Incrementally establish the eight boundaries using interfaces/modules inside the existing stack: Learning, Assessment, Review, Guidance, Family, Synchronization, Quran, Progress. Preserve compatibility facades during migration.
4. Add Quran font scaling, semantics/focus contracts, large-text layouts, and accessibility/golden tests.
5. Localize hardcoded Quran labels, qualify riwayah-dependent counts, reconcile terminology, and remove duplicate ARB keys.
6. Introduce a subtle state-aware companion that supports planning/recovery without animating over sacred text or trivializing worship.

**Ship condition:** Core flows work offline, navigation matches the Constitution, and accessibility/terminology have enforceable tests.

### Phase 4 — Production verification and maintainability (Medium/Nice-to-have)

1. Apply and verify all migrations on a fresh and the target Supabase project using `scripts/verify_supabase_contract.ps1`; capture evidence in CI/release artifacts.
2. Split oversized UI/orchestration files along the bounded-context seams and replace internal package imports with public APIs or a pinned adapter.
3. Add end-to-end offline, account-switch, sync-conflict, Quran-render, Kids, review, notification, and sharing tests.
4. Add monthly/annual surah/juz consolidation sweeps and prayer-aware notification timing after core correctness is stable.

**Ship condition:** Clean build/analyze/test, fresh-database contract pass, target-environment smoke pass, and no unresolved Blocker/High finding.

## 5. Quick Wins vs. Strategic Investments

### Can ship this week

- Disable religious-text daily notifications and their hardcoded fallbacks; use generic navigation copy until vetted content is available.
- Stop character truncation of any religious content.
- Remove the Quran formatter from display or gate the affected memorization surface until exact rendering tests pass.
- Remove unsupported Quran/Sunnah/Khatm claims from subtitles pending review; do not replace them with newly authored religious claims.
- Restore four primary tabs and move Adhkar to a secondary entry.
- Remove duplicate ARB keys and hardcoded Arabic labels in English screens.
- Add CI tests that fail when content metadata/manifests are missing, corpus counts change unexpectedly, or navigation has more than four primary tabs.

### Needs real scoping

- A licensed, versioned Quran/Adhkar/Dua dataset and qualified scholarly review workflow per `18_references.md`.
- Riwayah-safe identity across text, audio, tajweed, caches, bookmarks, progress, and review history.
- SM-2 record migration, grade-history model, globally ranked daily review, and a recall-first review flow.
- Reliable offline Arabic assessment/audio packs across Android/iOS device capabilities.
- Incremental extraction of the eight bounded contexts without changing the locked stack.
- Companion behavior, passage-level consolidation, and comprehensive accessibility/device testing.

## 6. Open Questions & Flagged for Scholarly Review

### A. Could not be verified from the repository alone

1. What exact source release, license, checksum, and approval produced `assets/data/quran.json`? The fetch script suggests a live API endpoint but does not bind the shipped asset to a reproducible version.
2. What exact QCF package corpus/riwayah/license is bundled, and does its page/verse helper return text identical to the approved source used elsewhere?
3. Are all six EveryAyah audio collections the same riwayah as the displayed text and tajweed data?
4. Who sourced and translated/transliterated each of the 85 Adhkar/Dua records, and are there existing reviewer notes outside the repo?
5. Are all Supabase migrations, especially `20260820221531_production_data_layer_remediation.sql`, applied to the production project, and does the runtime contract verifier pass there?
6. Does Arabic speech recognition work fully offline on every supported target/device, and what happens on a clean offline install with no cached audio?
7. Does `qcf_quran_plus` expose correct screen-reader semantics and font-load failure behavior on physical devices?
8. Does the current dirty snapshot compile and pass all tests? Tool execution was blocked by pre-existing Flutter test processes, as documented in Scope.

### B. Mandatory scholarly review

Under the current 2026-08-31 policy, the following require an explicit project-owner decision; this historical audit does not propose a religious resolution:

1. Quran text exactness, diacritics, ayah numbering, page/juz/hizb alignment, and the effects of the current memorization formatter — **QUR-03**, **QUR-04**.
2. Text/audio/tajweed riwayah alignment for every shipped reciter and rendering source — **QUR-03**.
3. Authentication, citation, grade, grader, disputed/weak status, count, and wording for all Sunnah-derived Adhkar/Dua records — **HAD-01**, **HAD-04**, **HAD-06**.
4. Provenance and accuracy of every translation/transliteration pair — **HAL-06**.
5. Any Quran-completion dua or other “popular”/unstructured item in the current corpus — **HAL-04**, **HAL-07**, **HAD-03**.
6. Kids/parent pedagogical and content framing before release — **PRD-04**.
7. Offline presentation/storage behavior for approved religious content — **PRD-06**.

No active fiqh ruling or fatwa feature was found. If such content is introduced, the **FAT-01/02/03** boundary and qualified-review requirement apply; this report intentionally provides no ruling.

## 7. Verdict

Talia is **on track in engineering ambition and core experience, but not yet on track for a production Islamic-content release**. Its strongest foundations — offline Quran text, active-recall V2 sessions, global Coach priority, separate Kids/Adult flows, local-first sync, owner-scoped security, and thoughtful visual reverence — are worth preserving. The single highest-leverage next step is to ship **Phase 0 as a release gate: eliminate sacred-text mutation and ungoverned religious output, then bind every shipped corpus to a versioned, checked, project-owner-approved manifest**. Until that gate passes, the correct production verdict is **No-Go**.
