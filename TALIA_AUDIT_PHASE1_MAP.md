# TALIA AUDIT — PHASE 1 — REVERSE ENGINEERED MAP
Generated: 2026-06-25
Codebase scanned: lib/ + pubspec.yaml (+ targeted reads of test/ are deferred to later prompts)

> Scope note: This map is built **from source code only** (lib/, pubspec.yaml).
> READMEs, `.md` docs, and code comments describing future plans were treated as
> unreliable and ignored. Findings/evaluations are NOT included here (Prompt 1 is
> "understand only, do not flag"). A small set of structural observations that are
> factual (e.g. "X file does not exist") appear only under "UNRESOLVABLE ITEMS"
> and "Structural Notes" — these are statements of fact, not evaluations.

---

## Stack (verified from `pubspec.yaml` + code)
- Flutter / Dart SDK `^3.11.4`, app `talia_quran` v1.0.0+1
- State management: **`flutter_bloc: ^9.1.1`** (Cubit, NOT Riverpod) ✓ matches domain context
- Navigation: **`go_router: ^17.2.1`** ✓
- DI: **`get_it: ^9.2.1`** ✓
- Backend: **`supabase_flutter: ^2.8.0`** ✓ (offline-first: optional init via `--dart-define`)
- Local DB: **`isar: ^3.1.0+1`** ✓ — NO Hive dependency present (see Data Flow Map)
- Audio: `just_audio`, `audio_cache` via `flutter_cache_manager`
- Speech: `speech_to_text` (recitation evaluation)
- Notifications: `flutter_local_notifications` + `timezone` + `flutter_timezone`
- Gamification/sharing: `confetti`, `screenshot`, `share_plus`, `gal`, `pdf`, `printing`, `qr_flutter`, `mobile_scanner`
- Quran rendering: `qcf_quran_plus: ^0.0.8` (+ bundled Amiri / Noto Naskh fonts)
- Persistence utils: `shared_preferences`, `path_provider`
- Error handling: `dartz` (`Either<Failure, …>`), `equatable`
- Icons/splash: `cupertino_icons`, `flutter_launcher_icons`, `flutter_native_splash`

---

## Feature Map
(Counts are non-generated `.dart` files per feature folder.)

### Feature: auth (7 files)
- Folder: `lib/features/auth/`
- Cubit(s): `AuthCubit` — **GetIt singleton** (`registerSingleton`), `BlocProvider.value` in root app
- Repository(ies): `AuthRepository` (abstract) / `AuthRepositoryImpl`
- Route(s): `/login`, `/auth/update-password`, `/update-password` (alias)
- Status: **Exists** — only repository touching Supabase auth + cloud sync tables (streaks/xp/ayah_progress/daily_activities)

### Feature: splash (1 file)
- Folder: `lib/features/splash/`
- Cubit(s): none (StatefulWidget)
- Route(s): `/splash` (initial location)
- Status: **Exists** — 2.5s animation, then routes to `/onboarding` (if `isFirstTimeAppOpen` true) else `/home`

### Feature: onboarding (4 files)
- Folder: `lib/features/onboarding/`
- Cubit(s): `OnboardingCubit`
- Repository(ies): uses `MemorizationPlusRepository` + `MemorizationPathResolver`
- Route(s): `/onboarding`, `/onboarding/child`
- Status: **Exists** — persists goal, user type, completion; shared prefs keys: `isFirstTimeAppOpen`, `onboarding_skipped`, `user_primary_goal`, `onboarding_user_type`, `onboarding_completed_at`

### Feature: home (5 files)
- Folder: `lib/features/home/`
- Cubit(s): `HomeCubit` → states: `HomeInitial/Loading/Loaded/Error`
- Repository(ies): aggregates many use cases (progress, hifz, quran page, custom plan, heatmap, smart coach, memorization profile)
- Route(s): `/` (shell branch 0)
- Status: **Exists** — dashboard; reacts to `MemorizationPathResolver.changes` stream and re-loads

### Feature: quran (20 files)
- Folder: `lib/features/quran/`
- Cubit(s): `SurahListCubit`, `SurahDetailCubit`, `QuranPageCubit`
- Repository(ies): `QuranRepository` / `QuranRepositoryImpl`; datasources `QuranLocalDatasourceImpl`, `BookmarkService`
- Route(s): `/quran` (shell), `/quran/surah/:surahId`, `/quran/page/:pageNumber`
- Status: **Exists** — local Quran JSON (`assets/data/quran.json`), bookmarks via SharedPreferences, mushaf page reader + surah reader

