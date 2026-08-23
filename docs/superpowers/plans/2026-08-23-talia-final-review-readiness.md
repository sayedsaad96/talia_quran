# Talia Final Review Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a release-candidate build of Talia whose engineering, Quran, Adhkar/Dua, memorization, Kids, offline, accessibility, synchronization, and security invariants are demonstrably satisfied, ready for full qualified Islamic review and publication only after approval.

**Architecture:** Keep the existing Flutter/Cubit/Clean Architecture/GoRouter/GetIt/Supabase/Isar stack. Add a small religious-content evidence layer and immutable corpus manifests; make Quran and devotional content fail closed; then repair the independent product and data-integrity findings. Every phase ends in a reviewable green gate, and the final approval artifact binds the reviewer decision to the exact Quran/Adhkar manifests and application commit.

**Tech Stack:** Flutter, Dart, flutter_bloc/Cubit, GetIt, GoRouter, Isar, SharedPreferences, Supabase/Postgres/RLS, GitHub Actions, PowerShell contract scripts.

**Spec:** `docs/talia-full-project-quality-islamic-content-audit-2026-08-22.md`, supplemented by `docs/talia_development_quality_audit_2026-08-22.md`, `docs/talia_remediation_plan.md`, and `.agents/talia_islamic_knowledge_skill/validation_rules.md`. Where the remediation plan rejects rolling-three weakness, recall-before-reveal, SM-2 reset semantics, or protect-before-grow, the explicit requirements in knowledge modules `06`, `07`, and `16` take precedence.

## Global Constraints

- Do not generate, reconstruct, paraphrase-as-revelation, or manually correct Quran/Hadith/Adhkar/Dua text.
- Quran display text must remain character-for-character identical to the approved corpus; normalization is permitted only on a comparison copy used by STT/search.
- Do not infer a hadith grade, citation number, repetition count, dua tier, or scholarly position from wording.
- No religious record may be displayed, notified, copied, or shared unless its release policy permits the record's review status.
- Keep Adult and Kids experiences separate; shared infrastructure must not force identical pedagogy.
- Core reading, recall, progress, and queued mutations remain offline-first.
- Do not change the locked Flutter/Cubit/Clean Architecture/GoRouter/GetIt/Supabase/Isar stack.
- Preserve user data with migrations and backward-compatible reads before deleting legacy fields or storage keys.
- A qualified Islamic reviewer must approve the exact corpus hashes and review packet before publication.
- Any post-approval change to Quran, Adhkar/Dua, religious UI literals, citations, grades, reciter/riwayah mappings, or religious notifications invalidates approval and returns the build to the Islamic-review gate.
- Each task follows test-first development and ends with focused tests, full affected-suite tests, analyzer, and a small commit.

## Delivery Gates

| Gate | Required result | Blocks |
|---|---|---|
| G0 Baseline | Toolchain healthy; reports reconciled; existing tests/analyzer reproducible | All implementation |
| G1 Content safety | Exact Quran render; manifests; fail-closed religious output; governed Adhkar/Dua | Product feature work touching religious content |
| G2 Data safety/security | Guardian, bookmark, sync, rewards, grants, hosted contract verified | RC build |
| G3 Learning quality | Recall-first review, documented scheduler, Kids policy, offline fallback | RC build |
| G4 Product quality | Localization, accessibility, performance, CI/E2E evidence green | RC build |
| G5 Islamic review | Qualified reviewer approves hashes, citations, grades, counts, translations and presentation | Publication |
| G6 Store release | Signed build matches approved commit and manifests; smoke/rollback evidence captured | Production rollout |

---

### Task 1: Establish a Reproducible Baseline and Reconcile the Audit

**Files:**
- Modify: `docs/talia_development_quality_audit_2026-08-22.md`
- Create: `docs/release/baseline-2026-08-23.md`
- Test: `test/architecture/release_baseline_test.dart`

**Interfaces:**
- Consumes: Both audit reports and the current repository state.
- Produces: One severity/dependency register with stable finding IDs and a reproducible baseline command set.

- [ ] **Step 1: Clear only confirmed stale Flutter test processes after checking ownership**

```powershell
Get-Process -Name flutter_tester,dart -ErrorAction SilentlyContinue |
  Select-Object ProcessName,Id,StartTime,Path
```

Record the process evidence. Stop only the two stale `flutter_tester` processes after confirming they are not part of an active user command; do not terminate unrelated Dart/Codex processes.

- [ ] **Step 2: Capture the baseline**

```powershell
flutter --version
flutter pub get
dart analyze
flutter test --reporter compact
git status --short --branch
```

Write exact versions, command results, test count, failures, commit SHA, and dirty-tree state to `docs/release/baseline-2026-08-23.md`.

- [ ] **Step 3: Add an audit consistency test**

```dart
test('release finding register contains every blocker exactly once', () {
  final ids = loadFindingIds('docs/talia_development_quality_audit_2026-08-22.md');
  expect(ids, containsAll(<String>['QUR-01', 'QUR-02', 'DEV-01', 'DEV-02', 'GOV-01']));
  expect(ids.length, ids.toSet().length);
});
```

- [ ] **Step 4: Reconcile the development audit**

Promote Quran mutation, corpus provenance, devotional metadata, notification truncation, and content governance to release blockers. Replace the `alquran.cloud` certainty claim with “candidate requiring pinned version/license/review”. Replace the runtime basmalah-strip recommendation with the approved-corpus import approach in Task 4. Link each finding to its owning task below.

- [ ] **Step 5: Verify and commit**

```powershell
flutter test test/architecture/release_baseline_test.dart
git add docs/talia_development_quality_audit_2026-08-22.md docs/release/baseline-2026-08-23.md test/architecture/release_baseline_test.dart
git commit -m "docs: establish final readiness baseline"
```

**Gate:** G0 passes only when analyzer and the full existing suite are reproducible or every pre-existing failure is recorded as an explicit blocking task.

---

### Task 2: Add Religious-Content Evidence Types and Release Policy

**Files:**
- Create: `lib/core/religious_content/content_evidence.dart`
- Create: `lib/core/religious_content/content_release_policy.dart`
- Create: `test/core/religious_content/content_release_policy_test.dart`
- Modify: `lib/features/azkar/domain/entities/azkar_entities.dart`
- Modify: `lib/features/azkar/data/models/zikr_model.dart`

