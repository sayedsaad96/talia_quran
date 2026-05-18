# Feature Specification: Fix Memorization User Identity & Guardian-Linking Flow

**Feature Branch**: `002-fix-memorization-identity`

**Created**: 2026-05-17

**Status**: Draft

**Input**: User description: "Fix the memorization user identity and guardian-linking flow in Talia Quran app."

---

## Clarifications

### Session 2026-05-17

- Q: How long should the pairing code remain valid, and can it be used more than once before expiring? → A: 15-minute single-use code. The code expires 15 minutes after generation and is invalidated immediately upon first successful scan, preventing replay use.
- Q: When a child account is already linked to a guardian and a new pairing is initiated, what should happen? → A: Block new pairing initiation. The user must explicitly unlink the current guardian first before a new pairing code can be generated.
- Q: When the user resets their memorization path, should Smart Memorization settings also be wiped? → A: No. Path reset clears only the selected path, guardian-linking status, and pairing data. Smart Memorization settings (schedule, review days, custom plan) are preserved.
- Q: After a path reset and re-selection of the Child path, should the guardian-linking step be shown again? → A: Yes. A path reset is a full identity reset. The guardian-linking step is always shown again when the Child path is re-selected, regardless of any prior "Continue without guardian" decision.
- Q: When a parent disables guardian mode and the link is severed, what happens on the child's side? → A: The child silently reverts to guardianLinkStatus = none. The child is NOT re-prompted with the guardian-linking step; they continue normally as an unlinked child and can re-link from Settings if desired.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First-Time Path Selection (Priority: P1)

A user opens the Memorization section for the first time. The app presents a mandatory choice between two memorization paths: **Child / Beginner** or **Adult**. The user selects one and this choice is saved permanently. On every subsequent launch, the app goes directly to the appropriate memorization flow without asking again.

**Why this priority**: This is the foundational identity gate. Every downstream guardian-linking and Smart Memorization decision depends on which path the user has chosen. Without it, all other flows are undefined.

**Independent Test**: Can be fully tested by fresh-installing the app, navigating to Memorization, selecting a path, force-closing, re-opening, and verifying the path selection screen is skipped and the correct flow is shown.

**Acceptance Scenarios**:

1. **Given** a new user with no saved path, **When** they open the Memorization section, **Then** a path-selection screen is shown with exactly two options: "Child / Beginner" and "Adult".
2. **Given** the path selection screen is visible, **When** the user attempts to dismiss or navigate away without selecting a path, **Then** the action is blocked and the screen remains.
3. **Given** the user selects "Adult", **When** the selection is saved, **Then** the app navigates directly to the adult memorization flow without showing guardian-linking steps.
4. **Given** the user has previously selected a path, **When** they reopen the Memorization section, **Then** the path-selection screen is not shown and the correct flow resumes immediately.
5. **Given** the user resets their path from Settings, **When** they next open the Memorization section, **Then** the path-selection screen is shown again.

---

### User Story 2 - Child Path Guardian Linking (Priority: P1)

After a child/beginner user selects the Child path, the app immediately presents a mandatory guardian-linking step. The user must explicitly choose: **Link guardian now** or **Continue without guardian**. If they choose to link, a pairing code is generated and displayed. Once a guardian scans it on another device, the child account is marked as linked. If they choose to skip, that decision is saved and the guardian-linking prompt is never shown again (unless the user initiates it from Settings).

**Why this priority**: Guardian oversight is a core safety and engagement feature for child users. The decision must be captured explicitly and cannot be deferred indefinitely without user action.

**Independent Test**: Can be fully tested by selecting the Child path, going through both branches (link / skip), verifying the pairing code screen appears in the link flow, and confirming the skip decision persists across restarts.

**Acceptance Scenarios**:

1. **Given** the user selected the Child path, **When** the path is saved, **Then** the guardian-linking step is shown immediately as the next screen.
2. **Given** the guardian-linking step is shown, **When** the user taps "Link guardian now", **Then** a unique pairing code (and optional QR code) is generated and displayed on screen.
3. **Given** the pairing code is displayed, **When** a guardian scans/enters the code on another device, **Then** the child account is marked as linked and the pairing screen closes.
4. **Given** the guardian-linking step is shown, **When** the user taps "Continue without guardian", **Then** the decision is saved, the step is dismissed, and the child memorization flow begins.
5. **Given** the user previously chose "Continue without guardian", **When** they return to the Memorization section, **Then** the guardian-linking step is NOT shown again.
6. **Given** the child account is linked to a guardian, **When** the user re-enters any memorization mode, **Then** the linked guardian status is still active and not reset.

---

### User Story 3 - Adult Path Direct Flow (Priority: P1)

A user who selects the Adult path proceeds directly to the adult memorization experience. No guardian-linking step, no pairing code, and no parent/guardian prompt appears anywhere in the memorization onboarding or Smart Memorization flow.

**Why this priority**: Showing guardian-linking prompts to adults creates confusion and erodes trust. Preventing this is equally critical to enabling it for children.

**Independent Test**: Can be fully tested by selecting the Adult path and verifying that no guardian-linking screen appears at any point during onboarding or while using Smart Memorization.

