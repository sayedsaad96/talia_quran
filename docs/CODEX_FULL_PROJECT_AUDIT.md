# CODEX Full Project Audit - Talia (تالية)

> Original audit date: 2026-05-21  
> Revalidated against current code: 2026-05-21  
> Mode: Audit Mode only  
> Source changes by this pass: none; docs only.

---

## 1. Executive Summary

Talia is a Flutter Quran reading, Hifz memorization, Azkar, kids learning, certificates, progress, and Supabase sync app using Cubit/BLoC and a Clean Architecture style. The current health score is **6.4/10**: the codebase has meaningful test additions since the initial audit, but most production fixes from `CODEX_FIX_PLAN.md` are still not implemented in runtime code. The largest remaining risk is still auth/bootstrap/data integrity: static router code creates independent `AuthCubit` instances through DI, offline Supabase startup is not truly safe, `.env` is still packaged as an asset, and streak/review dates still mix local time and UTC. Top priorities: fix auth/router/offline Supabase safely, remove `.env` from packaged assets and rotate credentials if exposed, then add tests before touching streak, review scheduling, Quran data, or persistence logic.

## 2. Critical Bugs 🔴

- `[lib/core/router/app_router.dart:107, lib/core/router/app_router.dart:109, lib/core/di/injection.dart:425, lib/app.dart:81] AuthCubit/router lifecycle still not fixed — Impact: protected-route redirects can use different factory-created AuthCubit instances than the UI tree, causing unreliable auth redirects and leaked auth subscriptions — Root cause: `AuthCubit` is registered as a factory and resolved ad hoc inside a static GoRouter while `TaliaApp` also creates its own provider — Suggested fix: create one owned auth controller/listenable and inject it into router/app consistently — Test strategy: route guard tests, login/logout redirect tests, and verification that only one auth stream subscription is active.`
- `[lib/main.dart:63, lib/main.dart:89-105, lib/features/auth/data/repositories/auth_repository_impl.dart:28-43] Offline Supabase startup remains unsafe — Impact: missing `.env` or skipped `Supabase.initialize` can still crash when auth code reads `Supabase.instance.client` — Root cause: `dotenv.load(fileName: '.env')` is not optional, and `AuthRepositoryImpl.currentUser` / `authStateChanges` do not guard uninitialized Supabase — Suggested fix: make dotenv loading optional and add a Supabase availability abstraction or guarded auth repository fallback — Test strategy: bootstrap and auth repository tests with no `.env` and no Supabase initialization.`
- `[pubspec.yaml:119] `.env` is still included as a Flutter asset — Impact: builds can expose Supabase URL/key even though `.env` is ignored by git — Root cause: `pubspec.yaml` still lists `- .env` under assets — Suggested fix: remove `.env` from assets, inject config through release-safe build/CI secrets, and inspect build artifacts — Test strategy: inspect APK/AAB/IPA assets and run auth/offline smoke tests.`
- `[android/app/src/main/AndroidManifest.xml:1-11, ios/Runner/Info.plist:5-10] Guardian QR scanner permissions are still missing — Impact: `mobile_scanner` guardian linking may fail on device or fail app review — Root cause: no Android `CAMERA` permission and no iOS `NSCameraUsageDescription` — Suggested fix: add localized camera permission entries — Test strategy: real-device Android/iOS QR linking flow.`
- `[lib/features/progress/data/repositories/progress_repository_impl.dart:127, lib/features/progress/data/repositories/progress_repository_impl.dart:199, lib/features/hifz/data/models/ayah_progress_model.dart:47, lib/features/hifz/data/models/ayah_progress_model.dart:70, lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart:211] Streak/review date policy is still mixed — Impact: streaks and due reviews can shift around midnight/timezone boundaries, risking incorrect user progress — Root cause: multiple services/repositories use local `DateTime.now()` while others use UTC — Suggested fix: define one canonical clock/date policy and migrate carefully — Test strategy: fixed-clock timezone tests for Cairo/UTC and migration rollback samples.`

## 3. High Priority Issues 🟠