**Interfaces:**
- Produces: `ReligiousSourceType`, `DuaTier`, `ContentReviewStatus`, `SourceCitation`, `ContentEvidence`, and `ContentReleasePolicy.canPublish(ContentEvidence)`.
- Consumed by: Tasks 5-8 and the final publication gate.

- [ ] **Step 1: Write release-policy tests**

```dart
test('approved record with resolvable evidence can publish', () {
  expect(ContentReleasePolicy.canPublish(approvedEvidence), isTrue);
});

test('pending, rejected, ungraded hadith, and unresolved citation fail closed', () {
  expect(ContentReleasePolicy.canPublish(pendingEvidence), isFalse);
  expect(ContentReleasePolicy.canPublish(ungradedHadithEvidence), isFalse);
  expect(ContentReleasePolicy.canPublish(unresolvedCitationEvidence), isFalse);
});
```

- [ ] **Step 2: Define explicit evidence types**

```dart
enum ReligiousSourceType { quran, hadith, athar, curatedDua, educationalGuidance }
enum DuaTier { quranic, prophetic, guidance }
enum ContentReviewStatus { pending, approved, rejected }

final class SourceCitation {
  const SourceCitation({this.surahId, this.ayahFrom, this.ayahTo, this.collection, this.book, this.number});
  final int? surahId;
  final int? ayahFrom;
  final int? ayahTo;
  final String? collection;
  final String? book;
  final String? number;
}

final class ContentEvidence {
  const ContentEvidence({
    required this.sourceType,
    required this.citation,
    required this.datasetId,
    required this.datasetVersion,
    required this.reviewStatus,
    this.authenticityGrade,
    this.gradedBy,
    this.reviewerId,
  });
  final ReligiousSourceType sourceType;
  final SourceCitation citation;
  final String datasetId;
  final String datasetVersion;
  final ContentReviewStatus reviewStatus;
  final String? authenticityGrade;
  final String? gradedBy;
  final String? reviewerId;
}
```

- [ ] **Step 3: Extend `Zikr` without inventing missing evidence**

Make evidence required in the new constructor and add `DuaTier? tier`; provide a temporary legacy decoder that marks existing rows `pending`, never `approved`.

- [ ] **Step 4: Run focused tests and commit**

```powershell
flutter test test/core/religious_content/content_release_policy_test.dart
dart analyze
git add lib/core/religious_content lib/features/azkar/domain/entities/azkar_entities.dart lib/features/azkar/data/models/zikr_model.dart test/core/religious_content
git commit -m "feat: add religious content evidence policy"
```

---

### Task 3: Introduce Immutable Corpus Manifests and Validation Tooling

**Files:**
- Create: `assets/data/content_manifest.json`
- Create: `tool/content_validation/validate_content.dart`
- Create: `test/content/content_manifest_test.dart`
- Modify: `pubspec.yaml`
- Modify: `.github/workflows/flutter-ci.yml`

**Interfaces:**
- Produces: Manifest entries for `quran.json`, `surahs.json`, `azkar.json`, QCF corpus, and reciter catalogs.
- Consumed by: Importers, runtime diagnostics, CI, reviewer export, and publication gate.

- [ ] **Step 1: Write failing manifest tests**

```dart
test('every shipped religious asset has immutable identity', () {
  final manifest = loadContentManifest();
  for (final id in ['quran-hafs', 'surah-metadata', 'adhkar-dua', 'qcf-pages', 'reciter-catalog']) {
    final item = manifest.item(id);
    expect(item.version, isNotEmpty);
    expect(item.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(item.licenseId, isNotEmpty);
    expect(item.reviewStatus, isNotEmpty);
  }
});
```

- [ ] **Step 2: Define the manifest schema**

```json
{
  "schemaVersion": 1,
  "items": [
    {
      "id": "quran-hafs",
      "file": "assets/data/quran.json",
      "version": "approved-source-release",
      "riwayahId": "hafs-an-asim",
      "pageLayoutId": "madani-604",
      "licenseId": "verified-license-id",
      "sha256": "64-lowercase-hex-characters",
      "sourceRecord": "docs/content-review/sources/quran.yaml",
      "reviewStatus": "pending"
    }
  ]
}
```

During implementation, replace descriptive values only with evidence copied from the selected provider; never guess them. `pending` is the only allowed status before reviewer sign-off.

- [ ] **Step 3: Implement deterministic validation**

The validator must compute SHA-256, reject missing manifest entries, verify 114/6236/604/30, contiguous numbering, surah boundaries, required religious metadata, valid enum values, and zero `approved` records lacking reviewer evidence. It exits non-zero on any mismatch.

- [ ] **Step 4: Wire the validator into CI before Flutter tests**

```yaml
- name: Validate religious content
  run: dart run tool/content_validation/validate_content.dart
- name: Analyze
  run: dart analyze
- name: Test
  run: flutter test --reporter compact
```

- [ ] **Step 5: Verify and commit**

```powershell
dart run tool/content_validation/validate_content.dart
flutter test test/content/content_manifest_test.dart
git add assets/data/content_manifest.json tool/content_validation test/content/content_manifest_test.dart pubspec.yaml .github/workflows/flutter-ci.yml
git commit -m "build: gate religious corpus integrity"
```

---

### Task 4: Replace the Quran Fetch Path with an Auditable Import and Exact Corpus Tests

**Files:**
- Replace: `scripts/fetch_quran.dart`
- Create: `tool/content_validation/import_quran.dart`
- Create: `docs/content-review/sources/quran.yaml`
- Create: `test/content/quran_corpus_integrity_test.dart`
- Modify: `assets/data/quran.json`
- Modify: `assets/data/surahs.json`
- Modify: `assets/data/content_manifest.json`

**Interfaces:**
- Consumes: A licensed, versioned, reviewer-selected Hafs corpus file supplied as an explicit local input.
- Produces: Deterministic production assets and manifest hashes; never downloads live data directly into production assets.

- [ ] **Step 1: Write corpus contract tests**

