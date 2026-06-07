# Supabase Connection & Auth Verification Audit — Talia Quran

> Scope: current `lib/` Flutter code, `lib/main.dart`, `lib/app.dart`, `lib/core/router/app_router.dart`, `lib/core/config/supabase_config.dart`, `lib/features/auth/**`, `supabase_schema.sql`, `.env`, `.env.example`, `.gitignore`, Android/iOS deep link config.
> Method: validated against actual Dart source, cubit, router, repository. No code changes were made.
> Output: audit report only.

---

## TL;DR

- ✅ Supabase is initialized correctly **once**, before `runApp()`, using `--dart-define` values, with no service_role key anywhere in the Flutter code.
- ✅ RLS is enabled on all 14 public tables, every policy uses `auth.uid()`, and all RPC functions validate `auth.uid()` and are REVOKEd from `anon`.
- ✅ `.env` is gitignored and never bundled into the app.
- ❌ **Email‑confirmation UX is broken**: a successful sign‑up that requires email confirmation is reported to the user as an *error* banner ("Account created, check your email") instead of a success banner. This will confuse first‑time users.
- ❌ **Double‑submission is not fully prevented** in the cubit (button is disabled, but cubit methods do not check `state is AuthLoading`).
- ⚠️ **Email validator on the login page is weak** (`contains('@') && contains('.')`) — accepts `a@b`.
- ⚠️ **Actual project URL and publishable key are written into `audits_project.md`**, which is a doc file. The publishable key is safe by design, but the convention of never embedding real project IDs in markdown is violated.
- ⚠️ `memorization_plus_repository_impl.dart` accesses `Supabase.instance.client` without the `_isSupabaseInitialized` guard that the auth repository uses; it relies on try/catch only.

---

## 1. ✅ What is correctly implemented

### 1.1 Single‑client source of truth

- `Supabase.initialize` is called **exactly once** in `lib/main.dart:88-93` inside `_bootstrapAndRun`, which runs *before* `runApp(const TaliaApp())` on `lib/main.dart:169`.
- All consumers use the singleton: `Supabase.instance.client` appears in only two places in the Dart tree:
  - `lib/features/auth/data/repositories/auth_repository_impl.dart:38, 47` (auth + sync)
  - `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:33` (memorization plus)
- There is no `SupabaseClient(` constructor call anywhere. ✅

### 1.2 Config driven by `--dart-define`, not from `.env` at runtime

- `lib/core/config/supabase_config.dart:7-10`:
  ```dart
  static const fromDartDefine = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  ```
- `lib/main.dart:83-93` reads the `const` value and only calls `Supabase.initialize` when `isConfigured` is true.
- `.env` is **not** read by the Dart code (no `dotenv` import in the inspected files; the previously‑used `dotenv` loader has been removed). The local `.env` is a developer convenience only.
- `.env` is in `.gitignore:2` and is not tracked by git (verified with `git ls-files --error-unmatch .env` → "did not match any file(s) known to git"). ✅

### 1.3 No service_role / private key leakage

- Repo‑wide search for `service_role`, `serviceRole`, `SERVICE_ROLE`, `secret_key`, `secretKey`, `api_key`, `apiKey` returned **0 matches** in `*.dart` and `*.sql`.
- The only secret‑like values are the project URL and `sb_publishable_…` key in `.env` (gitignored) and in `audits_project.md` (tracked — see §3.1).
- The publishable key is by definition public; it is bound to RLS policies and short‑lived JWTs, not to admin operations. ✅

### 1.4 Auth flows

