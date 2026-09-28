# Talia UI/UX Audit

Status: Step 1 (inventory, navigation map, consistency baseline) — complete.
Step 2 (design-system audit + unification plan) — complete, see §5–§9.
Next: Step 2 (design-system unification plan), Step 3 (per-feature critique),
Step 4 (accessibility + copy), Step 5 (fixes in small verified batches).

Severity uses the P0–P4 scale from `AGENTS.md`.

## 1. Screen inventory

53 page files under `lib/features/*/presentation/pages`.

**Shell (bottom navigation, `StatefulShellRoute.indexedStack`)** — 5 tabs:

| # | Tab | Route | Notes |
|---|-----|-------|-------|
| 0 | Home | `/` | Settings is reached from Home header / context bar only |
| 1 | Quran | `/quran` | |
| 2 | Memorization hub | `/memorization` | `/hifz`, `/memorization/practice-surah` redirect inside this branch |
| 3 | Azkar | `/azkar` | |
| 4 | Progress | `/progress` | |

Android back on a non-home tab jumps to tab 0 (`app_shell.dart` `PopScope`).

**Full-screen routes (over the shell)**: splash, onboarding (+ child alias),
login, update-password (+ alias), tutorial guide, certificate, Quran surah /
page / search / bookmarks / daily, azkar category, settings, privacy policy,
khatmah setup / dashboard / history / completion / khatm dua,
memorization-plus entry, guardian linking, kids journey / kids / kids home /
kids Quran / kids stage / kids completion, family dashboard, child detail,
custom plan, daily plan, V2 session, debug QCF POC.

## 2. Navigation findings

| ID | Sev | Finding | Evidence |
|----|-----|---------|----------|
| NAV-1 | P2 | Router `onException` is a no-op, and there is no `errorBuilder`. An unknown or stale deep link (from a notification or an old share link) leaves the user on a blank or unchanged screen with no way back. | `app_router.dart:441` |
| NAV-2 | P3 | The back-with-fallback logic (`canPop ? pop : go('/')`) is copy-pasted in at least 6 places. In the Azkar pages the fallback sends the user to Home instead of the Azkar tab they came from (for example, when opened from a notification). | `azkar_category_page.dart:128,482`, `general_azkar_page.dart:424`, `smart_wird_page.dart:405,826`, `settings_page.dart:119`, `khatmah_reader_session_bar.dart:188` |
| NAV-3 | P3 | 79 raw `Navigator.push/pop` calls are mixed with 129 `go_router` calls. Most are dialogs and sheets (fine); one full page bypasses the router (`family_dashboard_page.dart:880`), so it loses the app's page transition and deep-link support. | grep counts |
| NAV-4 | P4 | Settings has no stable entry point outside Home (Quran, Azkar, and Progress have none). | `home_context_bar.dart:107`, `home_night_header.dart:174` |

## 3. Consistency baseline (the root cause of "every page feels different")

A design system exists (`AppColors`, `AppTypography`, `AppSpacing`,
`AppDecorations`, `core/widgets/*`), but **screens build their own UI
instead of using it**:

| Shared component | Features using it |
|---|---|
| `AppScaffold` | 1 (39 files use a raw `Scaffold`) |
| `AppButton` | 1 (vs 227 raw Filled/Text/Outlined/Elevated buttons) |
| `AppCard` | 2 |
| `AppTextField` | 0 |
| `SkeletonLoader` | 0 (`ShimmerList` 1, raw `CircularProgressIndicator` 35) |
| `LoadingWidget` / `EmptyStateWidget` / `ErrorStateWidget` | 10 / 7 / 13 |
| `SectionHeader` | 3 |

Token bypass (in `lib/features` + `lib/core/widgets`):

| Metric | Count | Notes |
|---|---|---|
| `Color(0x…)` literals | 343 | Hotspots: `core/widgets` 144, `memorization_plus` 82, `certificate` 39, `progress` 24, `home` 19, `onboarding` 18 |
| `isDark ? … : …` branches | 287 | Dark mode is hand-wired per widget. `colorScheme.` is used only 24 times, so the `ThemeData` is mostly bypassed. |
| `fontSize:` literals | 116 | 20 distinct sizes, including 9, 9.5, 10.5, 11.5, 12.5, and 13.5. The hotspot is `onboarding` (34). |
| `fontFamily: 'Amiri'` literals | 98 | Should come from `AppTypography` (Quran/azkar styles) |
| `BorderRadius.circular(N)` | 93 | 10+ distinct radii (2, 4, 6, 12, 16, 20, 24, 26, 30, 99) vs `AppSpacing.radius*` |
| Numeric `EdgeInsets` / `SizedBox` | 136 / 250 | vs 1665 `AppSpacing` uses — mostly good, with a long tail |
| Custom headers | 69 `Scaffold` vs 17 `AppBar` + 10 `SliverAppBar` | Most pages draw their own header, so title size, back button, and spacing vary |

