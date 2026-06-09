# Talia Quran — Full Production Readiness Audit

_Audit date: 2026-06-08 · Flutter 3.41.8 / Dart 3.11.5 · App version `1.0.0+1`_
_Method: feature-by-feature, screen-by-screen, flow-by-flow, layer-by-layer review of `lib/` + routing + tests, with `flutter analyze` and `flutter test` executed._

> **Important context for severity calibration:** Talia (تالية) is an **Arabic-first** Quran-memorization app. The app name, default direction (RTL), splash, and most copy are Arabic; **English is a secondary locale**. Therefore pure "English copy is missing / Arabic-only" gaps are graded as **quality issues (P1/P2)** rather than hard release blockers, _except_ where they make a core flow unusable in English. Devotional content (Qur'an ayāt, hadith, du'ā in Azkar/tips) is intentionally Arabic and is **not** treated as a localization defect.

---

## 1. Executive Verdict

**CONDITIONALLY READY.**

The app is structurally healthy and shippable for its **primary Arabic audience** after a focused round of P1 fixes. Objective signals are strong:

- `flutter analyze` → **No issues found** (clean, 0 warnings).
- `flutter test` → **404 passed, 0 failed, 0 skipped**.
- Clean Architecture is consistently applied (data / domain / presentation), DI is centralized, BLoC/Cubit lifecycle is disciplined (subscriptions cancelled, controllers/audio/speech disposed).
- Routing is offline-safe, kids/adult paths are separated by route guards and covered by tests, and the app boots into a friendly error screen instead of a red crash screen.

**No P0 hard-crash blockers were found.** The blockers are **functional/UX correctness** issues (a few broken CTAs, kids navigation escaping into the adult shell, a backend dependency for account deletion) plus **English-localization polish**. None crash the app, but several damage the first-run/auth funnel and the kids experience enough to warrant fixing before a wide / English-market release.

---

## 2. Release Blockers (P0 / P1)

### P0 — Hard blockers (crash / broken core / data loss)
**None identified.** Build is clean, tests pass, no unguarded crash paths or data-loss flows were found.

### P1 — Must fix before wide release
| # | Blocker | Where | Why it blocks |
|---|---------|-------|---------------|
| B1 | **Adult "Sign in / Create account" from onboarding never opens `/login`** — for adults `_routeAfterOnboarding` ignores `intent` and returns the goal route (e.g. `/quran`). | `features/onboarding/presentation/cubits/onboarding_cubit.dart:132-138` | The primary account-creation CTA silently drops the user into guest content; the auth funnel is broken for the majority (adult) path. |
| B2 | **Home guest "Sign in" CTA navigates to Settings, not Login** | `features/home/presentation/pages/home_page_widgets.dart:907` | Misleading CTA; users tapping "Sign in" land on a settings list, not a login screen. |
| B3 | **Kids back-navigation exits into the adult home shell** (`context.go('/')` fallback on journey/stage/listen back when the nav stack is empty). | `kids_gamified_journey_page.dart:66`, `kids_gamified_stage_page.dart:31` | A child taps back and is dropped into the full adult bottom-nav app, breaking the kids "walled garden". |
| B4 | **Account deletion depends on a Supabase RPC `delete_current_user`** that must be deployed in prod. | `features/auth/data/repositories/auth_repository_impl.dart:299` | If the RPC is not deployed, deletion fails. There **is** graceful error handling (no crash), but a store-required "delete account" must actually work. **Verify the RPC is live before submission.** |
| B5 | **Guardian pairing polling stops when the code timer hits 0** — child stops polling `checkLinkStatus()` after expiry. | `features/memorization_plus/presentation/pages/guardian_linking_page.dart:346-351` | A parent who links right around expiry may never be detected; child is stuck until manual regenerate. |
| B6 | **Account deletion gives no warning that local progress (Isar/SharedPreferences) is retained**, and post-delete routes to home (not login). | `settings_page_tiles.dart` delete flow + `auth_repository_impl.deleteAccount` | Privacy/disclosure correctness; user may believe all data is gone. |
| B7 | **Stage-lock not enforced on deep links** — `KidsStageDetails` always enables "Start", and a deep link with missing `status` defaults to `current`. | `app_router.dart:750-755`, kids stage page | Locked stages can be started via URL/extra, bypassing progression. |
| B8 | **Arabic-only strings still surfaced from cubits regardless of locale** (English users see Arabic): `hifz_session_cubit.dart` audio/save errors (307, 350, 473, 522); `quiz_cubit.dart`; `kids_mode_cubit.dart`; `auth_repository_impl.dart` error strings. | listed files | Degraded English experience on error paths. P1 for an English release, P2 for Arabic-only release. |

