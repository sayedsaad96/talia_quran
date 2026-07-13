# Talia Memorization V2 – Product Rules

Version: 1.0
Status: Draft for Approval
Owner: Product Team

---

# 1. Purpose

The purpose of Memorization V2 is to create a true Quran memorization journey that mirrors real-world memorization methodology:

Learn → Memorize → Recite → Review → Reinforce

The system must clearly separate:

* Learning
* Memorization
* Recitation
* Review

and must never mix them in the same step.

---

# 2. Core Product Principles

## Principle 1 — Memorization is not Review

A user who is learning a new ayah must not be treated as a review user.

New memorization and review are different cognitive activities and require different experiences.

---

## Principle 2 — Recitation is Mandatory

An ayah cannot be considered memorized unless the user successfully recites it.

Listening alone does not count as memorization.

Reading while viewing the ayah does not count as memorization.

---

## Principle 3 — Block-Based Learning

Memorization happens in small blocks.

Default block size:

* Adults: 5 ayat
* Kids: 5 ayat

Future configuration may support:

* 3 ayat
* 5 ayat
* 8 ayat
* 10 ayat

---

## Principle 4 — Review Happens After Memorization

The user first memorizes individual ayat.

Only after completing the block does the user perform Block Review.

---

# 3. Adult Memorization Flow

## Session Start

User receives:

* Next memorization mission
* Surah
* Ayah range
* Block size

Example:

Surah Al-Mulk
Ayah 1–5

---

## Phase 1 — Learning

Goal:

Understand and hear the ayah.

Allowed:

* Listen
* Repeat listening
* Read text

No scoring.

No pass/fail.

No progress awarded.

---

## Phase 2 — Memorization

Goal:

Attempt to remember the ayah.

Allowed:

* Hide/show text
* Listen again
* Controlled hint system

No final evaluation yet.

---

## Phase 3 — Recitation

Goal:

Recite from memory.

Rules:

* Full-screen recitation mode
* No visible ayah text
* No automatic display of answer
* User records recitation

Outcome:

* Pass
* Fail

---

## Phase 4 — Remediation

Triggered when:

Recitation fails.

Actions:

* Replay ayah
* Show text again
* Allow another memorization attempt

User must return to Recitation.

---

## Phase 5 — Block Review

Triggered after all ayat in the block are passed.

Example:

Ayah 1–5 completed

Now review:

Ayah 1–5 together

Rules:

* No visible text
* No hints by default
* Full block evaluation

Outcomes:

* Pass
* Fail

---

## Phase 6 — Completion

Session completed when:

* All ayat passed
* Block Review passed

Session result saved.

---

# 4. Kids Memorization Flow

Kids follow the same engine.

Only presentation changes.

> **Known limitation (Phase 1 — documented in [memorization-remediation-plan.md](./memorization-remediation-plan.md)):**  
> As of the current release tier, Kids Mode uses a simplified gamified listen/remember flow that does **not** yet run the full V2 session FSM (Learning → Memorizing → Individual Recitation → Block Review). Presentation differs today; engine parity is **Phase 2 product work**, not a Sprint 1 blocker. Do not assume §4 and §14.8 below are fully implemented in Kids UI until that phase ships.

---

## Kids Learning

UI language:

🎧 Listen

---

## Kids Memorization

UI language:

🧠 Try to remember

---

## Kids Recitation

UI language:

🎤 Your turn

---

## Kids Review

UI language:

⭐ Review Challenge

---

## Kids Rules

The underlying memorization logic must remain identical to Adult rules.

No separate memorization engine for kids.

---

# 5. Hint Rules

Hints are allowed only during Memorization Phase.

Never during official Recitation.

---

## Hint Level 0

No help.

Full score.

---

## Hint Level 1

Reveal first word only.

Small score penalty.

---

## Hint Level 2

Reveal full ayah.

Large score penalty.

---

## Hint Usage Tracking

Every hint usage must be recorded.

Future Smart Coach decisions may use hint history.

---

# 6. Recitation Evaluation Rules

A recitation attempt produces:

* Pass
* Fail

Future versions may support confidence scores.

---

## Pass

Ayah considered memorized.

Progress updated.

