# Social Share Card Redesign ("Dawn") — Design Specification

**Product:** Talia Quran
**Feature:** Social share cards (`lib/core/widgets/social_share/`)
**Date:** 2026-09-28
**Status:** Approved direction, written for review. Design proposal, not an implementation claim.

---

## 1. Intent

The shared image is Talia's most-travelled marketing surface. It must:

- make the **content the hero** (ayah, dua, dhikr, achievement) so people share it because it is beautiful, and the brand rides along;
- carry **Talia's identity** unmistakably — the official logo, the emerald and gold palette, the pointed arch and the golden light rising from the open mushaf;
- invite others gently and purposefully (religious, encouraging, never an ad banner);
- look clearly better and more modern than the current cards.

Decisions taken with the owner during brainstorming:

| Question | Decision |
|---|---|
| Philosophy | Content first; brand is a quiet signature at the bottom. |
| First direction round (mushaf / emerald / editorial) | Rejected as "too traditional". |
| Visual direction | **Dawn** (cinematic light) + **Kufi numerals** for stats. |
| Identity | Keep Talia's identity and the official logo `assets/images/logo_new_padded.png`. |

### Problems in the current cards (observed in the QA matrix, `build/share_qa/`)

1. Ornament overload: lanterns, moon, corner arabesques, arch, rays, sprigs, character, badge, medallion, pill button and slogan all compete.
2. Brand repeated (logo twice, character in header, "تالية" three times).
3. Hero content occupies under a third of the canvas; story format has large empty areas.
4. A download "button" inside a static image reads as an ad and cannot be tapped.
5. Detail defects: streak number off-centre, scene pillars, floating footer.
6. No scannable path to the app, although `qr_flutter` is already a dependency.

## 2. Non-goals / unchanged

- `SocialShareData` fields and factories, `SocialShareCategory`, `SocialShareAudience`, `SocialShareFormat` (sizes 1080×1350, 1080×1080, 1080×1920).
- `SocialShareSheet.show(context, data)` API and all ~12 call sites.
- `captureSocialShareCardImage(...)` contract (1080 px width, pixel ratio 3) except that `theme:` becomes `mood:` (see §6).
- Plain-text share (`toPlainShareText`, `plainShareFooter`).
- Quran/azkar text: no change to text, source, or font (Amiri). No new religious text anywhere.

## 3. Visual system

### 3.1 Brand anchors

| Anchor | Source | Use on card |
|---|---|---|
| Emerald | `AppColors.primaryDark #042F2E`, `darkBackground #021210`, `primary #0D5C53` | Sky gradient base |
| Gold | `AppColors.gold #F59E0B`, glow `#FFCE6E` | Horizon light, eyebrow, reference, arch line |
| Mushaf light | The logo's open glowing book | Radial gold glow rising from bottom-centre ("dawn") |
| Pointed arch | The logo's mihrab silhouette | One faint gold hairline arch framing the hero (not a filled frame) |
| Logo | `assets/images/logo_new_padded.png` (1152², RGBA, transparent corners, soft round glow) | Once, in the signature bar, on emerald |
| Wordmark | "تالية القرآن" / "Talia Quran" | Reem Kufi, gold, beside the logo |

The logo appears **exactly once** per card. No lanterns, moon, corner arabesques, sprigs, skyline, or medallion.

### 3.2 Layer stack (every category, every format)

1. **Sky** — vertical linear gradient `top → mid → base` from the palette.
2. **Mushaf light** — radial gradient centred at bottom-centre (`Alignment(0, 1)`), radius ≈ 0.75 of width, gold → transparent. Strength per palette.
3. **Watermark word** (text-hero categories only) — the surah name (ayah) or the category word ("دعاء", "ذِكر") in Reem Kufi Bold, ~2× verse size, 7 % opacity, centred at ~20 % height. Never a Quran/azkar fragment.
4. **Arch hairline** — `CustomPainter` path of the logo's pointed arch, stroke 1 logical px, gold at 55 % opacity, inset 9 % horizontally, top 9 %, bottom stops above the signature bar.
5. **Content column** — eyebrow → hero → reference → optional personal line → signature bar.

### 3.3 Palettes (`share_card_palette.dart`, exempt from the design-token guard by the `_palette.dart` suffix)