### Feature: hifz (16 files)
- Folder: `lib/features/hifz/`
- Cubit(s): `HifzCubit`, `HifzSessionCubit`
- Repository(ies): `HifzRepository` / `HifzRepositoryImpl`; datasources `HifzLocalDatasource` (legacy SharedPreferences impl, still present) + `IsarHifzLocalDatasourceImpl` (production)
- Route(s): `/hifz` (shell, branch 2 with redirect), `/hifz/session`
- Status: **Exists** — active memorization with SM-2-style spaced repetition (intervals `[1,3,7,14,30,90]` days), checkpoint review gating, unlocks. One-time migration from SharedPreferences → Isar.

### Feature: azkar (11 files)
- Folder: `lib/features/azkar/`
- Cubit(s): `AzkarCubit`
- Repository(ies): `AzkarRepository` / `AzkarRepositoryImpl`; datasource `AzkarLocalDatasourceImpl`
- Route(s): `/azkar` (shell), `/azkar/:category` (morning/evening/general/duas)
- Status: **Exists** — local azkar JSON, daily counters persisted in SharedPreferences

### Feature: memorization_plus (52 files — largest feature)
- Folder: `lib/features/memorization_plus/`
- Cubit(s): `DailyPlanCubit`, `KidsModeCubit`, `KidsJourneyCubit`, `CustomPlanCubit`, `GuardianLinkingCubit`, `MemorizationIdentityCubit`, `MemorizationSessionCubit` (V2), `ParentDashboardCubit`, `QuizCubit`
- Repository(ies): `MemorizationPlusRepository` / `MemorizationPlusRepositoryImpl`; datasources `MemorizationPlusLocalDatasourceImpl` (SharedPreferences + Isar) + `V2SessionLocalDatasource`
- Route(s): `/memorization` (hub, shell), `/memorization-plus` (path selection), `/memorization-plus/guardian-linking`, `/memorization-plus/daily-plan`, `/memorization-plus/kids-journey`, `/memorization-plus/kids`, `/memorization-plus/kids-home`, `/memorization-plus/kids-quran`, `/memorization-plus/kids-stage`, `/memorization-plus/kids-completion`, `/memorization-plus/parent-dashboard`, `/memorization-plus/custom-plan`, `/memorization-plus/quiz`, `/memorization-v2/session`
- Status: **Exists** — umbrella for: adult "Memorization Plus", kids gamified journey, parent/guardian dashboard + remote link, custom plans, daily plans, quiz, and V2 session engine. Profile-driven path selection (child/adult) gates routes via `MemorizationRouteGuard`.

### Feature: progress (14 files)
- Folder: `lib/features/progress/`
- Cubit(s): `ProgressCubit`
- Repository(ies): `ProgressRepository` / `ProgressRepositoryImpl` (aggregates hifz + mem-plus + quran + streak datasources)
- Route(s): `/progress` (shell branch 4)
- Status: **Exists** — overall stats, achievements, certificates, smart-memorization widgets, activity heatmap

### Feature: settings (10 files)
- Folder: `lib/features/settings/`
- Cubit(s): `SettingsCubit`, `ProfileCubit`
- Repository(ies): `SettingsRepository` / `SettingsRepositoryImpl`
- Route(s): `/settings`, `/settings/privacy-policy`
- Status: **Exists** — notification toggles/times, streak toggle, theme/locale (via core cubits), profile, parent PIN

### Feature: streak (6 files)
- Folder: `lib/features/streak/`
- Cubit(s): `StreakCubit`
- Repository(ies): none (uses `StreakService` core service directly)
- Route(s): none (no dedicated route; consumed by home/progress/settings)
- Status: **Exists** — Isar-backed (`StreakIsar`, `DailyActivityIsar`)

### Feature: xp (2 files)
- Folder: `lib/features/xp/`
- Cubit(s): none
- Repository(ies): none — `XpService` (core) is the entry point; `XpIsar` model
- Route(s): none
- Status: **Exists** (service-only, no UI feature folder)

### Feature: certificate (3 files)
- Folder: `lib/features/certificate/`
- Cubit(s): none
- Repository(ies): none (uses `AchievementService`)
- Route(s): `/certificate` (push, full screen)
- Status: **Exists** — `CertificatePage`, `CertificateWidget`, `CertificateAward` entity; PDF/image export (recent commit f1b9676)