---

## 3. Feature-by-Feature Review

| Feature | Status | Screens | Severity | Issue | Recommended fix | Blocks release? |
|---------|--------|---------|----------|-------|-----------------|-----------------|
| Splash | Working | `splash_page` | P3 | Fixed 2.5s delay on every cold start; reads magic key `'isFirstTimeAppOpen'` instead of `OnboardingCubit.firstOpenKey`. | Use the constant; consider shortening delay for returning users. | No |
| Onboarding (adult) | Partially working | `onboarding_page` + cubit | **P1** | Adult "Sign in" CTA routes to content, not `/login` (B1). Skip vs "Continue as guest" diverge (skip → home w/ defaults; guest → deep goal route). Skip/complete errors only render on the final step. | Honor `intent==signIn` for adults; unify skip/guest; surface errors globally. | **Yes** |
| Onboarding (child) | Working (Arabic-only) | `child_onboarding_page` | P1/P2 | Entire screen built with `isArabic ? … : …` inline strings (bypasses ARB but renders both langs); back icon not RTL-flipped; back returns to full onboarding. | Move to ARB; flip chevron; route back to a sensible parent. | No |
| Guest mode | Working | (all public routes) | P2 | Guest = unauthenticated; nearly all routes public; only parent dashboard gated. Home shows upgrade banner. CTA bug (B2). | Fix B2; otherwise correct. | No (except B2) |
| Authentication | Working | `login_page`, `update_password_page`, `auth_cubit` | P1 | Login reachable & functional; error messages localized via fragile **Arabic substring matching**; repo returns Arabic-only strings. `signIn/signUp` emit `AuthAuthenticated` manually **and** via stream → possible double navigation. | Return error **codes** from repo, map to l10n in UI; rely on a single emission source. | No |
| Path selection | Working | `path_selection_page` | OK | Fully l10n, RTL-correct, confirm sheet + loading + error. `entryRedirect` auto-skips if a path exists. | — | No |
| Adult memorization | Partially working | `memorization_hub`, `daily_plan`, `custom_plan_setup`, `quiz` | P1 | Daily-plan (self-rating) and Hifz STT session are **parallel products**, not a connected flow. Completion bottom sheet **re-fires on rebuild/refresh** (no "shown once" guard). Hub rebuilds a new `Future` every build. | Add a completion-shown guard; memoize hub future; document/connect the two memorization surfaces. | No (UX) |
| Hifz / Hifz session | Working | `hifz_page`, `hifz_session_page` + cubit | P1/P2 | Strong session UX (STT, checkpoints, audio errors). Empty path-state shows message **without a CTA** to path selection. STT locale `'ar-SA'` here vs `'ar_SA'` in quiz — inconsistency. Cubit emits Arabic-only errors (B8). | Add CTA; unify STT locale id; localize cubit strings. | No |
| Smart memorization / custom plan | Working | `custom_plan_setup` | P2 | No dedicated error UI for `CustomPlanError`; `PlanTargetUser.child` selectable on adult-only route. | Add error surface; hide child target on adult gate. | No |
| Quiz | Working | `quiz_page` + cubit | P1 | Functional with manual fallback. Each `_QuestionView` creates its own `SpeechToText`; `dispose` only `stop()` not `cancel()`; locale mismatch with Hifz. Arabic-only cubit errors. | `cancel()` STT on dispose; unify locale; localize. | No |
| Quran reading | Working | `quran_page`, `quran_reader_page` | P2 | Solid mushaf reader w/ read-confirmation gate; juz/hizb labels hardcoded Arabic (`'الجزء…'`, `'الحزب…'`); mushaf palette hardcoded hex; `loadPage` re-emits loading on each swipe (minor flicker). | Localize labels; tokenize palette; avoid loading re-emit on swipe. | No |
| Quran — Surah detail (legacy) | **Dead code** | `surah_detail_page.dart` | **P1** | ~690-line page **not registered in router / not imported**; recreates all `TapGestureRecognizer`s on every `build()`. Superseded by `QuranReaderPage`. | Delete the page + its dead cubit wiring, or document why it's retained. | No |
| Kids path | Partially working | kids home/journey/stage/listen/completion | **P1** | Back escapes to adult shell (B3); stage-lock bypass via deep link (B7); triple-duplicate "Mission" CTAs on home; listen→completion uses `push` (stacks); completion "Next" defaults visible until async check (wrong on last ayah briefly). | Route kids back → kids home; enforce lock; dedupe CTAs; `pushReplacement`; default Next hidden until resolved. | **Yes (B3/B7)** |
| Kids Quran mode | Working (best-in-class) | `kids_quran_reader_page` | P2 | Proper dark/light adaptation; back icon RTL-aware. Minor: `_currentDetail = state.detail` assigned during `build()` (side effect). | Move assignment out of build. | No |
| Kids "recording" | Misleading | `kids_mode_cubit:187-195` | P2 | "Recording" is a 1.5s animation, **not** real speech recognition. | Confirm this is the intended product behavior or label it as "repeat after me". | No |
| Guardian linking | Working | `guardian_linking_page` + cubit | P1 | QR/code create + parent accept via Supabase. Poll stops at expiry (B5); 30s poll interval is slow; raw `error.toString()` to UI. | Keep polling through expiry; shorten interval; map errors. | No (except B5) |
| Parent dashboard | Working | `parent_dashboard_page` + cubit | P2/P3 | Auth-gated + child-blocked + PIN gate; QR scanner & manual token; feedback dedup. `disableParentMode` has no UI; reminder toggle has no time picker; side-by-side `Expanded` buttons overflow risk; `MobileScanner` no explicit controller dispose. | Wire/remove dead path; add time picker; constrain buttons. | No |
| Progress tracking | Working | `progress_page` + widgets | P2/P3 | Loading/error/retry present. Certificates list loading returns empty `SizedBox`; horizontal list uses `right:` padding only (clips in RTL). | Add spinner; use directional padding. | No |
| Azkar | Working | `azkar_page`, `azkar_category_page`, `general_azkar_page` | P1 | Counter UX strong. **Category error states have no retry**; hub card chevron not RTL-aware. Daily "tips" are Qur'an/hadith/du'ā (intentionally Arabic — _not_ a defect; the "Daily tip" chrome/label should be localized though). | Add `onRetry`; flip chevron; localize chrome only. | No |
| Settings | Working | `settings_page`, `settings_page_tiles` | P1 | Language/theme switch + persist correctly. Notification **time labels forced Arabic suffix (ص/م) in English** (`:1545`); no OS permission prompt before enabling notifications; auth/delete errors Arabic-only. | Locale-aware time format; request OS permission; localize errors. | No |
| Language switching | Working | `LocaleCubit` | OK | Persists to `app_locale`, applied at root, instant. | — | No |
| Theme switching | Working | `ThemeCubit` | P2 | Persists `theme_mode`; instant. In `system` mode the status-bar brightness is derived from a stored bool, not actual platform brightness. | Use platform brightness for `system`. | No |
| Profile / account | Working | `profile_cubit` | P2 | Local-only profile (no cloud sync); `ProfileError` never rendered in UI; default name `'مستخدم تالية'` Arabic. | Render error; localize default. | No |
| Account deletion | Risky | settings delete flow | **P1** | Depends on Supabase RPC (B4); no re-auth; local data retained without disclosure (B6); post-delete → home. | Verify RPC; disclose local-data behavior; route to login. | **Yes (verify B4)** |
| Privacy / legal | Working | `privacy_policy_page` | P2 | Bilingual body; reachable from settings; app-bar title hardcoded (not l10n). | Localize the title. | No |
| Tutorial / help | Working (Arabic-only) | `tutorial_guide_*` | P2 | Entire help content + categories Arabic-only; search filters Arabic only. Acceptable for Arabic-first launch; a gap for English users. | Provide English content (or hide for `en` until translated). | No (Arabic launch) |
| Certificate | Working | `certificate_page`, `certificate_widget` | P1/P2 | Share/save/PDF + permissions + orientation handling solid. Save bottom sheet hardcodes a dark theme; certificate copy Arabic-only. | Theme the sheet; provide EN certificate copy if targeting EN. | No |
| Notifications | Working | `notification_service`, settings | P1 | Scheduled once on first launch; refreshed on resume. No runtime OS-permission request from the settings toggles (requested fire-and-forget at startup only). | Prompt for permission when a toggle is enabled. | No |
| Navigation / routing | Working | `app_router` | OK | StatefulShell preserves tab state; offline-safe redirects with per-route try/catch + global `onException` no-op; auth gate for remote routes. | — | No |
| Supabase integration | Working (offline-first) | `main.dart`, `auth_repository_impl` | OK | Configured via `--dart-define`; absent config → offline mode, local features remain reachable. | Ensure prod `--dart-define` values + delete RPC at build time. | No (verify) |
| Local storage / cache | Working | Isar + SharedPreferences | OK | Isar opened with 5 schemas; SP→Isar migration on startup; audio cache service. | — | No |
| Offline behavior | Working | router + repos | OK | Redirect failures swallowed; local-first features function without network. | — | No |