```dart
test('approved Quran corpus preserves canonical structure and boundaries', () {
  final corpus = loadQuranCorpus();
  expect(corpus.surahs.length, 114);
  expect(corpus.ayahs.length, 6236);
  expect(corpus.pages.toSet(), equals(Set<int>.from(List.generate(604, (i) => i + 1))));
  expect(corpus.juz.toSet(), equals(Set<int>.from(List.generate(30, (i) => i + 1))));
  expect(corpus.hasUnnumberedBasmalahInsideAyahText(exceptSurahs: {1, 9}), isFalse);
  expect(corpus.sha256, loadManifest().item('quran-hafs').sha256);
});
```

- [ ] **Step 2: Implement an explicit-input importer**

```powershell
dart run tool/content_validation/import_quran.dart `
  --input D:\review-input\approved-quran-release.json `
  --source-record docs/content-review/sources/quran.yaml
```

The importer validates schema and boundaries, writes deterministically, prints the output hash, and refuses an unknown hash. It must not strip or rewrite Quran characters at runtime.

- [ ] **Step 3: Record provider evidence**

`quran.yaml` must contain provider, exact edition/version, riwayah, page layout, license evidence, retrieval date, original input hash, generated output hash, and reviewer status. Values come from provider/reviewer documentation only.

- [ ] **Step 4: Import structural metadata as sourced fields**

Carry `hizb`, `rubElHizb`, and `sajdah` metadata from the approved dataset; do not calculate boundaries from page midpoints. Sajdah records carry `countingTradition`, `agreementStatus`, and source evidence so the 14 agreed locations and one disputed location can be presented without silently resolving the disagreement.

- [ ] **Step 5: Validate the imported assets**

```powershell
dart run tool/content_validation/validate_content.dart
flutter test test/content/quran_corpus_integrity_test.dart
```

- [ ] **Step 6: Commit the importer separately from the reviewed corpus update**

```powershell
git add scripts/fetch_quran.dart tool/content_validation/import_quran.dart test/content/quran_corpus_integrity_test.dart
git commit -m "refactor: make Quran imports auditable"
git add assets/data/quran.json assets/data/surahs.json assets/data/content_manifest.json docs/content-review/sources/quran.yaml
git commit -m "data: pin reviewed Hafs Quran corpus"
```

---

### Task 5: Make Quran Rendering Exact and Structural Failures Fail Closed

**Files:**
- Modify: `lib/core/widgets/qcf_hifz_verse_view.dart`
- Modify: `lib/core/utils/quran_text_display_formatter.dart`
- Modify: `lib/features/quran/data/datasources/quran_local_datasource.dart`
- Modify: `lib/features/quran/data/models/ayah_model.dart`
- Modify: `lib/features/quran/domain/entities/quran_entities.dart`
- Modify: `lib/features/quran/presentation/widgets/quran_page_font_guard.dart`
- Test: `test/core/widgets/qcf_hifz_verse_view_test.dart`
- Create: `test/features/quran/quran_local_datasource_integrity_test.dart`

**Interfaces:**
- Produces: Byte-preserving sacred display and typed `QuranContentFailure` for corrupt/missing fields.
- Consumed by: Reader, memorization, Daily Plan, Kids, search, sharing, and reviewer screenshots.

- [ ] **Step 1: Replace formatter expectations with exact-output expectations**

```dart
testWidgets('Hifz view emits the exact approved ayah text', (tester) async {
  final ayah = approvedFixtureAyah();
  await tester.pumpWidget(buildHifzView(ayah));
  expect(renderedQuranText(tester), ayah.text);
});
```

- [ ] **Step 2: Remove sacred-display calls to `cleanAyahForMemorization`**

Pass `Ayah.text` unchanged to Quran widgets. Retain `ArabicNormalizer` only inside search/STT comparison code. If visual ayah markers are separate widgets, obtain them from structured approved fields rather than deleting characters from the verse string.

- [ ] **Step 3: Remove page/juz/global fallback guesses**

```dart
final page = requirePositiveInt(verseObj, 'page');
final juz = requireRangeInt(verseObj, 'juz', min: 1, max: 30);
final global = requireRangeInt(verseObj, 'global', min: 1, max: 6236);
```

Any failure returns a safe Quran error screen and logs a non-textual diagnostic; it must not display placeholder Quran text.

- [ ] **Step 4: Make QCF font failure safe**

Do not set `_isFontLoaded = true` after load failure. Render a localized retry/error state with no broken sacred glyph output.

- [ ] **Step 5: Verify and commit**

```powershell
flutter test test/core/widgets/qcf_hifz_verse_view_test.dart test/features/quran/quran_local_datasource_integrity_test.dart
dart analyze
git add lib/core/widgets/qcf_hifz_verse_view.dart lib/core/utils/quran_text_display_formatter.dart lib/features/quran test/core/widgets/qcf_hifz_verse_view_test.dart
git commit -m "fix: preserve exact Quran text in every render path"
```

**Gate:** No Quran display path may transform wording, diacritics, or verse boundaries.

---

### Task 6: Enforce Riwayah-Safe Text, Audio, Tajweed, and Identity

**Files:**
- Modify: `lib/features/quran/domain/entities/quran_entities.dart`
- Modify: `lib/features/quran/data/models/ayah_model.dart`
- Modify: `lib/core/services/quran_reciter.dart`
- Modify: `lib/core/services/quran_audio_service.dart`
- Create: `lib/core/religious_content/quran_corpus_identity.dart`
- Create: `test/core/services/quran_riwayah_alignment_test.dart`
- Modify: bookmark/review/cache keys that identify a passage if multi-corpus ambiguity exists.

**Interfaces:**
- Produces: `QuranCorpusIdentity(datasetId, version, riwayahId, pageLayoutId)` and reciter compatibility checks.
- Consumed by: Reader, audio, QCF adapter, bookmarks, review records, reviewer packet.

- [ ] **Step 1: Write alignment tests**

```dart
test('audio cannot be selected for a different riwayah', () {
  expect(
    () => QuranAudioService.buildUrl(ayah, reciter: incompatibleReciter),
    throwsA(isA<QuranCorpusMismatchFailure>()),
  );
});
```

- [ ] **Step 2: Add corpus identity to Quran and reciter boundaries**

```dart
final class QuranCorpusIdentity {
  const QuranCorpusIdentity({required this.datasetId, required this.version, required this.riwayahId, required this.pageLayoutId});
  final String datasetId;
  final String version;
  final String riwayahId;
  final String pageLayoutId;
}
```

