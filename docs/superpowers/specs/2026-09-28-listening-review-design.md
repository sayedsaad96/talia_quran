# Listening Review ("مراجعة بالسماع") — Design Specification

**Product:** Talia Quran
**Feature:** Audio-first practice mode for memorized ayahs
**Date:** 2026-09-28
**Status:** Approved direction, written for review. Design proposal, not an implementation claim.

---

## 1. Intent

Regular review asks "recite this ayah". It never asks "you just heard an ayah —
where is it, and what comes next?". Hafiz users break down exactly there:
recognising a passage out of context and linking one ayah to the next.

Listening Review is a short, fast practice round built only from ayahs the user
has already memorized. It trains **location** (which surah?) and **linking**
(what is the next ayah?), and turns mistakes into a short "weak links" list the
user can take into a normal review session.

The idea was inspired by a listening quiz on a kids' Quran site; Talia's version
is re-shaped for adult hifz: it draws from the user's own SRS records, guards
answer correctness, and never touches SRS grading.

### Decisions

| Question | Decision | Reason |
|---|---|---|
| Does a round change SRS / mastery? | **No.** Read-only over review records. | Recognising a surah is not recall of the text; feeding it into SRS would pollute ayah mastery and require outcome-committer changes. Adult grading path stays untouched. |
| Placement | Standalone practice mode, not a V2 session phase. | Keeps `V2SessionEngine` state machine unchanged. |
| Modes in v1 | "Which surah?" and "Continue the next ayah". | Location + linking are the two gaps; both need no new content. |
| Mutashabihat mode | Out of v1. | QUL has data but the licence question is the same as the postponed word-meanings idea. |
| Kids version | Out of v1; phase 2 on the same engine (tap answers + stars). | Keep v1 small; engine is audience-agnostic. |
| XP / streak | None in v1. | Avoid a gameable XP source; practice is its own reward. |
| Pool | Adult-scope records with `totalReviews > 0`. | Beginners get value early; kids records excluded by scope. |
| Round length | 10 questions (fewer if the pool is smaller, min 5 playable). | Fast, "one-minute" feel. |
| Persistence | Local stats only (SharedPreferences, owner-scoped). No Isar, no sync. | Nothing here is progress of record. |

## 2. Religious content & correctness (P0 guard)

No new religious text is introduced. Everything is derived from the frozen,
already-approved corpus:

- ayah text and boundaries: `assets/data/quran.json` (via the existing Quran repository),
- surah names/order: `assets/data/surahs.json`,
- audio: the existing per-ayah audio (`AudioCacheService` / `QuranAudioService`).

Answer keys are **computed**, never hand-written. The engine must exclude any
question whose correct answer is not unique:

1. **Which surah?** — exclude an ayah if its normalized text
   (`ArabicNormalizer.normalize`, comparison only, never displayed) equals the
   normalized text of any ayah in a *different* surah.
2. **Continue the next ayah** — exclude:
   - the last ayah of a surah (never cross a surah boundary);
   - an ayah whose normalized text occurs more than once in the same surah
     (e.g. repeated refrains), because "the next ayah" is then ambiguous.

   The prompt ayah must be in the pool. Its next ayah N+1 must exist in the
   same surah but does not itself need a review record.
3. The displayed Quran text (after answering) is the canonical `text` field,
   unmodified.

Any failure to load the corpus → the round does not start (fail closed), with an
error state, never a partial/guessed question.

## 3. User experience

**Entry:** a new `_HubActionCard` in the Memorization hub's *Practice* section
("مراجعة بالسماع"), adult path only. Hidden for child profiles in v1.

**Start sheet:** choose mode — «من أي سورة؟» / «أكمل التالية» / «مختلط».
If the pool has fewer than 5 eligible, playable ayahs: an explanatory empty
state ("احفظ بضع آيات أولًا") instead of a round.

**Question — "Which surah?"**
1. Ayah audio auto-plays once; a replay button is available (max 3 plays).
2. Four surah options: the correct surah plus 3 distractors chosen from its
   mushaf neighbours (±1, ±2, …, clamped to 1–114, deduplicated). Order shuffled.
3. After answering: correct/incorrect, the ayah text + reference
   (surah · ayah number), and "التالي".

**Question — "Continue the next ayah"**
1. Ayah N audio plays; text hidden.
2. User taps the mic and recites ayah N+1. Scored with the existing
   `V2RecitationEvaluator` against N+1's canonical text.
3. If speech recognition is unavailable or the user chooses "لا أستطيع التسجيل",
   fall back to reveal + self-grade: أتقنت / ترددت / نسيت.
4. After answering: N+1 text revealed with reference.