A `SharePalette` holds: `skyTop, skyMid, skyBase, glow, glowStrength, textPrimary, textAccent, eyebrow, signatureSurface, signatureBorder, signatureText, qrForeground, qrBackground, archLine`.

| Palette | Used for | skyTop | skyMid | skyBase | glow strength |
|---|---|---|---|---|---|
| `mushafLight` | quranAyah | #021210 | #042F2E | #0D5C53 | 0.85 |
| `suhoor` | dua | #0B1530 | #062C35 | #0D5C53 | 0.75 |
| `dusk` | azkar | #06202E | #053338 | #0D5C53 | 0.75 |
| `sunrise` | achievement, certificate, khatmah | #021210 | #0A3A33 | #148275 | 1.0 (wider radius) |
| `forenoon` | memorization, progress, streak | #021210 | #042F2E | #148275 | 0.85 |
| `kidsMorning` | any category when `audience == kids` | #0D5C53 | #148275 | #1FA08E | 1.0 |
| `night` | "Night" mood, all categories | #021210 | #042F2E | #0D5C53 | 0.55 |
| `day` | "Day" mood, all categories | #FDFCF8 flat | — | — | 0.28 |

Dark palettes: `textPrimary #FFF8EC`, `textAccent/eyebrow #F5C45A`, signature surface `#021210` @ 55 % with `#F5C45A` @ 45 % border.
Day palette: `textPrimary #1A1209`, `textAccent #B8862A`, eyebrow `#0D5C53`, signature surface solid `#042F2E` (so the logo always sits on emerald).

### 3.4 Moods (replace the 8 themes)

`enum SocialShareMood { auto, night, day }` — default `auto`.

- `auto` → category palette (table above; kids override).
- `night` → `night` palette.
- `day` → `day` palette.

`SocialShareThemeType` and `SocialShareTheme` are removed.

### 3.5 Typography

| Role | Font | Notes |
|---|---|---|
| Quran verse, dua/dhikr text | Amiri (unchanged `TaliaShareTypography.quranVerse`) | Exact source string, no styling of individual words |
| Reference, personal line, invitation | Noto Naskh Arabic | |
| Eyebrow, wordmark, numerals, stat labels, watermark word | **Reem Kufi** (new, OFL-1.1) | Never used for religious text |

Reem Kufi is bundled under `assets/fonts/Reem_Kufi/` (Regular 400, SemiBold 600, Bold 700 static TTFs + `OFL.txt`) and declared in `pubspec.yaml` as family `Reem_Kufi`. Bundling is required because cards are exported offline; `google_fonts` runtime fetching is not acceptable here. Downloading the font files needs the owner's go-ahead at implementation time.

Adaptive verse sizes (logical px, canvas width 360), larger than today:

| Length (chars) | square | portrait | story |
|---|---|---|---|
| ≤ 80 | 21 | 24 | 28 |
| ≤ 150 | 18 | 21 | 25 |
| ≤ 250 | 15.5 | 18 | 22 |
| > 250 | 13 | 15 | 18 |

`ShareCardContent` (scale-down, never clip) stays as the final safety net.

All sizes, paddings and radii live as named constants in `talia_share_tokens.dart` (`TaliaShareMetrics`) so new widget files contain no `fontSize: <literal>`, `Color(0x…)`, `BorderRadius.circular(<literal>)` or `isDark ?` — the design-token guard (`test/design_system/design_token_guard_test.dart`) starts new files at zero. Removed files' baseline entries are deleted; remaining entries may only shrink.

### 3.6 Layout per format (logical px on the 360-wide canvas)

| | square 360×360 | portrait 360×450 | story 360×640 |
|---|---|---|---|
| Outer padding | 16 | 20 | 24 (top 40 for story safe area) |
| Eyebrow size | 10 | 11 | 13 |
| Signature bar height | 44 | 50 | 60 |
| Logo size (in bar) | 34 | 40 | 48 |
| QR size | 34 | 40 | 52 |
| Story bottom safe area | — | — | 56 above bar |

Content column: eyebrow (centred) → `Expanded` hero (centred) → reference (gold) → personal line "رحلة {name} مع القرآن" (only when a name is present and shown) → signature bar.

### 3.7 Signature bar (`share_signature_bar.dart`)

`[logo] [wordmark over invitation line] [QR]` in RTL, rounded 12, glass surface on dark palettes / emerald on day.