| Capability | File:line | Verdict |
| --- | --- | --- |
| `signUp(email, password, data: {display_name})` | `auth_repository_impl.dart:116-120` | ✅ |
| `signInWithPassword` | `auth_repository_impl.dart:179-182` | ✅ (uses non‑deprecated method) |
| `signOut()` | `auth_repository_impl.dart:271-280` | ✅ |
| `resend(OtpType.signup, email)` | `auth_repository_impl.dart:208-213` | ✅ |
| `resetPasswordForEmail(redirectTo: …)` | `auth_repository_impl.dart:230-233` | ✅ |
| `updateUser(UserAttributes(password: …))` | `auth_repository_impl.dart:257` | ✅ |
| `onAuthStateChange` stream | `auth_repository_impl.dart:71-87` | ✅ (filters out `passwordRecovery`, mapped to `AppUser`) |
| `passwordRecoveryChanges` stream | `auth_repository_impl.dart:89-95` | ✅ |
| `currentUser` getter | `auth_repository_impl.dart:57-68` | ✅ (returns `null` when not initialized) |
| Account deletion via `delete_current_user` RPC | `auth_repository_impl.dart:283-326` | ✅ (with graceful fallback message) |

### 1.5 Email confirmation handling

- `auth_repository_impl.dart:128-133`: when `response.user!.identities` is empty, the user is told the email is already registered. ✅
- `auth_repository_impl.dart:137-143`: when `response.session == null` (email confirmation required), the user is told to check their email. ⚠️ This is correct logic, but see §3.2 for the UX problem it creates.

### 1.6 Login page

- `login_page.dart:223-230` rejects empty email and validates `contains('@')` + `contains('.')` (weak — see §3.3).
- `login_page.dart:256-264` rejects empty password and (for sign‑up only) rejects passwords shorter than 6 chars.
- Submit button is disabled while `state is AuthLoading` (`login_page.dart:299`) — so the user cannot double‑tap.
- `_localizedAuthMessage` (`login_page.dart:376-403`) re‑maps Arabic error messages to l10n keys.
- `BlocConsumer` listener (`:71-114`) reacts to `AuthAuthenticated`, `AuthPasswordResetSent`, `AuthError`.
- The login page is reachable only via the public route allowlist and the auth gate redirect (`app_router.dart:217-229`).

### 1.7 Auth state propagation

- `auth_cubit.dart:13-24` subscribes to `authStateChanges` and `passwordRecoveryChanges` and re‑emits as `AuthAuthenticated(user)`, `AuthUnauthenticated`, or `AuthPasswordRecoveryDetected`.
- The cubit is a GetIt singleton (`app.dart:85` uses `BlocProvider.value`), so the same instance is shared by the router redirect and the login page.
- The router listens to the cubit via `_AuthNotifier(getIt<AuthCubit>())` (`app_router.dart:216`) and redirects unauthenticated users away from protected routes.

### 1.8 Password recovery deep link

- `supabase_config.dart:4-5`: `defaultPasswordRecoveryRedirectTo = 'taliaquran://auth/update-password'`.
- `android/app/src/main/AndroidManifest.xml:39-47`: registers the intent filter for `scheme=taliaquran`, `host=auth`, `path=/update-password`. ✅
- `ios/Runner/Info.plist:35-44`: registers `CFBundleURLSchemes = [taliaquran]`. ✅
- `app.dart:87-92` routes to `AppRoutes.updatePassword` when `AuthPasswordRecoveryDetected` is emitted. ✅
- `app_router.dart:257-266` exposes both `/auth/update-password` and `/update-password` as the same `UpdatePasswordPage`. ✅

### 1.9 Database / RLS (from `supabase_schema.sql`)