Review records updated.

---

## Fail

Ayah enters remediation cycle.

No memorization credit granted.

---

# 7. Block Review Rules

Purpose:

Verify retention of the complete block.

Example:

Ayah 1–5

---

## Success

Block marked complete.

Session completed.

Review scheduling updated.

---

## Failure

System identifies weak ayat.

Only weak ayat re-enter remediation.

Passed ayat remain passed.

---

# 8. Review Engine Integration

Memorization V2 does NOT replace the Review Engine.

The existing Review Foundation remains the source of truth.

---

## Required Integration

When an ayah becomes memorized:

Create or update:

AyahReviewRecord

using existing project infrastructure.

---

## Forbidden

Do not create a second review database.

Do not create a competing review model.

---

# 9. Progress Integration

Progress must continue using the existing progress system.

Memorization V2 is a journey layer only.

Progress remains the responsibility of current progress infrastructure.

---

# 10. Smart Coach Integration

Smart Coach remains unchanged.

Memorization V2 provides session outcomes.

Smart Coach consumes those outcomes.

### Coach / Unified Journey priority (Sprint 3)

When Home Hero and Smart Coach compete, resolve in this order:

1. Incomplete Isar / restorable session  
2. Due / weak review  
3. Daily plan  
4. Explore / free navigation  

Hero metrics must come from `ProgressMetricsService` only and must not override Coach when Coach has a due weak ayah.

---

## Smart Coach may recommend:

* New memorization
* Review
* Retry weak ayat
* Continue unfinished session

---

# 11. Session States

Official state machine:

CREATED

↓

LEARNING

↓

MEMORIZING

↓

RECITING

↓

REMEDIATION (if needed)

↓

BLOCK_REVIEW_PENDING

↓

BLOCK_REVIEW

↓

COMPLETED

---

# 12. Non-Goals

Memorization V2 will NOT:

* Replace Smart Review Engine
* Replace Progress System
* Replace Guardian Features
* Replace Achievement System
* Replace Authentication
* Replace Existing Backend Infrastructure

---

# 13. Success Criteria

Memorization V2 is successful when:

* User clearly understands what to do next.
* Memorization and review are fully separated.
* Every memorized ayah is recited successfully.
* Block Review validates retention.
* Kids and Adults share one engine.
* Existing review and progress systems remain intact.

# 14. Final Product Decisions (Approved)

## 14.1 Recitation Technology

Official recitation evaluation method:

- Speech-to-Text (STT)

The user must recite the ayah.
The system converts speech into text.
The recognized text is compared against the target ayah.

Recording-only mode is not considered a valid memorization evaluation method.

---

## 14.2 Recitation Success Criteria

Success threshold:

- 100% match required

A memorization attempt is considered successful only when the ayah is recited correctly without omissions or substitutions.

Result:

- Pass
- Fail

No partial pass exists in V2.

---

## 14.3 Kids Block Review Exception

Block Review is mandatory for:

- Adults
- Older children

Block Review may be skipped for:

- Early-age children

The age threshold should be configurable.

Recommended default:

- Under 8 years old → Block Review optional
- 8+ years old → Block Review required

When skipped:

- Individual ayah recitation remains mandatory.
- AyahReviewRecord must still be updated.

---

## 14.4 Failure Escalation Rules

Failure counter is tracked per ayah.

After:

- 1st failure → Standard Remediation
- 2nd failure → Additional guided memorization
- 3rd failure → Mark as Weak Ayah

After 3 failures:

- Smart Coach receives weak-ayah signal.
- Future plans may reduce new memorization load.
- Future plans may prioritize review and reinforcement.

The ayah remains eligible for future memorization attempts.

---

## 14.5 Weak Ayah Definition

An ayah becomes Weak when:

- It fails recitation 3 times in the same session.

Weak ayat should receive:

- Higher review priority
- Additional reinforcement sessions
- Smart Coach intervention

---

## 14.6 Hint Penalty Rules

Hint Level 0:
- Full score

Hint Level 1:
- Reduced score

Hint Level 2:
- Minimum passing score

A recitation attempt that required Hint Level 2 may still pass memorization requirements if the final STT evaluation reaches 100%.