- `[android/app/build.gradle.kts:9, android/app/build.gradle.kts:25, android/app/build.gradle.kts:38, ios/Runner.xcodeproj/project.pbxproj, windows/runner/Runner.rc:92-99] Platform identity/signing are still placeholders — Impact: store release cannot be trusted — Root cause: Android/iOS/Windows still use `com.example` IDs and Android release signing still uses debug config — Suggested fix: set final bundle IDs, signing, package path if needed, and Windows metadata — Test strategy: signed build, install, and upgrade test.`
- `[lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:805, lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:817, lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:1104] Parent PIN remains unsalted SHA-256 — Impact: a local 4-digit PIN hash is trivial to brute force — Root cause: low-entropy secret stored as a fast unsalted hash in SharedPreferences-backed models — Suggested fix: migrate to secure storage/slow salted verification or explicitly document it as a convenience gate — Test strategy: migration and verification tests for existing `pinHash`.`
- `[lib/core/services/audio_cache_service.dart:53-75, lib/features/hifz/presentation/cubits/hifz_session_cubit.dart:190-193] Hifz audio prefetch still downloads the whole session — Impact: large sessions can trigger excessive network/battery usage — Root cause: `HifzSessionCubit` maps every ayah into `prefetchSession` — Suggested fix: prefetch current + next N ayahs and continue progressively — Test strategy: fake cache manager/cubit test asserting bounded request count.`
- `[lib/features/quran/presentation/pages/quran_reader_page.dart:460-461, lib/core/services/audio_cache_service.dart:83-90] Quran ayah playback still calls `play()` twice — Impact: duplicate player calls can cause flaky playback — Root cause: helper plays after setting source, caller plays again — Suggested fix: remove one call and define helper responsibility clearly — Test strategy: mock player interaction test.`
- `[lib/features/quran/data/datasources/quran_local_datasource.dart] Quran JSON loading optimization remains open — Impact: first page/search can be heavier than necessary — Root cause: full-corpus parsing/cache path remains unchanged — Suggested fix: only after integrity tests, split/index page data or lazy-load safely — Test strategy: 114-surah/6236-ayah/604-page integrity suite and representative golden checks.`
- `[build validation] Current Android/Windows build confidence is incomplete — Impact: release readiness is unknown — Root cause: previous Android debug build hung; Windows build was not approved; current `flutter analyze`/`flutter test` retry hung and was stopped — Suggested fix: clean tooling state, run commands sequentially, then add CI — Test strategy: successful clean debug/release builds.`

## 4. Medium Priority Issues 🟡

- `[lib/features/onboarding/presentation/pages/onboarding_page.dart:54-173] Onboarding still uses hardcoded Arabic and physical direction assumptions — Impact: English localization and RTL/LTR parity are incomplete — Root cause: strings bypass ARB and UI uses `Alignment.topLeft` / forward arrow icons directly — Suggested fix: move strings to ARB and use directional layout/icons — Test strategy: Arabic/English widget tests and RTL screenshot check.`
- `[ios/Runner/Info.plist:5-10, ios/Runner/Info.plist:62-74, lib/main.dart:71-75] iOS permission copy/orientation still inconsistent — Impact: app polish and review risk — Root cause: speech/microphone prompts are English and iOS allows landscape while Flutter locks portrait — Suggested fix: localized copy and orientation alignment — Test strategy: iOS permission/rotation smoke test.`
- `[android/app/src/main/AndroidManifest.xml:5-7] Bluetooth permissions remain unexplained — Impact: unnecessary permission surface can reduce store trust — Root cause: likely leftover permissions — Suggested fix: remove unless a concrete feature requires them — Test strategy: Android permission audit and QR/audio regression.`
- `[test/features/auth/**, test/features/progress/**] New tests exist but are not enough — Impact: they help but do not prove high-risk fixes — Root cause: tests focus on Cubit transitions and progress counts, not router ownership/offline bootstrap/streak UTC boundaries — Suggested fix: add targeted failing tests before implementation — Test strategy: router lifecycle, no-Supabase boot, and fixed-clock tests.`
- `[formatting/tooling] Formatter gate still fails — Impact: CI/release hygiene blocked — Root cause: unformatted files, `scripts/test_surahs.dart` UTF-8 decode failure, and missing cached `very_good_analysis` analysis options — Suggested fix: restore package cache / run `flutter pub get`, fix script encoding, then format after source-edit approval — Test strategy: `dart format --output=none --set-exit-if-changed .` exits 0.`

## 5. Low Priority / Improvements 🟢

- Document whether `third_party/mobile_scanner/**` is intentionally vendored and how updates are managed.
- Optimize large image assets before release.
- Exclude generated localization/Isar files from coverage reporting where appropriate.
- Complete crash reporting implementation before production.
- Keep monetization/subscription stubs hidden until fully implemented.

## 6. UX / UI Problems

