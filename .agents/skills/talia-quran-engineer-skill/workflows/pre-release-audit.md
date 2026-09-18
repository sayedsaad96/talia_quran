# Pre-Release Audit

1. Refresh official current target SDK/platform/store/privacy requirements that apply to this release.
2. Run analyzer/tests and the relevant release build.
3. Smoke critical Quran, reading restore, audio, memorization/revision, auth/backend, notifications, deep-link, offline and migration flows affected by the release.
4. Check permissions, background behavior, privacy disclosures, account deletion where applicable, signing/build variants, and Supabase/client compatibility.
5. Verify upgrade from an existing install/data state when persisted state changed.
6. Report `Release Verified` only for gates actually run; list remaining items as `not verified`.