---

## 4. Screen-by-Screen UX Review

| Screen | Issue | Severity | Recommendation |
|--------|-------|----------|----------------|
| Splash | Always-on 2.5s delay; hardcoded gradient hex | P3 | Tokenize colors; shorten for returning users |
| Onboarding | Free-swipe applies silent defaults; no global loading/error overlay; Next hidden but swipe-through allowed | P1/P2 | Gate progression; global error/loading |
| Child onboarding | Inline AR/EN strings; back chevron not flipped; blank spinner during redirect | P1/P2 | ARB + directional icon + message |
| Login | "Skip" wording overloaded (also onboarding skip); no "continue as guest" explanation | P2 | Clarify copy |
| Update password | Public route reachable w/o recovery session → cryptic submit error; shared obscure toggle | P2/P3 | Guard route; separate toggles |
| Home | Hardcoded brand `'تالية'`/basmala; many inline AR/EN; **guest CTA → settings**; duplicate settings entry (hero gear + quick action) | P1/P3 | Fix CTA (B2); ARB; dedupe entry |
| Quran list | Hero whites on gradient (intentional); good states | P3 | — |
| Quran reader | Arabic juz/hizb labels; hardcoded mushaf palette; loading re-emit on swipe | P2 | Localize + tokenize + avoid flicker |
| Hifz list | Empty path-state has no CTA; many `Colors.white`/hex on gradients | P1/P2 | Add CTA; tokenize |
| Hifz session | Heavy `Colors.*` semantic colors; silent clear on empty STT | P2 | Token map; user feedback |
| Memorization hub | ~30 inline AR/EN strings; new `Future` each build; duplicate "Review Quiz" title | P1 | ARB; memoize future |
| Daily plan | Completion sheet repeats; 3 rating buttons overflow on narrow screens; hardcoded section colors | P1/P2 | Shown-once guard; wrap buttons |
| Custom plan | No `CustomPlanError` UI; child target on adult route | P2 | Add error UI |
| Quiz | Per-question STT; `Colors.*` heavy; emoji in progress chip | P1/P2 | `cancel()` STT; tokenize |
| Kids home | Triple duplicate Mission CTA; inline AR/EN; fixed kids palette (intentional) | P2/P3 | Dedupe; ARB |
| Kids journey | **Back → adult shell**; nested double-scroll; fixed 172px cards | P1/P2 | Route to kids home; flatten scroll |
| Kids stage | **Back → adult shell**; **lock not enforced** | P1 | Fix back + enforce lock |
| Kids listen | listen→completion stacks (`push`); play label duplicates title | P2/P3 | `pushReplacement` |
| Kids completion | "Next" shown until async check resolves (wrong on last ayah); no error UI on fetch fail | P2 | Default hidden until resolved |
| Guardian linking | Poll stops at expiry; English-only semantic label; QR white (intentional) | P1/P2 | Keep polling |
| Parent dashboard | Side-by-side buttons overflow; reminder toggle lacks time picker; scanner dispose | P2/P3 | Constrain; add picker |
| Progress | Certificates empty `SizedBox` loading; RTL padding clip | P2 | Spinner + directional padding |
| Azkar hub | Chevron not RTL-aware; tip "chrome" not localized | P1/P2 | Flip chevron; localize labels |
| Azkar category / general | **Error states lack retry**; back icon not directional; reader `Colors.*` | P1/P2 | Add `onRetry`; directional icon |
| Settings | Time labels forced ص/م in EN; red/green hardcoded; unused `isLoading` | P1/P2/P3 | Locale time fmt; tokenize |
| Privacy policy | App-bar title hardcoded | P2 | Localize |
| Tutorial | Arabic-only content/categories/search | P2 | EN content or hide for EN |
| Certificate | Save sheet hardcoded dark; close button top-right awkward in LTR; Arabic-only copy | P1/P2 | Theme sheet; EN copy |