- **Logo**: `logo_new_padded.png` clipped to a circle, scaled ×1.35 so the emblem (not the padding) fills it; `cacheWidth` ≈ 3× display size.
- **Wordmark**: "تالية القرآن" / "Talia Quran", Reem Kufi SemiBold, gold.
- **Invitation line**: per category (§4), Noto Naskh, 1 line, ellipsis.
- **QR**: `QrImageView` of `ShareCardLinks.forCategory(category)`, foreground `#042F2E`, background `#F0EDE6`, error correction M, 2-module quiet zone. At portrait size it exports at 120 px — scannable from a phone screen.

`ShareCardLinks.forCategory(c)` = `https://taliaapp.com/?utm_source=talia_app&utm_medium=share_card&utm_campaign=<c.name>` (built with `Uri`, no user data in the URL).

No "download" pill, no domain line, no brand-promise slogan.

## 4. Per-category hero and copy

All copy below is **app-authored marketing copy**, not religious text. It lives in `SocialShareCopy` and is subject to owner review before release.

| Category | Eyebrow (ar / en) | Hero | Invitation (ar / en) |
|---|---|---|---|
| quranAyah | "آية · سورة {name}" / "Ayah · Surah {name}" | Verse (Amiri) + reference "{surah} {n}" | "شاركها… لعلّها تهدي قلبًا" / "Share it — it may guide a heart" |
| dua | "دعاء" / "Dua" (+ category title if present) | Text + `subtitle` reference verbatim | "ادعُ بها لمن تحب" / "Pray it for someone you love" |
| azkar (text) | "ذِكر" / "Dhikr" (+ category title) | Text + reference verbatim | "ذكّر بها من تحب" / "Remind someone you love" |
| azkar (wird progress, empty content) | `title` as given (e.g. "أذكار الصباح"), no prefix added | Kufi `completed/total` + progress bar | "حافظ على أذكارك معي" / "Keep your adhkar with me" |
| achievement | "إنجاز جديد" / "New achievement" | 8-point star medal (gold hairline) with the achievement emoji/icon, title (Kufi), description | "رافقني في رحلتي مع القرآن" / "Join my Quran journey" |
| memorization | "حفظ القرآن" / "Memorization" | Kufi numeral ayahs + "آيةً في صدري" + thin bar to target + "{n} سورة مكتملة" | "احفظ معي… خطوة كل يوم" / "Memorize with me, one step a day" |
| streak | "استمرارية" / "Streak" | Kufi numeral + day label + longest/new-record line | "ابدأ وِردك اليوم" / "Start your daily wird today" |
| progress | "حصاد التقدم" / "My progress" | Three Kufi stats (pages · ayahs · streak) | "رافقني في رحلتي مع القرآن" / "Join my Quran journey" |
| certificate | "شهادة إتمام" / "Certificate" | Award title (domain data, Kufi) + star medal + verification code | "رحلة إتقان مع تالية" / "A journey of mastery with Talia" |
| khatmah | "ختمة القرآن" / "Quran Khatmah" | "{title}" + Kufi days + pages + dedication subtitle | "ابدأ ختمتك القادمة" / "Start your next khatmah" |
| kids (any) | "أبطال تالية الصغار" / "Little Talia champions" | Category hero + companion character | "بطلٌ صغير يحفظ القرآن" / "A little champion memorizing Quran" |

**Arabic counting**: day/ayah/surah labels use a count-aware helper in `SocialShareCopy` (1 → "يوم واحد", 2 → "يومان", 3–10 → "أيام", 11+ → "يومًا"; same pattern for آية/سورة). Digits stay Western, as today.

**Character**: shown only on kids cards (prominent, bottom-leading of the hero), and only when `SocialSharePresentation` says the text load allows it. Adult cards never show the character. The `subtle` treatment is removed.

## 5. Share sheet

