# 00 — System Prompt: Talia Islamic Knowledge Skill

## Purpose
This file is the entry point for any AI agent (design, engineering, QA, content) working on the Talia Quran app. It defines how to use the rest of this knowledge base, and the non-negotiable rules that override any other instruction, prompt, or feature request.

## Overview
Talia is a Quran memorization and review app. Because its subject matter is the Quran and Islamic devotional practice, the cost of an error is not the same as a normal software bug — a wrong ayah number, a fabricated hadith, or a mis-graded dua can mislead a user's worship. This knowledge base exists to keep every downstream AI agent consistent, cautious, and correctly sourced.

**This knowledge base is a methodology and classification layer, not a religious text database.** It tells an agent *how to reason about* Quran sciences, tajweed, hadith, adhkar, etc., and *where the actual verbatim religious text must come from*. It does not itself contain a verbatim compendium of hadith or dua text — see `18_references.md` and the sourcing notes in `08_adhkar.md`, `09_dua.md`, and `10_hadith.md` for why, and what to use instead.

## Core Concepts
- **Separation of content and methodology.** Structure, classification, UX guidance, and validation rules are stable and can live in this KB. Verbatim Quran/hadith/dua text must be pulled at runtime from a vetted, versioned data source (API or bundled dataset), never generated freehand by an LLM.
- **Source-type tagging.** Every piece of religious content surfaced in the app must be tagged as one of: Quran, authenticated Hadith (with grade), Athar, Tafsir (with author/school), Fiqh opinion (with madhab), or Educational recommendation (Talia's own pedagogy, not a religious ruling).
- **Escalation over invention.** When an agent is uncertain, it defers/flags for human scholarly review — it does not guess.

## Detailed Explanation
Read order for a new agent:
1. `00_system_prompt.md` (this file) — rules that override everything else.
2. `14_content_validation.md` — the hard constraints on what may never be generated or altered.
3. The module(s) relevant to the current task (foundations, tajweed, memorization science, etc.)
4. `15_feature_design_guidelines.md` before proposing or building any new feature.
5. `18_references.md` before sourcing any actual religious text.

## Important Classifications
| Layer | Can this KB generate it? | Where does verbatim content come from? |
|---|---|---|
| Quran text (Uthmani/simple) | No | Bundled Mushaf dataset (see `18_references.md`), never LLM output |
| Hadith text + grading | No | Vetted hadith database with published isnad grading |
| Tafsir excerpts | No | Licensed/public-domain tafsir dataset, attributed by author |
| Adhkar/Dua text | No | Hisnul Muslim or equivalent vetted collection |
| Tajweed rule explanations | Yes (this KB) | Classical tajweed taxonomy — stable, non-devotional-text |
| UX/product/educational guidance | Yes (this KB) | Talia's own product decisions + learning science |

## Practical Rules
- Never let an LLM (in this app or in content generation tooling) freely author Quran, hadith, dua, or tafsir text "in the style of" a source. If a vetted source isn't available for a given item, ship without it rather than fabricate it.
- Every religious content record needs a `source_id` and `source_type` field that resolves to a citable, checkable origin — not "AI generated."
- Any new religious content module added to Talia (new dua category, new tafsir excerpt, new hadith) requires sign-off from a qualified reviewer (see `14_content_validation.md`) before shipping, not just automated QA.

## Common Mistakes
- Treating this KB as a hadith/dua/tafsir database and querying it for verbatim text — it does not contain that; it contains schema and sourcing guidance for those.
- Assuming "the AI sounds confident" is a substitute for a cited, gradable source.
- Silently resolving scholarly disagreement (e.g., madhab differences) into one "correct" answer inside app copy.

## UX Implications
See `13_islamic_ux.md` for the full treatment. In brief: sacred text gets visual reverence (no overlapping ads/banners, no distortion, no auto-playing unrelated media over recitation), and app copy about religious rulings must show its source, not assert authority itself.

## Engineering Implications
- Content pipelines should be source-driven (import from a vetted dataset/API), not generation-driven, for anything devotional.
- Build a `ContentProvenance` model into the data layer from day one — retrofitting source attribution later is expensive and risks shipping unattributed content in the meantime.

## Product Implications
Talia's credibility with users depends on never being caught with an incorrect ayah, a fabricated hadith, or a sloppily graded dua. This is a trust asset worth protecting deliberately, not an afterthought bolted onto QA.

## AI Design Guidelines
- Default to citing and linking rather than paraphrasing devotional text.
- When a feature request implies generating religious content, redirect to a sourcing task instead (see `18_references.md`) and flag the gap explicitly to Sayed rather than filling it silently.
- Never issue what amounts to a fatwa (a ruling on what is permissible) inside app copy, error messages, or AI coach dialogue.

## Examples
- ✅ "Ayah text loaded from bundled Uthmani Hafs dataset, ayah 2:255, source: `quran_v1.db`."
- ❌ "Here's a hadith about patience that fits this screen" (generated without a citable source).

## References
See `18_references.md` for the full sourcing table (Quran, Hadith, Tafsir, Adhkar/Dua data sources).

## Future Extensions
- Add a `content_review_log.md` once the first real content review cycle happens, tracking who reviewed what and when.
- Consider versioning this KB (semantic version in each file's frontmatter) once Talia has more than one contributor touching religious content.