- [ ] **Step 3: Validate every shipped reciter and QCF source**

Populate riwayah and source evidence only from verified provider records. A reciter with incomplete evidence remains unavailable in release builds.

- [ ] **Step 4: Isolate QCF behind a pinned public adapter**

Remove direct imports from `package:qcf_quran_plus/src/`. The adapter exposes only reviewed page/verse/font operations, pins the package/corpus version, checks its manifest identity at startup, and returns a typed safe failure if the public contract or font asset is unavailable.

- [ ] **Step 5: Migrate persisted identity safely**

Default legacy records to the single approved Hafs corpus only after verifying the app previously shipped no second corpus. Add migration tests for bookmarks, review records, audio cache keys, and progress references.

- [ ] **Step 6: Verify and commit**

```powershell
flutter test test/core/services/quran_riwayah_alignment_test.dart test/features/quran
git commit -am "feat: enforce Quran corpus and riwayah alignment"
```

---

### Task 7: Import a Reviewed Adhkar/Dua Corpus with Complete Evidence

**Files:**
- Create: `tool/content_validation/import_adhkar.dart`
- Create: `docs/content-review/sources/adhkar-dua.yaml`
- Modify: `assets/data/azkar.json`
- Modify: `assets/data/content_manifest.json`
- Modify: `lib/features/azkar/data/datasources/azkar_local_datasource.dart`
- Modify: `lib/features/azkar/data/models/zikr_model.dart`
- Create: `test/content/adhkar_corpus_integrity_test.dart`

**Interfaces:**
- Consumes: Reviewer-selected licensed dataset with exact Arabic, counts, structured citations, grades and grader attribution.
- Produces: Approved-schema records; Quranic records reference Quran IDs rather than hand-typed duplicate revelation where practical.

- [ ] **Step 1: Write schema and release tests**

```dart
test('every devotional record has enforceable evidence', () {
  for (final record in loadAdhkarCorpus()) {
    expect(record.evidence.citation.isResolvable, isTrue);
    expect(record.evidence.datasetVersion, isNotEmpty);
    if (record.evidence.sourceType == ReligiousSourceType.hadith) {
      expect(record.evidence.authenticityGrade, isNotEmpty);
      expect(record.evidence.gradedBy, isNotEmpty);
    }
    if (record.category == AzkarCategory.duas) expect(record.tier, isNotNull);
  }
});
```

- [ ] **Step 2: Implement deterministic import without religious inference**

Reject any input row lacking required fields. The importer may map field names and validate types; it must not manufacture grades, numbers, benefits, counts, or tiers.

- [ ] **Step 3: Resolve duplicate records intentionally**

Preserve legitimate morning/evening reuse through stable content IDs plus category assignments instead of divergent duplicate text. Produce a duplicate report for the reviewer covering the current 17 duplicate-text groups.

- [ ] **Step 4: Keep all imported rows pending until reviewer approval**

The app's release policy blocks pending records from external distribution. Development builds may show a clearly non-production review surface to the assigned reviewer.

- [ ] **Step 5: Verify and commit**

```powershell
dart run tool/content_validation/import_adhkar.dart --input D:\review-input\approved-adhkar.json --source-record docs/content-review/sources/adhkar-dua.yaml
dart run tool/content_validation/validate_content.dart
flutter test test/content/adhkar_corpus_integrity_test.dart test/features/azkar
git add tool/content_validation/import_adhkar.dart docs/content-review/sources/adhkar-dua.yaml assets/data lib/features/azkar test/content/adhkar_corpus_integrity_test.dart
git commit -m "data: introduce governed Adhkar and Dua corpus"
```

---

