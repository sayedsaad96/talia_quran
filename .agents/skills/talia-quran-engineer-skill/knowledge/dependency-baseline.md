---
generated_from_commit: d37da52d72f721adee09b5b9526dff03ad576b58
last_verified: 2026-10-06
confidence: medium
---

# Dependency Baseline

Source: `pubspec.yaml` declarations inspected; SDK binaries, resolved versions and upgrade availability were not verified. Read `pubspec.lock`, actual SDK output and affected native configuration during an upgrade. Declared Dart constraint: `^3.11.4`; do not interpret it as the installed version.

| Declared package(s) | Project role / affected areas | Upgrade attention |
|---|---|---|
| `flutter_bloc`, `equatable`, `get_it`, `go_router` | Cubit state, equality, manual DI, guards/navigation | State/lifetimes and launch/back behavior |
| `isar`, `isar_flutter_libs`, `isar_generator`, `build_runner` | Local durable records, schema and generated code | Critical: complete schema, native library compatibility, existing-data upgrade |
| `supabase_flutter`, `flutter_secure_storage`, `crypto` | Auth/backend and protected account/family state | Critical: sessions, RLS/RPC coexistence, storage/key handling |
| `just_audio`, `audio_service`, `flutter_cache_manager` | Recitation/cache/background audio | High: queue/ayah mapping, lifecycle and OS media behavior |
| `qcf_quran_plus` | Mushaf/QCF rendering | Critical: page/font/glyph correctness and full affected-range validation |
| `speech_to_text` | Recitation input | High: permissions, locale, evaluation representation versus exact Quran text |
| `workmanager`, `flutter_local_notifications`, `timezone`, `flutter_timezone`, `adhan` | Background work, reminders/prayer calculation and delivery | High: isolate DB schema, scheduling, timezone/permission/platform behavior |
| `shared_preferences` | Preferences and caches | High for account/child/session-related keys; separate from Isar transactions |
| `intl`, `flutter_localizations`, `google_fonts` | Localization/formatting/typography | RTL/LTR, digits/plurals, fonts/offline |
| `share_plus`, `screenshot`, `gal`, `pdf`, `printing` | Export/share/certificates | Exact religious text, font/export fidelity and permission handling |
| `qr_flutter`, `mobile_scanner` | Family linking inputs | Identity validation, camera permissions and server authorization |

These are risk-navigation groups, not a complete package/license inventory. No dependency was updated or marked obsolete by this refresh.