However, Smart Coach should record dependency on hints.

## 14.7 STT Matching Policy (Approved)

The memorization system uses Speech-to-Text (STT) evaluation.

Because Arabic STT systems may produce variations that do not affect actual recitation correctness, direct text comparison is forbidden.

Before evaluation, both:

- Target Ayah
- STT Result

must pass through a normalization pipeline.

---

### Normalization Rules

Apply the following:

- Remove all harakat (tashkeel)
- Normalize hamza forms
- Normalize alif variants
- Remove Quran stop symbols
- Remove punctuation
- Remove extra spaces
- Normalize Arabic character variants

Examples:

مَالِكِ يَوْمِ الدِّينِ

becomes

مالك يوم الدين

---

### Evaluation Rule

Success condition:

Normalized STT Output
=
Normalized Ayah Text

Required match:

100%

---

### Failure Rule

If normalized texts do not match exactly:

Result = Fail

User enters Remediation phase.

---

### Future Extensions

Future versions may support:

- Word-level error detection
- Missing-word identification
- Pronunciation scoring
- Tajweed evaluation

These are explicitly out of scope for Memorization V2 initial release.

## 14.8 Memorization Flow Policy (Approved)

The official memorization flow for Memorization V2 is:

Learning
→ Memorizing
→ Individual Recitation
→ Next Ayah
→ ...
→ Block Review
→ Complete

### Per-Ayah Flow

For each ayah:

1. Learning Phase

   * Listen to the ayah.
   * Read the ayah.
   * Repeat as needed.

2. Memorizing Phase

   * User attempts memorization.
   * Hint system is available.

3. Individual Recitation Phase

   * User recites the ayah using STT.
   * Evaluation uses normalized exact matching.
   * Pass required before moving forward.

4. Remediation Phase (if needed)

   * Triggered on failure.
   * User returns to memorization.
   * Retry allowed.

Only after successfully reciting the current ayah may the user move to the next ayah.

### Block Completion

After all ayahs in the block pass individual recitation:

Block Review becomes mandatory.

Example:

Ayah 1 → Pass

Ayah 2 → Pass

Ayah 3 → Pass

Ayah 4 → Pass

Ayah 5 → Pass

↓

Block Review

↓

Recite Ayah 1–5 together

↓

Complete Block

### Purpose

Individual Recitation validates memorization of each ayah.

Block Review validates continuity and retention across the entire memorized block.

Both are required for successful memorization.

### Kids Policy

Kids follow the same memorization engine.

The only allowed differences are:

* Simplified UI
* Gamification
* Optional Block Review for configured young ages

The memorization rules themselves remain identical.

> **Implementation status:** The policy above is the **target** behavior. Current Kids Mode is presentation-only gamification on a separate flow; full V2 engine parity (including Block Review wiring) is deferred to **Phase 2** — see PB7 in [memorization-remediation-plan.md](./memorization-remediation-plan.md). Until then, treat adult V2 sessions as the reference implementation of §14.8.

## 14.9 Block Size Policy (Approved)

Block Review is configurable.

The system must not enforce a single fixed block size.

Users may choose their preferred memorization block size.

### Supported Block Sizes

Recommended options:

* 3 Ayahs
* 5 Ayahs
* 8 Ayahs
* 10 Ayahs

Default:

* Adults → 5 Ayahs
* Kids → 5 Ayahs

### Behavior

Example:

Block Size = 5

Ayah 1 → Pass

Ayah 2 → Pass

Ayah 3 → Pass

Ayah 4 → Pass

Ayah 5 → Pass

↓

Block Review

↓

Complete Block

Example:

Block Size = 10

Ayah 1 → Pass

...

Ayah 10 → Pass

↓

Block Review

↓

Complete Block

### Smart Coach Compatibility

Block size affects:

* Session planning
* Progress pacing
* Block review timing

Block size must NOT affect:

* SRS scheduling
* AyahReviewRecord semantics
* Strength calculations
* Review classification logic

### Kids Policy

Kids may use smaller block sizes.

Recommended:

* Beginner Kids → 3–5 Ayahs
* Advanced Kids → 5–8 Ayahs

The actual memorization engine remains identical.


End of Document