---

## 5. Code Quality Findings

### Architecture
- **Strong.** Clean Architecture (`data` / `domain` / `presentation`) is consistent across all features. Use-cases wrap repositories; repositories return `Either<Failure, T>` (dartz). DI is fully centralized in `core/di/injection.dart` (singletons for services/repos, factories for cubits).
- **Dead code to remove:** `quran/.../surah_detail_page.dart` (unreachable, heavy), `qcf_rendering_poc_page.dart` (debug-only, fine), `HifzCubit.selectPath()`, `KidsJourneyCubit.createRemoteLinkQr()`, `GuardianLinkingCubit.acceptCode()`, `ParentDashboardCubit.disableParentMode()`, `OnboardingCubit.nextStep/previousStep`, pref key `onboarding_skipped` (written, never read).
- **Leftover template test:** `test/widget_test.dart` is the default "Counter increments" smoke test — replace with a real app smoke test.

### State management
- **Good lifecycle hygiene:** cubits cancel stream subscriptions in `close()` (home, progress, auth, hifz session); `AudioPlayer`/`SpeechToText` and controllers disposed.
- `AuthCubit.signIn/signUp` emit `AuthAuthenticated` directly **and** via the `authStateChanges` stream → risk of double emission / double navigation. Pick one source of truth.
- `OnboardingState.copyWith` clears `errorMessage` on any partial emit (line 72) — errors can be lost on step change.
- `daily_plan_cubit` emits `DailyPlanError` without restoring the previously loaded plan → user loses in-progress UI on a transient failure.

