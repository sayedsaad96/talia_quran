# 01 — Quran Foundations

## Purpose
Give any agent working on Talia a correct, software-usable mental model of how the Quran is structured, so navigation, progress tracking, and content models are built on accurate primitives.

## Overview
The Quran's structure is not arbitrary — it has multiple overlapping division systems (surah/ayah, juz, hizb, rub', manzil) used for different purposes (study vs. recitation pacing vs. memorization planning). Talia's data model needs to represent all of them, because users think in different units depending on context (a hafiz thinks in juz; a beginner thinks in surah).

## Core Concepts
- **Surah (سورة):** a chapter. 114 total, each with a name, a revelation-place classification (Makki/Madani), and a fixed ayah count.
- **Ayah (آية):** a verse — the atomic unit. Numbered both within its surah and globally.
- **Juz' (جزء):** one of 30 roughly equal parts, used to pace a full reading (khatm) over a month.
- **Hizb (حزب):** half a juz (60 total); each hizb is further split into 4 arba' (quarters, 240 total) — used for granular progress tracking.
- **Sajdah (سجدة):** a verse containing a command/description that calls for a prostration upon recitation.
- **Makki / Madani:** whether a surah was revealed before or after the Hijrah — affects theme (Makki: belief/afterlife; Madani: law/community) but is a classification about revelation, not a ranking of importance.
- **Mushaf page:** the standard 604-page Madani Mushaf layout most printed/digital Qurans follow — useful for a "page-based" reading UI that matches what users are used to from print.

## Detailed Explanation
**Stable counts (Hafs 'an 'Asim riwayah — the most widely used globally, and what Talia should default to):**
- 114 surahs, 30 juz, 60 hizb, 240 rub' al-hizb, 604 Mushaf pages.
- Longest surah: Al-Baqarah (286 ayahs). Shortest: Al-Kawthar (3 ayahs).
- Al-Fatiha has 7 ayahs (Basmalah counted as ayah 1 — this is specific to Al-Fatiha; elsewhere the Basmalah at the start of a surah is not numbered as a separate ayah).

**Total ayah count is riwayah-dependent — do not hardcode a single "true" number as universal.** The commonly cited 6,236 figure is the Kufi counting convention underlying the Hafs riwayah used in the standard Madani Mushaf. Other counting traditions (Basri, Meccan, Medinan, Syrian) split some long verses differently and arrive at slightly different totals. For a Hafs-only app like Talia this is usually a non-issue, but never present "6,236" as the single universal count if the app ever adds another riwayah (e.g., Warsh, common in parts of North/West Africa).

**Sajdah verses are a genuine, unresolved point of scholarly difference — do not silently pick one number.** There are 14 sajdah locations agreed upon by essentially all schools, plus one additional disputed location where sources differ on *which* verse it is (commonly discussed as Surah Al-Hajj 22:77 vs. Surah Sad 38:24, with the Hanafi school generally counting 14 and Shafi'i/Hanbali often counting 15). Talia should tag sajdah verses with the counting tradition rather than asserting a single "14" or "15," and this data should come from a vetted Mushaf dataset, not be hand-entered.

## Important Classifications
| Division | Count (Hafs) | Typical use in-app |
|---|---|---|
| Surah | 114 | Navigation, browsing, memorization "surah mode" |
| Ayah | ~6,236 (riwayah-dependent) | Atomic memorization/review unit |
| Juz' | 30 | Monthly khatm planning, "juz progress" bar |
| Hizb | 60 | Mid-granularity progress tracking |
| Rub' al-hizb | 240 | Fine-granularity progress tracking, daily targets |
| Mushaf page | 604 | Page-turn reading UI, "page memorized" mental model |
| Sajdah | 14 agreed + 1 disputed | Reading-mode UI prompt to note the prostration |

## Practical Rules
- Store `globalAyahNumber`, `surahNumber`, `ayahNumberInSurah`, `juz`, `hizb`, `rub`, and `pageNumber` on every ayah record — don't compute juz/hizb/page on the fly from unreliable heuristics.
- Never infer Makki/Madani, sajdah status, or ayah counts from a translation source — use a canonical Arabic Mushaf dataset (see `18_references.md`).
- When displaying "verses in this surah," always match the riwayah of the displayed Arabic text.

## Common Mistakes
- Treating juz boundaries as if they align with surah boundaries (they usually don't — a juz frequently starts or ends mid-surah).
- Assuming all Quran datasets number ayahs identically (Basmalah handling differs across data sources — this is a common cause of off-by-one ayah bugs).
- Presenting Makki/Madani as a value judgment in copy ("less important because Makki") — it is a chronological/thematic classification only.

## UX Implications
- Progress bars and "percent memorized" should let the user choose their mental unit (surah / juz / page) rather than forcing one.
- Sajdah verses should get a distinct, unobtrusive in-reading indicator (Talia already uses a page-based reading UI — a small marker matching the printed Mushaf symbol is the familiar pattern) without interrupting audio/reading flow.

## Engineering Implications
- The `Ayah`/`Surah` models already defined in Talia's technical stack (see the `quran-islamic-apps` engineering skill) should treat `juzNumber`, `hizbNumber`, and `pageNumber` as required, sourced fields — not derived at runtime.
- Any new riwayah added later (e.g. Warsh for a North African audience) needs its own ayah-count and Basmalah-numbering handling — do not assume the Hafs numbering generalizes.

## Product Implications
Users' sense of progress is emotionally tied to these units ("I finished Juz 'Amma"). Getting the division data right is a retention feature, not just a data-correctness issue.

## AI Design Guidelines
- When asked to generate or infer any structural fact about the Quran (counts, page numbers, sajdah status) that isn't already in a vetted dataset, say so and recommend sourcing it rather than asserting a number.
- Default to the Hafs riwayah unless a feature explicitly targets another riwayah's audience.

## Examples
- ✅ "Juz 1 begins at Al-Fatiha 1:1 and ends at Al-Baqarah 2:141 (Hafs numbering)."
- ❌ "The Quran has exactly 6,236 verses" stated as a universal fact with no riwayah qualifier, in content meant to generalize across readings.

## References
Structural facts here reflect the standard Hafs 'an 'Asim Madani Mushaf, cross-checked against multiple current sources on sajdah-count variation (see `18_references.md` for the vetted datasets Talia should actually load structural data from).

## Future Extensions
- Add a dedicated sub-table for riwayah-specific numbering deltas if/when Talia supports more than one riwayah.
- Add a `manzil` (7-part weekly reading division) reference table if a "weekly khatm" feature is ever planned.