- QR scanner cannot be trusted on real devices until camera permissions are added.
- Onboarding is still Arabic-only and not true localization.
- Android/iOS app display names are still `Talia`, not localized to `تالية`.
- iOS permission prompts are partly English while the app is Arabic-first.
- Several screens still use physical left/right visual assumptions.
- QCF rendering has tests but no golden/screenshot coverage across representative Mushaf pages, small screens, and dark mode.

## 7. Architecture Problems

- Static router code reaches into DI for a factory Cubit, which is the most important architecture issue still open.
- Supabase is accessed through `Supabase.instance.client` inside repositories, making offline/test modes fragile.
- Streak logic exists in both `StreakService`/Isar and legacy progress SharedPreferences paths.
- Some repositories still mix direct SharedPreferences-style persistence with repository responsibilities.
- Date policy is not centralized through a clock abstraction.
- The repo uses `lib/core/router` and `lib/core/di` rather than the AGENTS reference `lib/config/router` and `lib/config/di`; avoid migration unless explicitly approved.

## 8. Testing Gaps

Supporting tests now exist for AuthCubit, auth sync, progress counts, MemPlus/guardian, QCF POC, and some services. These are useful but do not close the release gaps.

Still missing or insufficient:

- Router redirect and single-auth-controller lifecycle tests.
- No-Supabase / missing `.env` bootstrap tests.
- Legacy `ProgressRepositoryImpl` streak UTC/local boundary tests.
- Hifz session cubit behavior tests, including prefetch bounds and review transitions.
- MemPlus review scheduling fixed-clock tests.
- Quran full integrity tests: 114 surahs, 6236 ayahs, 604 pages, juz/hizb boundaries, ayah numbering.
- QR scanner platform permission/device tests.
- Notification scheduling regression tests.
- Build validation in CI.

Previous completed audit evidence reported `189` tests passing and 11.4% coverage. This revalidation did not complete a fresh `flutter analyze` / `flutter test` run because the current retry hung and was stopped, so the previous result should be treated as historical, not proof of the current dirty tree.

## 9. Security / Data Risks

- `.env` is ignored by git but still packaged by Flutter assets.
- `.env` was not reported by `git ls-files`, but git history still needs `git log --all -- .env`.
- Parent PIN is weakly hashed and stored locally.
- Local bookmarks, progress, certificates, parent settings, pairing sessions, and kids logs need a documented storage-risk decision.
- Supabase deployed RLS was not verified against the live project.
- Android release signing still uses debug config.
- QR camera permission absence can break guardian linking security/usability expectations.

## 10. Performance Issues

- Full Quran data loading optimization remains open.
- Hifz audio prefetch can still request entire sessions/surahs.
- Achievement/certificate checks can scan broad progress data.
- Progress page derives some counts by loading pages individually.
- Large assets should be compressed.
- Broad dashboard/Quran/Hifz rebuilds should be profiled after blockers.

## 11. Step-by-Step Fix Plan

1. Add failing tests for auth/router lifecycle and no-Supabase startup. Files: `test/core/router/**`, `test/features/auth/**`. Risk: Low. Approval: source-test edit approval required.  
2. Remove `.env` from packaged assets and make config loading optional. Files: `pubspec.yaml`, `lib/main.dart`. Risk: Medium. Approval: required.  
3. Fix AuthCubit/router ownership. Files: `lib/core/di/injection.dart`, `lib/core/router/app_router.dart`, `lib/app.dart`. Risk: High. Approval: required.  
4. Guard AuthRepository against uninitialized Supabase. Files: `lib/features/auth/data/repositories/auth_repository_impl.dart`. Risk: High. Approval: required.  
5. Add QR camera permissions and localized copy. Files: Android manifest, iOS plist. Risk: Low. Approval: required for source/platform edits.  
6. Remove duplicate audio play and bound Hifz prefetch. Files: `audio_cache_service.dart`, `quran_reader_page.dart`, `hifz_session_cubit.dart`. Risk: Low/Medium. Approval: required.  
7. Add streak/review fixed-clock tests, then unify date policy. Files: progress, Hifz, MemPlus date logic. Risk: High. Approval: required.  
8. Replace or downgrade parent PIN storage. Files: MemPlus repository/datasource/models/tests. Risk: Medium. Approval: required.  
9. Set production identifiers/signing/metadata. Files: Android/iOS/Windows platform configs. Risk: Medium. Approval: required.  
10. Add Quran integrity tests before any Quran data loading optimization. Files: Quran tests/datasource only after approval. Risk: High. Approval: required.