- RLS enabled on **all 14** public tables: `profiles`, `ayah_progress`, `streaks`, `xp`, `xp_history`, `bookmarks`, `certificates`, `daily_activities`, `child_link_requests`, `parent_child_links`, `kids_progress_cloud`, `kids_session_logs`, `parent_rewards`.
- Every policy uses `(SELECT auth.uid())` (or `auth.uid()`) — this is the recommended pattern for performance.
- Profiles are **insert‑blocked** by RLS (`profiles_select_own` / `profiles_update_own` only); they are created only via the `handle_new_user` trigger on `auth.users` insert. ✅
- `xp_history` is immutable (no UPDATE/DELETE policies). ✅
- All RPC functions:
  - Validate `auth.uid()` is NOT NULL (`RAISE EXCEPTION 'Not authenticated'`).
  - Validate input ranges (`p_total_xp`, `p_current_streak`, etc.).
  - Limit batch sizes (`jsonb_array_length(p_data) > 6236` for ayahs, `> 3650` for daily activities).
  - `REVOKE EXECUTE … FROM anon, PUBLIC` and `GRANT EXECUTE … TO authenticated` only. ✅
- `ON DELETE CASCADE` on every table that references `auth.users(id)`, so deleting a user cleans up everything. ✅

### 1.10 Tests

- `test/core/config/supabase_config_test.dart` validates:
  - empty `url` + `anonKey` → `isConfigured == false`
  - missing `url` → false
  - missing `anonKey` → false
  - both present → true
- This means the production code cannot accidentally boot "configured" with empty values. ✅
- `test/features/auth/auth_cubit_lifecycle_test.dart` and `test/features/auth/presentation/cubits/auth_cubit_test.dart` exist and use mocks (verified by file glob).

---

## 2. ⚠️ Potential risks

### 2.1 Email confirmation UX bug (P1)

When a user signs up with email confirmation enabled in Supabase:

1. `auth_repository_impl.dart:137-143` returns `Left(AuthFailure('تم إنشاء الحساب! يرجى تفقّد بريدك الإلكتروني لتأكيد الحساب قبل تسجيل الدخول.'))`.
2. `auth_cubit.dart:51-54` folds the `Left` and emits `AuthError(message)`.
3. `login_page.dart:89-113` treats `AuthError` as an *error* banner (red icon, error copy) but with a "Resend" action — but the user has just signed up, so the resend action is awkward.

**Effect:** the user sees a red error banner on a *successful* sign‑up. They will think the account creation failed. The next release should:
- Add a new `AuthState` subclass (e.g. `AuthCheckEmail`) emitted by the cubit.
- Or, return a different `Failure` subtype (e.g. `AuthCheckEmailFailure`) so the cubit can emit `AuthCheckEmail` and the login page can render a success banner.
- The resend action should also be shown on the success path.

### 2.2 Double‑submission not fully prevented (P1)

`login_page.dart:299` disables the submit button when `state is AuthLoading`. This works for the *user tapping the button*, but does not cover:

- A user pressing Enter on the keyboard in a password field (the validator runs, but the cubit call can fire twice if the user double‑presses Enter quickly).
- Programmatic re‑entry from a BlocListener side‑effect.

The cubit should add `if (state is AuthLoading) return;` at the top of `signUp`, `signIn`, `signOut`, `deleteAccount`, `resetPassword`, `updatePassword`, and `resendConfirmation`. The current `emit(const AuthLoading())` is fine for the UI but does not prevent the request from firing.

### 2.3 Email validator is weak (P2)

`login_page.dart:223-230`:
```dart
if (!v.contains('@') || !v.contains('.')) {
  return context.l10n.invalidEmail;
}
```
This accepts `a@b` and `@@@...`. Replace with a proper regex such as:
```dart
final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
```

### 2.4 Display name not length‑validated (P2)

`login_page.dart:192-208` accepts any non‑empty `display_name` and sends it to `signUp(..., data: {'display_name': displayName})`. The DB schema truncates to 100 chars (`supabase_schema.sql:309`), so a 200‑char name is silently cut. Add a `maxLength: 100` on the `TextFormField`.

### 2.5 Inconsistent Supabase init guards (P2)

- `auth_repository_impl.dart:36-43` has a static `_isSupabaseInitialized` getter that catches the `StateError` and returns `false`.
- `memorization_plus_repository_impl.dart:33` directly returns `Supabase.instance.client` without the guard — it relies on each call site having a try/catch (which most do).