### Routing / guards
- Offline-safe by design: per-route `try/catch` returning safe fallbacks + global `onException` no-op. Kids/adult separation enforced via `kidsOnlyRedirect` / `adultOnlyRedirect`, **covered by tests** (`memorization_route_guard_test.dart`, `app_router_route_policy_test.dart`).
- **Guard gap:** `kidsOnlyRedirect` and `adultOnlyRedirect` both **allow `null` profiles** (a profile-less user can reach kids/adult routes). Acceptable for local-first guest access but worth tightening if strict separation is required.

### Storage
- Isar opened once with 5 schemas; SharedPreferences→Isar migrations run on startup (`migrateFromSharedPreferencesIfNeeded`, `migrateReviewRecordsToIsarIfNeeded`). Bookmarks/azkar counters in SharedPreferences.
- `azkar_cubit.increment()` is `void async` with unawaited prefs writes → possible race on very rapid taps.

### Supabase
- Initialized only when `--dart-define` config present; otherwise offline. Auth errors mapped from Arabic substring matching (fragile). **Account deletion relies on RPC `delete_current_user`** — must be deployed.

### Localization
- ARB-based `AppLocalizations` (ar/en) with a **localization regression test** guarding against re-introduced hardcoded Arabic in key memorization screens. However:
  - **Arabic-only literals remain in cubits/services** surfaced to UI regardless of locale (auth repo, hifz session cubit, quiz cubit, kids mode cubit).
  - **Bilingual `isArabic ? … : …` ternaries** (home: 26, hub: 16, kids home: 3, etc.) render the correct language but bypass ARB — maintainability debt, not a user-facing break.
  - Several **directional icons hardcoded** (`arrow_back_ios`, `arrow_forward_ios`) instead of locale-aware chevrons in azkar.

