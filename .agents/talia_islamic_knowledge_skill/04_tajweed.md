# 04 — Tajweed (Rules of Recitation)

## Purpose
Give agents the stable, classical tajweed rule taxonomy needed to design tajweed-highlighting, feedback, and teaching features correctly.

## Overview
Tajweed (تجويد) is the discipline of correct Quranic pronunciation and articulation. Unlike tafsir or fiqh, tajweed's core rules are technical/phonetic and not meaningfully disputed across mainstream schools — this makes it one of the safer modules for an AI system to reason about directly, though *assessment* of a user's actual recitation is a much harder, error-prone problem (see Engineering Implications).

## Core Concepts
- **Makharij al-Huruf (مخارج الحروف):** the articulation points of Arabic letters — throat, tongue positions, lips, nasal cavity (khaishum). Classical count is 17 points grouped into 5 main regions (throat, tongue, lips, nasal cavity, and the jawf/oral cavity for long vowels).
- **Sifat al-Huruf (صفات الحروف):** the manner/quality of a letter's pronunciation (e.g., hams/jahr — whispered vs. voiced; shiddah/rakhawah — stress vs. softness; isti'la/istifal — raised vs. lowered tongue).
- **Noon Sakinah & Tanween rules:** izhar (clear pronunciation), idgham (merging — with/without ghunnah), iqlab (conversion to meem sound), ikhfa (concealment) — governing how a silent noon or tanween is pronounced based on the following letter.
- **Meem Sakinah rules:** ikhfa shafawi, idgham shafawi, izhar shafawi — the meem-specific parallel to the noon rules.
- **Madd (مد — elongation):** rules for how long a vowel sound is held, ranging from the natural 2-count madd to 4–6 counts depending on type (e.g., madd wajib muttasil, madd jaiz munfasil, madd lazim).
- **Qalqalah (قلقلة):** a slight bounce/echo on specific letters (ق ط ب ج د) when they carry sukoon.
- **Waqf (وقف) and Ibtida (ابتداء):** rules for where a reciter may pause and where to correctly resume, so pausing doesn't distort meaning.

## Detailed Explanation
These rules exist to preserve accurate, consistent oral transmission of the Quran — the same motivation behind the "never invent Quran text" rule elsewhere in this KB, applied to *sound* rather than *text*. A tajweed-highlighting feature is essentially a visual index into this rule set, mapped onto the Uthmani script.

## Important Classifications
| Rule family | What it governs | Common visual convention |
|---|---|---|
| Noon Sakinah/Tanween | Pronunciation of silent noon/tanween before the next letter | Color-coded by sub-rule (izhar/idgham/iqlab/ikhfa) |
| Meem Sakinah | Pronunciation of silent meem before the next letter | Color-coded, parallel to noon rules |
| Madd | Vowel elongation duration | Often marked with a length indicator or distinct color |
| Qalqalah | Bounce on qalqalah letters with sukoon | Distinct marker on the specific letter |
| Waqf signs | Where pausing is recommended/required/prohibited | Standard Mushaf waqf symbols (ۖ ۗ ۚ ۛ etc.) |

## Practical Rules
- Tajweed color/markup data must come from a vetted tajweed-annotated Mushaf dataset (e.g., a tajweed JSON keyed to the same Uthmani text Talia already renders) — never inferred letter-by-letter by an LLM at runtime, since a single misclassification teaches a user an incorrect pronunciation habit.
- Waqf symbols must be rendered exactly as they appear in the source Mushaf, not simplified or omitted, since they carry real recitation guidance.

## Common Mistakes
- Treating tajweed color-coding as decorative rather than functional — every color must map to one specific, correctly identified rule.
- Auto-generating tajweed markup with a general-purpose LLM instead of a rule-based/dataset-driven parser — tajweed rule application is deterministic given the text, and should be handled as such.
- Ignoring regional/riwayah differences in how some madd durations are applied.

## UX Implications
- Tajweed highlighting should be toggleable and explainable — tapping a colored segment should show which rule applies and why, not just show color.
- For a "learn tajweed" flow (relevant to Talia's memorization/review UX), pair the visual rule with an audio example, since tajweed is fundamentally an auditory skill.

## Engineering Implications
- Talia's existing `TajweedSpan` pattern (see the `quran-islamic-apps` engineering skill) should source `rule` values from the vetted dataset's rule taxonomy, not a freeform string.
- **Recitation assessment (checking a user's actual spoken tajweed) is a distinct, much harder problem** from static text markup — it requires phonetic/audio ML, not text generation, and should be treated with appropriate humility about false positives/negatives in feedback copy ("this may need work" rather than "this is wrong").

## Product Implications
Tajweed correctness is a core differentiator for a serious memorization app vs. a casual reading app — but only if the underlying rule data is accurate; a flashy but wrong tajweed feature is worse than none.

## AI Design Guidelines
- When building or debugging tajweed markup, verify against the source dataset's rule labels rather than re-deriving rules from the raw Arabic text via model inference.
- Be explicit in any AI coach feedback about the difference between "text-level tajweed rule" (deterministic, from data) and "how well you recited it" (probabilistic, from audio assessment).

## Examples
- ✅ Ikhfa segment colored consistently across the app because it's sourced from `tajweed_rules.json`, not derived per-render.
- ❌ A "smart" feature that asks an LLM to color-code tajweed live from plain text — deterministic-rule content should not go through a generative model.

## References
Classical taxonomy per standard tajweed curricula (e.g., *Tuhfat al-Atfal*, *al-Jazariyyah*); see `18_references.md` for actual tajweed-annotated Quran datasets.

## Future Extensions
- Per-riwayah madd-duration variants if Talia adds a non-Hafs riwayah.
- Audio-based tajweed assessment module, scoped separately from this text-markup module once/if that ML capability is built.
