# Research: Kids Gamified Memorization UI

## Codebase Audit Findings

### Existing Kids Path Architecture

**Decision**: The kids memorization path already has a well-structured architecture under `lib/features/memorization_plus/`. The gamified UI will be a presentation-layer reskin of this existing feature — no domain or data layer changes needed.

**Rationale**: The existing code already separates concerns cleanly:
- Domain entities: `KidsProgress`, `KidsJourneyStage`, `KidsSessionLog`, `KidsJourneyStageStatus`
- Cubits: `KidsJourneyCubit` (journey map), `KidsModeCubit` (listen & repeat)
- Pages: `KidsJourneyPage` (stage list + progress), `KidsModePage` (ayah playback)
- Use cases: `GetKidsJourneyUsecase`, `GetKidsProgressUsecase`, `AwardKidsPointsUsecase`, `MarkAyahMemorizedUsecase`, `SaveKidsSessionLogUsecase`

**Alternatives considered**: Creating a parallel feature module — rejected because it would duplicate business logic.

### Stage Entity Mapping

**Decision**: `KidsJourneyStage` already contains exactly what the gamified houses need: `stageNumber`, `surahId`, `startAyah`, `endAyah`, `completedAyahs`, `status` (enum: `locked`, `current`, `completed`, `needsReview`).

**Rationale**: Direct 1:1 mapping confirmed in spec clarification. No new stage data model required.

### Progress Entity

**Decision**: `KidsProgress` already has `totalPoints`, `currentLevel`, `currentStreak`, `starsEarned`, `ayahsCompleted`, `lastSessionAt`. The `addPoints()` method handles leveling (exponential: `level * 100` points per level).

**Rationale**: The star economy clarification (20 stars/stage, 100 stars = level) differs from the existing formula. The gamified UI will use the existing fields but the display logic will adapt:
- `starsEarned` → displayed as star count in the UI
- `currentLevel` / `levelProgress` → displayed as level bar
- No modification to the `addPoints()` or `_starsForRating()` methods needed for the UI layer

### Routing Structure

**Decision**: Existing routes: `/memorization-plus/kids-journey` and `/memorization-plus/kids`. The gamified UI will replace these routes' page builders conditionally via feature flag.

**Rationale**: Uses `go_router` with `AppRoutes` constants. The child profile detection happens at `AppRouter` line ~270: `if (profile.isChild) return AppRoutes.memorizationPlusKidsJourney`. This routing logic stays unchanged.

### Color Palette Analysis

**Decision**: Create a dedicated `kids_theme.dart` file with the gamified color palette based on the reference design.

**Rationale**: The reference design uses a distinct night-blue/deep-green palette that differs from `AppColors`:
- Night sky background: `#0D1B2A` (darker than `AppColors.darkBackground`)
- Forest green accents: `#2D8E4C` (already used in current kids pages)
- Gold/amber stars: matches `AppColors.gold` / `AppColors.goldLight`
- Cream/parchment cards: matches `AppColors.parchmentLight`
- New additions: ribbon green `#3C9F5F`, house brown `#8B6914`

### Audio Integration

**Decision**: Reuse existing `KidsModeCubit` audio logic with `just_audio` and `QuranAudioService.buildUrl()`.

**Rationale**: The listen & repeat screen is a visual reskin only. The cubit already handles:
- 3-loop auto-play with `_onPlaybackCompleted()`
- Audio error handling with fallback messages
- Completion flow with points, streak, XP, and achievement checks

### Feature Flag Strategy

**Decision**: Use a simple `SharedPreferences` boolean flag `useNewKidsGamifiedUi` defaulting to `true`. Wrap the page builders in the router with an `ErrorBoundary`-style try/catch that falls back to old UI.

**Rationale**: Aligns with constitution's `shared_preferences` for simple flags. No Isar schema change needed.

## Best Practices Research

### Flutter Custom Painting for Journey Map

**Decision**: Use `CustomPainter` for the curved path connecting houses, with `Stack` + `Positioned` for house cards overlaid on the path.

**Rationale**: The reference design shows a winding vertical path. `CustomPainter` with `Path.cubicTo()` provides smooth Bezier curves. Alternative (SVG image background) rejected because it can't adapt dynamically to the number of stages.

### Animation Strategy

**Decision**: Use `flutter_animate` (already in the project) for micro-animations: star celebrations, house unlock transitions, ribbon banner entrance.

**Rationale**: Already approved in the constitution's technology stack. No new dependency needed.

### Asset Strategy

**Decision**: Use generated images for house illustrations and kid character avatars as PNG assets. Store under `assets/images/kids/`.

**Rationale**: The reference design has detailed illustrations (houses, characters, lanterns). These must be pre-generated as assets since they can't be reproduced with Flutter's built-in painting alone.
