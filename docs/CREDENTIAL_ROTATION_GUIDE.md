# Supabase Credential Rotation Guide - Talia (تالية)

> Created: 2026-05-20  
> Reviewed: 2026-05-21  
> Risk Level: HIGH - incorrect rotation breaks user sync.

## Current Status From Code Review

- `.env` is ignored by git via `.gitignore`.
- `git ls-files .env docs` did not report a tracked `.env`.
- `pubspec.yaml` still packages `.env` as a Flutter asset, so builds may expose the Supabase URL/key.
- Rotation is strongly recommended if the current `.env` was shared, included in a build artifact, or ever committed in history.

## Pre-Rotation Checklist

- [ ] Remove `.env` from Flutter packaged assets.
- [ ] Confirm `.env` is not in git history: `git log --all -- .env` should return empty.
- [ ] Confirm built APK/AAB/IPA does not contain `.env`.
- [ ] Confirm `.env` remains in `.gitignore`.
- [ ] Back up current `.env` locally.
- [ ] Schedule rotation during a low-traffic window, for example 2-4 AM Egypt time.

## Rotation Steps

1. Open the Supabase Dashboard.
2. Select the Talia project.
3. Navigate to Settings -> API.
4. Generate a new anon key.
5. Update local and CI secret storage:

```env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY=<paste-new-key-here>
```

## Verify Locally

Run these after the app uses a release-safe config path:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Manual flows:

- [ ] Sign up with a new account.
- [ ] Sign in with an existing account.
- [ ] Sync to cloud.
- [ ] Pull from cloud.
- [ ] Start app without Supabase config and verify offline Quran/Hifz/Azkar still work.

## Deploy

- [ ] Update all build machines and CI secret managers.
- [ ] Produce a build and inspect assets for `.env`.
- [ ] Smoke test auth and sync against the deployed Supabase project.
- [ ] Only then revoke the old anon key.

## If Something Goes Wrong

1. Re-enable or restore the old anon key in Supabase.
2. Restore the previous local/CI secret values.
3. Re-test auth, sync, and offline startup.

## RLS Verification

After rotation, verify:

- Users can only read/write their own data.
- The anon key cannot bypass RLS policies.
- RPC functions such as `upsert_ayah_progress`, `upsert_streak`, `upsert_xp`, and `upsert_daily_activities_batch` still execute only for authenticated users.
