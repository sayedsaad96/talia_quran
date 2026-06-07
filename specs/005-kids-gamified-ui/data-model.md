# Data Model: Kids Gamified Memorization UI

## Existing Entities (No Changes)

All entities below already exist in `lib/features/memorization_plus/domain/entities/memorization_entities.dart`. The gamified UI reads from them as-is.

### KidsJourneyStage

Maps 1:1 to a "House" (بيت الحفظ) in the gamified UI.

| Field | Type | Description |
|-------|------|-------------|
| stageNumber | int | House number (displayed as "بيت الحفظ ١") |
| surahId | int | Surah this stage belongs to |
| startAyah | int | First ayah in the range |
| endAyah | int | Last ayah in the range |
| completedAyahs | List\<int\> | Which ayahs have been completed |
| status | KidsJourneyStageStatus | locked / current / completed / needsReview |

**Computed properties**: `totalAyahs`, `completedCount`, `progress` (0.0–1.0), `isUnlocked`

**UI mapping**:
- `locked` → grey/dimmed house with lock icon
- `current` → highlighted, glowing house
- `completed` → bright house with gold stars
- `needsReview` → special "بيت المراجعة" styling (purple dome)

### KidsProgress

| Field | Type | Description |
|-------|------|-------------|
| totalPoints | int | Cumulative points earned |
| currentLevel | int | Current level (1-based) |
| currentStreak | int | Consecutive days with activity |
| starsEarned | int | Total stars (displayed as ⭐ count) |
| ayahsCompleted | int | Total ayahs memorized |
| lastSessionAt | DateTime? | Last session timestamp (UTC) |

**Computed properties**: `pointsForNextLevel` (level × 100), `pointsInCurrentLevel`, `levelProgress` (0.0–1.0), `starsForLevel` (1–3 based on level)

### KidsSessionLog

| Field | Type | Description |
|-------|------|-------------|
| id | String | Unique session ID |
| surahId | int | Surah practiced |
| ayahNumber | int | Ayah practiced |
| repeatsCompleted | int | Number of listen loops completed |
| pointsEarned | int | Points earned in this session |
| completedAt | DateTime | When session was completed |
| syncedAt | DateTime? | When synced to backend (nullable) |

### KidsJourneyStageStatus (Enum)

```
locked → House is inaccessible (grey/dimmed)
current → Active house (highlighted, playable)
completed → Fully done (bright, starred)
needsReview → Review house (special styling)
```

## New UI-Only Models (Presentation Layer)

These models exist only in the presentation layer for the gamified UI. They do NOT touch the domain or data layers.

### KidsGamifiedConfig (Feature Flag)

| Field | Type | Storage | Default |
|-------|------|---------|---------|
| useNewKidsGamifiedUi | bool | SharedPreferences | true |

### KidsThemeColors (Constants)

| Token | Hex | Usage |
|-------|-----|-------|
| nightSkyDark | #0D1B2A | Deep background |
| nightSkyMid | #1B2838 | Card backgrounds |
| forestGreen | #2D8E4C | Primary accents (existing) |
| ribbonGreen | #3C9F5F | Ribbon banners |
| goldStar | #FFB300 | Star icons and rewards |
| goldWarm | #D4A843 | Existing AppColors.gold |
| creamParchment | #FFF8E7 | Content card backgrounds |
| houseBrown | #8B6914 | House structure color |
| lockedGrey | #6B7280 | Locked house state |
| reviewPurple | #7C3AED | Review house dome |

## State Transitions

```
KidsJourneyStageStatus state machine:
  locked → current (when previous stage completed)
  current → completed (when all ayahs in stage memorized)
  completed → needsReview (when review interval reached)
  needsReview → completed (after successful review)
```

No changes to this state machine — it is driven by existing domain logic.