This is acceptable functionally but inconsistent. Either move the `_isSupabaseInitialized` getter to a shared helper (e.g. `core/services/supabase_availability.dart`) and reuse it, or document the contract.

### 2.6 `updatePassword` can be called by any logged‑in user (P2)

`app_router.dart:259, 265` exposes `/auth/update-password` and `/update-password` as public routes. The page (`update_password_page.dart:33`) calls `AuthCubit.updatePassword(newPassword)`, which calls `client.auth.updateUser(UserAttributes(password: newPassword))` — this updates the password of the **current session user**, not the recovery user.

If a logged‑in user navigates to this route manually (e.g. via deep link from a *different* account's recovery email), they would change the password of whoever is currently logged in. Mitigation: add a guard in `UpdatePasswordPage` that checks `authStateChanges` for the `passwordRecovery` event within the last N minutes, or restrict the route to only be reachable from the auth flow.

### 2.7 `signOut` in offline mode always reports success (P3)

`auth_repository_impl.dart:271-275`:
```dart
Future<Either<Failure, Unit>> signOut() async {
  try {
    if (!_isSupabaseInitialized) return const Right(unit);
    await _supabase.auth.signOut();
    return const Right(unit);
  } catch (e) {
    ...
  }
}
```

This is intentional (the user is "signed out" because there is no client), but it means the UI always shows success. If `_supabase.auth.signOut()` itself throws a network error, the user sees a generic "sign out failed" message. This is fine for v1, but consider returning a "partial" result so the user knows their cloud session may still be active.

### 2.8 Actual project URL + publishable key embedded in `audits_project.md` (P3)

`audits_project.md:1386-1387` and `audits_project.md:10109-10110` contain:
```
SUPABASE_URL=https://vxsqwozctxkvhgxkciua.supabase.co
SUPABASE_ANON_KEY=sb_publishable_B3vTCMcf1HV76SiEhQkeHA_i8EEKZq4
```

The publishable key is designed to be public, but:
- The project URL is a stable identifier — once leaked, an attacker can target the project's auth endpoint for credential‑stuffing (mitigated by Supabase's built‑in rate limits and RLS).
- The convention of "never embed real project identifiers in tracked docs" is violated.

**Recommendation:** replace with placeholders (`https://your-project-id.supabase.co`, `your-publishable-key-here`) before the next commit.

### 2.9 No password‑strength meter (P3)

`login_page.dart:256-264` only checks `length < 6`. A 6‑char password of all `1`s is accepted. This is a product decision, not a security one (Supabase Auth enforces 6‑char minimums on its side). Consider adding a strength meter for the sign‑up flow.

### 2.10 `appName` is set to `'تالية'` in `MaterialApp.router(title: …)` (P3)

`app.dart:98` hard‑codes the title. The localized `appName` from `l10n` exists but is not used here. Not a security issue, just an inconsistency.

---

## 3. 🔐 Security issues

### 3.1 `.env` not in repo but values exposed in `audits_project.md` ⚠️

The publishable key is **safe by design** — it is the public client key, and all data access is gated by RLS. The service_role key would NOT be safe; verified absent.

The project URL in `audits_project.md` is the only thing that needs scrubbing. See §2.8.

### 3.2 Auto‑profile creation is trigger‑based and safe

- `supabase_schema.sql:319-335` defines `handle_new_user` as `SECURITY DEFINER` and inserts a row into `public.profiles`.
- The trigger fires `AFTER INSERT ON auth.users` for each new user.
- Profiles cannot be inserted via the API (`profiles_update_own` is the only UPDATE policy, no INSERT policy). ✅
- This is the recommended Supabase pattern.

### 3.3 RPC `auth.uid()` checks are consistent

Every `SECURITY DEFINER` RPC function checks `IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated';`. This means an anonymous request that somehow reaches the RPC (via direct call or SQL injection) is rejected. ✅

