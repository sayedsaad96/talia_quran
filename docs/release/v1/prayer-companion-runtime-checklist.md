# Prayer Companion V1 — runtime evidence checklist

**Scope:** manual platform verification for the opt-in Prayer Companion (self-confirmation, preparation reminder, 20-minute check-in, one follow-up, daily status in the prayer-times sheet).

**Rules for this document**

- Record only what was actually observed on a real device or emulator.
- Leave a row as `Not run` when the scenario was not executed. Never infer or copy a result from a similar scenario.
- A scenario counts as passed only with a device, OS version, build identifier, and the seen result.
- iOS background delivery is best-effort: the app reconciles stale events on next open. Do not mark iOS background scenarios as passed without observing them.

## 1. Build under test

| Field | Value |
|---|---|
| Build / commit | |
| Android device + OS | |
| iOS device + OS | |
| Tester + date | |

## 2. Automated contract coverage (already green in CI/local runs)

These are covered by automated tests and do not need manual repetition:

- confirmation idempotency and follow-up suppression;
- `prayNow` vs `confirmed` distinction;
- `remindLater` one-follow-up limit;
- ignored notification remains `unconfirmed` (never `notYet`);
- Companion disabled leaves prayer-time alerts intact;
- city/method/timezone refresh preserves explicit records;
- account reset clears local history;
- Arabic/English status labels and the confirmed count.

## 3. Manual scenarios

| # | Scenario | Android result | iOS result |
|---|---|---|---|
| 1 | Enable Companion in Settings, verify the section explains local-only storage and offers preparation, check-in, follow-up, and clear-confirmations controls | Not run | Not run |
| 2 | Preparation reminder appears at the configured offset (test 5/10/15) | Not run | Not run |
| 3 | Post-prayer check-in appears 20 minutes after the prayer | Not run | Not run |
| 4 | Check-in shows `I prayed` / `I will pray now` / `Remind me later` actions; `Not yet` is available in-app only | Not run | Not run |
| 5 | Action with the app **foregrounded**: state persists and the sheet reflects it | Not run | Not run |
| 6 | Action with the app **backgrounded**: opening Talia persists the action and routes to Home | Not run | Not run |
| 7 | Action with the app **terminated**: launch → persist → Home (launch first, persist second) | Not run | Not run |
| 8 | Repeated taps of the same action do not duplicate a record or a second follow-up | Not run | Not run |
| 9 | `I will pray now` schedules exactly one follow-up; `Remind me later` schedules exactly one follow-up 10 minutes later | Not run | Not run |
| 10 | Confirming after an intent cancels the pending check-in/follow-up | Not run | Not run |
| 11 | Notification body tap opens Home without changing any status | Not run | Not run |
| 12 | Rebooting the device keeps the two-day Companion window reconciled after the app opens | Not run | Not run |
| 13 | Changing city / calculation method / timezone rebuilds future Companion events and preserves recorded confirmations | Not run | Not run |
| 14 | Quiet hours: a Companion event falling inside the window is suppressed (not shifted) | Not run | Not run |
| 15 | Notification permission denied: the in-app sheet and actions remain fully usable | Not run | Not run |
| 16 | Disabling the Companion cancels its events and leaves prayer-time alerts working | Not run | Not run |
| 17 | `Clear prayer confirmations` asks for confirmation, then removes local history | Not run | Not run |
| 18 | Arabic RTL and English LTR: statuses are readable, not color-only, and readable with large text scaling and dark mode | Not run | Not run |

## 4. Known platform limitations (V1)

- A Companion action always launches Talia first; there is no hidden background write.
- iOS background delivery is best-effort; stale events are reconciled when the app opens.
- The headless refresh resolves the local owner id, so a signed-in user's events may be re-planned against local scope until the app next opens; records are never lost.
