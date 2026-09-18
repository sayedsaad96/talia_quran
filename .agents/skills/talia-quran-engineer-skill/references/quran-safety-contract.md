# Quran Safety Contract

**Never generate or repair canonical Quran text with an LLM.**

Never silently remap ayah, surah, page, juz, hizb, QCF, recitation, bookmark, memorization, or review identifiers.

Visual plausibility is not proof of correctness. AI opinion is never the canonical validator of Quran data. Canonical-data changes require **deterministic** validation, regression coverage, canonical-source comparison, and broader impact analysis.

## Correctness-Critical Areas

- Quran text and canonical identifiers.
- ayah ↔ surah ↔ page relationships.
- QCF/Mushaf glyph and page mappings.
- recitation/audio ↔ ayah synchronization.
- stored reading positions, bookmarks, memorization references, revision references.
- juz/hizb/page navigation and any migration touching those identifiers.

## Stored State

Do not silently reset or reinterpret stored reading position, memorization state, review state, or bookmarks. Identifier/schema migrations require compatibility analysis and a recovery/rollback path.

## Runtime and Offline

Preserve verified offline/cache behavior when related code changes. If the source of Quran data or mapping is unclear, stop speculative modification and trace the current canonical source first.