RTL: good overall. There are no `TextAlign.left/right` and almost no
`EdgeInsets.only(left/right)`. The 62 `Alignment.topLeft/bottomRight`
matches are gradient directions, which are not a bug. The arrow icons
mirror automatically.

Hardcoded Arabic in UI (not through l10n): `certificate` (62 lines),
`settings/privacy_policy_content.dart`, `core/widgets/social_share`, and
`progress_repository_impl.dart`. Achievement titles are localized through
id mapping in `localization_helpers.dart`, with the Arabic string only as a
fallback. Certificate and share-card copy stay Arabic in the English locale.
This needs a product decision, because certificates may be intentionally
Arabic-only.

Accessibility signals: 70 `tooltip:` for 66 `IconButton`s and 57
`Semantics(` wrappers. Text scaling is handled in only a few places.
Step 4 covers this in depth.

## 4. Implications for the plan

1. The biggest lever is **not a redesign** but adoption. Make the theme
   (`ColorScheme` + `ThemeExtension` for Talia-specific tokens) the single
   source of truth, then migrate screens onto shared `AppScaffold`/header,
   buttons, cards, and state widgets. That removes the 287 `isDark`
   branches and the per-page drift.
2. Migrate feature by feature, with the worst first: `memorization_plus`,
   `core/widgets`, `onboarding`, `certificate`, `progress`, `home`. Keep
   each batch small and verify it with `flutter analyze` + `flutter test`.
3. Fix NAV-1 (error route) and NAV-2 (shared back button with a
   per-feature fallback) early. They are cheap and user-visible.

---

## 5. Design-system audit (Step 2)

**Scope:** `lib/core/theme/*`, `lib/core/constants/app_spacing.dart`,
`lib/core/widgets/*`. **Score: 42/100.** The tokens are well defined, but
the theme is not wired to deliver them and the components are not adopted.

### Token coverage

| Category | Defined | Hardcoded in UI | Root cause |
|---|---|---|---|
| Colors | ~60 in `AppColors`, full light/dark `ColorScheme` | 343 `Color(0x…)`, 287 `isDark ? :` | Talia-specific colors (card, text secondary/hint, gold, gradients, glass) have **no theme slot**, so widgets pick them by hand with `isDark` |
| Typography | 15 Material roles + 7 Quran/azkar styles | 116 `fontSize:`, 98 `fontFamily: 'Amiri'` | `AppTypography.*` getters carry **no color**; each call site adds `.copyWith(color: isDark ? … : …)`. `textTheme` (colored) is used only 13 times. |
| Spacing | 7-step scale + semantic (`pagePadding`, `cardPadding`, …) | 136 `EdgeInsets`, 250 `SizedBox` literals | Mostly adopted (1665 uses); this is a long tail |
| Radius | xs4 sm8 md12 lg16 xl24 xxl32 full (+ `radiusHero` = xxl duplicate) | 93 `BorderRadius.circular(N)`, 10+ values | No rule for which radius goes with which surface |
| Elevation/shadow | `shadowLight/Medium/Dark` colors | inside 393 raw `BoxDecoration`s | No elevation tokens |
| Motion | one page transition builder | per-widget durations | No duration/curve tokens |

### Component completeness

| Component | Exists | States | Variants | Adopted | Score |
|---|---|---|---|---|---|
| Component themes in `ThemeData` | appBar, card, input, chip, bottomNav, sheet, divider | — | — | automatic | 4/10: **missing** filled/outlined/text/elevated/icon button, dialog, snackBar, navigationBar, listTile, progress, switch, segmentedButton, FAB. So 227 raw buttons fall back to Material defaults or one of 83 ad-hoc `styleFrom`s. |
| `AppScaffold` | ✅ | — | gradient, no-appbar | 1 feature | 3/10 |
| `AppButton` | ✅ | loading, disabled, press-scale | primary/secondary/ghost/danger/gold × S/M/L | 1 feature | 5/10: well built but unused |
| `AppCard` / `GlassCard` + 11 `AppDecorations` | ✅ | tap | 13 visual styles | 3 of 11 decorations used; 393 raw `BoxDecoration` | 2/10: too many card languages |
| `SectionHeader` | ✅ | — | action | 3 files (plus private `_…SectionHeader` copies) | 4/10 |
| `LoadingWidget` / `ShimmerList` / `SkeletonLoader` | ✅ | — | — | 10 / 1 / 0; 35 raw spinners | 4/10 |
| `EmptyStateWidget` / `ErrorStateWidget` | ✅ | retry | — | 7 / 13 | 6/10 |
| Page header | ❌ no shared one | — | — | 18 custom header classes | 1/10 |
| Back button | ❌ | — | — | 6 copy-pasted fallbacks | 1/10 |
| SnackBar / sheet / confirm dialog helpers | ❌ | — | — | 58 / 25 / 24 raw calls | 1/10 |

