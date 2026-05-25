# CODEX Release Checklist - Talia (تالية)

> Updated: 2026-05-21  
> Basis: current code revalidation against `CODEX_FIX_PLAN.md`.  
> Mode: No app source changes made during this review.

## Current Go / No-Go

Release remains **No-Go**.

The previous plan has only partial supporting work implemented, mostly tests/docs. The production blockers are still present in code: AuthCubit/router lifecycle, unsafe offline Supabase access, `.env` packaged as an asset, missing QR camera permissions, local/UTC date inconsistencies, weak parent PIN storage, incomplete build validation, and placeholder platform identity/signing.

## Verified Done

- [x] Audit docs exist in `docs/`.
- [x] Credential rotation guide exists.
- [x] `.env` is listed in `.gitignore`.
- [x] `git ls-files .env docs` did not show a tracked `.env`.
- [x] AuthCubit unit tests exist.
- [x] Auth repository sync tests exist.
- [x] Progress repository count tests exist.
- [x] QCF proof-of-concept widget test exists.

## Partial / Not Enough For Release

- [ ] Auth tests do not yet cover router redirect ownership or duplicate Cubit creation.
- [ ] Progress tests do not yet cover legacy streak UTC/local boundary behavior.
- [ ] Hifz date handling is only partly UTC; initial progress uses UTC but later review updates still use local `DateTime.now()`.
- [ ] Offline mode has comments and partial config checks, but auth repository access can still touch `Supabase.instance.client` when uninitialized.
- [ ] Previous completed checks (`flutter analyze`, `flutter test`) are historical only; current retry hung and was stopped.

## Hard Blockers

- [ ] Replace `getIt.registerFactory<AuthCubit>()` + static router `getIt<AuthCubit>()` calls with one owned auth controller/listenable.
- [ ] Make app bootstrap safe when `.env` is missing.
- [ ] Guard AuthRepository Supabase access when Supabase is not initialized.
- [ ] Remove `.env` from `pubspec.yaml` assets.
- [ ] Verify `.env` was never committed: `git log --all -- .env`.
- [ ] Rotate Supabase anon key if `.env` was shared, packaged, or committed.
- [ ] Add Android `android.permission.CAMERA`.
- [ ] Add iOS `NSCameraUsageDescription`.
- [ ] Replace debug/example Android application ID and release signing.
- [ ] Replace iOS/Windows `com.example` identifiers.
- [ ] Complete successful Android debug and release builds.
- [ ] Complete successful Windows debug build or drop Windows from release scope.
- [ ] Unify streak/review date behavior before trusting production progress data.

## Verification Commands

- [ ] `dart format --output=none --set-exit-if-changed .` succeeds.
- [ ] `dart format --set-exit-if-changed .` succeeds after source-edit approval.
- [ ] `flutter analyze` succeeds on the current working tree.
- [ ] `flutter test` succeeds on the current working tree.
- [ ] `flutter test --coverage` succeeds on the current working tree.
- [ ] `genhtml coverage/lcov.info -o coverage/html` succeeds after installing `genhtml`.
- [ ] `flutter build apk --debug` completes.
- [ ] `flutter build apk --release` completes.
- [ ] `flutter build windows --debug` completes if Windows remains supported.

## Security

- [ ] `.env` is not packaged in APK/AAB/IPA.
- [ ] `.env` is not present in git history.
- [ ] Supabase anon key is rotated if exposure is possible.
- [ ] Supabase deployed RLS matches `supabase_schema.sql`.
- [ ] RPC execute grants are verified in the deployed Supabase project.
- [ ] Parent-child linking token flow is tested against deployed Supabase.
- [ ] Parent PIN storage is migrated or explicitly documented as convenience-only.
- [ ] Local storage risk is documented for bookmarks, notes, memorization progress, certificates, kids logs, and parent settings.

## Data Integrity

- [ ] Streak updates use one canonical service/date policy.
- [ ] Hifz review updates store and compare dates consistently.
- [ ] MemPlus review records store and compare dates consistently.
- [ ] Hifz legacy progress migration from SharedPreferences to Isar is verified.
- [ ] Smart memorization review records survive app update/migration.
- [ ] Cloud pull never overwrites newer local memorization data.
- [ ] Certificate awards are idempotent.
- [ ] Last-read location is restored only for valid routes.

## Quran / Islamic Content

- [ ] Quran text is not modified by fixes.
- [ ] Ayah numbering remains 1-based per surah.
- [ ] Bismillah handling is verified for Fatiha and non-Fatiha surahs.
- [ ] Page mapping follows the 604-page Hafs Mushaf layout.
- [ ] Tajweed colors remain unchanged.
- [ ] Quran data loading optimization has full integrity tests before implementation.
- [ ] Azkar JSON has schema/count/source validation.
- [ ] Arabic strings are reviewed for respectful wording.

## Platform / UX

- [ ] Android camera/microphone/notification permission prompts work.
- [ ] iOS camera/microphone/speech/photo permission prompts are localized.
- [ ] App orientation settings are consistent across Flutter and iOS plist.
- [ ] Guardian QR scan works on physical Android and iOS devices.
- [ ] Offline Quran reading works with no network and no Supabase config.
- [ ] Audio playback handles uncached, cached, and offline cases gracefully.
- [ ] Hifz audio prefetch is bounded and battery/network safe.
- [ ] Onboarding supports Arabic/English and RTL/LTR directionality.
- [ ] RTL layout is checked on Quran, Hifz, Azkar, Settings, Kids, Certificates.

## Current No-Go Reason

The code is not release-ready because the highest-risk fixes are still open, and the current working tree could not be fully revalidated after the new changes. Treat the existing tests as useful progress, not as release clearance.