**Acceptance Scenarios**:

1. **Given** the user selected the Adult path, **When** the selection is saved, **Then** the app navigates directly to the adult memorization flow with no guardian-linking prompts.
2. **Given** an adult user in any memorization mode (Normal or Smart), **When** they change memorization settings, **Then** no guardian-linking dialog or prompt appears.
3. **Given** an adult user using Smart Memorization, **When** they configure daily schedule, ayah isolation, or review days, **Then** their adult path identity and absence of guardian state is preserved.

---

### User Story 4 - Parent/Guardian Mode via Settings (Priority: P2)

An adult user who is a parent can optionally enable a "I am a parent/guardian" mode from within Settings. When enabled, they can scan or enter a child's pairing code to link to that child's memorization progress. This role is completely optional, independent of their own memorization path, and does not affect their own memorization settings or Smart Memorization behavior.

**Why this priority**: Parental oversight is valuable but must not intrude on the adult user's own experience. Keeping it in Settings ensures it is accessible without being disruptive.

**Independent Test**: Can be fully tested by navigating to Settings, enabling parent mode, scanning a pairing code, confirming the link appears, then opening Smart Memorization and verifying the adult user's own memorization is unaffected.

**Acceptance Scenarios**:

1. **Given** an adult user in Settings, **When** they enable "I am a parent/guardian", **Then** an option to scan/enter a child's pairing code is revealed.
2. **Given** the parent mode is enabled and a pairing code is entered, **When** the code matches a valid child account, **Then** the guardian is linked and can view the child's memorization progress.
3. **Given** the parent/guardian role is enabled, **When** the adult uses their own Smart Memorization, **Then** their personal memorization settings and path are not altered.
4. **Given** parent mode is disabled, **When** the adult uses any memorization mode, **Then** no guardian-related options or prompts appear.

---

### User Story 5 - Smart Memorization Respects Path Identity (Priority: P2)

Smart Memorization is a memorization method, not a separate user identity. When a child user enters Smart Memorization, their child identity and guardian-linking status carry over. When an adult enters Smart Memorization, no guardian state is imposed. Changing Smart Memorization settings (daily schedule, review days, ayah isolation, custom plan) never resets or overwrites the user's path, child status, guardian-linked status, or parent/guardian role.

**Why this priority**: Without this safeguard, smart memorization configuration changes silently corrupt the user's identity state, causing child users to lose guardian links and adult users to be unexpectedly prompted for guardian linking.

**Independent Test**: Can be fully tested by setting up a child user with guardian linked, entering Smart Memorization, changing multiple settings, returning to the main memorization screen, and verifying the guardian link is still active. Repeat with an adult user verifying no guardian state appears.

**Acceptance Scenarios**:

1. **Given** a child user linked to a guardian, **When** they enter Smart Memorization and change a setting, **Then** the guardian link remains active after saving.
2. **Given** a child user who chose "Continue without guardian", **When** they configure Smart Memorization, **Then** the guardian-linking prompt does not reappear.
3. **Given** an adult user, **When** they use Smart Memorization, **Then** no guardian-linking prompt is shown at any point.
4. **Given** any user changes Smart Memorization settings, **When** the settings are saved, **Then** the saved path (Child/Adult), guardian status, and parent/guardian role are unchanged.

---

### Edge Cases

