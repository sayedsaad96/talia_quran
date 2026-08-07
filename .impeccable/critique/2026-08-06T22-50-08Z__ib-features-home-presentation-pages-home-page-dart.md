---
target: home screen
total_score: 26
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 4
timestamp: 2026-08-06T22-50-08Z
slug: ib-features-home-presentation-pages-home-page-dart
---
# Home Screen Design Critique

## Heuristic Scores

| # | Heuristic | Score | Finding |
|---|---|---:|---|
| 1 | Visibility of system status | 3/4 | Loading, retry, progress, streak, and resume state are visible; primary-action completion feedback is not evident. |
| 2 | Match to the real world | 3/4 | Daily wird, review, and memorization map well; XP and religiously loaded level labels pull toward generic gamification. |
| 3 | User control and freedom | 2/4 | Resume and banners can be dismissed, but system-led ordering and tappable containers do not always explain alternatives. |
| 4 | Consistency and standards | 2/4 | Shared tokens are present, but dark navigation uses persistent gold against the documented semantic rule; tap patterns vary. |
| 5 | Error prevention | 3/4 | Retry and mutually exclusive recommended-action logic are good safeguards. |
| 6 | Recognition rather than recall | 3/4 | Labelled navigation and contextual practice recommendations help, but similar cards compete for primacy. |
| 7 | Flexibility and efficiency | 2/4 | Resume state helps returning users; duplicated routes and dense vertical content add traversal. |
| 8 | Aesthetic and minimalist design | 3/4 | Hero, typography, spacing, and borders are coherent; the analytics stack is too dense for the calm product promise. |
| 9 | Error recognition and recovery | 3/4 | Dedicated error/retry state exists; offline and persistence recovery could not be verified from source. |
| 10 | Help and documentation | 2/4 | A conditional home-tour banner exists, but contextual help at the first practice decision is not evident. |
| **Total** |  | **26/40** | **Acceptable — significant hierarchy and restraint improvements needed.** |

## Design Specificity Verdict

Talia-specific elements—the mosque hero, Amiri/Noto Arabic pairing, warm-paper and teal palette, daily wird, and contextual Quran/memorization action—are strong. The lower screen becomes a generic gamified productivity dashboard of XP, streaks, levels, heatmaps, colourful metrics, and shortcuts, which competes with the retention-first Guided Sanctuary identity.

The deterministic scan returned no findings (`[]`) for `lib/features/home/presentation/pages/home_page.dart`.

## Overall Impression

The home screen opens with warmth and reverence but loses its focus as analytics, banners, and parallel routes accumulate. The biggest opportunity is to make one compassionate daily practice step unmistakably dominant and let the rest recede.

## What's Working

- The hero has a genuine Talia point of view: mosque imagery, dark-teal gradient, Amiri identity moment, prayer text, and contextual greeting.
- The contextual action logic intelligently chooses a coach recommendation, resumed session, kids mission, plan, or daily wird instead of blindly stacking all of them.
- Labelled navigation preserves core domains—Quran, memorization, adhkar, and progress—and keeps review context discoverable.

## Priority Issues

### [P1] No single dominant practice moment

**Why it matters:** Dashboard cards, banners, and shortcuts have comparable prominence to the memorization action, creating hesitation where daily consistency matters.

**Fix:** Reserve the first actionable viewport for one full-width practice card with a concrete next step and outcome (for example, “Review 5 ayahs due now”). Sequence sign-in and tour prompts after or beneath that action; demote daily wird and metrics.

**Suggested command:** `$impeccable layout`

### [P1] Gamification and rainbow metrics dilute the calm, reverent system

**Why it matters:** XP, the fire streak, purple level, blue due count, orange activity, and the heatmap produce a generic study-tracker feel and can turn encouragement into pressure.

**Fix:** Collapse engagement into one calm “Today’s progress” summary. Use teal for routine guidance, reserve gold for actual milestones, and move detailed streak/XP analysis to Progress or progressive disclosure. Use neutral learning-stage language if levels remain.

**Suggested command:** `$impeccable distill`

### [P1] Dark-mode navigation breaks the Meaningful Gold Rule

**Why it matters:** The shared system reserves gold for milestones and spiritual emphasis, but `_NavItem` and the navigation rail select gold in dark mode. Persistent use erodes the reward signal.

**Fix:** Use Royal Teal Light for active navigation in both themes. Keep gold for achievements and genuine completion moments.

**Suggested command:** `$impeccable colorize`

### [P1] Accessibility semantics and motion are inconsistent on primary controls

**Why it matters:** Source-visible `GestureDetector` cards/badges lack explicit semantic descriptions, icon-only controls lack source-visible labels, and repeating decorative animations have no source-visible reduced-motion path.

**Fix:** Use `InkWell`/`ListTile` or explicit `Semantics(button: true, label: ..., hint: ...)`; add tooltips to icon-only controls; gate repeating animation through the platform’s disable-animation preference.

**Suggested command:** `$impeccable audit`

### [P2] Duplicate pathways obscure the prescribed route

**Why it matters:** Tabs, quick actions, hero actions, daily wird, and progress badges can lead to overlapping routes. New learners must infer which starts today’s intended practice.

**Fix:** Let the primary action own today’s prescribed practice; remove redundant Settings and Progress quick actions; keep at most one contextual secondary entry such as Daily Wird.

**Suggested command:** `$impeccable distill`

## Persona Red Flags

- **Jordan, first-time Quran learner:** Sign-in, tour, next action, daily wird, metrics, heatmap, progress, and shortcuts compete before the first practice. It is unclear whether Today’s Plan, Daily Wird, and Memorization are alternatives or a sequence.
- **Casey, distracted mobile learner:** Resume support is useful, but it competes with tall prompt and analytics stacks. A short “resume in ~5 min” action would better support interrupted, one-handed returns.
- **Sam, accessibility-dependent learner:** Custom tappable cards/badges and icon-only controls lack source-visible semantic descriptions. Compact 10–12px labels and continuous decoration motion need device-level accessibility verification.

## Minor Observations

- The shell changes to a navigation rail at 600px, but large-text and wide-content behaviour within the home sections needs visual verification.
- Many sections use independent entrance animation, which can create visual churn on every return.
- Parent tools are appropriately conditional but add another audience to an already mixed learner dashboard; isolate them from the daily practice hierarchy.

## Questions to Consider

- What would the screen look like if success meant a learner starts the right five-minute review within five seconds?
- Should progress become a post-practice reward instead of a pre-practice dashboard?
- Could Daily Wird appear only when there is no due review rather than competing as a parallel destination?