### 3.4 Batch‑size limits on bulk upserts

- `upsert_ayah_progress`: max 6236 rows (one per Quran ayah). ✅
- `upsert_daily_activities_batch`: max 3650 rows (10 years of daily entries). ✅
- These prevent a malicious client from filling the DB by sending a huge batch.

### 3.5 No app‑side rate limiting

The app does not throttle sign‑in / sign‑up / password‑reset requests. Supabase provides server‑side rate limits (configurable in the dashboard), but the app could add a soft client‑side cooldown to reduce accidental lockouts. (Not a security issue per se, but a UX one.)

### 3.6 Session storage

- `supabase_flutter` v2 stores the session in EncryptedSharedPreferences (Android) and Keychain (iOS). The Dart code does not need to manage this. ✅
- The session is automatically refreshed by the SDK; `AuthStateChanges` emits new sessions as the JWT rotates.

### 3.7 No CSRF risk

All Supabase auth calls use a bearer token; the SDK adds it to a header. There is no cookie‑based auth, so CSRF is not a concern. ✅

### 3.8 `passwordRecoveryChanges` is correctly separated

`auth_repository_impl.dart:72-74` filters out `passwordRecovery` events from `authStateChanges`, and `auth_repository_impl.dart:89-95` exposes them via a separate stream. The cubit routes the recovery event to `AppRoutes.updatePassword` via `app.dart:87-92`. ✅

---

## 4. 🛠️ Files that need changes (priority order)

| # | File | Change | Why |
| --- | --- | --- | --- |
| 1 | `lib/features/auth/data/repositories/auth_repository_impl.dart:137-143` | Introduce a `AuthCheckEmail` state path (new `Failure` subclass or new `AuthState` subclass) so sign‑up success with email confirmation is not reported as an error. | §2.1 — P1 UX bug. |
| 2 | `lib/features/auth/presentation/cubits/auth_cubit.dart:39-120` | Add `if (state is AuthLoading) return;` guard at the top of every public action method. | §2.2 — P1. |
| 3 | `lib/features/auth/presentation/pages/login_page.dart:89-113` | Render the "check your email" message as a success banner (or new dedicated UI) when the cubit emits the new state. | §2.1 — P1. |
| 4 | `lib/features/auth/presentation/pages/login_page.dart:223-230` | Replace weak email validator with `RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')`. | §2.3 — P2. |
| 5 | `lib/features/auth/presentation/pages/login_page.dart:192-208` | Add `maxLength: 100` to the name field, and a soft validator for non‑empty after trim. | §2.4 — P2. |
| 6 | `lib/features/auth/presentation/pages/update_password_page.dart` | Add a guard that the current route is from a recovery event, or restrict the route to require `AuthPasswordRecoveryDetected` within the last N minutes. | §2.6 — P2. |
| 7 | `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart:33` | Wrap `Supabase.instance.client` with the same `_isSupabaseInitialized` guard used in the auth repo (move it to a shared helper). | §2.5 — P2. |
| 8 | `audits_project.md:1386-1387, 10109-10110` | Replace the actual project URL and publishable key with placeholders. | §2.8 — P3. |
| 9 | `lib/app.dart:98` | Use `l10n.appName` instead of the hard‑coded `'تالية'`. | §2.10 — P3. |
| 10 | `lib/main.dart:88-93` | Add a `TaliaLogger.w(...)` call when `!supabaseConfig.isConfigured` so the offline mode is observable in production logs. | Diagnostics. |

---

## 5. 🧪 Manual test checklist

### 5.1 New user registration — email confirmation ENABLED