### Task 8: Remove Ungoverned Religious Output from UI, Notifications, Certificates, and Sharing

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_page.dart`
- Modify: `lib/core/services/notification_service.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_notification_tiles.dart`
- Modify: `lib/features/certificate/presentation/widgets/certificate_widget.dart`
- Modify: `lib/features/home/presentation/pages/home_page_widgets.dart`
- Modify: `lib/core/widgets/social_share/`
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Create: `test/architecture/religious_literal_guard_test.dart`
- Create: `test/core/services/religious_notification_policy_test.dart`

**Interfaces:**
- Consumes: Approved records and `ContentReleasePolicy` from Tasks 2 and 7.
- Produces: Source-backed in-app display; generic fail-closed notifications; evidence-preserving sharing.

- [ ] **Step 1: Add a repository-wide literal guard**

The test scans production Dart and ARB files for Quran delimiters, known sacred phrases, and religious-content blocks. It permits only generated localization output and an explicit asset/fixture allowlist; it reports file and line for every violation.

- [ ] **Step 2: Delete `_DailyTipState._tips` and load typed records**

Quran tips reference approved `surahId/ayahFrom/ayahTo`; hadith/dua tips reference approved record IDs. UI renders text, citation, grade, and source label supplied by the record.

- [ ] **Step 3: Make notifications fail closed**

Remove `_fallbackDailyDuas` and `_compactNotificationText`. Notification bodies use localized generic navigation copy such as “Your reviewed daily Dua is ready”; full religious text is displayed only after opening the approved record in-app. Asset failure schedules no religious text.

- [ ] **Step 4: Move certificate/home religious text to approved references**

Do not place Quran text in ARB. Resolve the certificate verse and any displayed basmala through the approved Quran repository and corpus identity.

- [ ] **Step 5: Preserve evidence in copy/share**

Sharing is enabled only for approved records and includes the resolvable citation, authenticity grade where required, and dataset attribution. Pending/rejected records expose no copy/share action.

- [ ] **Step 6: Verify and commit**

```powershell
flutter test test/architecture/religious_literal_guard_test.dart test/core/services/religious_notification_policy_test.dart test/features/azkar test/core/widgets/social_share_test.dart
dart analyze
git commit -am "fix: govern every religious output surface"
```

**Gate:** G1 passes after Tasks 2-8 and the content validator are green. Product fixes may continue, but no religious corpus is labeled approved until Task 19.

---

### Task 9: Repair Guardian Unlink and Verify the Hosted Contract

**Files:**
- Create: `supabase/migrations/20260823120000_add_revoke_guardian_link.sql`
- Modify: `scripts/verify_supabase_contract.ps1`
- Modify: guardian repository/gateway file containing the current RPC call.
- Create: `test/integration/guardian_unlink_contract_test.dart`

**Interfaces:**
- Produces: `revoke_guardian_link` RPC with authenticated role/ownership checks and idempotent revoked state.

- [ ] **Step 1: Write the failing client/integration contract test**

```dart
test('guardian can unlink, relink, and child can unlink safely', () async {
  await gateway.linkChild(validCode);
  await gateway.revokeGuardianLink(childId);
  expect(await gateway.relationship(childId), RelationshipStatus.revoked);
  await gateway.linkChild(validCode);
  expect(await gateway.relationship(childId), RelationshipStatus.active);
});
```

- [ ] **Step 2: Implement the SQL RPC**

Use `SECURITY DEFINER`, fixed `search_path`, `auth.uid()` ownership checks, explicit execute grants, and idempotent state transition. Add negative SQL assertions for unrelated users.

- [ ] **Step 3: Generate the verifier's RPC list from client calls**

The contract script must fail if a `.rpc('name')` client call lacks a matching hosted signature/grant.

- [ ] **Step 4: Verify locally and on target Supabase**

```powershell
powershell -File scripts/verify_supabase_migrations.ps1
$taliaTargetTestDbUrl = Read-Host 'Target test database URL'
powershell -File scripts/verify_supabase_contract.ps1 -DatabaseUrl $taliaTargetTestDbUrl
flutter test test/integration/guardian_unlink_contract_test.dart
```

- [ ] **Step 5: Commit**

```powershell
git add supabase/migrations scripts/verify_supabase_contract.ps1 test/integration/guardian_unlink_contract_test.dart lib
git commit -m "fix: restore guardian unlink contract"
```

---

### Task 10: Prevent Bookmark Loss During Sign-Out

**Files:**
- Modify: auth sign-out coordinator/cubit and bookmark sync service discovered by `rg "signOut|dirty.*bookmark" lib`.
- Modify: `lib/features/quran/data/datasources/bookmark_service.dart`
- Create: `test/integration/bookmark_signout_safety_test.dart`

**Interfaces:**
- Produces: One `PendingUserDataGate` covering every dirty domain, with explicit force-sign-out semantics that retain queued data.

- [ ] **Step 1: Write the offline-loss regression test**

```dart
test('offline bookmark blocks ordinary sign-out and survives forced sign-out', () async {
  await bookmarkService.add(approvedBookmark);
  cloud.blockNetwork();
  expect(auth.signOut(), throwsA(isA<AuthSignOutBlockedPendingData>()));
  await auth.forceSignOut();
  expect(await queue.containsBookmarkMutation(), isTrue);
});
```

- [ ] **Step 2: Centralize dirty-domain checks**

Return named pending domains for review records, plans, bookmarks, streaks, XP, activities, Kids, identity, and rewards. Ordinary sign-out blocks until acknowledged; forced sign-out preserves owner-scoped durable queue rows.

- [ ] **Step 3: Test relogin reconciliation**

Assert exactly one cloud bookmark after reconnection and consistent local/cloud revision and tombstone behavior.

- [ ] **Step 4: Verify and commit**

```powershell
flutter test test/integration/bookmark_signout_safety_test.dart test/features/quran
git commit -am "fix: preserve bookmarks across sign-out"
```

---

### Task 11: Make Sync Dead Letters Visible, Recoverable, and Correctly Classified

**Files:**
- Modify: `lib/core/sync/cloud_sync_queue.dart`
- Modify: synchronization coordinator and user-visible sync status Cubit/widget.
- Create: `test/core/sync/dead_letter_recovery_test.dart`

**Interfaces:**
- Produces: `SyncHealth`, `DeadLetterItem`, `recoverDeadLetter`, typed retryability, and UI recovery action.

- [ ] **Step 1: Write state-transition tests**

```dart
test('eight retryable failures become visible and can recover', () async {
  await failRetryably(times: 8);
  expect(await syncHealth.deadLetters(), hasLength(1));
  await syncHealth.recover(deadLetterId);
  expect(await queue.hasPending(), isTrue);
});
```

- [ ] **Step 2: Classify errors before consuming attempts**

Authentication/configuration/schema errors do not burn transient retry attempts. Network/timeout/server-transient errors use bounded exponential backoff. Pull dead letters must wake `resumeIfNeeded` or appear in a visible blocked state.

- [ ] **Step 3: Add user-safe recovery UX and diagnostics**

Show last attempt, affected domain, non-sensitive error code, retry action, and support/export diagnostics action. Never expose tokens, payload content, Quran text, or personal data.

- [ ] **Step 4: Verify and commit**

```powershell
flutter test test/core/sync/dead_letter_recovery_test.dart test/core/sync
git commit -am "fix: surface and recover sync dead letters"
```

---

### Task 12: Queue Parent Rewards and Use Monotonic Merge

**Files:**
- Modify: parent reward repository/gateway, sync kind registry, queue coordinator, cloud mapper.
- Create: `test/integration/parent_rewards_sync_test.dart`

**Interfaces:**
- Produces: Owner-scoped idempotent reward mutation and merge-by-stable-ID semantics.

- [ ] **Step 1: Write offline and conflict tests**

```dart
test('offline reward survives pull and syncs exactly once', () async {
  await rewards.unlockOffline(reward);
  cloud.seedRemote(existingRemoteReward);
  await sync.runAfterReconnect();
  expect(await rewards.all(), containsAll([reward, existingRemoteReward]));
  expect(cloud.writeCount(reward.id), 1);
});
```

- [ ] **Step 2: Add queue kind and idempotency key**

Use stable reward ID + owner ID. Push dirty local transitions, acknowledge only after server success, and union/monotonic-merge on pull rather than wholesale overwrite.

- [ ] **Step 3: Verify and commit**

```powershell
flutter test test/integration/parent_rewards_sync_test.dart test/features/memorization_plus
git commit -am "fix: make parent rewards offline safe"
```

---

### Task 13: Close Database Grants and Make Hosted Schema Verification a Release Gate

**Files:**
- Create: Supabase hardening migration for audit pruning and direct DML revokes.
- Modify: `scripts/verify_supabase_contract.ps1`
- Modify: `.github/workflows/supabase-verify.yml`
- Create: `test/supabase/security_grants_test.dart`

**Interfaces:**
- Produces: RPC-only writes for streak/XP/activity domains and service-role-only audit pruning.

- [ ] **Step 1: Add negative grant assertions**

Assert authenticated users cannot execute `prune_audit_logs` or directly mutate protected tables; approved RPCs remain executable with owner checks.

- [ ] **Step 2: Apply explicit revokes and safe grants**

Every security-definer function uses a fixed search path. Remove stale overloads and orphan trigger functions only after dependency queries prove they are unused.

- [ ] **Step 3: Verify fresh and target databases**

```powershell
powershell -File scripts/verify_supabase_migrations.ps1
$taliaFreshDbUrl = Read-Host 'Fresh verification database URL'
$taliaTargetDbUrl = Read-Host 'Target database URL'
powershell -File scripts/verify_supabase_contract.ps1 -DatabaseUrl $taliaFreshDbUrl
powershell -File scripts/verify_supabase_contract.ps1 -DatabaseUrl $taliaTargetDbUrl
```

- [ ] **Step 4: Commit**

```powershell
git add supabase/migrations scripts .github/workflows/supabase-verify.yml test/supabase
git commit -m "security: enforce production database contracts"
```

**Gate:** G2 passes after Tasks 9-13 and all real-Isar/account-switch/sync integration tests are green.

---

### Task 14: Align STT Privacy, Manual Recall, and Kids Pedagogy

**Files:**
- Modify: speech recognition adapter and V2/Kids Cubits.
- Modify: `lib/core/memorization/v2/recitation_evaluator.dart`
- Modify: privacy policy ARB/copy only if verified platform behavior requires it.
- Create: `lib/core/memorization/assessment/assessment_availability.dart`
- Create: `test/core/memorization/assessment_fallback_test.dart`
- Modify: `test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart`

**Interfaces:**
- Produces: `AssessmentAvailability`, explicit on-device capability state, Adult self-grade fallback, and child-specific evaluator policy.

- [ ] **Step 1: Write unavailable-STT completion tests**

```dart
test('adult and kids sessions remain completable without STT', () async {
  speech.stubUnavailable();
  await session.startRecall();
  await session.selfGrade(PerformanceRating.average);
  expect(session.state, isA<SessionCompleted>());
});
```

- [ ] **Step 2: Request on-device recognition explicitly where supported**

Expose `availableOnDevice`, `permissionDenied`, `languageUnavailable`, and `temporarilyUnavailable`. Do not claim guaranteed local processing unless device behavior proves it.

- [ ] **Step 3: Add manual/self-grade fallback**

Map excellent/average/weak through the same scheduling and XP contracts as successful STT paths. Mark assessment method for analytics without penalizing rewards.

- [ ] **Step 4: Give Kids a distinct reviewed policy**

Inject a child policy rather than using the default 0.92 evaluator. The exact threshold, retry count, wording, and guardian escape hatch must be approved during product/Islamic review and expressed as named constants with tests; no silent bypass or false “perfect recitation” claim.

- [ ] **Step 5: Verify privacy text against observed behavior**

Test on one on-device-capable Android device, one incapable/unprovisioned device, and iOS. Update Arabic/English policy text to state the actual processing and fallback behavior.

- [ ] **Step 6: Verify and commit**

```powershell
flutter test test/core/memorization/assessment_fallback_test.dart test/features/memorization_plus/presentation/cubits/kids_mode_cubit_test.dart
git commit -am "feat: make recitation assessment private and resilient"
```

---

### Task 15: Correct Review Scheduling, Weak Evidence, and Protect-Before-Grow Ordering

**Files:**
- Modify: `lib/features/memorization_plus/domain/entities/ayah_review_record.dart`
- Modify: Isar model/generated migration and cloud mappers.
- Modify: `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart`
- Modify: `lib/core/memorization/smart_coach_engine.dart`
- Modify: `lib/features/memorization_plus/domain/entities/daily_plan.dart`
- Modify: `lib/core/memorization/pending_ayah_resolver.dart`
- Modify: Daily Plan generation/page.
- Create: `docs/product/review-scheduler-contract.md`
- Create: `test/core/memorization/review_contract_test.dart`

**Interfaces:**
- Produces: Versioned `ReviewSchedulerContract`, sufficient grade history, recall-first review intent, and one globally ranked due queue.

- [ ] **Step 1: Freeze the intended scheduler contract in tests**

Document grade mapping, repetition state, first/second intervals, lapse reset, overdue handling, fuzz bounds, maximum intervals, timezone semantics, migration behavior, and FSRS shadow-mode boundary. Do not continue calling custom behavior “SM-2” unless it satisfies the documented contract.

- [ ] **Step 2: Add the minimum history required by product rules**

```dart
final class ReviewAttempt {
  const ReviewAttempt({required this.rating, required this.at, required this.method});
  final PerformanceRating rating;
  final DateTime at;
  final AssessmentMethod method;
}
```

Persist sufficient recent attempts and repetition state. Migrate legacy records deterministically and keep rollback/export capability.

- [ ] **Step 3: Implement the rolling weak rule**

Classify weak only after the required evidence window; add separate “latest attempt weak” UI state if useful, without conflating it with the scheduling classification.

- [ ] **Step 4: Introduce review intent**

Due review starts with hidden-text recall. Listening/learning occurs only after the attempt or explicit remediation request.

- [ ] **Step 5: Build one global review-first plan**

Order weak/overdue/near/far/memorized-due before new ayahs across all surahs. Direct Daily Plan entry, Smart Coach, resume, and Kids/adult navigation must obey the same priority contract.

- [ ] **Step 6: Verify migrations, boundaries, and commit**

```powershell
flutter test test/core/memorization/review_contract_test.dart test/core/memorization/smart_coach_engine_test.dart test/features/memorization_plus
git commit -am "fix: enforce recall first review scheduling"
```

**Gate:** G3 passes after Tasks 14-15 plus clean-device offline Adult/Kids completion tests.

---

### Task 16: Complete Localization, Terminology, Navigation, and Accessibility

**Files:**
- Modify: notification, certificate, tutorial, splash, language tile, and error surfaces identified in the audits.
- Modify: `lib/core/l10n/app_ar.arb`, `lib/core/l10n/app_en.arb`
- Modify: `lib/core/widgets/app_shell.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: Quran reader/list presentation files.
- Create: `test/architecture/presentation_localization_guard_test.dart`
- Create: `test/accessibility/core_journeys_accessibility_test.dart`

