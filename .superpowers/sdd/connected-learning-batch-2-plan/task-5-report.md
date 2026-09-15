# Task 5 report — one exact Home recommendation outcome

## Outcome

Home now carries the authoritative `SmartCoachRecommendation.route` into
critical-alert and review-backlog journey inputs, and the Unified Journey
engine remains the only priority selector. Identical route outcomes are kept
once, in priority order. The old post-engine urgent-review suppression has
been removed.

An active Khatmah continuation remains Home's primary card. When the selected
learning outcome is an urgent review, Home renders that exact action directly
below the Khatmah card. Both the compile-time journey gate and the persisted
preference gate preserve the legacy Home action chain when disabled.

## TDD evidence

- **RED:** `Scenario 2: Critical Learning Alert emits P2 Action` expected the
  Coach session URI and received `/memorization` instead.
- **GREEN:** the same test passed after the Cubit populated
  `learningAlertRoute` from the Coach route.
- **RED:** `keeps urgent review visible below active Khatmah` found no
  `UnifiedHeroActionCard` below the continuation card.
- **GREEN:** it passed after the primary resolver exposed the urgent-review
  secondary contract and Home rendered it.
- **RED:** the exact-route alternatives test received the same Coach URI at
  p2, p3, and p4.
- **GREEN:** the engine now retains that URI once, preserving the highest
  priority action and distinct alternatives.

## Changed files

- `lib/core/journey/unified_journey_input.dart`
- `lib/core/journey/unified_journey_engine.dart`
- `lib/features/home/domain/services/home_primary_action_resolver.dart`
- `lib/features/home/presentation/cubits/home_cubit.dart`
- `lib/features/home/presentation/cubits/home_state.dart`
- `lib/features/home/presentation/pages/home_page.dart`
- Focused journey, Home Cubit, resolver, coherence, and responsive-widget
  tests.

## Verification

- Focused engine/resolver/Cubit/coherence suite: 38 passing tests.
- Khatmah urgent-review widget contract: passing.
- Legacy action-card flag-off widget contract: passing.
- Smart Coach Home validation regression suite: 20 passing tests.
- Targeted `dart analyze` completed with exit code 0.

## Self-review / concerns

- URI assertions parse and verify `surahId`, `ayahNumber`, `intent`, and
  `origin`; no route is reconstructed.
- Route deduplication is intentionally exact-string based, retaining the
  first (highest-priority) action. Equivalent URIs with differently ordered
  query parameters are not normalized.
- No persistence, schema, migration, DI, or router registration changed.