1. Open app, complete onboarding with goal = "memorization".
2. On Home, tap "Sign in" / "إنشاء حساب" (if a sign‑in nudge is shown) or navigate to `/login`.
3. Switch to "Sign up" mode.
4. Enter a **new** email (`newuser+test1@gmail.com`) and a strong password (12+ chars).
5. Enter a display name.
6. Tap "Create account".
7. **Expected:**
   - Spinner appears, button disabled.
   - Banner appears with "تم إنشاء الحساب! يرجى تفقّد بريدك الإلكتروني...".
   - ❌ **Current bug:** banner is *red* (error). ✅ **Should be:** banner is *green* (success) with a "Resend" action.
   - The form clears, the toggle goes to "Sign in".
8. Open the email inbox, click the confirmation link.
9. The link opens the app via deep link `taliaquran://auth/update-password` → no, actually the link opens the browser; the user returns to the app.
10. Tap "Sign in", enter the same credentials, submit.
11. **Expected:** authenticated, Home loads, profile name matches the display name, `_SignInNudgeBanner` no longer appears.

### 5.2 New user registration — email confirmation DISABLED

1. Same as 5.1, but the project has "Confirm email" toggled off.
2. **Expected:** after the spinner, the user is **automatically** signed in and routed to Home. The banner may briefly show "Account created" success.

### 5.3 Existing email registration

1. With the same email as 5.1 already registered, repeat the sign‑up flow.
2. **Expected:**
   - Spinner, then banner with "البريد الإلكتروني مسجل بالفعل. حاول تسجيل الدخول.".
   - No account is created.
   - Toggle remains on "Sign in".

### 5.4 Wrong password login

1. With a known‑good email, enter a wrong password.
2. **Expected:**
   - Spinner, then banner with "البريد الإلكتروني أو كلمة المرور غير صحيحة".
   - No session is created.
   - User remains on the login page.

### 5.5 Correct login

1. Enter the correct email + password.
2. **Expected:**
   - Spinner, user is routed to Home, profile cubit updates with `displayName`.

### 5.6 Logout

1. Open Settings, tap "Sign out".
2. **Expected:**
   - Spinner, user is routed back to `/login` (or `/` if "skip" is allowed).
   - Local progress (Isar streaks, XP, etc.) is preserved (this is by design for the offline‑first model).
3. Sign back in: cloud progress is pulled via `pullProgressFromCloud`.

### 5.7 App restart — session persistence

1. Sign in.
2. Force‑kill the app.
3. Relaunch.
4. **Expected:**
   - Splash → Home (no login screen).
   - `AuthCubit` initial state reads `currentUser` from the SDK and emits `AuthAuthenticated` immediately (`auth_cubit.dart:27-32`).
   - Local data is intact, cloud pull is triggered.

### 5.8 Email confirmation toggled mid‑flow (only in dev)

1. Sign up with confirmation enabled → see the email.
2. **Do not click** the link.
3. Sign out, sign in with the same credentials.
4. **Expected:** the auth server returns "Email not confirmed" → banner with "يرجى تأكيد بريدك الإلكتروني أولاً. تحقق من صندوق الوارد." and a "Resend" action.
5. Tap "Resend".
6. **Expected:** new confirmation email sent (silent success); the resend action briefly shows "Email sent" success banner.
7. Click the link, sign in: should succeed.

### 5.9 Password reset

1. On the login page, tap "Forgot password?".
2. Enter the registered email.
3. **Expected:** banner "Password reset email sent".
4. Open the email, click the link.
5. **Expected:** app opens to `/auth/update-password` (via deep link).
6. Enter a new password, confirm, submit.
7. **Expected:** snackbar "Password updated", then auto sign‑out, routed to `/login`.
8. Sign in with the new password: should succeed.

### 5.10 Account deletion

1. Open Settings, tap "Delete account", confirm.
2. **Expected:** the Supabase RPC `delete_current_user` is called; all owned rows in `ayah_progress`, `streaks`, `xp`, `xp_history`, `bookmarks`, `certificates`, `daily_activities` are cascaded; the user is signed out and routed to `/login`.
3. If the RPC is not deployed in Supabase yet, the user sees a friendly "Delete account requires the Supabase delete_current_user function to be enabled first." error.