## 12. Safe Implementation Order

**Phase 1 - Tests and tooling**

- Router/auth lifecycle tests.
- No-Supabase startup tests.
- Streak/review fixed-clock tests.
- Fix formatter blockers after source-edit approval.

**Phase 2 - Low-risk runtime/platform**

- Camera permissions.
- Duplicate audio play removal.
- Bounded audio prefetch.
- Onboarding localization/directional layout.

**Phase 3 - Medium-risk release readiness**

- `.env` asset removal and optional config loading.
- Parent PIN migration or downgrade.
- Platform IDs/signing/metadata.
- Build validation.

**Phase 4 - High-risk core/data**

- Auth/router lifecycle implementation.
- Offline Supabase semantics.
- Streak/review scheduling unification.
- Quran data loading changes only after integrity tests.

## 13. Files Likely Affected

Phase 1:

- `test/core/router/**`
- `test/features/auth/**`
- `test/features/progress/**`
- `test/features/hifz/**`
- `test/features/memorization_plus/**`
- `scripts/test_surahs.dart`

Phase 2:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `lib/core/services/audio_cache_service.dart`
- `lib/features/quran/presentation/pages/quran_reader_page.dart`
- `lib/features/hifz/presentation/cubits/hifz_session_cubit.dart`
- `lib/features/onboarding/presentation/pages/onboarding_page.dart`
- ARB/l10n files

Phase 3:

- `pubspec.yaml`
- `lib/main.dart`
- `.env.example` / release config files
- `lib/features/memorization_plus/data/datasources/memorization_plus_local_datasource.dart`
- `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`
- `lib/features/memorization_plus/data/models/memorization_models.dart`
- `android/app/build.gradle.kts`
- iOS project bundle config
- `windows/runner/Runner.rc`

Phase 4:

- `lib/core/di/injection.dart`
- `lib/core/router/app_router.dart`
- `lib/app.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/features/progress/data/repositories/progress_repository_impl.dart`
- `lib/core/services/streak_service.dart`
- `lib/features/hifz/data/models/ayah_progress_model.dart`
- `lib/features/memorization_plus/domain/usecases/memorization_plus_usecases.dart`
- `lib/features/memorization_plus/domain/entities/memorization_entities.dart`
- Quran datasource/rendering files only with explicit Quran approval.

## 14. Pre-Production Risks

If shipped today, the app can still expose packaged backend config, fail guardian QR scanning, use example/debug platform identity/signing, create inconsistent auth router state, and record review/streak data inconsistently around timezone boundaries. The current working tree also could not be fully revalidated in this pass because `flutter analyze` / `flutter test` hung and had to be stopped. Before release, clear the auth/offline/config/platform blockers, add high-risk tests, run clean builds, verify Supabase deployment/RLS, and rerun the full command suite sequentially.

## Current Revalidation Command Notes

### `dart format --output=none --set-exit-if-changed .`

Result: failed.

```text
Changed lib\core\services\achievement_service.dart
Changed lib\core\widgets\ayah_listen_button.dart
Changed lib\core\widgets\qcf_hifz_verse_view.dart
Changed lib\features\hifz\data\models\isar_ayah_progress.g.dart
Changed lib\features\memorization_plus\domain\entities\memorization_entities.dart
Changed lib\features\memorization_plus\presentation\pages\quiz_page.dart
Hit a bug in the formatter when formatting scripts\test_surahs.dart.
FileSystemException: Failed to decode data using encoding 'utf-8', path = '.\scripts\test_surahs.dart'
Changed test\features\auth\data\repositories\auth_repository_sync_test.dart
Changed test\features\auth\presentation\cubits\auth_cubit_test.dart
Changed test\features\auth\presentation\cubits\auth_cubit_test.mocks.dart
Changed test\features\memorization_plus\presentation\cubits\guardian_linking_cubit_test.mocks.dart
PathNotFoundException: Cannot open file, path = 'C:\Users\SayedSaad\AppData\Local\Pub\Cache\hosted\pub.dev\very_good_analysis-10.1.0\lib\analysis_options.yaml'
```

### `flutter analyze`

Current retry: started, hung for several minutes, and was stopped. Previous completed audit baseline: `No issues found!`.

### `flutter test`

Current retry: started while another Flutter command held the startup lock, then hung and was stopped. Previous completed audit baseline: `189` tests passed.

### Build commands

No new successful Android or Windows build was completed during this revalidation.
