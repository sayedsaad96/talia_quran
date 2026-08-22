# Talia Social Share Cards — Visual Redesign Plan

## Goal
Recreate the reference image's premium night-emerald/gold design language inside the **existing** social share architecture (SocialShareData → Sheet → Card → Shell → Resolver → Templates → Export). No new share system, no changes to data sourcing, entry points, resolver mapping, or export pipeline. All content stays 100% dynamic.

## What stays untouched
- `social_share_model.dart` (data + factories), `social_share_sheet.dart` entry API & export (3x pixelRatio, 1080px canvases), `share_card_template_resolver.dart` mapping, `share_card_content.dart` overflow-safety (ShareCardContent + FittedBox scaleDown), theme-type names/`defaultFor` (tests + sheet picker depend on them), all `lib/features/certificate/` code and all feature entry points.
- Existing widget keys preserved so tests keep passing: `islamic-hero-arch`, `share-parchment-footer`, `share-hero-character`, `share-character-image`.

## Design direction (from reference, rebuilt in Flutter — no raster backgrounds)
Deep emerald night sky with scattered stars, a soft crescent moon, hanging gold lantern strings near the top, richer gold corner arabesques; a taller gold-outlined mihrab arch (double stroke, inner glow, faint mosque silhouette, botanical sprigs at base) framing the dynamic hero; content-type badge; large hero typography; and a **curved parchment footer** (concave arc transition like the reference) with gold keyline, star medallion logo, dynamic sharing statement, and a muted decorative icon row. Kids variants: warmer glow, more sparkles, Talia character anchored at the arch base (existing `TaliaCharacterHero`, enhanced with ground glow). Adults: restrained decoration, typography-led.

## File-by-file changes (all under `lib/core/widgets/social_share/`)

### 1. `talia_share_tokens.dart` — new decoration painters + token tweaks
- Keep `TaliaShareColors`/`Dimensions`/`Spacing`/`Typography`; add night-sky tokens (star gold, lantern glow, deep emerald ink) as needed.
- New painters (all vector, theme-color driven):
  - `StarFieldPainter` — deterministic seeded star field (dots + tiny 4-point sparkles), denser/warmer for kids, dimmed on light themes.
  - `CrescentMoonPainter` — subtle glowing crescent (top corner; dark themes only).
  - `HangingLanternsPainter` — thin gold strings with small lantern shapes hanging from the top edge (2–3, adults subtle / kids warmer glow).
  - `BotanicalSprigPainter` — gold leaf sprigs for arch base and footer corners.
  - Upgrade `GoldenCornerPainter` to a richer arabesque flourish.
- Keep existing painters that remain in use.

### 2. New `share_card_widgets.dart` — shared template components
- `TaliaCharacterInline` — dedupes the 4 duplicated adult character blocks (keeps key `share-character-image`).
- `StatMedallion` — number-in-gold-ring stat (used by memorization/streak/progress).
- `GoldDivider` — gradient rule with center ornament.
- `ShareOrnament` — small 8-point star / ornament widget.

### 3. `share_card_shell.dart` — the major redesign
- Background stack: theme gradient → star field → crescent + hanging lanterns → corner arabesques → content column. Light themes get softer gold pattern instead of night-sky elements (theme-aware via `isDark`).
- `_BrandHeader` → public `TaliaShareBrandHeader` (logo in gold ring + wordmark + tagline + `ShareTypeBadge` chip), centered like the reference.
- `IslamicHeroArch` upgraded: taller pointed mihrab silhouette, double gold outline, inner radial glow, faint mosque skyline, botanical sprigs at base, kids sparkles; keeps key. Interior wash chosen by category (illuminated parchment feel for quranAyah/dua, atmospheric for stats, ceremonial gold for certificate/achievement).
- `TaliaCharacterHero`: bottom-anchored inside arch, warm ground glow + soft shadow, per-format heights (keep key).
- `ParchmentShareFooter` redesigned: curved-top parchment panel (`CustomPainter`/`ClipPath` concave arc + gold keyline on the curve), `journeyFor(userName)` line, gold divider with center star medallion holding the real logo, `sharedFrom` statement, muted decorative icon row (pure ornament — implies no platform), botanical sprigs at corners; keeps key.
- Per-format padding: story gets taller arch + larger footer, square tightest, portrait balanced (no cropping — same Expanded column mechanism).

### 4. Templates (`templates/*.dart`) — distinct compositions, same signatures `{data, theme, format}` + ShareCardContent
- **QuranVerse**: verse is hero inside illuminated arch interior, ornamental ﴿ ﴾ brackets, surah/ayah medallion pill; no character; no fabricated text; Bismillah never added.
- **Achievement**: gold rosette/medal with `achievementIcon`, subtle burst rays, title hero, progress chip; kids extra sparkle + encouragement; adult refined.
- **Memorization**: milestone hero + `StatMedallion` stats (ayahs/surahs from real counts), open-book/Quran illumination motif, optional gold progress bar only when `targetValue` present.
- **Streak**: hero streak number in ember-glow ring, "consecutive days" banner, record line from real `targetValue`.
- **Progress**: three `StatMedallion` stats (pages/ayahs/streak) joined by gold rules; keeps inner scale-down.
- **DuaZikr**: serene lantern motif, «text» hero in Amiri, reference chip, soft glow; no character.
- **Certificate**: ceremonial double-gold frame inside arch, award sentence hero, verification-code seal; no character; certificate feature code untouched.
- Kids vs adult differentiated by composition (character, sparkle density, warmth), not just color. All new copy strings go through `SocialShareCopy` in both AR/EN (add to catalog only if needed).

### 5. Localization & RTL
- Cards already pin `Directionality` from copy; keep forcing RTL for Quran/dua text and LTR for English translations. No hardcoded Arabic-only strings.

## Tests & QA
1. `flutter analyze` — must be clean.
2. `flutter test test/core/widgets/social_share_test.dart` — all existing cases keep passing (keys, localization, kids/adult, overflow matrix, defaults). Only update a case if a visual structure legitimately changed.
3. `flutter test test/core/widgets/social_share_export_test.dart` — expand the QA matrix to cover the 10 required real cards (Quran AR/EN, Achievement adult/kids, Memorization adult/kids, Progress, Streak, Dua, Certificate) across 1:1 / 4:5 / 9:16; renders the exact production widget on the real export canvas.
4. Runtime visual QA: inspect the regenerated `build/share_qa/*.png` exports myself (Read the PNGs), iterate on composition until no clipping/overflow, clean RTL/LTR, correct hierarchy. This harness renders the true production card at export resolution.
5. Run the wider `test/core/widgets` suite to catch regressions.

## Deliverable report
Final message structured per spec §28: visual summary, design system (colors/typography/arch/hero/character/footer/ornaments), template differences, kids vs adult, format adaptation, exact files changed, test results, visual QA list, data-integrity confirmation, certificate-safety confirmation.

## Explicitly NOT doing
No hardcoded reference text, no sample content, no new logo/character assets, no reference image as background, no second share system, no certificate logic changes, no weakened tests.