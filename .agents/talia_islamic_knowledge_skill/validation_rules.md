# Talia Islamic Knowledge Base — Validation & Governance Rules

**Priority:** this document ranks immediately below `00_system_prompt.md` and above every other module in the repository, including `14_content_validation.md`. Where `14_content_validation.md` states the same rules at module-summary level (for consistency with the other 19 content modules' shared template), this document is the canonical, detailed source — `14` defers to it, not the other way around. Any conflict between this document and any other module (other than `00_system_prompt.md`) is resolved in this document's favor.

**Enforcement vocabulary used throughout:** **Blocking** (output must not ship/be returned until resolved) · **Mandatory Review** (requires qualified human sign-off before shipping) · **Advisory** (agent should follow and flag deviations) · **Soft** (best practice, logged for improvement, not blocking).

**Risk vocabulary used throughout:** **Critical** · **High** · **Medium** · **Low** (defined fully in §13).

---

## 1. Validation Philosophy

- **Truthfulness** — an answer that sounds right is worthless if it isn't right; fluency is never evidence of accuracy.
- **Transparency** — every claim traces to a visible source or is explicitly marked as Talia's own educational voice (never blended, see §6).
- **Authenticity** — content is only as good as its chain back to a real, checkable origin (Quran text, graded hadith, attributed tafsir) — see §2.
- **Educational responsibility** — Talia is teaching real people about their religious practice; errors here have consequences ordinary app bugs don't.
- **Respect for Islamic sources** — sacred and scholarly material is handled with the reverence defined in `13_islamic_ux.md`, not as generic app content.
- **AI humility** — an AI agent's fluent confidence is not a substitute for scholarly grounding; the correct response to genuine uncertainty is to say so (§9, §14), not to produce a plausible-sounding guess.
- **Explainability** — every validation decision (why something shipped, why something was blocked) must be traceable to a specific rule ID in this document, not to an unstated judgment call.

---

## 2. Source Authority Hierarchy

| Level | Source type | Authority |
|---|---|---|
| 1 | Quran (revealed text) | Absolute — never overridden by any lower level |
| 2 | Authentic Sunnah (Sahih/Hasan graded hadith) | Binding evidentiary weight, second only to Quran |
| 3 | Companion reports (Athar) | Contextual weight, below direct prophetic hadith |
| 4 | Classical Tafsir | Interpretive authority, attributed per work/author |
| 5 | Recognized scholarly consensus (Ijma', where genuinely established) | High — but genuine ijma' is narrower than it's often assumed to be; do not label something consensus without a citable basis |
| 6 | Recognized scholarly opinions (individual/madhab-specific) | Attributed opinion, never presented as universal |
| 7 | Educational recommendations (Talia's own pedagogical voice) | Lowest — explicitly Talia's own voice, never framed as religious instruction |

**Conflict resolution across levels:** a higher level always overrides a lower one when they genuinely conflict. **Conflict resolution within the same level** (e.g., two Sahih hadith that appear to conflict, or two classical tafsir works that differ) is not resolved by this KB or by any AI agent — it is presented as scholarly disagreement per §7, never silently decided.

---

## 3. Hallucination Prevention Rules

**HAL-01 — No Invented Quran Verses**
- Purpose: Guarantee every verse shown is real Quran text.
- Description: No AI agent may generate, reconstruct from memory, or paraphrase-as-verse any Quran text.
- Why it exists: Quran text is Level 1 authority (§2) — there is zero tolerance for alteration.
- Example: A feature needs a verse about patience and none is loaded in context.
- Correct behavior: Pull the exact verse from the vetted Mushaf dataset (`18_references.md`); if unavailable, say so.
- Incorrect behavior: Producing a verse-sounding sentence from general recollection.
- Risk level: Critical.
- Enforcement: Blocking.

**HAL-02 — No Modified Quran Wording**
- Purpose: Preserve verse integrity exactly as transmitted.
- Description: No altering wording, diacritics, or verse boundaries, including for formatting/length convenience.
- Why it exists: Even a "harmless" trim changes transmitted text.
- Example: A UI card is too narrow for a long ayah.
- Correct behavior: Resize the UI, don't trim the verse.
- Incorrect behavior: Silently shortening or re-punctuating the verse to fit.
- Risk level: Critical.
- Enforcement: Blocking.

**HAL-03 — No Fabricated Hadith**
- Purpose: Prevent invented narrations from being presented as prophetic reports.
- Description: No hadith-sounding text may be generated without a real, checkable collection/number/grade.
- Why it exists: A fabricated hadith is a severe category of religious error (see `10_hadith.md`'s Mawdu' classification).
- Example: A "hadith of the day" slot needs content and no sourced item fits the theme.
- Correct behavior: Leave the slot empty or pick a different, actually-sourced theme.
- Incorrect behavior: Writing a plausible prophetic-sounding sentence to fill the slot.
- Risk level: Critical.
- Enforcement: Blocking.

**HAL-04 — No Fabricated References**
- Purpose: Ensure every citation resolves to something real.
- Description: A citation (collection+number, tafsir author+work, Quran ref) must be checkable, never invented to look legitimate.
- Why it exists: A fake-but-plausible citation is more dangerous than an absent one — it launders unverified content as verified.
- Example: Drafting copy that "needs" a citation to feel credible.
- Correct behavior: Cite only what was actually sourced; omit the citation (and likely the claim) otherwise.
- Incorrect behavior: Inserting a realistic-looking book/number that wasn't actually checked.
- Risk level: Critical.
- Enforcement: Blocking.

**HAL-05 — No Invented Scholarly Opinions**
- Purpose: Prevent misattribution of positions to scholars/madhabs.
- Description: A position may only be attributed to a named scholar/school if that attribution is sourced.
- Why it exists: Misattributing a fiqh position is both a religious-accuracy failure and reputationally serious.
- Example: Summarizing "the view of the Hanafi school" on a topic without a source.
- Correct behavior: Cite the specific source or state "position needs sourcing."
- Incorrect behavior: Writing a plausible-sounding position and attaching a madhab label to it.
- Risk level: Critical.
- Enforcement: Blocking.

**HAL-06 — No Invented Arabic Text or Transliteration**
- Purpose: Ensure Arabic text (adhkar, dua, hadith) and its transliteration are accurate.
- Description: Arabic text and transliteration must come from the same vetted dataset as the item's translation and grading — not separately reconstructed.
- Why it exists: A transliteration invented independently of the source can silently drift from the actual pronunciation/wording.
- Example: A dataset provides Arabic + translation but transliteration is missing.
- Correct behavior: Source transliteration from the same or an equally vetted dataset, or omit it.
- Incorrect behavior: Auto-transliterating the Arabic with a generic transliteration algorithm and presenting it as authoritative.
- Risk level: High.
- Enforcement: Mandatory Review.

**HAL-07 — Mandatory Behavior When Evidence Is Missing**
- Purpose: Define the required fallback when no sourced content exists for a request.
- Description: The agent must state that no vetted source was found and propose a sourcing task (see `18_references.md`) — never fill the gap with generated content "as a placeholder."
- Why it exists: Placeholders in religious content ship far more often than intended (see `14_content_validation.md` Common Mistakes).
- Example: A requested adhkar category has no matching dataset entry.
- Correct behavior: "No sourced item currently available for this category — recommend sourcing before shipping."
- Incorrect behavior: Generating a plausible item and marking it `TODO: verify later`.
- Risk level: Critical.
- Enforcement: Blocking.

---

## 4. Quran Validation Rules

**QUR-01 — Verse Integrity**
- Purpose: Guarantee displayed verses match the canonical source exactly.
- Description: Verse text must be checked character-for-character against the vetted dataset at integration and after any pipeline change.
- Why it exists: Silent corruption during data transformation (encoding, trimming) is a real, easy-to-miss failure mode.
- Example: A font/encoding migration touches verse-rendering code.
- Correct behavior: Diff rendered output against the source dataset before shipping.
- Incorrect behavior: Assuming a rendering change can't affect text content.
- Risk level: Critical. Enforcement: Blocking.

**QUR-02 — Surah Name Accuracy**
- Purpose: Correct, consistent surah naming (Arabic and transliterated).
- Description: Surah names must match the vetted dataset's naming, with one consistent transliteration convention app-wide (see `11_islamic_terminology.md`).
- Why it exists: Inconsistent naming across screens reads as low-quality and can confuse navigation.
- Example: Search and reading-mode display a surah's name differently.
- Correct behavior: Single source of truth for surah names, referenced everywhere.
- Incorrect behavior: Hand-typing a surah name in a new feature instead of pulling from the dataset.
- Risk level: Medium. Enforcement: Advisory.

**QUR-03 — Ayah Numbering (Riwayah-Dependent)**
- Purpose: Prevent off-by-one and cross-riwayah numbering errors.
- Description: Ayah numbering must match the specific riwayah in use (see `01_quran_foundations.md` on Basmalah-handling differences); never mix numbering schemes from different datasets.
- Why it exists: This is a documented, common source of subtle bugs.
- Example: Integrating a second audio source that numbers ayahs differently than the text dataset.
- Correct behavior: Verify numbering alignment before pairing any two datasets.
- Incorrect behavior: Assuming all Quran datasets number ayahs identically.
- Risk level: High. Enforcement: Mandatory Review.

**QUR-04 — Arabic Text Preservation (Diacritics)**
- Purpose: Preserve tashkeel (diacritical marks) exactly.
- Description: No stripping or "simplifying" of diacritics for display convenience without an explicit, separate "simplified script" mode that's clearly labeled as such.
- Why it exists: Diacritics carry pronunciation-critical information (see `04_tajweed.md`).
- Example: A low-contrast dark theme tempts a design shortcut of removing diacritics for "cleanliness."
- Correct behavior: Fix contrast/rendering, keep diacritics (see `13_islamic_ux.md`).
- Incorrect behavior: Dropping diacritics to solve a legibility problem.
- Risk level: High. Enforcement: Mandatory Review.

**QUR-05 — Translation Handling**
- Purpose: Keep translations attributed and unmixed.
- Description: Every displayed translation must show its translator/work; translations from different sources must not be silently blended within one passage.
- Why it exists: Translation is interpretive by nature — attribution lets a user judge and cross-check it.
- Example: Two different translation sources are integrated for language coverage.
- Correct behavior: Tag each translation with its source; let the user pick or clearly section them.
- Incorrect behavior: Presenting a merged/edited translation as if from one source.
- Risk level: Medium. Enforcement: Advisory.

**QUR-06 — Citation Formatting**
- Purpose: Standardize how Quran references are written app-wide.
- Description: Use `Surah Name Ayah:Number` (e.g., "Al-Baqarah 2:255") consistently in all app copy, docs, and generated content.
- Why it exists: Consistent citation format is a small but real trust/quality signal, and prevents ambiguous references.
- Example: Two features format verse references differently.
- Correct behavior: Enforce one format via shared constants/localization keys.
- Incorrect behavior: Ad hoc citation formatting per feature.
- Risk level: Low. Enforcement: Soft.

---

## 5. Hadith Validation Rules

**HAD-01 — Authenticity Grade Is Mandatory**
- Purpose: Never show hadith content without its grade.
- Description: Every hadith surfaced anywhere in Talia must carry Sahih/Hasan/Da'if/Mawdu' (see `10_hadith.md`), sourced from the dataset's own grading, not inferred.
- Why it exists: Grade is the single most safety-critical piece of hadith metadata.
- Example: A UI redesign proposes hiding the grade "to reduce clutter."
- Correct behavior: Keep grade visible (can be a tappable detail, not necessarily always-expanded — see `13_islamic_ux.md`) but never remove it from the data shown.
- Incorrect behavior: Dropping the grade field from a display component.
- Risk level: Critical. Enforcement: Blocking.

**HAD-02 — Citation Format**
- Purpose: Standardize hadith citation.
- Description: Use `Collection, Book/Number` format (e.g., "Sahih Muslim, [number]") consistently, with grading source noted where it isn't the collection's own internal grading (e.g., Al-Bukhari/Muslim are self-authenticating by scholarly convention; other collections often need an external grading reference).
- Why it exists: Consistent, checkable citation is what makes a hadith claim verifiable at all.
- Risk level: Medium. Enforcement: Advisory.

**HAD-03 — Source Verification Before Use**
- Purpose: Ensure hadith content traces to a real dataset, not general impression.
- Description: Before any hadith is added to Talia, its presence and grading must be confirmed in a vetted dataset (`18_references.md`) — not "this is commonly known."
- Why it exists: Many widely-circulated hadith-sounding quotes are weak, misattributed, or fabricated.
- Risk level: Critical. Enforcement: Blocking.

**HAD-04 — Weak (Da'if) Narration Handling**
- Purpose: Prevent weak hadith from being used as if authoritative.
- Description: Da'if hadith are excluded from devotional/practical content by default; if ever included for educational/historical discussion, they must be prominently labeled weak.
- Why it exists: Devotional use of weak hadith is a documented, common source of error in popular Islamic content.
- Risk level: High. Enforcement: Mandatory Review.

**HAD-05 — Fabricated (Mawdu') Narration Handling**
- Purpose: Prevent fabricated narrations from appearing as hadith at all.
- Description: Mawdu' narrations are never presented as hadith; if referenced at all (e.g., "commonly misattributed to the Prophet ﷺ" educational content), the fabricated status must be explicit and immediate, not buried.
- Why it exists: Ambiguity here directly causes misinformation to spread further.
- Risk level: Critical. Enforcement: Blocking.

**HAD-06 — Disputed Grading / Chain Uncertainty**
- Purpose: Handle cases where scholars disagree on a hadith's grade.
- Description: When grading is genuinely disputed among hadith scholars, show which scholar's grading is being cited rather than presenting one grade as universally settled.
- Why it exists: Grading is scholarship, not a fixed database fact in every case — see `10_hadith.md`.
- Risk level: Medium. Enforcement: Advisory.

---

## 6. Tafsir Rules

Tafsir must always be distinguishable from four adjacent categories: **Quran** (the revealed text itself), **opinion** (an individually attributed scholarly or fiqh position, not general exegesis), **inference** (an AI agent's own reasoning about a passage — never permitted as displayed content, see TAF-03), and **educational explanation** (Talia's own pedagogical paraphrase, explicitly not scholarly tafsir).

**TAF-01 — Quran/Tafsir Separation**
- Purpose: Prevent tafsir from being confused with revelation.
- Description: Quran text and tafsir are always visually and structurally separate blocks, each independently attributed.
- Risk level: Critical. Enforcement: Blocking.

**TAF-02 — Tafsir Must Be Attributed**
- Purpose: Every tafsir statement is traceable to a named scholar/work.
- Description: No "traditional interpretation says..." without naming the source (see `03_tafsir.md`).
- Risk level: High. Enforcement: Mandatory Review.

**TAF-03 — Never Present Tafsir as Revelation, Never Present AI Inference as Tafsir**
- Purpose: Keep the authority levels in §2 intact.
- Description: An AI agent's own reasoning about verse meaning is never displayed as if it were tafsir or as if it were the verse's plain meaning — it is either omitted, or explicitly labeled as an unofficial educational note (Level 7 in §2), never Level 4.
- Risk level: Critical. Enforcement: Blocking.

**TAF-04 — Educational Explanation Labeling**
- Purpose: Keep Talia's own pedagogical content honestly labeled.
- Description: Any simplified "what this means for your day" style content is explicitly Talia's own voice (Level 7), never phrased to sound like scholarly tafsir.
- Risk level: Medium. Enforcement: Advisory.

---

## 7. Scholarly Disagreement

- **When disagreement must be mentioned:** whenever mainstream scholarship (across madhabs or major tafsir/hadith-grading authorities) genuinely differs on a point the content touches — not only when a user explicitly asks about the disagreement.
- **How disagreement should be presented:** as a range of attributed positions ("the Hanafi position holds X; Shafi'i/Hanbali commonly hold Y"), not as a debate to be won.
- **Neutral language:** no adjectives that imply one position is more correct, modern, moderate, or authentic than another, absent a cited basis for that characterization.
- **No preference without evidence:** an AI agent's own aggregate impression of which view is "more common" is not evidence — only a cited source justifies emphasis.
- **No hidden disagreement:** silently picking one view and presenting it as the only one is a violation of `14_content_validation.md` rule 4, regardless of intent (space constraints, simplicity) — see DIS rules below.

**DIS-01 — Mandatory Disclosure**
- Description: Known scholarly disagreement relevant to the content must be surfaced, not omitted for simplicity.
- Risk level: High. Enforcement: Mandatory Review.

**DIS-02 — Neutral Presentation**
- Description: Present each attributed position without editorializing which is better.
- Risk level: Medium. Enforcement: Advisory.

**DIS-03 — No Unsourced Preference**
- Description: Any emphasis on one position over another must cite why (e.g., "most widely followed in [region]" needs its own source).
- Risk level: Medium. Enforcement: Advisory.

**DIS-04 — No Silent Resolution**
- Description: Never resolve genuine scholarly disagreement into a single "the answer is" statement.
- Risk level: Critical. Enforcement: Blocking.

---

## 8. Fatwa Boundary Rules

**No AI agent, feature, or piece of app copy in Talia issues a fatwa** (a ruling on what is religiously permissible, obligatory, discouraged, or forbidden in a user's specific situation).

| | Allowed | Not allowed |
|---|---|---|
| Content | Presenting sourced information, citing attributed positions, explaining a concept | Telling a user what they personally should or must do religiously |
| Framing | "Scholars differ; [source] holds X" | "It is permissible/impermissible for you to..." |
| AI Coach | Encouraging review/memorization habits (Level 7 pedagogy) | Answering "is it okay that I missed my wird because of X" as a religious ruling |
| Referral | Suggesting the user consult a qualified local scholar/imam for their specific situation | Attempting to substitute for that consultation |

**FAT-01 — No Rulings**
- Description: Never state what is religiously permissible/obligatory for a specific user's situation.
- Risk level: Critical. Enforcement: Blocking.

**FAT-02 — Allowed/Not-Allowed Boundary**
- Description: Informational/educational content is allowed; personal religious rulings are not — see table above.
- Risk level: Critical. Enforcement: Blocking.

**FAT-03 — Referral Strategy**
- Description: When a user's question is actually a fatwa request, redirect to consulting a qualified scholar rather than attempting a partial answer.
- Risk level: High. Enforcement: Mandatory Review.

**FAT-04 — Educational Response Fallback**
- Description: Where relevant, offer the informational/attributed-positions version of the topic instead of declining outright, per §2's levels — declining doesn't mean refusing to discuss the topic at all, only refusing to rule on it.
- Risk level: Medium. Enforcement: Advisory.

---

## 9. Confidence Levels

| Level | When to use |
|---|---|
| **Verified** | Content pulled directly from a vetted primary dataset (Quran/hadith text matching the source exactly) |
| **High Confidence** | From a named, attributed secondary source (a specific tafsir/scholar) with a working citation |
| **Moderate Confidence** | Topic has broad but not universal scholarly convergence; presented with attribution and appropriate hedging |
| **Low Confidence** | Single source, an unusual or narrowly-held claim, or a weaker (Hasan-range) grading |
| **Uncertain** | Sources conflict or grading is disputed (see HAD-06, DIS rules) |
| **Insufficient Evidence** | No vetted source found at all — this is the mandatory fallback state per HAL-07, not a last resort to avoid |

An agent should be able to state which of these six levels applies to any religious-content claim it makes; if it can't, that's itself a signal to re-check sourcing before responding.

---

## 10. AI Decision Workflow

```mermaid
graph TD
    A[Receive request] --> B[Identify topic]
    B --> C["Load required modules<br/>(per knowledge_index.md §4/§7)"]
    C --> D[Validate sources for any religious content involved]
    D --> E{Conflicts across sources?}
    E -->|Yes, cross-level| F["Higher source-authority level wins (§2)"]
    E -->|Yes, same-level| G["Present as scholarly disagreement (§7)"]
    E -->|No conflict| H[Assign confidence level (§9)]
    F --> H
    G --> H
    H --> I[Generate response]
    I --> J["Run Response Validation Checklist (§12)"]
    J --> K{Checklist passes?}
    K -->|Yes| L[Return answer]
    K -->|No| M[Revise or escalate — do not ship a failed checklist item]
    M --> J
```

This workflow is mandatory for any response involving religious content (per §2's source levels) or a product decision touching such content; purely technical/non-religious tasks can skip directly to a lighter form of §12's checklist (the non-religious-content items only).

---

## 11. Product Validation Rules

Every proposed feature must be checked against `15_feature_design_guidelines.md`'s checklist in full; the rules below are the validation-specific subset with formal rule IDs.

**PRD-01 — Islamic Correctness**
- Description: Any religious content or claim in the feature has passed §3–§8's rules.
- Risk level: Critical. Enforcement: Blocking.

**PRD-02 — Educational Value & Reverent UX**
- Description: The feature serves a genuine learning/practice need and follows `13_islamic_ux.md`'s reverence table.
- Risk level: High. Enforcement: Mandatory Review.

**PRD-03 — Respect for Quran, Adhkar, and Dua Content Specifically**
- Description: Any feature touching these three content types follows their dedicated sourcing modules (`01`, `08`, `09`) — not just general UX rules.
- Risk level: Critical. Enforcement: Blocking.

**PRD-04 — Child Safety & Parent Mode Compatibility**
- Description: Kids Mode features preserve age-appropriate pacing/grading (`12_islamic_education.md`) and remain visible/appropriate within Parent Dashboard where relevant.
- Risk level: High. Enforcement: Mandatory Review.

**PRD-05 — Accessibility**
- Description: Font scaling, contrast, and screen-reader support for Arabic content specifically (`13_islamic_ux.md`), not just general accessibility defaults.
- Risk level: Medium. Enforcement: Advisory.

**PRD-06 — Offline-First Compatibility**
- Description: Core religious-content features function fully offline (`16_product_knowledge.md`); any online-only devotional feature is a design flag, not a default.
- Risk level: High. Enforcement: Mandatory Review.

---

## 12. Response Validation Checklist

Run before returning any response that includes religious content:

- [ ] No fabricated Quran, hadith, dua, adhkar, or tafsir content (§3)
- [ ] Every claim's source is identified and checkable (§2, §4–§6)
- [ ] A confidence level (§9) could be stated for each claim if asked
- [ ] Terminology matches `11_islamic_terminology.md`/`17_glossary.md` usage
- [ ] Scholarly disagreement, if relevant, is disclosed and presented neutrally (§7)
- [ ] No fatwa issued; referral used if the request was actually a ruling request (§8)
- [ ] Source-type tag applied where the content will be stored (Quran/Hadith/Athar/Tafsir/Fiqh opinion/Educational recommendation, per `14_content_validation.md`)
- [ ] If any item above fails, the response is revised or the gap is stated plainly — not shipped silently incomplete

---

## 13. Risk Classification

| Failure | Risk level | Why |
|---|---|---|
| Wrong/altered Quran verse | **Critical** | Violates Level 1 authority directly |
| Wrong or missing Hadith grade | **Critical** | Grade is the safety-critical field (HAD-01) |
| Fabricated hadith or reference | **Critical** | Manufactures false religious authority |
| Fatwa issued by the app/AI | **Critical** | Crosses the fatwa boundary (§8) |
| Hidden scholarly disagreement | **High** | Misrepresents the state of knowledge as settled |
| Unattributed tafsir presented as plain meaning | **High** | Blurs Level 1/Level 4 (§2) |
| Weak (Da'if) hadith used devotionally without label | **High** | Elevates weak evidence silently |
| Missing translation attribution | **Medium** | Reduces verifiability but doesn't misstate content |
| Inconsistent transliteration across screens | **Medium** | Quality/trust signal, not a factual error |
| Citation formatting inconsistency | **Low** | Cosmetic/consistency issue only |
| UI reverence deviation (e.g., minor animation on non-sacred chrome) | **Low–Medium** | Depends on proximity to actual sacred text (see `13_islamic_ux.md`) |

---

## 14. AI Failure Recovery

The preferred behavior in every case below is **honesty over speculation** — stating a limitation is never a worse outcome than confidently producing something wrong.

- **Knowledge is missing:** state plainly that no vetted source is available; propose sourcing (§3 HAL-07). Do not fill the gap.
- **Evidence conflicts across authority levels (§2):** apply the higher level; note the lower-level source was overridden and why.
- **Evidence conflicts within the same level:** present as scholarly disagreement (§7); do not pick a side.
- **Sources disagree on grading (hadith) or interpretation (tafsir):** cite which scholar/authority holds which position (HAD-06).
- **User asks for an unsupported claim to be confirmed:** decline to confirm it, explain what is and isn't sourced, offer to look further if tools are available.
- **Information cannot be verified in the time/tools available:** mark it Insufficient Evidence (§9) rather than defaulting to a best guess.

---

## 15. Governance Rules

**GOV-01 — Who Can Update These Rules**
- Description: The project owner (Sayed) may update any rule. Changes to §3–§8 (the religious-content rule categories) should additionally get sign-off from a qualified Islamic content reviewer before being finalized, consistent with `14_content_validation.md`'s review requirement for religious content generally.
- Risk level: High. Enforcement: Mandatory Review.

**GOV-02 — Versioning**
- Description: This document should carry a version number once it's under active iteration; version bumps accompany any change to a rule's Risk level or Enforcement level (not just wording polish).
- Risk level: Medium. Enforcement: Advisory.

**GOV-03 — Backward Compatibility**
- Description: A rule's meaning should not silently change — a change that alters what passes/fails validation needs a visible changelog note, not just a diff.
- Risk level: Medium. Enforcement: Advisory.

**GOV-04 — Deprecation Policy**
- Description: A deprecated rule is marked `[DEPRECATED — see <replacement rule ID>]` in place, not deleted outright, for at least one review cycle — mirrors `knowledge_index.md` §12's module-deprecation policy.
- Risk level: Low. Enforcement: Soft.

**GOV-05 — Review & Audit Requirements**
- Description: Shipped religious content should be periodically spot-checked against this document's rules (see `14_content_validation.md`'s proposed `content_review_log.md`); this is a recommended cadence, not yet an implemented process as of this document's creation.
- Risk level: Medium. Enforcement: Advisory.

---

## 16. Future Compatibility

This validation engine is designed so future modules extend existing rule categories rather than requiring new philosophy:

| Future module | Extends | How |
|---|---|---|
| Fiqh | §8 (Fatwa Boundary), §2 (Level 6) | Adds structured multi-madhab opinion data; FAT rules apply unchanged — still no rulings issued |
| Seerah | §5 (Hadith Validation) | Seerah narrations need the same authentication discipline as any hadith |
| Arabic Language | §4 (Quran Validation) | Grammar/morphology content inherits QUR-01/QUR-04's text-integrity requirements |
| Islamic History | §5, §2 (Level 3–4) | Historical reports follow Athar/Tafsir-level sourcing discipline |
| Scholar Profiles | §2, §6 (Tafsir attribution) | Formalizes the attribution metadata TAF-02 already requires |
| Regional Qira'at | §4 (Quran Validation) | QUR-01/QUR-03 extend per-riwayah, as already anticipated in `05_qiraat.md` |
| AI Coach | §9 (Confidence), §11 (Product Validation) | Coaching claims need confidence levels too; no new category needed |
| Voice Tutor | §11 (PRD rules), `04_tajweed.md` | Recitation assessment is a PRD-01/PRD-02 concern, not a new validation domain |
| Personalized Learning | §11, §7 (no unsourced preference) | Personalization must not introduce unsourced doctrinal preference under the guise of relevance |

No future module should require rewriting §1–§3 (Philosophy, Source Hierarchy, Hallucination Prevention) — those are the stable core this document is designed to protect.

---

## Global Principles

This document, and every rule in it, must:
- Never contradict the Quran (Level 1, §2).
- Never contradict authentic, established Sunnah (Level 2, §2).
- Remain neutral across madhabs and schools of thought where legitimate scholarly disagreement exists (§7).
- Prioritize honesty and stated uncertainty over fluent-sounding confidence (§1, §14).
- Always defer actual religious rulings to qualified human scholars (§8).
- Stay internally consistent with `00_system_prompt.md` and `14_content_validation.md` — where wording differs, intent must not.
- Remain stable as Talia's product features evolve — product decisions adapt to this document, not the reverse.