### Tests
- **404 tests, all passing.** Good coverage of repositories, cubits, route policy, localization regression, kids flows, RTL/narrow widget tests.
- Gaps: no test for the adult onboarding→login intent path (the B1 bug slipped through); no test for kids back-navigation target; limited coverage of error/retry states.

---

## 6. Performance Findings

- **Startup:** Bootstrap is sensible — fonts bundled (`allowRuntimeFetching = false`), notifications permission request **not awaited** before `runApp` (good, avoids hang), Isar opened once. Splash adds a fixed 2.5s delay on every launch (P3).
- **Navigation:** `StatefulShellRoute.indexedStack` preserves tab Navigator stacks → no rebuild thrash switching tabs.
- **Rebuilds / build-method cost:**
  - `memorization_hub_page` creates a **new `Future` on every build** in a `FutureBuilder` → redundant async work each rebuild (P1, easy fix: hoist the future).
  - Dead `surah_detail_page` recreates all `TapGestureRecognizer`s every `build()` — irrelevant while dead, must not be revived as-is (P1 if revived).
  - `kids_quran_reader_page` assigns state in `build()` (side effect) (P2).
  - `quran_reader_page` re-emits loading on each page swipe → brief flicker (P2).
- **Cache:** `QuranReadConfirmationGate` is in-memory only (resets across restarts — intended anti-gaming). Audio cache service present.
- **Memory:** No leaks found in audited screens — controllers, timers, `AudioPlayer`, `SpeechToText` are disposed/cancelled. `MobileScanner` in parent QR page relies on widget disposal (no explicit controller dispose) (P3).
- **Animations:** confetti/animate usage is bounded; no runaway controllers found.
- **Lists:** 114-surah lists use `ListView.builder` / `SliverChildBuilderDelegate` (lazy) — fine.

---

## 7. Responsive / RTL / Theme Findings

- **RTL/LTR:** Core is RTL-correct (MaterialApp locale-driven; login/settings wrap `Directionality`; onboarding flips chevrons). **Defects:** child onboarding, azkar hub/category back icons, and certificate chrome use non-directional icons / forced RTL.
- **Arabic:** Renders correctly throughout (Amiri / Noto Naskh fonts bundled; QCF mushaf fonts loaded at startup).
- **English:** Functional but **incomplete** — tutorial/help Arabic-only, several cubit/service error strings Arabic-only, notification time suffix forced to ص/م, some Arabic-only default names and certificate copy. Acceptable for Arabic-first launch; **must be addressed for an English-market release**.
- **Dark / light:** Theme system is well-built (`AppTheme.light/dark`, `ColorScheme`, typed `AppColors`). Most screens respect it. **Hardcoded `Colors.*`/hex** appear widely but largely on **gradient overlays / semantic accents** (record=red, success=green) and kids' intentionally-bright palette — mostly cosmetic (P2/P3). `system` theme mode derives status-bar brightness from a stored bool rather than platform brightness (P2). Certificate save sheet hardcodes a dark theme (P1/P2).
- **Small screens / overflow risk:** daily-plan 3-rating button row, parent dashboard side-by-side `Expanded` buttons, and fixed-width kids cards are overflow risks on narrow devices (P2).

---

## 8. Test Results

All commands run on Flutter 3.41.8 / Dart 3.11.5 (Windows). The Cursor sandbox does not support filesystem isolation on Windows, so commands were run outside the sandbox.

