# Quickstart: Kids Gamified Memorization UI

## Prerequisites

- Flutter SDK ≥ 3.22, Dart ≥ 3.4
- Current branch: `005-kids-gamified-ui`
- All existing tests pass: `flutter test`

## Feature Flag

The new gamified UI is controlled by:
```dart
// lib/features/memorization_plus/presentation/kids_gamified_config.dart
const bool kUseGamifiedKidsUi = true;
```

Set to `false` to revert to the old kids UI instantly.

## Key Files to Modify

### Existing Files (Modify)
1. `lib/core/router/app_router.dart` — Wrap kids page builders with feature flag check
2. `lib/core/l10n/app_ar.arb` — Add new Arabic UI strings
3. `lib/core/l10n/app_en.arb` — Add new English UI strings

### New Files (Create)

**Theme & Config:**
- `lib/features/memorization_plus/presentation/theme/kids_theme.dart` — Gamified color palette & text styles

**Widgets (Reusable):**
- `lib/features/memorization_plus/presentation/widgets/kids_journey_map.dart` — Curved path with houses
- `lib/features/memorization_plus/presentation/widgets/kids_house_card.dart` — Single house widget (3 states)
- `lib/features/memorization_plus/presentation/widgets/kids_progress_header.dart` — Welcome + level + stars
- `lib/features/memorization_plus/presentation/widgets/kids_mission_card.dart` — Last mission card
- `lib/features/memorization_plus/presentation/widgets/kids_stage_details.dart` — Stage detail with 3 steps
- `lib/features/memorization_plus/presentation/widgets/kids_reward_dialog.dart` — Completion celebration
- `lib/features/memorization_plus/presentation/widgets/kids_ayah_card.dart` — Parchment-style ayah card

**Pages:**
- `lib/features/memorization_plus/presentation/pages/kids_gamified_home_page.dart` — New home screen
- `lib/features/memorization_plus/presentation/pages/kids_gamified_journey_page.dart` — New journey map
- `lib/features/memorization_plus/presentation/pages/kids_gamified_stage_page.dart` — Stage details screen
- `lib/features/memorization_plus/presentation/pages/kids_gamified_listen_page.dart` — Listen & repeat reskin
- `lib/features/memorization_plus/presentation/pages/kids_gamified_completion_page.dart` — Celebration screen

**Assets:**
- `assets/images/kids/` — House illustrations, character avatar, decorative elements

## Build & Test

```bash
# 1. Verify no breaking changes
flutter analyze
flutter test

# 2. Run the app in kids mode
flutter run

# 3. Navigate to: Settings → Profile → Kids mode → Kids Journey
```

## Architecture Constraints

- All new code stays within `lib/features/memorization_plus/presentation/`
- No changes to domain/ or data/ layers
- No new packages — uses existing: flutter_animate, just_audio, flutter_bloc
- All new strings must go through .arb localization files
- Arabic RTL must be tested on all new screens