**Interfaces:**
- Produces: One ARB-based presentation localization path, agreed Adhkar/Dhikr terminology, four primary product tabs, and enforceable semantics/text-scale behavior.

- [ ] **Step 1: Add localization and duplicate-key gates**

Fail on raw presentation copy outside allowlisted brand/source content, duplicate ARB keys, missing locale parity, and data-layer display sentences.

- [ ] **Step 2: Move remaining copy to ARB and typed error codes**

Pass resolved notification strings into the scheduler. Remove ternary `SocialShareCopy` and map repository failures to codes in presentation.

- [ ] **Step 3: Restore four primary tabs**

Home, Quran, Memorization, and Progress remain primary. Keep Adhkar/Dua as a reviewed secondary Home/More destination with deep links preserved.

- [ ] **Step 4: Add Quran and Kids accessibility contracts**

Test text scale at 1.0/1.3/2.0, semantics labels, focus order, RTL/LTR, narrow width, dark mode, and reduced motion. Add Quran-specific font scaling that does not alter corpus text.

- [ ] **Step 5: Run locale and accessibility suites**

```powershell
flutter gen-l10n
flutter test test/architecture/presentation_localization_guard_test.dart test/accessibility/core_journeys_accessibility_test.dart
dart analyze
git commit -am "feat: complete accessible bilingual product shell"
```

