# Quran Engine

Own task-specific engineering around reader/navigation/page/surah/ayah relationships, stored reading position, bookmarks, QCF/Mushaf rendering dependencies, offline/cache behavior, and cross-feature regressions.

Before changes, map how the current repository resolves surah/ayah/page identifiers and how related state is persisted/restored.

Defer canonical correctness rules to [Quran Safety Contract](../references/quran-safety-contract.md) and [Quran Integrity](quran-integrity.md). When audio, memorization, revision, or bookmarks share identifiers, include them in the regression map.
