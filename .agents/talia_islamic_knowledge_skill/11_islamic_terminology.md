# 11 — Islamic Terminology

## Purpose
Provide a working glossary of Islamic/Quranic terms an AI agent will repeatedly encounter while building Talia, each with enough context to use the term correctly in code, copy, and design discussions.

## Overview
Consistent, correct terminology use is a low-effort, high-payoff form of content quality — inconsistent transliteration or misused terms across screens reads as unpolished to Talia's target audience. This module is a working reference; `17_glossary.md` is the compact, flat-lookup version of the same terms for quick scanning.

## Core Concepts
Entries below follow: **Term (Arabic) — Definition — Context/Usage — Related — Software implication.**

### Hifz (حفظ)
Memorization of the Quran. Context: the core activity Talia is built around. Related: muraja'ah (review), talqin (dictation-style teaching). Software: primary domain object naming (`MemorizationEntry`, `hifz`-prefixed routes) should use this term consistently rather than mixing "memorization" and "hifz" arbitrarily in code vs. UI.

### Muraja'ah (مراجعة)
Revision/review of previously memorized material. Related: hifz. Software: distinct feature area from new memorization — see `07_revision_methodology.md`.

### Tilawah (تلاوة)
Recitation of the Quran (reading aloud, with proper tajweed), as distinct from silent reading or memorization. Software: relevant to labeling "reading mode" vs. "memorization mode" vs. "review mode" distinctly.

### Khatm (ختم)
Completing a full reading of the Quran cover-to-cover. Related: juz'-based pacing (see `01_quran_foundations.md`). Software: natural feature name for a "complete the Quran in N days" reading-plan feature, distinct from hifz progress.

### Wird (ورد)
A regular, often daily, portion of Quran recitation/review a person commits to. Software: Talia's companion character "celebrates on finishing wird" — this term should map to a concrete daily-target data object, not just flavor text.

### Ayah al-Kursi (آية الكرسي)
The well-known verse (Al-Baqarah 2:255) about Allah's dominion — frequently referenced in adhkar contexts. Software: if referenced, pull as a normal ayah record (see `01_quran_foundations.md`), not as special-cased freeform text.

### Isti'adhah (استعاذة) / Ta'awwudh
The phrase "A'udhu billahi min al-shaytan al-rajim," recited before Quran recitation. Software: relevant to reading-mode UI conventions (often shown/played before Basmalah at the start of a session).

### Basmalah (بسملة)
"Bismillah al-Rahman al-Rahim" — recited at the start of most surahs (see numbering note in `01_quran_foundations.md`). Software: needs consistent handling across surah-start UI and audio.

### Fiqh (فقه)
Islamic jurisprudence — scholarly derivation of practical rulings. Related: madhab. Software: Talia should avoid issuing fiqh rulings itself (see `14_content_validation.md`); fiqh-adjacent content needs explicit sourcing and madhab attribution.

### Madhab (مذهب)
A school of Islamic jurisprudence (commonly: Hanafi, Maliki, Shafi'i, Hanbali, among others). Software: relevant wherever a practice varies by school (e.g., sajdah count, see `01_quran_foundations.md`) — tag content by madhab rather than picking one silently.

### Sunnah (سنة)
The Prophet's ﷺ practice/example, as distinct from Quran (revealed text) and later scholarly opinion. Software: relevant to labeling content-source type per `14_content_validation.md`'s source-type list.

### Salaf / Salafus-Salih
The early generations of Muslims often referenced as an authoritative interpretive reference point in some traditions. Software: mostly relevant to how tafsir/fiqh sourcing describes a work's methodology — not something Talia needs to take a doctrinal position on.

### Mushaf (مصحف)
The physical/printed (or digital-rendered) copy of the Quran text. Software: the term for the rendered Quran text component itself (`Mushaf` display, page-based reading UI).

### Sabaq / Sabqi / Manzil (in hifz pedagogy usage)
Traditional hifz-circle terms: *sabaq* (new lesson/portion being memorized today), *sabqi* (recently memorized portion still in short-term consolidation), *manzil* (long-term memorized portion in the maintenance review cycle — not to be confused with the unrelated "Manzil" 7-part Quran division mentioned in `01_quran_foundations.md`). Software: these three map closely onto Talia's memorization-stage model in `06_memorization_science.md` (new acquisition / consolidation / long-term retention) and are useful internal naming if a more traditional hifz-circle terminology is ever wanted in UI copy.

## Detailed Explanation
This glossary is deliberately not exhaustive — it covers terms that recur across Talia's actual feature set. Add new entries as new features surface new terms, following the same five-field format.

## Important Classifications
See the per-term "Related" and "Software implication" fields above; this module doesn't need a separate classification table beyond the entries themselves.

## Practical Rules
- Use consistent transliteration across the codebase and UI copy (pick one romanization convention — e.g., "Muraja'ah" not alternately "Murajaah"/"Moraga'a" — and stick to it; a terminology style guide is a good `Future Extensions` candidate).
- Arabic terms used in UI copy should generally be paired with a brief plain-language gloss on first use per screen, especially for less common terms (sabaq/sabqi/manzil), since not all users share hifz-circle background.

## Common Mistakes
- Using "hifz" and "memorization" inconsistently between backend naming and UI copy, causing confusion when debugging or writing docs.
- Conflating fiqh (jurisprudence/opinion) with Quran/Sunnah (revealed text/prophetic practice) in casual copy — see `14_content_validation.md`.

## UX Implications
Terminology consistency is itself a UX-quality signal for an Arabic-literate, religiously-engaged audience — inconsistent or slightly-wrong term usage reads as a lower-quality product to this specific audience even if the underlying feature works fine.

## Engineering Implications
Consider a single shared terminology constants file (or localization key naming convention) that mirrors this glossary, so Arabic terms aren't independently re-transliterated in different parts of the codebase.

## Product Implications
A consistent, correctly-used Islamic vocabulary is part of what makes Talia feel authored by people who understand the domain, not a generic app with Islamic content bolted on — worth explicit attention in copy review.

## AI Design Guidelines
When generating UI copy or code identifiers involving Islamic terms, check this glossary first rather than reaching for a term from general knowledge that might not match Talia's established usage.

## Examples
- ✅ Consistent use of "Muraja'ah" as the review feature's internal and user-facing name.
- ❌ Backend uses "review," UI uses "muraja'ah," docs use "revision" — three names for one concept.

## References
Standard usage across Quran/hifz pedagogy literature; no fabricated definitions used.

## Future Extensions
- A formal terminology/style guide (transliteration conventions, capitalization rules) once Talia has more than one contributor writing copy.