---

### Task 17: Strengthen CI, Real-Service Tests, Performance, and Maintainability

**Files:**
- Modify/Create: `.github/workflows/flutter-ci.yml`
- Modify: streak/XP mirror tests.
- Create: real-Isar streak and XP tests.
- Create: bookmark cloud CAS tests.
- Modify: oversized widgets/cubits only along seams touched by earlier tasks.
- Create: `docs/release/performance-budget.md`

**Interfaces:**
- Produces: Release-critical CI matrix, real persistence verification, measurable startup/reader/session budgets, and smaller reviewed components.

- [ ] **Step 1: Make CI run content validation first**

Matrix includes analyze, unit/widget/integration suites, content validation, Supabase migration history, localization generation/diff, formatting check, and Android release build.

- [ ] **Step 2: Replace mirror tests with real services**

Use temporary real Isar databases for UTC-midnight streak transitions and XP idempotency. Add bookmark push/pull/conflict/tombstone tests against the real mapper and fake remote boundary.

- [ ] **Step 3: Add release-critical end-to-end journeys**

Cover offline Quran read/bookmark/restart, Adult recall/fallback/complete, Kids fallback/complete, due-review reschedule, account switch, queued reconnection, guardian unlink, religious notification navigation, and evidence-preserving share.

- [ ] **Step 4: Profile before decomposition**

Record cold start, first Quran page, page swipe, Daily Plan open, and V2 transition timings on a low/mid-tier Android device. Set explicit budgets from measured healthy behavior, then optimize regressions.

- [ ] **Step 5: Split only touched oversized files**

Extract notification scheduling, certificate content, Daily Plan sections, and Quran options into focused widgets/controllers with their own tests. Do not perform unrelated repository-wide rewrites.

- [ ] **Step 6: Verify and commit in reviewable units**

```powershell
dart format --output=none --set-exit-if-changed lib test tool
dart analyze
flutter test --reporter compact
flutter build apk --release
git add .github test docs/release lib
git commit -m "test: enforce final release quality gates"
```

**Gate:** G4 passes only with zero analyzer issues, zero failing tests, reproducible release build, no content-validator exceptions, and documented device smoke results.

---

### Task 18: Build the Islamic Reviewer Packet and Freeze Release Candidate 1

**Files:**
- Create: `tool/content_validation/export_reviewer_packet.dart`
- Create: `docs/content-review/reviewer-checklist.md`
- Create: `docs/content-review/release-candidate-1.yaml`
- Create: `docs/release/rc1-engineering-evidence.md`
- Test: `test/content/reviewer_packet_test.dart`

**Interfaces:**
- Consumes: Approved-candidate manifests, content records, screenshots, reciter mappings, and G0-G4 evidence.
- Produces: Deterministic reviewer packet and frozen RC identity.

- [ ] **Step 1: Write deterministic export tests**

```dart
test('review packet inventories every religious output exactly once', () {
  final packet = exportReviewerPacket();
  expect(packet.recordIds.toSet(), approvedCandidateRecordIds.toSet());
  expect(packet.quranHash, manifest.item('quran-hafs').sha256);
  expect(packet.unresolvedItems, isEmpty);
});
```

- [ ] **Step 2: Export the packet**

Include every Quran corpus identity/hash, surah/ayah/page/juz/hizb/sajdah invariants, every Adhkar/Dua Arabic text, translation, transliteration, count, tier, citation, grade and grader, all religious UI/notification/share screenshots, reciter-riwayah mapping, and every explicitly disputed item.

- [ ] **Step 3: Provide a reviewer checklist**

The reviewer records pass/fail/comment for exact Quran text and boundaries, audio alignment, tajweed presentation, Adhkar/Dua wording/count/citation/grade, translations/transliterations, Kids/parent framing, reverence, notification/share context, and disagreement disclosure.

- [ ] **Step 4: Freeze RC1**

The export tool writes `appCommit` from `git rev-parse HEAD`, reads the Quran and Adhkar hashes from the validated manifest, computes the manifest and Android/iOS artifact hashes, sets `engineeringGate: passed`, and sets `islamicReview: pending`. It refuses a dirty tree or missing artifact instead of writing a partial RC file.

- [ ] **Step 5: Verify and tag the candidate**

```powershell
dart run tool/content_validation/export_reviewer_packet.dart --rc docs/content-review/release-candidate-1.yaml
flutter test test/content/reviewer_packet_test.dart
git add tool/content_validation/export_reviewer_packet.dart docs/content-review docs/release/rc1-engineering-evidence.md test/content/reviewer_packet_test.dart
git commit -m "release: freeze Islamic review candidate 1"
git tag talia-islamic-review-rc1
```

Do not publish or mark content approved at this step.

---

### Task 19: Process Islamic Review Without Breaking Traceability