| Command | Result |
|---------|--------|
| `flutter clean` | n/a (sandbox-blocked on first attempt; not required after rerun) |
| `flutter pub get` | **Got dependencies!** (60 packages have newer incompatible versions — informational only) |
| `flutter analyze` | **No issues found!** (ran in 912.1s) |
| `flutter test` | **All tests passed!** — `+404`, **0 failed, 0 skipped** (golden tag excluded) |
| `flutter test --coverage` | Not run (skipped; full test suite already passed) |
| `flutter build apk --debug` | **Skipped** (per release audit scope) |
| `flutter build appbundle --debug` | **Skipped** (per release audit scope) |

> **Build note:** APK/appbundle builds were intentionally skipped during this audit. Run `flutter build apk --debug` and/or `flutter build appbundle --debug` locally before store submission. Release configs were **not** modified.

---

## 9. Required Fix Plan Before Release

### P0 — (none)
No hard crash/data-loss blockers identified.

### P1 — Fix before wide / English release
- [ ] **B1** Adult "Sign in / Create account" must route to `/login` — honor `intent == signIn` in `onboarding_cubit._routeAfterOnboarding` for adults.
- [ ] **B2** Home guest "Sign in" CTA → `/login` (not `/settings`).
- [ ] **B3** Kids back-navigation fallback → kids home, never adult `/`.
- [ ] **B4** Verify Supabase `delete_current_user` RPC is deployed in production (store requirement).
- [ ] **B5** Guardian pairing: keep polling through/after code expiry; shorten interval.
- [ ] **B6** Disclose local-data retention on account delete; route post-delete to login.
- [ ] **B7** Enforce kids stage-lock on deep links / extras.
- [ ] **B8** Move Arabic-only cubit/service error strings (auth repo, hifz session, quiz, kids mode) into ARB; localize notification time format.
- [ ] Daily-plan completion sheet: add a "shown once" guard.
- [ ] Memorization hub: hoist the `FutureBuilder` future (perf) + add error/empty handling.
- [ ] Azkar category/general error states: add `onRetry`.
- [ ] Notifications: request OS permission when a toggle is enabled.
- [ ] Remove or document the dead `surah_detail_page.dart`.

### P2 — Strongly recommended
- [x] Unify STT locale id (`ar-SA` vs `ar_SA`) and call `cancel()` (not just `stop()`) on quiz STT dispose.
- [x] `system` theme mode: use platform brightness for status bar.
- [x] RTL chevrons in child onboarding, azkar, certificate chrome.
- [x] Tokenize hardcoded `Colors.*`/hex where a theme token exists; theme the certificate save sheet.
- [x] Constrain overflow-risk rows (daily-plan ratings, parent dashboard buttons).
- [x] `daily_plan_cubit`: preserve loaded plan on transient evaluate failure.
- [x] `AuthCubit`: single emission source to avoid double navigation.
- [x] Certificates list: show a loading spinner; fix RTL padding.

### P3 — Polish / cleanup
- [ ] Replace default `widget_test.dart` counter test with a real smoke test.
- [ ] Remove dead methods/keys (`HifzCubit.selectPath`, `createRemoteLinkQr`, `acceptCode`, `disableParentMode`, `nextStep/previousStep`, `onboarding_skipped`).
- [ ] Splash: use `OnboardingCubit.firstOpenKey` constant; consider shorter delay.
- [ ] Localize privacy-policy title and bilingual inline ternaries (migrate to ARB over time).

---

## 10. Final Recommendation

**Release after fixes (Conditionally Ready).**

- For an **Arabic-first launch:** ship after fixing the functional P1s — **B1, B2, B3, B4, B5, B6, B7** (auth funnel, kids walled-garden, account-deletion correctness). The Arabic experience is otherwise polished, analyze is clean, and 404 tests pass.
- For an **English-market launch:** additionally complete **B8** and the localization items (tutorial/help, cubit/service error strings, notification time format, certificate copy) so English users don't hit Arabic-only screens and errors.

The codebase is well-architected and stable; there are **no P0 crash blockers**, and the remaining work is a contained, well-scoped list of correctness and localization fixes rather than structural rework.