- The 8-theme grid is replaced by a 3-chip **mood selector** ("تلقائي · ليل · نهار" / "Auto · Night · Day"), each chip with a small live mini-preview swatch of the palette.
- Format selector, "show my name" toggle, share-as-image, save-to-gallery, share-as-text are unchanged.
- No persistence of the chosen mood (matches today's behaviour for themes).

## 6. Code structure

```
lib/core/widgets/social_share/
  social_share_model.dart          unchanged
  share_card_palette.dart          NEW  SocialShareMood, SharePalette, SharePalettes.resolve(data, mood)
  share_card_links.dart            NEW  ShareCardLinks.forCategory
  share_card_backdrop.dart         NEW  sky + mushaf light + watermark + arch hairline painter
  share_signature_bar.dart         NEW  logo + wordmark + invitation + QR
  share_card_shell.dart            REWRITE  composes backdrop, eyebrow, hero slot, personal line, bar
  share_card_content.dart          unchanged (scale-down safety)
  share_card_template_resolver.dart  palette instead of theme
  templates/                       REWRITE each template on the new tokens
    quran_verse_template.dart, dua_zikr_template.dart,
    streak_template.dart, memorization_template.dart, progress_template.dart,
    achievement_template.dart, certificate_template.dart
  share_medal.dart                 NEW  8-point star medal (replaces ShareStarOrnament use)
  talia_share_tokens.dart          TRIM  keep typography + TaliaShareMetrics; drop night-scene colours
  share_card_widgets.dart          DELETE (painters: star field, lanterns, moon, corners, sprigs, rosette, hexagon, calligraphy border)
  social_share_theme.dart          DELETE
  social_share_presentation.dart   SIMPLIFY (none | prominent)
  social_share_copy.dart           ADD invitations, eyebrows, mood names, count helper; REMOVE badges/slogans/CTA no longer used
  social_share_sheet.dart          mood selector; capture passes mood
  social_share_card.dart           pass mood
```

`captureSocialShareCardImage({context, data, mood, format, hideUserName})` — the only signature change; all in-package.

Font asset: `assets/fonts/Reem_Kufi/*` + `pubspec.yaml` entry.
Logo asset: `logo_new_padded.png` is already declared (used by `home_skin` and splash); `precacheImage` it in the sheet before first capture, as today for the character.

## 7. Content-policy guarantees

- Verse text is `QuranAyahDisplayText.withoutTrailingNumber(ayah.text)` exactly as today; reference number is shown separately. Covered by `social_share_quran_exactness_test.dart`, which must pass unchanged.
- Dua/dhikr text and `reference` are rendered verbatim from the approved `Zikr`; no truncation, no re-wrapping into highlighted fragments.
- The watermark word is never a Quran or azkar fragment (surah name or category label only).
- Invitations are app copy (§4) flagged for owner review; no hadith, ayah, or dua is added to any card.

## 8. Testing

| Test | Change |
|---|---|
| `test/core/widgets/social_share_test.dart` | Replace theme assertions with mood/palette resolution; assert one logo per card, QR present with the per-category URL, invitation per category, no character on adult cards, Amiri on verse and Reem Kufi never on verse/dua text. |
| `test/core/widgets/social_share_export_test.dart` | Same 28-case QA matrix on moods; add `auto/night/day` × ayah and kids cases; still asserts exact 1080 export sizes and no layout exceptions. Loads Reem Kufi in `_loadRealFonts`. |
| `social_share_quran_exactness_test.dart`, `social_share/social_share_khatmah_test.dart` | Must pass; update only constructor args if the theme param is referenced. |
| `share_card_palette_test.dart` (new) | Every category × audience × mood resolves; text/background contrast ≥ 4.5:1 for `textPrimary` on `skyMid` and signature text on signature surface. |
| `share_card_links_test.dart` (new) | URL shape and that it contains no user data. |
| `design_token_guard_test.dart` | Passes; delete entries for removed files, lower others where counts dropped. |

Visual acceptance: regenerate `build/share_qa/*.png` and review every image (long verse, long name, English, kids, square/story) before claiming completion.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Gold glow reduces contrast near the bar | Bar sits on its own dark glass surface; glow centre is below the hero. Contrast test. |
| QR not scannable after platform recompression | Error correction M, ≥ 34 logical (≥ 102 px) with quiet zone; manual scan check on exported PNG. |
| Long verses (Ayat al-Kursi) in square | Adaptive size table + `ShareCardContent` scale-down; QA case 11 covers it. |
| Landing page ignores UTM | Harmless; campaign data is optional analytics. |
| Font licence | Reem Kufi is OFL-1.1; ship `OFL.txt` with the font. |

## 10. Out of scope

Animated/video cards, per-user custom backgrounds, translations on cards beyond what `SocialShareData.translation` already carries, server-side tracking of shares, and changes to the landing page.