### Feature: tutorial_guide (4 files)
- Folder: `lib/features/tutorial_guide/`
- Cubit(s): none
- Route(s): `/tutorial-guide`
- Status: **Exists** — static help/how-to content

### Core (not a feature) — `lib/core/`
- **di/**: `injection.dart` (GetIt bootstrap, see Dependency Map)
- **router/**: `app_router.dart` (GoRouter + guards)
- **services/**: `AchievementService`, `AppSessionService`, `AppVersionInfoProvider`, `AudioCacheService`, `HapticService`, `TaliaNotificationService`, `QuranAudioService`, `StreakService`/`StreakReader`, `XpService`
- **memorization/** (shared domain logic): `MemorizationPathResolver`, `MemorizationProgressReader`, `SmartCoachEngine`/`SmartCoachRecommendation`, snapshot/retention/review helpers, and **v2/** subpackage (`SessionEngine`, `SessionAdapters`, `RecitationEvaluator`, `AyahFailureTracker`, `SessionPhase/State`, `V2FeatureFlag`)
- **config/**: `SupabaseConfig` (from `--dart-define`)
- **theme/**: `AppColors`, `AppDecorations`, `AppTheme`, `AppTypography`, `ThemeCubit`
- **l10n/**: `app_ar.arb`/`app_en.arb`-backed `AppLocalizations`, `LocaleCubit`, `CubitMessageCodes`, helpers (arb files live under `lib/core/l10n/`)
- **constants/**: `AppConstants`, `AppSpacing`, `SpeechConstants`, `SurahNames`, `XpConstants`
- **widgets/**: `AppShell` (bottom nav), `AppScaffold/Card/Button/TextField`, `CelebrationOverlay`, `ActivityHeatmap`, etc.
- **utils/**: `ArabicNormalizer`, `MushafHizbHelper`, `QuranTextDisplayFormatter`, `TaliaLogger`, `UseCase` base, `context_extensions`

---

## Navigation Map
GoRouter (`AppRouter.router`), `initialLocation: /splash`.
Top-level `redirect` = global AUTH GATE (see below). Per-route async `redirect`s implement path/profile guards.
`onException` swallows network errors during async redirects (offline-safe no-op).

```
GLOBAL AUTH GATE (router.redirect):
  - requiresAuthentication(loc)  → true only for routes starting with '/memorization-plus/parent-dashboard'
      if NOT (Authenticated|Initial) → '/login'
  - isPublicLocation(loc)         → explicit public allowlist (home/quran/hifz/mem-hub/azkar/progress/settings/...)
      returns null (allow)
  - else if Authenticated|Initial → allow
  - else                           → '/login'
refreshListenable: _AuthNotifier(AuthCubit.stream)  → re-evaluates on auth changes

FULL-SCREEN ROUTES (push over shell; parentNavigatorKey = root):
/splash                       → SplashPage            (initial)
/onboarding                   → OnboardingPage
/onboarding/child             → ChildOnboardingPage
/login                        → LoginPage
/auth/update-password         → UpdatePasswordPage    (auth recovery target)
/update-password               → UpdatePasswordPage    (alias)
/tutorial-guide               → TutorialGuidePage
/debug/qcf-rendering-poc      → QcfRenderingPocPage   (kDebugMode ONLY)
/certificate                  → CertificatePage       (extra: award, userName)
/quran/surah/:surahId         → QuranReaderPage
/quran/page/:pageNumber       → QuranReaderPage
/hifz/session                 → HifzSessionPage       (redirect: hifzSessionRedirect → kids redirected to kids listen/home)
/azkar/:category              → AzkarCategoryPage | GeneralAzkarPage (general|duas)
/settings                     → SettingsPage
/settings/privacy-policy      → PrivacyPolicyPage
/memorization-plus            → PathSelectionPage     (redirect: entryRedirect → kids home / adult entry / null)
/memorization-plus/guardian-linking → GuardianLinkingPage (redirect: only child+status==required; else back to /memorization-plus)
/memorization-plus/daily-plan → DailyPlanPage | CustomPlanSetupPage (redirect: adultOnlyRedirect)
/memorization-plus/kids-journey → KidsGamifiedJourneyPage (redirect: kidsOnlyRedirect)
/memorization-plus/kids       → KidsGamifiedListenPage (redirect: kidsOnlyRedirect)
/memorization-plus/kids-home → KidsGamifiedHomePage  (redirect: kidsOnlyRedirect)
/memorization-plus/kids-quran → KidsQuranReaderPage   (redirect: kidsOnlyRedirect)
/memorization-plus/kids-stage → KidsGamifiedStagePage (redirect: kidsOnlyRedirect)
/memorization-plus/kids-completion → KidsGamifiedCompletionPage (redirect: kidsOnlyRedirect)
/memorization-plus/parent-dashboard → ParentDashboardPage (redirect: parentDashboardRedirect; auth-required)
/memorization-plus/custom-plan → CustomPlanSetupPage  (redirect: adultOnlyRedirect)
/memorization-plus/quiz       → QuizPage               (redirect: adultOnlyRedirect)
/memorization-v2/session      → V2SessionPage          (redirect: adultOnlyRedirect; entered only when V2FeatureFlag.isAdultEnabled())

SHELL — StatefulShellRoute.indexedStack (AppShell, bottom nav, 5 branches):
├── Branch 0: /                  → HomePage
├── Branch 1: /quran             → QuranPage
├── Branch 2: /memorization      → MemorizationHubPage
│             └── /hifz          → HifzPage   (redirect: hifzRedirect → child→kids-home; no path→/memorization-plus)
├── Branch 3: /azkar             → AzkarPage
└── Branch 4: /progress          → ProgressPage
```
Bottom nav tabs (in order): Home, Quran, Memorization, Azkar, Progress.
Public (no-auth) routes allowlist also includes `/memorization-v2/session` and (debug) `/debug/qcf-rendering-poc`.

---

## Dependency Map

### Bootstrap order (`main.dart` → `_bootstrapAndRun`)
1. `runZonedGuarded` wraps everything; `FlutterError.onError` logs (debug shows red screen, prod shows friendly Arabic error widget).
2. `WidgetsFlutterBinding.ensureInitialized()`
3. `GoogleFonts.config.allowRuntimeFetching = false` (fonts are bundled assets)
4. `QcfFontLoader.setupFontsAtStartup()`
5. Lock portrait; set status-bar overlay style
6. `SupabaseConfig.fromDartDefine` — if `isConfigured` (https URL + non-empty key) → `Supabase.initialize`; else **skip** (offline mode)
7. `configureDependencies()` (GetIt — see below)
8. `notificationService.initialize()`; `requestPermissions()` is **not awaited** (M05 fix: avoid hang on Android 13+)
9. First-launch notification scheduling block (guarded by `notifications_initialized` flag)
10. `notificationService.cancelStreakAlert()`
11. `runApp(TaliaApp())`
12. On bootstrap failure → `runApp(_StartupFailureApp())` (Arabic error screen)

### Root widget (`TaliaApp`) providers (MultiBlocProvider)
- `ThemeCubit..loadTheme()`, `LocaleCubit..loadLocale()`, `ProfileCubit..loadProfile()` (lazy singletons)
- `AuthCubit` as `BlocProvider.value` (singleton — must NOT be disposed by framework)
- `BlocListener<AuthCubit>`: on `AuthPasswordRecoveryDetected` → go `/auth/update-password`
- Lifecycle observer: on resume → refresh notifications; on inactive/pause → save current location

### GetIt registrations (`lib/core/di/injection.dart`)
External / infra:
- `SharedPreferences` (singleton), `Isar` (singleton — 6 schemas), `V2SessionLocalDatasource` (lazy)
- Migrations run inline: `IsarHifzLocalDatasourceImpl.migrateFromSharedPreferencesIfNeeded()`, `MemorizationPlusLocalDatasourceImpl.migrateReviewRecordsToIsarIfNeeded()`

Core cubits/services (mostly lazy singletons):
- `ThemeCubit`, `LocaleCubit`, `ProfileCubit` (lazy)
- `SettingsCubit` (factory)
- `AudioCacheService`, `AppSessionService`, `AppVersionInfoProvider`, `TaliaNotificationService`
- `StreakService` (singleton), `StreakReader` (singleton, alias of StreakService), `XpService` (singleton), `AchievementService` (singleton)

Datasources (lazy): `ProgressLocalDatasource`, `MemorizationPlusLocalDatasource`, `QuranLocalDatasource`, `SettingsRepository`, `BookmarkService`, `AzkarLocalDatasource`

Repositories (lazy): `ProgressRepository`, `QuranRepository`, `HifzRepository`, `AzkarRepository`, `MemorizationPlusRepository`, `AuthRepository`; plus resolvers/readers: `MemorizationPathResolver`, `MemorizationProgressReader`

Engines/adapters (lazy): `SmartCoachEngine`, `V2SessionEngine`, `V2SessionReviewAdapter`, `V2SessionProgressAdapter`, `V2SessionGamificationAdapter`

Use cases (lazy, ~30): snapshot/smart-coach, progress, surahs, hifz (progress/save/unlock/checkpoint×4), azkar, daily-plan (generate/cache/save/evaluate/mark), kids (progress/points/journey/session-log), quran page, custom plan, parent (dashboard/access/remote-link)

Feature cubits (factories): `ProgressCubit`, `SurahListCubit`, `SurahDetailCubit`, `QuranPageCubit`, `HifzCubit`, `HifzSessionCubit`, `AzkarCubit`, `GuardianLinkingCubit`, `MemorizationIdentityCubit`, `OnboardingCubit`, `DailyPlanCubit`, `KidsModeCubit`, `CustomPlanCubit`, `KidsJourneyCubit`, `ParentDashboardCubit`, `MemorizationSessionCubit`, `QuizCubit`, `HomeCubit`, `StreakCubit`
- **Singleton** cubit: `AuthCubit` (only one)

Key wiring examples:
```
HifzRepository → HifzLocalDatasource(Isar), QuranLocalDatasource
ProgressRepository → ProgressLocalDatasource, HifzLocalDatasource, MemorizationPlusLocalDatasource, QuranLocalDatasource, StreakReader
MemorizationPlusRepository → MemorizationPlusLocalDatasource, QuranRepository
AuthRepository → Isar, SharedPreferences  (the only repo touching Supabase cloud tables)
HomeCubit → GetProgress, GetHifzProgress, GetQuranPage, GetCustomPlan, MemorizationPlusRepository, AppSessionService, GetActivityHeatmapUsecase(Isar), MemorizationPathResolver, GetSmartCoachRecommendationUsecase
HifzSessionCubit → 13 deps (surahs, detail, save/get progress, path, segments, unlock, 4×checkpoint, SettingsRepository, Streak, Xp, Achievement, MemorizationPlus)
MemorizationSessionCubit → QuranRepository, MemorizationPlusRepository, V2SessionEngine, V2SessionReview/Progress/Gamification adapters
```

---

## Cubit Graph (State → UseCase → Repository → DataSource)

```
AuthCubit (singleton)
  States: AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated,
          AuthAccountDeleted, AuthPasswordResetSent, AuthPasswordRecoveryDetected,
          AuthPasswordUpdated, AuthResendConfirmationSuccess, AuthError
  Repo: AuthRepositoryImpl → Supabase (auth) + Isar (streak/xp/ayah/daily) + SharedPreferences

LocaleCubit → SharedPreferences (locale code, default 'ar')
ThemeCubit  → SharedPreferences (theme mode)
ProfileCubit → SharedPreferences (display name/avatar)
SettingsCubit → MemorizationPlusRepository, SharedPreferences, MemorizationPathResolver

OnboardingCubit → SharedPreferences, MemorizationPlusRepository, MemorizationPathResolver
  (persists isFirstTimeAppOpen / skipped / goal / userType / completedAt)

HomeCubit (HomeInitial/Loading/Loaded/Error)
  → GetProgressUsecase, GetHifzProgressUsecase, GetQuranPageUsecase, GetCustomPlanUsecase,
    GetActivityHeatmapUsecase, GetSmartCoachRecommendationUsecase, MemorizationPlusRepository,
    AppSessionService, MemorizationPathResolver (listens to its changes stream)

SurahListCubit   → GetSurahsUsecase → QuranRepository → QuranLocalDatasource (JSON)
SurahDetailCubit → GetSurahDetailUsecase → QuranRepository
QuranPageCubit   → QuranRepository, SaveReadPageUsecase, StreakService

HifzCubit → GetSurahs, GetHifzProgress, GetHifzPath, SaveHifzPath, MemorizationPlusRepository, MemorizationPathResolver
HifzSessionCubit → (13 deps above) → Isar via HifzLocalDatasource + SettingsRepository + gamification services
  (SM-2 spaced repetition; checkpoint gating)

AzkarCubit → GetAzkarUsecase → AzkarRepository → AzkarLocalDatasource (JSON); per-zikr counters in SharedPreferences

ProgressCubit → GetProgressUsecase, MemorizationPathResolver
  (ProgressRepository aggregates hifz + mem-plus + quran + streak)

DailyPlanCubit → GenerateDailyPlan, GetCachedDailyPlan, EvaluateMemorization, SaveDailyPlan, Achievement, Streak, Xp, MemorizationPathResolver
KidsModeCubit → GetKidsProgress, AwardKidsPoints, MarkAyahMemorized, SaveKidsSessionLog, Achievement, QuranRepository, Streak, Xp
KidsJourneyCubit → GetKidsJourney, GetKidsProgress, ParentRemoteLink, QuranRepository
CustomPlanCubit → MemorizationPlusRepository
GuardianLinkingCubit → MemorizationPlusRepository
MemorizationIdentityCubit → MemorizationPlusRepository, MemorizationPathResolver
ParentDashboardCubit → GetParentDashboard, ParentAccess, ParentRemoteLink
QuizCubit → MemorizationPlusRepository, QuranRepository, Achievement
MemorizationSessionCubit → QuranRepository, MemorizationPlusRepository, V2SessionEngine + 3 adapters (review/progress/gamification)
StreakCubit → StreakService (Isar)
```

### Core domain logic (not cubits, but central)
- `SmartCoachEngine` (pure) + `GetSmartCoachRecommendationUsecase` ← `GetMemorizationSnapshotUsecase` ← `MemorizationProgressReader`
- V2: `V2SessionEngine` drives `MemorizationSessionCubit`; adapters translate engine output into review-record saves (SM-2 via `ScheduleNextReviewUsecase`), V2-session Isar persistence, and streak/xp/achievement side effects.
- `ScheduleNextReviewUsecase.schedule()` — SM-2-style: excellent ×2.5 / average ×1.5 / weak → 1 day; strength 0–10; UTC dates.

---

## Data Flow Map

### Isar collections (6 schemas, opened in one DB)
| Class | File | Purpose |
|---|---|---|
| `IsarAyahProgress` | features/hifz/data/models/isar_ayah_progress.dart | Hifz per-ayah memorization progress |
| `IsarAyahReviewRecord` | features/memorization_plus/data/models/isar_ayah_review_record.dart | SM-2 review records (mem-plus) |
| `IsarV2Session` | features/memorization_plus/data/models/isar_v2_session.dart | V2 session persistence |
| `StreakIsar` | features/streak/data/models/streak_isar.dart | Current/longest streak, freezes |
| `XpIsar` | features/xp/data/models/xp_isar.dart | XP total |
| `DailyActivityIsar` | features/streak/data/models/daily_activity_isar.dart | Per-day activity (heatmap) |

### Hive boxes
- **None.** No `package:hive` import, no `Hive.box`/`openBox` calls anywhere in `lib/`. (The audit's domain context mentions "Hive (legacy)" — this is NOT present in the current codebase.)

### SharedPreferences keys (representative; there are many)
- Bootstrap/flags: `isFirstTimeAppOpen`, `notifications_initialized`, `notifications_azkar_initialized`
- Onboarding: `onboarding_skipped`, `user_primary_goal`, `onboarding_user_type`, `onboarding_completed_at`
- Hifz (legacy + migration marker): `hifz_progress`, `hifz_checkpoint_progress`, `hifz_path_mode`, plus per-surah checkpoint string-lists and `_*_migrated` flags
- Progress: `read_pages`
- Notifications: `dailyReviewPreferenceKey` (+ `_hour`/`_minute`), `streakAlertPreferenceKey`(+h/m), `morningAzkarPreferenceKey`(+h/m), `eveningAzkarPreferenceKey`(+h/m), `dailyDuaPreferenceKey`(+h/m), `kidsReminderPreferenceKey`(+h/m), `open_hours`, `last_msg_index`
- Theme/locale/profile: theme key, locale key, profile keys
- Achievements: earned-key, new-certificate-badge key
- Mem-plus: profile/pairing/track/dailyPlan/kidsProgress/kidsSessionLogs/parentSettings/parentRewards/customPlan/smartSettings JSON blobs; `mem_plus_is_parent_mode`; review-record Isar-migration flag
- Session: last-location key
- Feature flags: `enable_memorization_v2`, `enable_memorization_v2_kids`

### Supabase tables (`.from(...)` calls — all inside AuthRepositoryImpl + MemorizationPlusRepositoryImpl)
- `ayah_progress` (auth sync)
- `streaks` (auth sync)
- `xp` (auth sync)
- `daily_activities` (auth sync)
- `parent_child_links` (mem-plus remote linking)
- `profiles` (mem-plus)
- `kids_progress_cloud` (mem-plus)
- `kids_session_logs` (mem-plus)
- `parent_rewards` (mem-plus insert/select)

> Supabase is **optional** (offline-first). When `--dart-define SUPABASE_URL/KEY` absent, `Supabase.initialize` is skipped; auth/cloud features return friendly offline errors while local features keep working.

---

## Feature Flag Map

| Flag | Defined | Checked | Gates | Current |
|---|---|---|---|---|
| `enable_memorization_v2` | `lib/core/memorization/v2/v2_feature_flag.dart:10` (`_keyAdult`) | `lib/features/memorization_plus/presentation/pages/daily_plan_page.dart:229` (`V2FeatureFlag.isAdultEnabled()`) | Adult V2 session entry: when ON, "Practice" from DailyPlan pushes `/memorization-v2/session` (V2SessionPage); when OFF, pushes `/memorization-plus/quiz` (legacy quiz) | **Disabled by default** (`?? false`). Runtime-toggle via `setAdultEnabled` (dev/test only — no in-app UI found in lib/). |
| `enable_memorization_v2_kids` | `lib/core/memorization/v2/v2_feature_flag.dart:11` (`_keyKids`) | **No read sites found in `lib/`** (only `setKidsEnabled` writer exists) | Intended to gate kids V2 (Phase G) — but currently unused | **Disabled by default; effectively dead** (no consumer). |
| `kDebugMode` (framework) | — | `app_router.dart:128,300` | `/debug/qcf-rendering-poc` route only registered in debug | Debug-only by definition. |

Other runtime toggles (not "feature flags" per se, but behavioral): notification per-type booleans + times, streak toggle, parent-mode (`mem_plus_is_parent_mode`), theme/locale.

---

## UNRESOLVABLE ITEMS
- ⚠️ **No `supabase/migrations/` directory exists in the repository.** Searched `supabase/` and any `migrations/` dir (excluding `node_modules`, `build/`) — none found. The Supabase schema for the 9 tables referenced in code (`ayah_progress`, `streaks`, `xp`, `daily_activities`, `parent_child_links`, `profiles`, `kids_progress_cloud`, `kids_session_logs`, `parent_rewards`) is **not present in source**. (RLS policies, column definitions, and triggers therefore cannot be verified from the repo — only inferred from the Dart read/write calls.)
- ⚠️ `enable_memorization_v2_kids` flag has **no read site** in `lib/` — declared and writable but never consulted. Cannot confirm whether a kids-V2 path was intended elsewhere.

## Structural Notes (factual observations only — not evaluations)
- **Auth model is "offline-first / auth-optional":** the global redirect treats the vast majority of routes as public (the `_publicRoutes` allowlist is broad). Only `/memorization-plus/parent-dashboard` is in `_remoteProtectedRoutes` (true auth-required). Supabase auth still drives `AuthCubit` and the password-recovery redirect.
- **Two parallel memorization engines coexist:** (a) legacy Hifz (`/hifz`, `/hifz/session`, SM-2 intervals `[1,3,7,14,30,90]`) and (b) Memorization Plus adult flow (`/memorization-plus/daily-plan` → quiz OR V2 session depending on flag) + kids gamified flow (`/memorization-plus/kids-*`). V2 (`/memorization-v2/session`, `MemorizationSessionCubit`) is fully implemented but **gated default-off** at the single call site.
- **`MemorizationPlusRepositoryImpl` is the cloud-boundaries owner** for parent/child linking and kids cloud sync (the only non-auth feature writing to Supabase).
- **Migrations are first-class at startup:** SharedPreferences→Isar for Hifz, and review-records→Isar for Mem-Plus, both run during `configureDependencies()`.
- **Singleton vs factory split:** `AuthCubit` is the only singleton feature cubit (must use `BlocProvider.value`); all other feature cubits are factories. Core/global cubits (`Theme`/`Locale`/`Profile`) are lazy singletons provided once at the root.

---

**Next: hand this file to PROMPT 2 (evaluation/findings).**