### Naming

| Issue | Where | Standard |
|---|---|---|
| Two names for one value | `AppColors.amber == gold`, `radiusHero == radiusXxl` | Keep `gold` and `radiusXxl`; deprecate the aliases |
| Decorations named by mood rather than role | `royalGlass`, `spiritualCard`, `bentoCard`, `goldRimCard`, … | Name by role: `AppCard` variants `surface / tinted / hero / outlined` |
| Private header clones | `_HubSectionHeader`, `_HubAppBar`, `_JourneyTopBar`, … | One shared `TaliaAppBar` + `SectionHeader` |

## 6. Target architecture (decisions)

The owner delegated open design choices, so each decision below includes
its rationale.

**D1. `TaliaTokens` `ThemeExtension` is the single source for
Talia-specific colors.** It holds card, surfaceVariant, divider,
textPrimary / Secondary / Hint, gold / goldSoft, success / warning / info,
glassBorder, shadow, and the hero / primary / gold gradients. There is one
instance per brightness, registered in `AppTheme.light/dark.extensions`, and
widgets read it through `context.tokens`.
*Why:* this deletes the 287 `isDark` branches instead of moving them
around. It also makes a future OLED or high-contrast theme a single new
instance (the `oled*` colors already exist but are never wired).

**D2. Colored text through the theme.** Add `context.text`, which returns
`Theme.of(context).textTheme`, and a `TaliaTextStyles` extension for the
Quran/azkar/surah styles with color already applied. `AppTypography`
stays as the raw scale that `AppTheme` builds from. Features stop calling
it directly.
*Why:* this matches Material, respects light/dark automatically, and needs
only a mechanical migration.

**D3. Type scale snap table.** Stray sizes map onto the scale:

| Literal | Role |
|---|---|
| 9, 9.5, 10, 10.5 | `labelSmall`, **raised from 10 to 11** as the minimum legible Naskh size |
| 11, 11.5, 12, 12.5 | `bodySmall` / `labelMedium` (12) |
| 13, 13.5, 14 | `bodyMedium` / `labelLarge` / `titleMedium` (14) |
| 15, 16 | `bodyLarge` / `titleLarge` (16) |
| 18 | `headlineSmall` |
| 20, 22 | `headlineMedium` (Naskh), or `quranMedium` / `surahTitle` (Amiri) |
| 24–32 | `headlineLarge` / `displaySmall` |
| 48+ (hero numbers, e.g. `fontSize: 80`) | allowed only via a named `TaliaTextStyles.heroNumber` |

*Why:* the literals cluster around 11 and 13, which shows that the scale
is missing an 11px step, not that screens need custom sizes.

**D4. Radius by role.** Chips and badges use `full`. Buttons and inputs use
`md` (12). Cards use `lg` (16). Hero cards and dialogs use `xl` (24).
Bottom sheets use `xxl` (32, top only). Progress bars and handles use
`xs` (4). Literals snap as 2 → xs, 6 → sm, 20 → xl, 26/30 → xxl, and
99 → full.

**D5. Complete the component themes before migrating any screen.** Add
`filledButtonTheme` (the primary CTA: height 52, radius md, labelLarge),
`outlinedButtonTheme`, `textButtonTheme`, `elevatedButtonTheme` (aliased
to the filled look), `iconButtonTheme`, `dialogTheme` (radius xl),
`snackBarTheme` (floating, radius md), `navigationBarTheme`,
`listTileTheme`, `progressIndicatorTheme` (primary + track), `switchTheme`,
`segmentedButtonTheme`, and `floatingActionButtonTheme`.
*Why:* this is the highest-leverage change. The 227 raw buttons converge
on one look without editing a single feature file. The remaining
`styleFrom` overrides then become visible, reviewable exceptions.

**D6. One page chrome.** Evolve `AppScaffold` into three modes:
- `standard`: `TaliaAppBar` with centered title (headlineSmall), `TaliaBackButton`, and actions
- `collapsing`: `SliverAppBar.large` for hub pages
- `immersive`: no chrome, for the Mushaf reader, V2 session, and certificate

