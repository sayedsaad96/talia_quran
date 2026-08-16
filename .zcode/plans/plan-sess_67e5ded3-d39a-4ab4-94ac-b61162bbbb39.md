# Social Share Card System — Audit & Repair Plan

## PHASE A — Audit Result (completed)

**Implementation map.** The live system is `lib/core/widgets/social_share/` (9 files + 7 templates), entered via `SocialShareSheet.show()` from 6 call sites (Quran reader, 2 azkar pages, progress page, achievements sheet, certificate page). Data flows: domain entities → `SocialShareData` factories → `ShareCardTemplateResolver` switch → template inside `ShareCardShell` → offscreen `captureFromWidget` @ pixelRatio 3.0 on a fixed 360-logical canvas → PNG → `share_plus`/`Gal`. Quran text comes from the trusted `Ayah` entity; dua from `Zikr`; achievements from `Achievement`; stats from `OverallProgress`. Certificate files are NOT touched by this plan.

**Compliance matrix (condensed — full evidence gathered from file reads):**

| Requirement | Status | Evidence / Problem |
|---|---|---|
| Content-driven architecture | PASS | Pure DTO + resolver switch; no business logic in widgets |
| 6 required share types | PASS (+certificate, azkar) | All 8 enum values render |
| Achievement data integrity | PARTIAL | Real data, but `memorization()` factory **accepts `surahsCount` and silently discards it** (social_share_model.dart:229-250 — param never used); test even asserts the stat is absent |
| Quran content safety | **FAIL** | Hardcoded Bismillah `﴿ بِسْمِ اللهِ…﴾` rendered on **every** verse card (quran_verse_template.dart:54) — hardcoded Quran text in presentation; religiously wrong for At-Tawbah/mid-surah verses and redundant for Al-Fatiha 1:1 |
| Export never clips | **FAIL** | All 7 templates wrap content in `SingleChildScrollView` — during offscreen capture there is no scrolling, so long content is **silently cut off** in the exported PNG (no error raised; existing tests can't catch it) |
| Tests green | **FAIL** | `defaultCharacterAssetFor()` returns 5 nonexistent `.jpg` pose files (only `Talia_Master_Character.png` exists); test file contradicts itself (line 29 expects master PNG, lines 428-461 expect `.jpg` poses) → suite is red |
| Localization ar/en | PARTIAL | Card copy localized via `SocialShareCopy`, but sheet chrome (title, buttons, snackbars, tooltips), format names, theme names, category `defaultBadge`, certificate template strings, and `toPlainShareText()` footer are Arabic-only → English users get Arabic UI |
| Kids/Adult differentiation | PARTIAL (superficial) | Kids = character + 2 star icons + tagline; Adult = same card with character removed. Templates never branch on audience |
| Category differentiation | PARTIAL | Templates differ structurally (good), but all default to the same dark `emeraldDark` theme |
| Talia visual identity | PARTIAL | `royalGradient` theme is **purple** (#3B1B66) — off the specified teal/emerald/gold/ivory palette; default dark+gold-borders+heavy ornaments reads certificate-like (spec forbids) |
| Dimensions 1080×1350/1080×1080/1080×1920 | PASS (arithmetic) | 360-logical × 3.0 pixelRatio; will verify actual PNG headers in Phase C |
| Share flow robustness | PASS | `_isExporting` guard, mounted checks, error snackbars |
| Assets/logo | PASS w/ risk | Correct logo (`logo_icon_padded.png`) & character (`Talia_Master_Character.png`); broken fallback map is dead code but must be fixed; no `cacheWidth` on 2.2MB/1.5MB images decoded at ~34-84px |
| RTL typography | PARTIAL | Verse text RTL w/ Amiri + length-based sizing; but header/footer/badge `Row`s are LTR-ordered in Arabic; English `zikr.translation` shown on Arabic cards |

**Bug classification:** P0: hardcoded Bismillah; export clipping via scrollviews; red/contradictory tests + broken asset fallback. P1: discarded `surahsCount` user data; Arabic-only sheet chrome/localization gaps; superficial Kids/Adult differentiation; off-brand purple theme + certificate-like default. P2: RTL row order; translation gating; plain-text share localization; image decode memory; duplicated magic colors; single default theme for all categories. P3: fixed-position kids stars can overlap content; redundant on-screen `Screenshot` wrapper; `baseWidth` 380 vs 360 mismatch.

## PHASE B — Repair (all changes inside `lib/core/widgets/social_share/**` + tests; call-site signatures unchanged so the 6 entry points and the certificate page need zero edits)

**P0 fixes**
1. `templates/quran_verse_template.dart`: remove the hardcoded Bismillah chip. Verse card becomes typography-first: verse (Amiri, RTL) → reference badge. Verse text continues to come exclusively from `Ayah.text`.
2. Replace `SingleChildScrollView` in all 7 templates with an adaptive fit: keep length-based font sizing, then wrap template body in `FittedBox(fit: BoxFit.scaleDown)` inside the shell's fixed content region — guarantees the exported PNG never clips, shrinking only as a last resort. Extract a shared `ShareCardContent` layout helper to avoid duplicating this in 7 files.
3. `social_share_model.dart`: `defaultCharacterAssetFor()` → return `Talia_Master_Character.png` for all categories (single source of truth until pose assets exist). Fix the two contradictory tests.

**P1 fixes**
4. `memorization()` factory: add `memorizedSurahsCount` field; template renders both stats (ayahs + surahs) from real `OverallProgress` data; update test from `findsNothing` to `findsOneWidget`.
5. Full localization pass via `SocialShareCopy` (established share-specific pattern, allowed by spec): sheet header/buttons/tooltips/snackbars, format + theme display names, certificate badge/labels, `toPlainShareText` footer (parameterized). No Arabic-only strings left in presentation code paths reachable in en locale.
6. Real Kids/Adult differentiation: audience-aware theming (`SocialShareTheme.forAudience`) + template branches — kids: warmer accents, larger character, playful emblem, star decorations behind content (not overlapping); adult: typography-forward, calmer, character suppressed. Failure of the profile read now falls back to adult (currently falls back to character-on for adults via factory defaults); factory `showCharacter` defaults become `false`, with the audience resolver opting kids in.
7. `social_share_theme.dart`: replace purple `royalGradient` with an on-brand teal/turquoise "tealTwilight" palette; add `defaultThemeFor(category, audience)` so each share type opens on a fitting style (verse → light parchment typography-first; achievement → emerald celebration; streak → midnight+gold, etc.); user can still override. Rebalance shell decoration (border 2.0→1.25, lower ornament alphas) to de-certificate the look.

**P2/P3 fixes**
8. `Directionality(copy.direction)` on header/footer/badge rows; hide English `translation` on Arabic-locale cards; `quranAyah` stops setting raw `'1'` subtitle (plain-text share shows labeled reference instead).
9. `cacheWidth` on logo/character `Image.asset`s; extract streak-ember/medal-gold magic colors into `TaliaShareColors`; relocate kids stars; drop redundant on-screen `Screenshot` wrapper; align `baseWidth` to 360.

## PHASE C — Verification

1. `flutter analyze` clean; full `flutter test` green.
2. Rewrite/extend `test/core/widgets/social_share_test.dart` + new export-QA test covering the 16-case matrix (achievement ar/en, verse ar/en, dua, memorization, streak, progress, kids, adult, long verse/title/name, all 3 dimensions): overflow exceptions, content presence per locale, audience differentiation, per-category default themes, and **actual PNG dimension check** (decode IHDR: 1080×1350 / 1080×1080 / 1080×1920) using the same capture path as production.
3. Visual QA: test harness loads real Amiri/Noto fonts via `FontLoader` and writes the 16 PNGs to a temp dir; inspect each image directly (hierarchy, RTL readability, no clipping, branding, not certificate-like) and iterate on visuals before finishing.
4. Certificate safety: `git diff` confirms only `lib/core/widgets/social_share/**` + test files changed; certificate feature files and the 6 call sites untouched; `SocialShareData.certificate()` signature preserved.
5. Final report: executive summary, honest compliance score, P0/P1 list, fixes, files changed, data sources per type, branding assets, dimensions, tests, visual QA findings, certificate safety statement.