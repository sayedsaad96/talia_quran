# Share Good signed Android runtime QA

Status: **UNVERIFIED — external release prerequisites outstanding.** Keep Share Good rollout off. Android only; iOS deferred links are not supported in V1. Record dates, tester, app version, build identifier and redacted evidence separately. Never record invite bearer tokens.

| Prerequisite | Status | Evidence |
|---|---|---|
| Approved HTTPS host and redirect hosting | UNVERIFIED | Domain not supplied |
| Upload-key SHA-256 fingerprint in served association file | UNVERIFIED | Fingerprint not supplied |
| Play App Signing SHA-256 fingerprint in served association file | UNVERIFIED | Fingerprint not supplied |
| Staging migration, API cache and RPC contracts | UNVERIFIED | Not supplied |
| Signed release distributed by Play test track | UNVERIFIED | Not supplied |

| Case | Device 1 | Device 2 (Android 12+) | Expected result |
|---|---|---|---|
| `pm get-app-links com.talia.quran` | UNVERIFIED | UNVERIFIED | The configured host is verified |
| Installed, cold launch from WhatsApp and Telegram | UNVERIFIED | UNVERIFIED | One preview for the invite |
| Installed, warm and background launch | UNVERIFIED | UNVERIFIED | Correct preview opens |
| Duplicate delivery / activity recreation | UNVERIFIED | UNVERIFIED | One preview and one open event |
| First-ever launch with invite | UNVERIFIED | UNVERIFIED | Preview opens before onboarding; onboarding remains pending |
| Not installed → real Play listing → install → first open | UNVERIFIED | UNVERIFIED | Deferred invite is restored and preview opens |
| Update, reinstall and consumed referrer | UNVERIFIED | UNVERIFIED | No stale or duplicate invite |
| Expired and invalid link | UNVERIFIED | UNVERIFIED | Safe notice; no participation |
| First open while offline, then reconnect | UNVERIFIED | UNVERIFIED | No false completion; retry works |
| Arabic and English | UNVERIFIED | UNVERIFIED | Correct readable localized flow |
| Reminder delivery and tap | UNVERIFIED | UNVERIFIED | Correct session; no token in notification or logs |
| Account switch and account deletion | UNVERIFIED | UNVERIFIED | No prior-account data or identity disclosure |
| Cancel share sheet | UNVERIFIED | UNVERIFIED | No share sent and app remains usable |
| Quran invitation before and after confirmed reading | UNVERIFIED | UNVERIFIED | Exact page/surah/wird is retained; invitation completion never creates a second reading record |
| Khatmah final-page confirmation and save retry | UNVERIFIED | UNVERIFIED | Invitation completion stays unavailable until the existing explicit confirmation has saved successfully |
| Morning/evening counters and already-completed collection | UNVERIFIED | UNVERIFIED | New completion counts once; an already-completed collection requires explicit confirmation; general/duas have no invitation action |
| Private completion, dismissal and process restart | UNVERIFIED | UNVERIFIED | No name is disclosed; an interrupted unresolved choice returns from the preview |
| Guest sign-in from consent, then switch account | UNVERIFIED | UNVERIFIED | Current account name is shown and another explicit tap is required before disclosure |
| Chain after private/shared completion and expired parent | UNVERIFIED | UNVERIFIED | Same target and after-activity copy; continuing never discloses a private completion; expired parent offers an explicit standalone invitation |
| Reminder toggle, quiet hours and denied permission | UNVERIFIED | UNVERIFIED | One pending reminder at most; disabling cancels it; quiet hours and the expiry margin are respected; no permission request is triggered by Share Good |
| Switch to child profile with a pending reminder | UNVERIFIED | UNVERIFIED | Pending reminder is cancelled and invitation controls stay hidden |

The command above is an observation, not a substitute for a Play-install test. Record both physical device models and Android versions in the release evidence. Do not mark this document passed without completing every required row on the frozen signed candidate.