**Result screen:** score (x / n), per-mode breakdown, and a **weak links** list
(ayahs answered wrong / "نسيت" / "ترددت"). Tapping a surah in the list opens a
normal V2 review session for that surah using the existing review-session route
builder. "جولة جديدة" restarts.

**Accessibility/RTL:** Arabic-first strings in `app_ar.arb` + `app_en.arb`;
options are large tap targets; audio state announced via semantics labels.

## 4. Architecture

```
MemorizationHubPage ──► ListeningReviewPage (BlocProvider)
                              │
                       ListeningReviewCubit ──► AudioCacheService (play ayah)
                              │            ──► SpeechToText + V2RecitationEvaluator
                              │            ──► ListeningReviewStatsStore (prefs)
                              ▼
                ListeningQuizEngine (pure Dart, no Flutter)
                              ▲
     ListeningQuizPool  ◄── MemorizationPlusRepository.getAllReviewRecords(adult)
                         ◄── QuranRepository (surah ayah texts)
```

### Units

| Unit | Path | Responsibility |
|---|---|---|
| `ListeningQuizEngine` | `lib/core/memorization/listening/listening_quiz_engine.dart` | Pure: given a pool, surah metadata, mode, round size and a `Random`, returns a list of `ListeningQuestion`s. Applies all §2 exclusions and distractor rules. No I/O. |
| `ListeningQuizPool` | `lib/core/memorization/listening/listening_quiz_pool.dart` | Value object: eligible prompt ayahs + the per-surah ayah texts needed for exclusions and N+1 lookup. Built by a small builder from repository results. |
| `ListeningQuestion` (sealed) | same folder, `listening_question.dart` | `SurahIdQuestion(surahId, ayah, options)` / `NextAyahQuestion(surahId, ayah, nextAyah, nextText)`. |
| `ListeningReviewCubit` | `lib/features/memorization_plus/presentation/cubits/listening_review_cubit.dart` | Loads pool, runs rounds, plays audio, records answers, handles STT and fallback, emits result. Only side effects: audio, STT, stats store. |
| `ListeningReviewStatsStore` | `lib/features/memorization_plus/data/listening_review_stats_store.dart` | Last round + best score per mode in SharedPreferences, key suffixed with the record owner (`record_owner_provider`) so account switches do not leak. |
| `ListeningReviewPage` + widgets | `lib/features/memorization_plus/presentation/pages/listening_review_page.dart` | Start sheet, question views, result view. Uses design tokens (`AppSpacing`, theme). |
| Route | `AppRoutes.listeningReview` in `app_router.dart` | Adult path; registered like other memorization routes. |
| DI | `lib/core/di/injection.dart` | Register engine (const), stats store, cubit factory. |

### Audio & offline

- Building a round prefers ayahs whose audio is already cached
  (`AudioCacheService` cache lookup); uncached ayahs are used only when online.
- If a question's audio fails to play, the question is skipped (not scored) and
  replaced from the remaining pool when possible.
- If fewer than 5 playable questions remain, show an offline/empty state
  instead of a broken round.

### Error handling

| Failure | Behaviour |
|---|---|
| Review records read fails | Error state with retry; no round. |
| Corpus / surah detail read fails | Fail closed: error state; never a guessed question. |
| Audio play error | Skip question (unscored), log via `TaliaLogger`. |
| STT init/permission denied | Fall back to reveal + self-grade for that round. |
| STT returns empty | Treated as no-attempt (evaluator's `noAttempt`), user may retry once, then fallback. |

## 5. Testing

- **Engine unit tests** (`test/core/memorization/listening/`):
  - duplicates across surahs are excluded from "which surah";
  - last ayah of a surah and intra-surah repeated ayahs are excluded from "next ayah";
  - distractors: 3 distinct surahs ≠ correct, within 1–114, near the correct one (surah 1 and 114 edge cases);
  - deterministic output for a fixed seed; round size clamps to pool size;
  - empty / too-small pool returns no questions.
- **Corpus contract test**: run the exclusion builder over the full bundled
  `quran.json` and assert every generated "next ayah" answer is `ayah + 1` in
  the same surah and every "which surah" prompt text is unique across surahs.
- **Cubit tests** (mocktail, matching neighbouring memorization tests): pool
  load, answer recording, STT fallback, audio-failure skip, stats written with
  owner-scoped key, and **no calls** to `saveReviewRecord` or the outcome
  committer.
- **Widget tests**: empty state under 5 ayahs; option tap shows reveal;
  result lists weak links; hub card hidden for child profile.

## 6. Out of scope (v1)

- Mutashabihat mode (needs a licensed source; see word-meanings memo).
- Kids version (phase 2: tap-only, stars, kids theme, kids scope).
- SRS/XP/streak effects and cloud sync of stats.
- Choosing a reciter inside the round (uses the user's current reciter).