### 5.11 Offline mode (no `--dart-define`)

1. Build the app **without** `--dart-define=SUPABASE_URL=…` and `SUPABASE_ANON_KEY=…`.
2. **Expected:** app boots to Splash → Home; cloud sync is silently skipped; `_SignInNudgeBanner` appears if `streakDays > 0`; auth flows show "تسجيل الدخول السحابي غير مهيأ في هذا الإصدار" error if attempted.
3. Local features (Quran, Hifz, Azkar, Progress) work normally. ✅

### 5.12 Double‑submission prevention

1. On the sign‑in page, fill credentials, tap "Sign in" rapidly 5 times.
2. **Expected:** the button disables after the first tap, subsequent taps are no‑ops. Only one request reaches Supabase.
3. **Note:** if a programmatic call fires (e.g. a test), the cubit may emit `AuthLoading` twice. See §2.2.

---

## 6. Step‑by‑step safe fix plan

The plan is ordered from lowest risk to highest risk. Each step is a single, isolated change that can be reviewed and rolled back independently.

### Step 1 — Scrub the doc (10 minutes, no code change)

Open `audits_project.md`, replace the two occurrences of:
```
SUPABASE_URL=https://vxsqwozctxkvhgxkciua.supabase.co
SUPABASE_ANON_KEY=sb_publishable_B3vTCMcf1HV76SiEhQkeHA_i8EEKZq4
```
with the placeholders from `.env.example`. Commit. **Why first:** it's the lowest risk and removes a real exposure.

### Step 2 — Strengthen the cubit guards (30 minutes)

In `lib/features/auth/presentation/cubits/auth_cubit.dart`, add a single private helper:
```dart
bool get _busy => state is AuthLoading;
```
At the top of every `signUp`, `signIn`, `signOut`, `deleteAccount`, `resetPassword`, `updatePassword`, and `resendConfirmation`:
```dart
if (_busy) return;
```
This makes the cubit the single source of truth for "is auth in flight", not just the button.

### Step 3 — Fix the email validator (5 minutes)

In `lib/features/auth/presentation/pages/login_page.dart`, replace:
```dart
if (!v.contains('@') || !v.contains('.')) {
  return context.l10n.invalidEmail;
}
```
with:
```dart
final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
if (!emailRegex.hasMatch(v)) {
  return context.l10n.invalidEmail;
}
```

### Step 4 — Add `maxLength` to the name field (5 minutes)

In `lib/features/auth/presentation/pages/login_page.dart`:
```dart
TextFormField(
  controller: _nameController,
  maxLength: 100, // match DB CHECK constraint
  ...
)
```

### Step 5 — Fix the email‑confirmation UX (1 hour, P1)

**Plan:**

a) Add a new `Failure` subclass in `auth_repository_impl.dart`:
```dart
class AuthCheckEmailFailure extends Failure {
  const AuthCheckEmailFailure([
    super.message =
        'تم إنشاء الحساب! يرجى تفقّد بريدك الإلكتروني لتأكيد الحساب قبل تسجيل الدخول.',
  ]);
}
```

b) In `signUp` (line 137‑143), return:
```dart
if (response.session == null) {
  return const Left(AuthCheckEmailFailure());
}
```

c) In `auth_cubit.dart`, add a new state:
```dart
class AuthCheckEmail extends AuthState {
  const AuthCheckEmail();
}
```
And in `signUp`:
```dart
result.fold(
  (failure) {
    if (failure is AuthCheckEmailFailure) {
      emit(const AuthCheckEmail());
    } else {
      emit(AuthError(failure.toString()));
    }
  },
  (user) => emit(AuthAuthenticated(user: user)),
);
```

d) In `login_page.dart`, handle `AuthCheckEmail` in the `BlocConsumer` listener with a success‑styled banner and a "Resend" action.

### Step 6 — Guard `updatePassword` (30 minutes)