**Files:**
- Create per cycle: `docs/content-review/feedback/current-rc-review.yaml`
- Modify only the files explicitly implicated by reviewer findings.
- Create after approval: `docs/content-review/approvals/approved-release.yaml`
- Modify: `assets/data/content_manifest.json` review statuses only after matching approval.

**Interfaces:**
- Consumes: Signed reviewer findings tied to RC hashes.
- Produces: Corrected candidate cycles or a final approval artifact tied to immutable hashes.

- [ ] **Step 1: Record each reviewer finding structurally**

```yaml
findingId: IR-001
recordId: dq1
severity: blocker
decision: change-required
reviewerCommentSource: qualified-reviewer-form
reviewedCorpusSha256Source: release-candidate-manifest
```

`reviewerComment` is copied verbatim from the signed reviewer form and `reviewedCorpusSha256` is copied from the RC manifest by the import command; neither is entered from memory.

- [ ] **Step 2: Correct content only from reviewer-approved source material**

Engineering applies supplied text/metadata or reruns the vetted importer. It does not improvise a religious correction. Add a regression assertion for each finding.

- [ ] **Step 3: Re-run every invalidated gate**

Any content change reruns G1, G4, reviewer packet export, hashes, and full reviewer inspection of affected plus regression scope. Any code-only change reruns G0-G4 and reviewer-facing screenshot diff where presentation changed.

- [ ] **Step 4: Accept approval only when hashes match**

The approval artifact must contain reviewer identity, qualification record/reference, date, decision, reviewed scopes, app commit, manifest hash, corpus hashes, and any disclosed limitations. The publication validator rejects a signature whose hashes differ from the current tree.

- [ ] **Step 5: Commit the matching approval**

```powershell
dart run tool/content_validation/validate_content.dart --require-approved-review docs/content-review/approvals/approved-release.yaml
git add docs/content-review/approvals assets/data/content_manifest.json test
git commit -m "content: record qualified Islamic approval"
git tag talia-approved-release
```

**Gate:** G5 passes only here. A verbal approval or approval of different hashes does not pass.

---

### Task 20: Produce, Verify, and Roll Out the Approved Store Release

**Files:**
- Create: `docs/release/final-release-checklist.md`
- Create: `docs/release/rollback-plan.md`
- Modify: application version/build metadata.
- Modify: store metadata/privacy declarations if actual capabilities changed.

**Interfaces:**
- Consumes: `talia-approved-release` and G0-G5 evidence.
- Produces: Signed store artifacts identical in source/content identity to the approved candidate.

- [ ] **Step 1: Build from the approved tag in a clean environment**

```powershell
git status --short
dart run tool/content_validation/validate_content.dart --require-approved-review docs/content-review/approvals/approved-release.yaml
dart analyze
flutter test --reporter compact
flutter build appbundle --release
flutter build ipa --release
```

- [ ] **Step 2: Verify artifact and source identity**

Record Git SHA, manifest/corpus hashes, Android/iOS artifact hashes, signing identities, dependency lock hash, database migration version, and backend contract result.

- [ ] **Step 3: Run final physical-device smoke tests**

Arabic/English, RTL/LTR, dark/light, large text, clean install, upgrade, offline launch, Quran read/search/bookmark/audio cache, Adult/Kids sessions with and without STT, review reschedule, notifications, sharing, account switch, guardian link/unlink, background sync, and restoration after network loss.

- [ ] **Step 4: Verify store declarations**

Privacy labels must match microphone/STT/network/analytics behavior. Screenshots and descriptions must not overstate AI recitation precision, offline availability, Quran verification, or religious authority.

- [ ] **Step 5: Stage rollout with rollback criteria**

Release to internal testing, then closed testing, then a small production percentage. Pause/rollback on content hash mismatch, Quran render defect, crash-free regression, data loss, sync duplication, STT-blocked completion, or reviewer-reported religious issue.

- [ ] **Step 6: Close the release**

Archive all G0-G6 evidence, reviewer approval, store artifact hashes, migration evidence, known limitations, and monitoring links. Schedule periodic content spot-checks and require a new approval cycle for every religious-content update.

---

## Hifz Experience Target

Current audited score: **67/100**.

RC target: **90+/100**, requiring:

- exact Quran text in every learning surface;
- recall before exposure for due review;
- globally ranked protect-before-grow workload;
- documented and migrated scheduler semantics;
- child-specific assessment policy and recovery;
- offline-completable Adult and Kids sessions;
- understandable progress, streak, and achievement behavior without punitive pressure;
- accessible Quran/Kids flows and clear Coach explanations.

## Final Definition of Done

- All P0/P1, Islamic Blocker/High, data-loss, security, and core offline findings are closed with tests.
- Content manifests and CI hashes match every shipped religious asset.
- No sacred display path alters Quran characters or verse boundaries.
- Every shipped Adhkar/Dua/Hadith-derived record has resolvable evidence and the required grade/tier/review state.
- Quran text, QCF/tajweed presentation, numbering, and every enabled reciter are explicitly aligned to the approved riwayah.
- Analyzer, full tests, release builds, fresh/target database contracts, and clean-device smoke tests pass.
- The qualified Islamic reviewer approves the exact RC hashes and all requested corrections are closed.
- Store artifacts are built from the approved tag and their hashes are recorded.
- Rollback and post-release content-governance processes are documented and tested.

## Self-Review Record

- **Spec coverage:** All findings in both audits and the unified remediation plan are mapped to Tasks 1-20; religious correctness, sourced sajdah/hizb metadata, Hifz, Kids, offline, localization, accessibility, data safety, security, testing, reviewer handoff, and publication are covered. The remediation plan's rejected learning rules were corrected against explicit KB lines before finalization.
- **No placeholders:** Commands use explicit paths and behaviors. Angle-bracket values occur only where execution requires an external reviewer/database/signing value and are named as required inputs rather than implementation gaps.
- **Type consistency:** `ContentEvidence`, `ContentReleasePolicy`, `QuranCorpusIdentity`, `ReviewAttempt`, manifest identities, RC hashes, and approval hashes are introduced before their consumers.
- **Scope control:** New optional religious features, Tafsir, multi-riwayah expansion, prayer-time integration, and broad visual redesign are excluded from this release; current features are completed and governed first.
