# Data Model: Fix Memorization User Identity & Guardian-Linking Flow

## Entities

### `MemorizationProfile`
Represents the user's core identity within the memorization feature.
- **Fields**:
  - `selectedPath` (`MemorizationPath` enum: `child` | `adult`)
  - `guardianLinkStatus` (`GuardianLinkStatus` enum: `none` | `pending` | `linked`)
  - `isParentGuardian` (`bool`)
  - `linkedChildId` (`String?`)
  - `guardianId` (`String?`)
- **Validation / State Transitions**:
  - If `selectedPath == adult`, `guardianLinkStatus` MUST be `none`.
  - `isParentGuardian` can only be `true` if `selectedPath == adult`.
  - On path reset, reset all fields except `SmartMemorizationSettings` (handled separately).

### `PairingSession`
A temporary session used to connect a child account with a guardian.
- **Fields**:
  - `pairingCode` (`String`) - Unique code.
  - `qrData` (`String`) - Encoded data for QR generation.
  - `expiresAt` (`DateTime`) - Set to 15 minutes from generation.
  - `status` (`PairingSessionStatus` enum: `pending` | `completed` | `expired`)
  - `isUsed` (`bool`) - Set to true upon first successful scan.
- **State Transitions**:
  - `pending` -> `completed` (on successful scan by parent, sets `isUsed = true`)
  - `pending` -> `expired` (if `DateTime.now() > expiresAt`)

### `SmartMemorizationSettings`
User's smart memorization configuration.
- **Fields**:
  - `dailySchedule` (`List<int>`)
  - `reviewDays` (`List<int>`)
  - `ayahIsolationEnabled` (`bool`)
  - `customPlan` (`Map<String, dynamic>?`)
- **Constraints**:
  - Changing this MUST NOT alter `MemorizationProfile`.