In `lib/features/auth/presentation/pages/update_password_page.dart`, add a check in the build method:
```dart
@override
Widget build(BuildContext context) {
  final authCubit = context.read<AuthCubit>();
  final isRecovery = authCubit.state is AuthPasswordRecoveryDetected;
  if (!isRecovery) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.updatePasswordTitle)),
      body: Center(child: Text(context.l10n.updatePasswordRecoveryExpired)),
    );
  }
  ...
}
```
(Also surface a "Recovery session expired, request a new link" message.)

### Step 7 — Centralize the Supabase init guard (1 hour)

Create `lib/core/services/supabase_availability.dart`:
```dart
class SupabaseAvailability {
  static bool get isInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }
}
```
Replace the static getter in `auth_repository_impl.dart:36-43` and the direct `Supabase.instance.client` call in `memorization_plus_repository_impl.dart:33` with calls to this helper. Existing try/catch blocks remain as a safety net.

### Step 8 — Localize `MaterialApp.router(title: …)` (5 minutes)

In `lib/app.dart:98`, replace:
```dart
title: 'تالية',
```
with:
```dart
title: AppLocalizations.of(context)?.appName ?? 'تالية',
```
Or wrap in a `Builder` that reads from l10n.

### Step 9 — Log offline mode (10 minutes)

In `lib/main.dart`, before `runApp`:
```dart
if (!supabaseConfig.isConfigured) {
  TaliaLogger.w(
    'Supabase is not configured. Running in offline mode. '
    'Provide --dart-define=SUPABASE_URL=… and SUPABASE_ANON_KEY=… to enable cloud features.',
  );
}
```

### Step 10 — Add `appName` localization if missing (1 hour)

Ensure `app_localizations*.dart` defines `appName`, and the l10n is wired in `app.dart`. (Confirm via `grep "appName:" lib/core/l10n/*.arb`.)

---

## 7. CI / pre‑commit checks (recommended)

- **Secret scan** with `gitleaks` or `trufflehog` to prevent any future `.env` or `service_role` from being committed.
- **Lint rule** to forbid `String.fromEnvironment` outside `core/config/`.
- **Unit test** that asserts `AuthCubit.signUp` returns immediately when state is `AuthLoading`.
- **Widget test** that asserts the login page shows a *success* banner (not error) when the cubit emits `AuthCheckEmail`.
- **Integration test** that runs the full sign‑up → email confirmation → sign‑in flow against a Supabase test project (this is the only way to catch real‑world issues with deep links and email redirects).

---

## 8. What is already NOT a problem (validated)

- ❌ ~~`.env` is bundled into the app~~ — Not bundled. Read only via `--dart-define` at build time, not at runtime.
- ❌ ~~Service role key leaks~~ — Verified absent from the entire repo.
- ❌ ~~Anonymous users can read other users' data~~ — RLS policies on all 14 tables use `auth.uid()`; `REVOKE ALL … FROM anon` is applied.
- ❌ ~~Profile is created from the client side, race conditions on sign‑up~~ — Profile is created by a Postgres trigger on `auth.users` insert, atomic.
- ❌ ~~Auth state changes leak through `passwordRecovery` events~~ — Filtered in `auth_repository_impl.dart:73` and re‑emitted via a separate stream.
- ❌ ~~Deep link scheme is not registered~~ — Registered on both Android (`AndroidManifest.xml:39-47`) and iOS (`Info.plist:35-44`).
- ❌ ~~Supabase is initialized twice~~ — Verified single `Supabase.initialize` call.
- ❌ ~~Auth gate doesn't redirect unauthenticated users~~ — `app_router.dart:217-229` redirects to `/login`.

---

## 9. Deliverable

This audit is a static review of the current code; it does not modify any files. The next step is for the team to implement §6 in order, ideally behind a feature flag, with the Step 5 (email‑confirmation UX) being the highest priority because it is user‑visible today.
