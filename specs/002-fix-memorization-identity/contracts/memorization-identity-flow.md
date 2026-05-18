# Contract: Memorization Identity Flow

This is a mobile UI and repository contract for the existing Flutter app. It is not an
HTTP API contract.

## Repository Contract

Extend `MemorizationPlusRepository` with identity methods that return `Either<Failure, T>`.

```dart
Either<Failure, MemorizationProfile> getMemorizationProfile();
Future<Either<Failure, MemorizationProfile>> selectMemorizationPath(
  MemorizationPath path,
);
Future<Either<Failure, MemorizationProfile>> continueWithoutGuardian();
Future<Either<Failure, PairingSession>> createGuardianPairingSession();
Future<Either<Failure, MemorizationProfile>> acceptGuardianPairingCode(
  String codeOrQrData,
);
Future<Either<Failure, PairingSession>> refreshPairingSession();
Future<Either<Failure, MemorizationProfile>> unlinkGuardian();
Future<Either<Failure, MemorizationProfile>> setParentGuardianMode(bool value);
Future<Either<Failure, MemorizationProfile>> resetMemorizationIdentity();
```

### Required Behavior

- `getMemorizationProfile()` performs one-time migration from existing
  `mem_plus_track`, `mem_plus_is_parent_mode`, and Hifz path values when no profile
  exists.
- `selectMemorizationPath(adult)` saves adult identity and sets guardian status to none.
- `selectMemorizationPath(child)` saves child identity and marks guardian onboarding as
  required.
- `continueWithoutGuardian()` is valid only for child identity with required onboarding.
- `createGuardianPairingSession()` is valid only for child identity that is not already
  linked and has no active pending session.
- `acceptGuardianPairingCode()` accepts both raw code and `talia-kids-link:<code>` QR
  payloads.
- `resetMemorizationIdentity()` removes identity and pairing keys only.

## Cubit/UI Contract

### Memorization Entry

Route: `/memorization-plus`

State contract:

```text
initial/loading
needsPathSelection
adultReady(lastSurahId)
guardianOnboardingRequired
pairingPending(session)
childReady(lastSurahId, guardianLinkStatus)
error(message)
```

Behavior:

- No saved path shows a mandatory path-selection view.
- The path-selection view cannot be dismissed without selecting Adult or Child/Beginner.
- Adult path routes to `/memorization-plus/daily-plan?surahId=<lastSurahId>`.
- Child path shows guardian onboarding immediately unless the profile says onboarding
  was already skipped/completed.
- Child ready state routes to `/memorization-plus/kids-journey?surahId=<lastSurahId>`.

### Guardian Onboarding

Choices:

```text
Link guardian now
Continue without guardian
```

Behavior:

- Link guardian now creates and displays a 15-minute single-use pairing code plus QR
  data.
- Continue without guardian saves the skip decision and starts the child flow.
- Expired code shows a distinct "code expired" error and offers regeneration.
- Already-used code shows a distinct "code already used" error and offers regeneration.
- Already-linked child sees a blocking message directing them to unlink in Settings.

### Settings

Required controls:

```text
Reset / Change path
I am a parent/guardian
Scan or enter child pairing code
Unlink guardian / disable parent mode
```

Visibility rules:

- Reset/change path is visible after a path exists.
- Parent/guardian toggle is visible only for adult identity.
- Scan/enter child pairing code is visible only when adult parent mode is enabled.
- Child unlink/regenerate controls are visible only for child identity in Settings.
- Parent dashboard entry must not imply the adult user's own memorization path changed.

## Smart Memorization Contract

- Daily plan save, custom plan save/delete, review-day changes, ayah isolation changes,
  and quiz/kids progress updates must not write profile identity fields.
- Smart Memorization reads identity only to decide adult vs child routing and guardian
  display state.
- Existing custom plan values remain valid after identity reset.

## Error Contract

| Condition | Expected UI Result |
|---|---|
| No path selected | Mandatory path-selection view. |
| Adult identity | No guardian onboarding anywhere in memorization flows. |
| Child skipped guardian | Child flow opens without automatic re-prompt. |
| Child already linked | New pairing is blocked with unlink guidance. |
| Pairing expired | Show expired-code error and regenerate action. |
| Pairing already used | Show used-code error and regenerate action. |
| Network error during pairing | Keep local identity unchanged and show retry. |
| Reset/change path | Return to no-path state and preserve Smart settings. |