- What happens if the pairing code expires (after 15 minutes) or has already been used before the guardian scans it? → The app must display an error message distinguishing the two states ("Code expired" vs. "Code already used") and offer to regenerate a fresh single-use code.
- What happens if the user closes the app mid-pairing? → The pairing attempt is abandoned; the child's guardian-linking status remains "not linked" until a successful pairing occurs.
- What happens if a user resets their path via Settings? → Only the selected path, guardian-linking status, and pairing data are cleared. Smart Memorization settings (daily schedule, review days, custom plan, ayah isolation) are preserved. The user must go through path selection again on next entry to the Memorization section. If they re-select the Child path, the guardian-linking step is shown again as a fresh start, overriding any previous "Continue without guardian" decision.
- What happens if an adult who enabled parent mode disables it? → The link is severed on both sides. The parent's `isParentGuardian` flag is cleared and `linkedChildId` is removed. The child's `guardianLinkStatus` is silently set to `none` and `guardianId` is cleared. The child is NOT shown the guardian-linking step again; they continue as an unlinked child and can initiate a new link from Settings.
- What happens if a child attempts to re-enter the path selection after it has been saved? → The path selection screen is only accessible via the explicit "Reset / Change path" action in Settings.
- What happens if a child who is already linked to a guardian tries to link a new guardian? → The new pairing is blocked. The app must show a message indicating an active guardian link exists and direct the user to unlink the current guardian in Settings before initiating a new pairing.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display a mandatory path-selection screen (Child / Beginner vs. Adult) the first time a user opens the Memorization section with no saved path.
- **FR-002**: The app MUST prevent dismissal of the path-selection screen without a user making an explicit selection.
- **FR-003**: The app MUST persistently save the selected memorization path so that the path-selection screen is not shown on subsequent launches.
- **FR-004**: The app MUST display a guardian-linking step immediately after the Child / Beginner path is selected, before entering the child memorization flow.
- **FR-005**: The guardian-linking step MUST offer exactly two choices: "Link guardian now" and "Continue without guardian".
- **FR-006**: When "Link guardian now" is selected, the app MUST generate a unique, single-use pairing code valid for exactly 15 minutes and display it (with an optional QR code representation) for the guardian to scan on another device. The code MUST be invalidated immediately upon first successful use or upon expiry, whichever comes first.
- **FR-007**: When a guardian successfully scans or enters the pairing code, the app MUST mark the child account as linked to that guardian and close the pairing screen.
- **FR-008**: When "Continue without guardian" is selected, the app MUST save this decision and MUST NOT show the guardian-linking step again unless the user initiates it from Settings.
- **FR-009**: The Adult path MUST NOT trigger any guardian-linking step during memorization onboarding or in any memorization mode.
- **FR-010**: The app MUST provide a "Reset / Change path" option in Settings that clears the selected path, guardian-linking status, and pairing data, then restores the first-time path-selection flow. Smart Memorization settings (daily schedule, review days, custom plan, ayah isolation) MUST NOT be cleared by this action.
- **FR-017**: After a path reset, if the user re-selects the Child / Beginner path, the guardian-linking step MUST be shown as a fresh start. Any prior "Continue without guardian" decision MUST be treated as cleared by the reset and MUST NOT suppress the guardian-linking step.
- **FR-011**: Settings MUST include an optional "I am a parent/guardian" toggle available only to users on the Adult path.
- **FR-012**: When the parent/guardian toggle is enabled in Settings, the app MUST allow the adult user to scan or enter a child's pairing code to link to that child's progress.
- **FR-013**: The app MUST maintain a single shared source of truth for: selected memorization path, guardian-linking status, guardian role, and Smart Memorization settings.
- **FR-014**: Saving or changing Smart Memorization settings MUST NOT overwrite the user's selected path, child/adult status, guardian-linked status, or parent/guardian role.
- **FR-015**: All memorization modes (Normal, Smart, and any future mode) MUST read the user's memorization path identity and apply guardian behavior consistently.
- **FR-016**: If a child account already has an active guardian link, the app MUST block any attempt to generate a new pairing code and MUST display a message directing the user to unlink the current guardian in Settings before re-linking.
- **FR-018**: When a parent/guardian disables their guardian mode, the app MUST silently set the linked child's `guardianLinkStatus` to `none` and clear the `guardianId` field. The child MUST NOT be shown the guardian-linking step as a result of this action; they continue their memorization flow as an unlinked child.

### Key Entities

- **MemorizationProfile**: Represents the user's memorization identity. Key attributes: `selectedPath` (child/adult), `guardianLinkStatus` (none/pending/linked), `isParentGuardian` (boolean), `linkedChildId` (optional), `guardianId` (optional).
- **PairingSession**: A temporary session used to connect a child account with a guardian. Key attributes: `pairingCode`, `qrData`, `expiresAt` (15 minutes from generation), `status` (pending/completed/expired), `isUsed` (boolean, set true on first successful scan). A code transitions: pending → completed (on scan) or pending → expired (on timeout); once completed or expired it cannot be reused.
- **SmartMemorizationSettings**: User's smart memorization configuration. Key attributes: `dailySchedule`, `reviewDays`, `ayahIsolationEnabled`, `customPlan`. Must not contain path or guardian fields.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of new users opening Memorization for the first time are presented with the path-selection screen before accessing any memorization content.
- **SC-002**: 0% of adult users encounter a guardian-linking prompt during memorization onboarding or while using any memorization mode.
- **SC-003**: 100% of child users encounter the guardian-linking step immediately after path selection, with no way to bypass it without making an explicit choice.
- **SC-004**: Guardian-linking status and selected path survive app restarts and settings changes, with 0 regressions after modifying Smart Memorization configuration.
- **SC-005**: The pairing flow completes in under 2 minutes from code generation to confirmed link under normal network conditions.
- **SC-006**: Changing Smart Memorization settings results in 0 changes to the user's path, guardian status, or parent/guardian role in the saved state.
- **SC-007**: The "I am a parent/guardian" option is accessible in Settings and functional without affecting the adult user's own memorization experience.

---

## Assumptions

- The Talia Quran app currently has a local persistence layer (e.g., shared preferences or local storage) that can be extended to store the new memorization profile fields.
- The existing memorization architecture uses a state management pattern (e.g., BLoC/Cubit) that allows a single shared state to be read by all memorization modes.
- The pairing code mechanism requires the child's device to be online to generate a code and for the guardian's device to validate it; fully offline pairing is out of scope for this feature.
- The "Reset / Change path" action in Settings will clear guardian-linking status and require the user to go through the full onboarding again, treating it as a fresh start.
- Smart Memorization settings are stored separately from the MemorizationProfile to ensure future changes to either do not interfere with the other.
- This specification covers the memorization section only; authentication, Quran reading, and other app sections are out of scope.
- A parent/guardian user can link to only one child account per device in v1; multi-child support is deferred to a future release.
