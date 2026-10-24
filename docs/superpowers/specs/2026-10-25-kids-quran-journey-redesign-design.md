# Kids Quran journey: cartoon island redesign

Date: 2026-10-25. Status: **design approved section by section in chat by the owner on 2026-10-25; awaiting owner review of this written spec**. No application code, assets, or ARB keys were changed for this document.

Builds on [2026-10-16-kids-quran-journey-design.md](2026-10-16-kids-quran-journey-design.md), which defined the page, its data and behaviour. This spec changes only the visual layer.

## Goal

Make the whole-Quran journey map (`KidsQuranJourneyPage`) feel like a cartoon adventure that draws children in, close to the owner's reference concept: floating islands, a dashed golden path with coins, Talia standing on the current surah, parchment cards with stars and a progress ring, and a juz ribbon.

Success: a child sees a living, inviting world; the map stays fast with 114 rows; behaviour, data, and accessibility are unchanged or better.

## Owner decisions (2026-10-25)

1. **Art strategy B:** eight drawn island sprites plus code-drawn path, coins, cards, and glow. Generated art must contain no text, letters, Arabic calligraphy, numbers, or people. The owner approves the eight images before they enter the app.
2. **Day/night A:** follow the kids world rule (day Fajr→Maghrib, night Maghrib→Fajr). Islands are neutrally lit; code adds glow at night. One sprite set serves both phases.
3. **Motion A (moderate):** Talia breathes on the current island; completed path segments are gold with coins; on returning after finishing a surah its stars pop in once and Talia walks to the current island. All motion stops under OS reduce-motion and the guardian policy (`KidsMotionScope`).

## Assumptions (stated in chat, not contested)

- Data, statuses, jump-confirm dialog, open-on-current-surah, and routing stay as they are.
- There is no real locking. A lock glyph is a visual for `notStarted` only; tapping still opens (with the existing confirm when it is not the current surah).
- Three stars derive from existing progress: one per third. No new data.
- Surah names, ayah counts, and juz numbers come from the existing state (`surahs.json` pipeline). Nothing is copied from the reference image.

## Architecture

Keep the lazy `ListView.builder` with a fixed `itemExtent`, raised from 132 to about 200. Each row stacks: road segment painter, island sprite, card, optional juz ribbon. Talia is drawn in an overlay `Stack` above the list; her position is computed from the current row index, the extent, and the scroll offset, which lets her walk across two rows. Open-on-current-surah keeps its arithmetic.

Rejected: one tall canvas for the whole road (builds all 114 islands at once); a game engine such as Flame (new dependency for a scroll screen).

### Units

| Unit | Purpose | Location |
|---|---|---|
| `kidsSurahStars(KidsSurahHouse) → int` | 0–3 stars from progress; `needsReview` keeps earned stars | `domain/services/` (pure) |
| `kidsIslandFor(int surahId) → KidsIsland` | picks one of 8 sprites; never the same on adjacent rows | `domain/services/` (pure) |
| `KidsQuranMapCelebrationStore` | per-owner set of surah ids seen completed; returns newly completed; first visit and any error → none | `data/datasources/`, mirrors `KidsMapCelebrationStore` |
| `KidsSurahHouseCard` (restyled) | parchment card: name, ayah count, progress bar, stars, status ring (star / lock / review) | `widgets/kids_quran_journey_map.dart` |
| `KidsQuranRoadPainter` (extended) | dashed rounded path; gold + coin before current, faded cream after; night glow | same file |
| `_JuzRibbon` | gold ribbon with folded tail, existing localized juz text | same file |
| `KidsQuranTaliaOverlay` | Talia pose, breathing, walk animation | new widget file |
| `KidsQuranJourneyCubit` | additionally exposes the celebrated surah ids from the store | existing cubit |

## Row composition

- Island sprite at about 40% of the width, alternating side per row, direction-aware (RTL/LTR). The card overlaps the island slightly so it appears to rest on it.
- Card: cream parchment gradient, thick rounded border, soft shadow; name (one line, ellipsis), ayah count, progress bar, three stars; circular progress ring on the far edge containing a star (completed), faded lock (not started), purple review glyph (needs review), or progress only (in progress).
- Current surah: glowing gold border; Talia (`readingQuran` pose) stands on its island.
- Juz ribbon above the first surah of each juz.

## Path, coins, motion

- Before the current surah: warm gold dashes and one code-drawn coin (rim + star) mid-segment. After it: faded cream dashes, no coins.
- Coins are decorative only. No balance or counter, so no reward system parallel to XP/stars.
- Talia breathing: 2% scale, about 3 s period; the only continuously running controller.
- Celebration: when the store reports surahs completed since the last visit, that surah's stars pop in one by one, then Talia (`celebrate` pose) walks along the path to the current island in about 1.5 s and returns to `readingQuran`. Once per completion.
- Coins shimmer once when a row first appears.
- Reduce-motion (OS or guardian policy via `KidsMotionScope`): no controllers run; final states render immediately.

## Day and night

Read the phase from `KidsWorldPhaseScope`; the background stays `KidsBackground`.

- Night: warm halo behind completed and current islands, coin glow, a few static code-drawn fireflies.
- Day: no halos; soft ground shadow under each island; coins bright gold without glow.

## Island assets

Eight transparent 512 px PNGs in `assets/images/kids/islands/`, matching the reference style (floating rock island with grass top):

1. palms and lantern
2. small mud house with dome
3. waterfall and pool
4. sand fort
5. camel with colourful saddle
6. closed mushaf on a stand (fully closed, no visible text)
7. oasis and tent
8. flower garden and fountain

Constraints in every prompt: no text, letters, calligraphy, numbers, signs, logos, people, or watermarks; neutral lighting with no baked glow. Document prompts and processing in `assets/images/kids/islands/generated_island_assets.md`, as was done for the house assets. Register the folder in `pubspec.yaml`. The owner approves the images before integration.

## Accessibility

- Card semantics keep name, ayah count, status, current marker; add the star count through a new ARB key pair (`app_ar.arb` + `app_en.arb`).
- Islands, road, coins, fireflies, and Talia are decorative (`ExcludeSemantics`).
- Text colour stays `inkOnParchment`; tap target stays the whole card.
- No overflow in RTL and LTR at text scale up to 1.3.

## Performance

- Lazy fixed-extent list; only visible rows build.
- Island images decode with a `cacheWidth` matched to their display size.
- Static painters wrapped in `RepaintBoundary`; one continuous controller.

## Testing

- Unit: `kidsSurahStars` (0, ⅓, ⅔, complete, needsReview); `kidsIslandFor` (no adjacent repeat); `KidsQuranMapCelebrationStore` (first visit none, only new ones later, owner isolation, storage failure → none).
- Widget (extend `test/features/memorization_plus/presentation/pages/kids_quran_journey_page_test.dart`): stars/lock/review per status; Talia only on the current surah; no running animation controllers under reduce-motion; no overflow in RTL/LTR at text scale 1.3; jump-confirm and open-on-current unchanged.
- Asset: the eight island files exist and are declared.
- Manual: emulator screenshots at day and night compared against the reference.

## Out of scope

- Any change to data, repository, status rules, or real currency.
- `assets/images/kids/house_current.png` contains generated calligraphy resembling the basmalah, the word قرآن, and a "QURAN CLASS" sign, which conflicts with the Islamic content policy. This redesign does not use it on the map. Handling it is a separate task.
