# 02 — Ulum Al-Quran (Sciences of the Quran)

## Purpose
Equip agents with the classical framework scholars use to study the Quran's revelation, compilation, and interpretation — so features that touch "why/how/when a verse came down" are handled with appropriate nuance instead of flattened into trivia.

## Overview
Ulum al-Quran ("sciences of the Quran") is the umbrella discipline covering everything about the Quran's revelation, transmission, and textual properties. It is scholarly infrastructure, not devotional content itself — it explains *how to read the Quran responsibly*, which is exactly the posture Talia's AI features need.

## Core Concepts
- **Asbab al-Nuzul (أسباب النزول):** the historical occasions/circumstances of a verse's revelation. Known for some verses, unknown for most. Never invent an occasion of revelation for a verse where none is transmitted.
- **Naskh (نسخ) — Nasikh/Mansukh:** the classical concept of one ruling superseding an earlier one. This is a narrow, contested, and rule-specific (fiqh-level) topic among scholars — never apply it casually to imply a verse is "outdated" or "cancelled."
- **Muhkam (محكم) vs. Mutashabih (متشابه):** muhkam verses have clear, unambiguous meaning; mutashabih verses have meanings scholars differ on or that are not fully knowable (e.g., the nature of Allah's attributes). This distinction exists precisely to caution against confident claims about ambiguous verses.
- **Jam' al-Quran (compilation):** the historical process of the Quran's oral transmission and written compilation during and after the Prophet's ﷺ lifetime, culminating in the Uthmanic codex that standardized the text.
- **Seven Ahruf (الأحرف السبعة):** a hadith-attested concept of seven modes/dialects in which the Quran was revealed for ease of recitation across Arab tribes — distinct from, though related to, the later-canonized Qira'at (see `05_qiraat.md`).

## Detailed Explanation
These concepts exist in classical scholarship specifically to prevent overconfident, flattened readings of the Quran. An AI system is structurally prone to the opposite failure mode — producing confident, smooth-sounding answers regardless of actual certainty. Every place Talia surfaces "why" or "what does this mean" content should inherit that caution rather than override it.

## Important Classifications
| Concept | What it explains | Risk if mishandled in an app |
|---|---|---|
| Asbab al-Nuzul | Historical context of specific verses | Inventing a plausible-sounding but false occasion of revelation |
| Naskh | Ruling supersession (fiqh-level, contested) | Implying a verse is void/no longer applicable — a fiqh claim, not a fact to assert casually |
| Muhkam/Mutashabih | Clarity vs. ambiguity of meaning | Presenting a scholarly-disputed reading as settled |
| Seven Ahruf / Qira'at | Legitimate variance in recitation | Treating recitation differences as "errors" |

## Practical Rules
- Only state an asbab al-nuzul for a verse when it is drawn from an attributed, sourced tafsir/hadith reference — never generated from context.
- Never use "naskh" language in app copy (e.g., "this verse replaces that one") without a cited fiqh source; this is exactly the kind of ruling this KB forbids AI from issuing on its own.
- When a verse is classified as mutashabih in mainstream tafsir, do not resolve it to one interpretation in app copy — present it as a topic with scholarly range, or omit interpretive commentary entirely and show the verse.

## Common Mistakes
- Treating "this ayah was revealed because of X" as trivia to auto-generate for engagement content.
- Confusing the Seven Ahruf (a revelation-era phenomenon) with the Ten Qira'at (later-standardized canonical reading traditions) — see `05_qiraat.md` for the distinction.
- Using "abrogated" (mansukh) as a casual descriptor for any verse that seems to contradict another, without scholarly sourcing — most apparent contradictions are resolved through context, not naskh.

## UX Implications
- If Talia ever surfaces "context" or "reflection" content alongside a verse, it should be clearly labeled as sourced commentary (with attribution), not narrated as if it were part of the Quran itself.
- Ambiguous/mutashabih topics are good candidates for "here's the range of scholarly views" UX patterns rather than a single authoritative-sounding paragraph.

## Engineering Implications
- Any "verse context" or "background" feature needs a `source_citation` field, populated only when a real source exists — leave it empty rather than backfilled with AI inference.
- Build a review flag for any content touching naskh, since it's one of the more technical/contested areas of fiqh.

## Product Implications
This is where Talia's "trustworthy companion" positioning is won or lost — a memorization app that gets a verse's historical context wrong, even in a minor "did you know" card, damages credibility disproportionately to the feature's importance.

## AI Design Guidelines
- Default posture: cite or omit. Never fill an information gap about revelation history, abrogation, or ambiguous meaning with a plausible-sounding invention.
- When asked to "explain what this verse means," default to structure ("here is the verse; here is what [named tafsir/scholar] says") rather than a synthesized, unattributed explanation.

## Examples
- ✅ "According to [named tafsir source], this verse's occasion of revelation relates to [X], though other narrations differ."
- ❌ A generated "fun fact" about why a verse was revealed, with no source.

## References
Classical framework as taught across mainstream Ulum al-Quran works (e.g., al-Suyuti's *Al-Itqan*, al-Zarqani's *Manahil al-'Irfan*) — see `18_references.md` for how to source verifiable citations rather than relying on this summary as a citable authority itself.

## Future Extensions
- A dedicated `asbab_al_nuzul` dataset with per-verse sourced entries, once/if Talia adds contextual commentary as a feature.
