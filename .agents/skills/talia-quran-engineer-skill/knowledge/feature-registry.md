---
generated_from_commit: d37da52d72f721adee09b5b9526dff03ad576b58
last_verified: 2026-10-06
confidence: medium
---

# Feature Registry

Status throughout: source present; runtime behavior and release readiness unverified. This is a directory/owner inventory, not the full user-flow inventory required for a release audit. Feature paths are under `lib/features/`; trace their routes/providers in the router/DI before extending them.

| Feature directory | Scope and ownership hints | Existing test evidence |
|---|---|---|
| `quran` | Reader, search, bookmarks, audio presentation; canonical local datasource | `test/features/quran` |
| `memorization_plus` | Adult/child sessions, revision/listening, daily/custom plans, kids world, family linking/rewards; shared V2 engine in core | `test/features/memorization_plus`, `test/core/memorization` |
| `hifz` | Compatibility local data/domain paths; presentation/write retirement is guarded by tests. Do not treat as the active new-feature write owner | `test/features/hifz/hifz_write_api_retired_test.dart`, `test/features/memorization_plus/hifz_presentation_retired_test.dart` |
| `khatmah` | Setup/schedule, reading recording, history, completion and dua | `test/features/khatmah` |
| `home` | Today/coach actions, prayer context, activity and cross-feature journey summaries | `test/features/home` |
| `progress` | Progress summaries and refresh, including adult/child data | `test/features/progress` |
| `auth` | Authentication, owner readiness, account switching, cloud coordination | `test/features/auth`, `test/integration` |
| `azkar` | Approved release corpus, categories, smart wird, favorites/completion and audio | `test/features/azkar`, `test/core/content` |
| `prayer_companion` | Prayer interaction, policy/controller, scheduler and local records | `test/features/prayer_companion`, `test/core/prayer_delivery` |
| `settings` | Profile, notification/prayer preferences, privacy and app settings | `test/features/settings` |
| `certificate` | Award/domain behavior and presentation; inspect progress/share consumers | `test/features/certificate`, `test/core/widgets/social_share` |
| `streak`, `xp` | Daily activity, streak and reward data; inspect DI and effect processors | Shared storage and service tests under `test/core/services` |
| `onboarding`, `splash`, `tutorial_guide` | Entry/setup/readiness and user guidance | `test/features/onboarding`, `test/features/splash`, `test/features/tutorial_guide` |

Do not infer network requirements from a directory. For task-specific records, inspect repository/data collaborators to identify Isar versus SharedPreferences, local-only versus cloud, identity scopes and migration dependencies.
