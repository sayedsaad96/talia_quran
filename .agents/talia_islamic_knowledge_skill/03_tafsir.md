# 03 — Tafsir (Quranic Exegesis)

## Purpose
Define what tafsir is, how major schools/works differ, and — most importantly for an AI-built app — the hard boundary between the Quran itself and human interpretation of it.

## Overview
Tafsir is scholarly interpretation and explanation of the Quran's meaning. It is authored, dated, attributable human scholarship — never to be confused with, blended into, or presented with the same authority as the Quranic text itself.

## Core Concepts
- **Tafsir bi-l-Ma'thur (تفسير بالمأثور):** interpretation via transmitted sources — Quran explaining Quran, hadith, companions' statements. Considered the most authoritative *type* of tafsir because it relies on transmission rather than personal reasoning.
- **Tafsir bi-l-Ra'y (تفسير بالرأي):** interpretation via scholarly reasoning/ijtihad, within accepted methodological bounds (distinct from unqualified, ungrounded opinion).
- **Attribution is mandatory.** Every tafsir statement belongs to a named scholar/work and a school/era — it is never generic "Islamic teaching."

## Detailed Explanation
Major classical tafsir works commonly referenced (for classification purposes only — Talia should source actual excerpts from a licensed/public-domain dataset, not generate them):
- *Tafsir al-Tabari* — early, heavily transmission-based (tafsir bi-l-ma'thur), foundational.
- *Tafsir Ibn Kathir* — transmission-based, widely used, relies heavily on hadith and earlier tafsir.
- *Tafsir al-Qurtubi* — strong emphasis on fiqh rulings derived from verses.
- *Tafsir al-Sa'di* — modern, concise, accessible style, popular for general readers.
- *Tafsir al-Baghawi*, *Tafsir al-Jalalayn* — concise, widely used reference works.
Different works reflect different methodologies (linguistic, legal, transmission-based, thematic) and sometimes different theological/madhab leanings. Presenting one as "the" tafsir erases that diversity.

## Important Classifications
| Category | Description | App handling |
|---|---|---|
| Tafsir bi-l-Ma'thur | Transmission-based | Higher-confidence default for general audiences |
| Tafsir bi-l-Ra'y (mahmud) | Reasoned, within accepted method | Attribute to scholar/work explicitly |
| Modern thematic tafsir | Topic-based modern works | Useful for app "themes" features, still needs attribution |
| Never: unattributed AI synthesis | N/A | Not tafsir — do not present as such |

## Practical Rules
- **Never mix tafsir text into the Quran display.** The Mushaf text block shown to a user must contain only the Quran text (plus, if needed, translation clearly marked as translation) — any tafsir/commentary goes in a visually and structurally separate block, attributed by name.
- Every tafsir snippet needs: author, work title, and (where possible) a locator (verse/juz reference in that work) — not just "traditional interpretation."
- If a verse has genuinely disputed interpretations across major works, either show more than one attributed view or omit interpretive commentary rather than picking one silently.

## Common Mistakes
- Rendering a paraphrase of Ibn Kathir (or any work) as if it were the verse's plain meaning, without labeling it as tafsir.
- Using an AI model to "explain this ayah in simple words" and presenting the output as tafsir — this is neither sourced nor attributable and should be labeled, if used at all, as an unofficial educational paraphrase, clearly distinguished from scholarly tafsir.
- Flattening scholarly disagreement between tafsir works into one merged "the meaning is."

## UX Implications
- Visually distinct card/section styling for "Quran text" vs. "Tafsir" vs. "Translation" — different background, label, and typography so users never confuse the three at a glance.
- Tafsir author name and work should be as visible as the content itself, not a small footnote.

## Engineering Implications
- Data model: `TafsirEntry { verseRef, authorName, workTitle, text, sourceDatasetId }` — `sourceDatasetId` must resolve to a real, licensed dataset. No `TafsirEntry` should exist with an empty or "generated" source.
- Tafsir content should be versioned/cacheable separately from Quran text, since it's larger and less frequently accessed than core Mushaf data.

## Product Implications
A "verse of the day with reflection" feature is a natural fit for Talia's companion experience — but only if every reflection is either (a) a properly attributed tafsir excerpt from a real work, or (b) explicitly labeled as Talia's own educational note and never phrased as if it were scholarly interpretation.

## AI Design Guidelines
- If asked to "add tafsir" for a verse and no vetted dataset is wired up yet, say so and treat it as a data-sourcing task (see `18_references.md`), not a generation task.
- Never let an AI coach/chat feature answer "what does this verse mean" with unattributed synthesis when the alternative (citing a real tafsir, or saying scholarly sources should be consulted) is available.

## Examples
- ✅ Verse block (Quran only) → separate "Tafsir" tab → "Ibn Kathir: [attributed excerpt from sourced dataset]"
- ❌ A single scrolling block mixing verse text and unlabeled interpretive commentary.

## References
Classification reflects standard tafsir methodology taxonomy taught in Ulum al-Quran; see `18_references.md` for where to obtain actual, licensable tafsir text.

## Future Extensions
- A "compare tafsir" feature (show 2–3 attributed works side by side for a verse) once a licensed multi-work dataset is integrated.
