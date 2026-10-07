# Talia icon system

Status: implemented (direction A "Nuqta", plus the coloured doors from B for the kids track). Approved by the owner on 2026-10-07.

## Why

Before this change the app used 238 different Material icons, 810 times, all stock. The audit found:
- The navigation icons did not match their tabs. Hifz was a brain (`psychology`), Azkar was the generic AI sparkle (`auto_awesome`), and Progress was a trophy.
- The same meaning had two icons: the Mushaf was both `menu_book` and `auto_stories`.
- Prayer times used `mosque`, the icon every Islamic app uses.
- The kids track used the adult icons, only recoloured.

## The language

| Rule | Value |
|---|---|
| Grid | 24 × 24 |
| Stroke | 1.75, round caps, round joins (kids: 2.5) |
| Signature | The nuqta: a small rhombus, like the qalam dot of «تـ», on Talia feature icons only |
| States | The nuqta lights up in gold (`tokens.gold`) only when the icon is active. When inactive it keeps the icon colour. Filled glyphs (`starFilled`, `checkCircleFilled`, …) are kept only where filled vs outline carries a meaning |
| RTL | Directional glyphs set `matchTextDirection`, exactly like the Material icons they replace |
| Avoided | Crescent, mosque, lantern, and crescent-with-star. The moon glyph is a plain moon for night and Isha |

Feature glyphs, all custom and drawn in `tools/icons/src/talia`:

| Glyph | Use |
|---|---|
| `home` | Home |
| `mushaf` | Mushaf: an open book with the nuqta above the spine |
| `reading` | Khatmah and reading: the book with a gold ribbon |
| `hifz` | Hifz: a heart with lines of text. Hifz is "in the chest", not a brain |
| `recite` | Recitation |
| `mic` | Microphone |
| `azkar` | Azkar: a repeat loop around the nuqta |
| `dua` | Dua: a hand holding a gold heart |
| `prayer` | Prayer: the sun on the horizon, replacing the mosque |
| `flame` | Streak |
| `medal`, `certificate`, `trophy` | Rewards |
| `progress` | Progress |
| `sparkle` | Smart and suggested items |
| `journey` | Journey, maps, explore |
| `listen` | Listening |
| `family` | Family and guardian |

Generic glyphs (close, arrows, media, settings, …) come from Lucide (ISC). They are rebuilt at Talia's stroke weight, so they read as one family with the custom glyphs. The license is shipped in `assets/fonts/TaliaIcons/LICENSE-lucide.txt` and listed in the open-source licenses page through `LicenseRegistry` in `main.dart`.

## Kids variant

- Every icon has a kids glyph under the same name (`TaliaKidsIcons.x`). It uses a 2.5 stroke, a soft tinted fill layer, and draws the nuqta as a yellow sparkle (`AppColors.kidsSparkle`).
- Kids files use `TaliaKidsIcons` directly. This also covers dialogs, which open outside any route subtree. `TaliaIconScope.kids` switches `TaliaIcons` to the kids glyphs for a whole subtree.
- `TaliaFeatureDoor` comes from direction B. It is a coloured arch in the shape of the logo frame, holding a white kids glyph. It gives each kids "place" its own colour: the home navigation cards, the treasure regions, and parent gifts.
- The door colours are `AppColors.kidsDoor*`. Each one keeps a white glyph at 3:1 or better (WCAG non-text contrast).

## How it is built

`tools/icons/build_talia_icons.py` (needs `pip install fonttools skia-pathops`):
1. It strokes the SVG sources to outlines with Skia PathOps and builds two TrueType fonts: `TaliaIcons` and `TaliaIconsKids`.
2. It writes the accent (nuqta) and kids fill layers as extra glyphs at codepoint + 0x800 and codepoint + 0x1000.
3. It generates `lib/core/icons/talia_icon_data.dart`. All `IconData` there are `const`, so release builds can still tree-shake the icon fonts.
4. Codepoints are append-only (`tools/icons/codepoints.json`). Never renumber them.

To add an icon:
1. Draw a 24-grid stroke SVG. Use `class="nuqta"` (a `<circle cx cy r>`) for the rhombus, `class="accent"` for any other gold part, and `class="fill"` for the kids tint.
2. Add the icon to `manifest.json` and run the script.
3. Use `TaliaIcons.<name>` in code.

## Using it

- Use `Icon(TaliaIcons.x)` anywhere `Icon(Icons.x)` was used. It is a drop-in, monochrome glyph.
- Use `TaliaIcon(TaliaIcons.x, active: …)` where the gold nuqta should light up: the navigation (`app_shell.dart`), selected states, and feature headers.
- `test/core/icons/talia_icon_test.dart` fails if Material `Icons.*` comes back anywhere in `lib/`.