`TaliaBackButton(fallback: AppRoutes.x)` replaces the 6 copy-pasted
fallbacks and fixes NAV-2: the Azkar pages fall back to `/azkar`, not `/`.

**D7. One card language.** `AppCard(variant: surface | tinted | hero |
outlined)`. `GlassCard` and the 11 `AppDecorations` fold into these
variants. Unused decorations are deleted once nothing references them.

**D8. Mandatory state widgets.** Every async screen uses
`LoadingWidget`/`ShimmerList`, `EmptyStateWidget`, and `ErrorStateWidget`.
`SkeletonLoader` (0 uses) merges into `ShimmerList`. Add the helpers
`showTaliaSnackBar(context, msg, {type})`, `showTaliaSheet(...)` (drag
handle + safe area), and `showTaliaConfirmDialog(...)`.

**D9. Scoped themes, not exceptions.**
- **Kids track:** keeps its playful look through a `Theme` wrapper with its
  own `TaliaTokens` instance (kidsGreen, rounder radii), not through literals.
- **Certificate and share cards:** these are exported images with their own
  palettes, which live in a dedicated `*_palette.dart` excluded from the
  guard (D10).
- **Mushaf page and Quran text colors:** untouched. `qcf_quran_plus`
  rendering and all Quran/azkar text stay out of scope (content policy).

**D10. A ratchet so drift can't come back.** Add
`test/design_system/design_token_guard_test.dart`. It scans
`lib/features/**/presentation` and `lib/core/widgets` for `Color(0x`,
numeric `fontSize:`, `BorderRadius.circular(<number>)`, and `isDark ?`, and
compares the counts to a checked-in per-file baseline. The counts may only
go down. New files start at 0.
*Why:* the repo already enforces contracts with tests (azkar, corpus,
Supabase), so this follows house style and needs no custom lint plugin.

## 7. Migration order

Constraint: the working tree holds uncommitted owner work in
`memorization_plus` (61 files), `azkar` (15), `quran` (12), `settings` (10),
`khatmah` (7), `core/widgets` (7), `home` (4), and `core/theme` (2). Batches
touch only files the owner is not editing, **or wait until that work is
committed**.

| Phase | Batch | Touches | Visible change |
|---|---|---|---|
| 0 | Foundations: `TaliaTokens` + context extensions (D1, D2), component themes (D5), `TaliaAppBar`/`TaliaBackButton` (D6), feedback helpers (D8), NAV-1 error route, guard + baseline (D10) | `core/theme` (additive only), new files in `core/widgets`, `app_router.dart` | Buttons, dialogs, and snackbars unify app-wide |
| 1 | `onboarding` (34 font literals, 18 colors), `splash`, `auth`, `tutorial_guide` | 1–2 dirty files | First-run experience |
| 2 | `progress`, `streak`, `xp`, `certificate` (palette file) | ~1 dirty file | Stats, achievements |
| 3 | `home` | 4 dirty files, after owner commit | Main entry |
| 4 | `khatmah`, `settings`, `quran` (non-Mushaf chrome only), `azkar` | after owner commit | |
| 5 | `memorization_plus` in 4 sub-batches: hub, V2 session chrome, kids (scoped theme), family/guardian | after owner commit | Largest (82 colors, 25 scaffolds) |
| 6 | Cleanup: delete unused decorations and aliases, lower the guard baseline to zero for migrated dirs | | |

**Per-batch definition of done:** `flutter analyze` is clean, `flutter test`
is green (including the 4 golden tests, whose updates happen only for
intended visual changes and are listed in the batch notes), the guard
baseline goes down, and screenshots are taken on the connected Android
device (light + dark, AR + EN, text scale 1.0 and 1.3). Only edited files
get formatted.

## 8. Out of scope

Quran text, ayah numbering, tafsir, azkar/dua wording, Mushaf page
rendering, the memorization engine, sync, and prayer logic. This is a
visual and navigation pass only. Any change to displayed religious text is
blocked by `docs/TALIA_ISLAMIC_CONTENT_SOURCES_POLICY.md`.

## 9. Open questions for the owner

1. Should the certificate and share-card copy stay Arabic-only in the
   English locale?
2. Can `memorization_plus`/`azkar`/`quran`/`settings` be committed first,
   so Phases 3–5 can start without conflicts?
3. Should an OLED-black theme ship? It costs one `TaliaTokens` instance
   after Phase 0, and the colors already exist.
