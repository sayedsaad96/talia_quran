# Talia Quran — Share Good / Good Impact V1 Design Spec

**Date:** 2026-09-11  
**Status:** Product design approved; ready for implementation-plan review  
**Working feature names:** **شارك الخير** (Share Good) and **أثر الخير** (Good Impact)

## 1. Purpose

Create a privacy-respecting invitation and sharing system inside Talia Quran that lets a user invite another person to perform the same worship activity they are doing, either before starting or after completing it.

The feature should serve two goals at the same time:

1. Encourage companionship and spreading beneficial religious practice.
2. Create a natural product-growth loop where real use of Talia can introduce new users to the app.

The feature must never turn worship into competition, quantify religious reward, or create a social network around private acts of worship.

## 2. Product Principles

1. **Worship first, growth second.** Sharing must support the activity, not interrupt it.
2. **No reward claims.** Talia must not promise, calculate, or display quantities of religious reward.
3. **Privacy by default.** Aggregate impact may be shown, but identities are shown only with explicit user consent.
4. **No social pressure.** No leaderboards, public rankings, friend counts, streak competition, or social feed.
5. **Low friction.** A recipient can open and complete an invited activity as a guest without creating an account first.
6. **Context-aware sharing.** The invite always points to the exact activity or content that motivated the invitation.
7. **Smart prompts, not spam.** Sharing actions remain available, while proactive prompts are frequency-limited.

## 3. V1 Scope

### Included

- Quran activities:
  - Specific Quran page
  - Specific Surah
  - Defined Quran reading portion / wird when the existing product context supports it
- Adhkar activities:
  - Morning adhkar
  - Evening adhkar
  - Other existing adhkar collections that fit the same completion model
- Invite before starting an activity
- Invite after completing an activity
- Personal invitation mode
- Public sharing mode
- Native OS share sheet
- Dynamic share text and branded share card
- Deep link into the exact activity
- Deferred invite restoration after installation, where technically supported by the chosen mobile-link solution
- Guest recipient flow
- Smart expiration by activity type
- Completion tracking appropriate to the activity
- Optional identity disclosure on completion
- Good Chain propagation
- Good Impact dashboard / area
- Aggregate impact metrics
- Symbolic non-competitive milestones
- Limited invitation-related notifications
- Smart sharing prompts with frequency caps

### Explicitly excluded from V1

- Friends system / contact graph
- In-app user search
- Social feed
- Chat or direct messaging
- Live synchronized reading rooms
- Leaderboards or user ranking
- Profile photos
- Web reader
- Public Talia web application
- Worship points based on invites or invite completions

## 4. Full Vision vs V1

The long-term vision supports both:

1. **Asynchronous participation** — recipient reads when convenient.
2. **Live participation** — multiple people join the same activity in real time.

V1 implements **asynchronous participation only**.

## 5. Core User Loop

The main product loop is:

**Activity → Invite → Recipient opens → Starts → Completes → Chooses whether to reveal completion → Can create a new invite → Good Chain grows**

This loop must work without requiring a social graph.

## 6. Entry Points

### 6.1 Before activity

The CTA communicates companionship, for example:

- "تشاركني؟"
- "سأقرأ أذكار الصباح، تشاركني؟"
- "سأقرأ سورة الكهف، تشاركني؟"

### 6.2 After activity

The CTA communicates spreading good, for example:

- "شارك الخير"
- "ادعُ شخصًا ليقرأها أيضًا"

The exact localized copy may vary by activity, but the semantic difference between **companionship before** and **spreading good after** must remain.

## 7. Smart Sharing Prompts

The share action itself may remain discoverable inside eligible activity screens, but Talia must not show an intrusive share prompt after every activity.

Rules:

- First-time feature education is brief and shown once.
- Proactive prompts are frequency-capped.
- Repeated dismissals reduce future prompt frequency.
- Frequent users of the feature do not need repeated promotional prompts.
- No blocking modal is allowed before the user can continue worship.

## 8. Invite Mode Selection

Before opening the native share sheet, the user selects one of two modes:

### Personal invitation

Intended for sending to one person.

### Public share

Intended for groups, status posts, channels, or wider sharing.

Talia must not try to infer the final share destination from the operating system share sheet.

The selected mode is stored with the invite and influences privacy defaults and message copy.

## 9. Context-Aware Invite Target

The invitation always preserves the originating content context:

- Morning adhkar → Morning adhkar collection
- Evening adhkar → Evening adhkar collection
- Quran page → Same page
- Surah → Same Surah
- Defined wird → Same target range / amount

An invite must not degrade into a generic home-screen link when the original context is available.

## 10. Dynamic Share Package

Each invite produces a share package containing:

1. Context-aware invitation text.
2. A branded Talia share card.
3. The activity name or target.
4. A clear CTA.
5. The invite link/token.

The user may edit the share text before sending. The invite identity and target encoded in the invite must remain intact.

Examples of semantic copy:

### Before activity

"سيد يدعوك لقراءة سورة الكهف معه 🤍"

### After activity

"سيد أتم قراءة سورة الكهف اليوم، ويدعوك لتقرأها أنت أيضًا 🤍"

The final production copy must avoid claims such as "ضاعف ثوابك" or any numeric claim about reward.

## 11. Recipient Flow — App Already Installed

1. Recipient opens invite link.
2. Talia resolves the invite token.
3. A lightweight **Invite Preview** appears.
4. Preview shows:
   - inviter identity according to privacy settings
   - activity name
   - invite state / expiration if relevant
   - primary CTA: **ابدأ الآن**
5. Recipient enters the exact activity.
6. Recipient may complete the activity as a guest if not signed in.

No account creation or normal onboarding may be forced before the invited activity.

## 12. Recipient Flow — App Not Installed

Talia remains a **mobile-only product**. There is no user-facing web reader and no general Talia web application in this feature.

Target behavior:

1. Recipient opens invite link.
2. User is directed to the appropriate app store / installation flow.
3. After installation and first launch, Talia restores the pending invite where the selected mobile link solution supports it.
4. The user is taken to Invite Preview.
5. The user starts the exact activity without being forced to register first.

A minimal technical redirect service, association files, or third-party link infrastructure may exist solely to support mobile linking. It must not become a product-facing web experience.

If invite restoration is not possible on a specific platform/path, the implementation must provide the closest safe fallback without silently opening unrelated content.

## 13. Guest-First Rules

A guest recipient may:

- Open an invite
- View Invite Preview
- Start the invited activity
- Complete the activity
- Choose not to disclose identity

A guest must create/sign into an account before they can:

- Create a new invite as the next identified link in a Good Chain
- Persist Good Impact history across devices/account sessions
- Attribute a named completion to themselves
- Access account-level invitation history

Registration is positioned **after value is delivered**, not before worship.

## 14. Inviter Identity and Privacy

There is no profile-photo feature in V1.

Available identity modes:

- Full name
- First name
- Display name
- Anonymous

The UI may use a generated avatar based on the first letter of the visible name, or a neutral Talia avatar for anonymous invites.

Recommended default behavior:

- Personal invite: show the configured personal identity setting.
- Public invite: use a more privacy-preserving identity presentation by default.

No phone number, email address, or other account identifier is exposed through an invite.

## 15. Recipient Completion Privacy

After completing an invited activity, the recipient is given an explicit choice:

- **أخبره أنني أتممت**
- **احتفظ بإتمامي لنفسي**

If the user chooses private completion:

- The aggregate completion count may increase.
- Their name must not be disclosed to the inviter.

If the user chooses to tell the inviter:

- Their allowed display identity may be shown to the inviter.
- A personal completion notification may be sent if notification settings allow it.

No identity may be inferred from aggregate analytics.

## 16. Completion Model

Completion is context-aware.

### Adhkar

Completion is based on the existing adhkar progress/count model. The system records completion only when the collection reaches its defined completed state.

### Quran page

Reaching the end of the page allows the user to explicitly confirm **أتممت القراءة**.

### Surah

Reaching the end of the Surah allows explicit completion confirmation.

### Defined wird

The user reaches the configured end of the target range/amount, then confirms completion when confirmation is appropriate.

Talia records that the user **confirmed completion**; it does not claim to verify a person's actual internal act of reading.

If the recipient exits early, the participation state remains started/incomplete.

## 17. Invite Lifecycle and Smart Expiration

Expiration depends on activity semantics.

Examples:

- Morning adhkar: expires with the relevant morning/day window.
- Evening adhkar: expires with the relevant evening/day window.
- Quran page / Surah / reading target: longer validity, with a default product window such as several days.

Expired links must not become dead ends.

When an expired invite is opened:

1. Talia explains that the original invitation has expired.
2. The same activity can still be started as a fresh personal activity.
3. It is not counted as a completion of the expired invite.
4. The user may later create a new invitation if eligible.

Exact expiration durations are centralized in product configuration rather than hard-coded independently in multiple screens.

## 18. Good Chain — سلسلة الخير

When a recipient completes an activity, they may continue the loop by inviting another person.

Example:

**Sayed → Mohamed → Ahmed → Omar**

Each participant creates their own invite. Internally, Talia keeps lineage metadata so downstream impact can be attributed to the originating chain.

The system may show an originator aggregate wording such as:

"دعوتك امتد أثرها إلى 18 شخصًا."

The chain must not expose a tree of private user identities.

No leaderboard, longest-chain competition, or public chain ranking is allowed.

## 19. Good Impact — أثر الخير

Talia includes a lightweight dedicated area for invitation impact, not a social feed.

Possible V1 information:

- Active invites
- Recently expired invites
- Number of invite responses
- Number of completed activities
- Total downstream Good Chain reach
- Named completion acknowledgements only where recipients opted in
- Symbolic milestones

Example aggregate language:

- "8 أشخاص استجابوا لدعوتك"
- "5 أشخاص أتموا القراءة"
- "سلسلة الخير التي بدأت منك امتدت إلى 23 شخصًا"

These numbers measure product participation, not religious reward.

## 20. Symbolic Milestones

Good Impact milestones are separate from Talia's normal worship points/reward system.

Examples:

- First Good Chain started
- Impact reached 5 participants
- 10 people responded to invites

Rules:

- No points are granted because someone else worshipped.
- No leaderboard exists.
- No comparative message such as "better than X% of users" is allowed.
- Milestones celebrate spreading participation, not superiority or piety.

## 21. Notifications

Notifications are intentionally limited.

Potential notification events:

- In V1, Talia does **not** generate an in-app “invite received” push merely because an external share was sent. Delivery is handled by WhatsApp, Messenger, Telegram, SMS, or the selected share destination.
- After a recipient opens/resolves an invite, Talia may schedule at most one reminder before expiration if the user started or opened the activity without completing it, subject to notification permission and product frequency rules.
- Aggregate impact milestone reached.
- A recipient explicitly chose to tell the inviter that they completed the activity.

The inviter must not receive a push notification for every anonymous open/start/completion.

Users can disable invitation-related notifications.

## 22. Invite Participation States

At minimum, the conceptual state machine supports:

- created
- opened
- started
- completed_private
- completed_shared_identity
- expired
- continued_as_new_invite

Implementation may normalize event storage differently, but product behavior must preserve these distinctions.

## 23. Aggregate Metrics and Privacy Rules

Good Impact may count events such as:

- unique invite opens
- unique starts
- unique completions
- named completion acknowledgements
- downstream chain continuations

Counts should avoid obvious duplicate inflation from repeated opens by the same local participant when practical.

Analytics identifiers must not be shown as user identities.

Product analytics must distinguish:

- invite conversion
- activity engagement
- account conversion
- chain continuation

from religious reward or spiritual value.

## 24. Account Conversion Point

Talia does not block the invited worship activity with registration.

After completion, a guest may see a contextual CTA such as:

- "استمر في سلسلة الخير"
- "أنشئ حسابك واحفظ أثرك"

Account creation is required only when the user wants account-level capabilities such as creating an attributed chain invite or keeping persistent impact history.

The CTA must remain dismissible.

## 25. Error and Edge-Case Behavior

### Invalid invite token

Show a clear error and offer access to the relevant Talia section only if the target can be safely recovered. Never fabricate an inviter or activity.

### Expired invite

Explain expiration and allow a fresh start of the same activity without counting it toward the old invite.

### Deleted or unavailable content

Explain that the invited content is unavailable and offer a safe navigation path to the closest valid Quran/Adhkar section.

### Offline opening

If the invite target can be resolved from previously stored invite data, allow the activity to open offline when the underlying content is locally available. Otherwise show a retry state rather than dropping the user at Home.

### User changes account after opening invite

Participation remains tied to the invite session. Identity disclosure uses the account that explicitly confirms disclosure, not an inferred previous account.

### Repeated completion

One participant should not inflate the same invite's unique completion count through repeated confirmations on the same participation identity/session. Re-reading remains allowed but is not repeatedly counted as new unique invite completion.

## 26. UX Requirements

- Invite Preview should feel lightweight and devotional, not promotional.
- Primary action is always the worship activity, not account creation.
- Share UI should fit Talia's existing design language.
- No cluttered social controls inside Quran/Adhkar reading screens.
- Sharing entry points should not compete visually with reading controls.
- Arabic RTL and English LTR must both be supported.
- All invite and impact copy must be localization-ready.
- Accessibility labels are required for invite, privacy, completion, and share controls.

## 27. Architecture Boundaries — Product-Level

The feature should be designed as a reusable invitation subsystem rather than embedding separate share logic in each Quran/Adhkar screen.

Conceptual modules:

1. **Invite Context** — identifies target activity/content.
2. **Invite Creation** — creates personal/public invite metadata.
3. **Share Package Builder** — builds copy/card/link information.
4. **Invite Resolver** — resolves incoming/deferred invite tokens.
5. **Participation Tracker** — tracks open/start/completion state.
6. **Privacy Layer** — controls inviter identity and recipient disclosure.
7. **Good Chain Service** — tracks lineage and downstream reach.
8. **Good Impact Read Model** — exposes aggregate impact data to UI.
9. **Prompt Policy** — controls smart share prompts/frequency.
10. **Notification Policy** — controls invitation-related notifications.

Exact files, packages, backend collections, and state-management classes must be decided only after reviewing the existing Talia codebase and current backend architecture.

## 28. Success Metrics

The feature should be evaluated using product metrics such as:

- Share initiation rate
- Invite link open rate
- Open → start conversion
- Start → completion conversion
- Guest completion rate
- Guest → account conversion after completion
- Completion → new invite conversion
- Good Chain continuation depth
- Invite-driven new installs
- Share prompt dismissal rate
- Notification opt-out rate

No success metric should attempt to estimate religious reward.

## 29. V1 Acceptance Criteria

V1 is complete only when all of the following are true:

1. A user can invite before or after an eligible Quran/Adhkar activity.
2. User explicitly chooses personal or public share mode before the OS share sheet.
3. Invite preserves the exact activity context.
4. Share package contains contextual copy, Talia branding, and invite link.
5. Installed recipients reach Invite Preview and the correct activity.
6. A recipient without an account can complete the invited activity.
7. The app does not require account creation before reading.
8. Completion logic differs appropriately by activity type.
9. Recipient identity is never shared without explicit consent.
10. Anonymous/private completions may contribute only to aggregate counts.
11. Good Chain lineage can attribute downstream aggregate impact.
12. Good Impact displays aggregate responses/completions/reach without ranking users.
13. Symbolic milestones do not grant worship points.
14. Invite expiration follows centralized context-aware rules.
15. Expired invites provide a useful fresh-start path.
16. Smart sharing prompts respect frequency/dismissal rules.
17. Invitation notifications are limited and configurable.
18. No friends system, social feed, chat, leaderboard, profile photo, live room, or web reader is introduced.
19. Mobile installation flow restores pending invite context on every release platform where V1 advertises deferred-invite support, using a mechanism verified end-to-end on real devices. If a platform cannot reliably support that behavior, the limitation must be explicit and the fallback must never silently lose the invite into an unrelated Home screen.
20. Automated tests cover invite state, privacy, expiration, completion, and chain attribution; runtime QA covers real deep-link/share/install paths on supported mobile platforms.

## 30. Future Extensions — Not V1

Potential later work:

- Live "read with me now" sessions
- Real-time participant presence
- Additional worship/activity types
- More advanced chain visualizations that remain privacy-safe
- Internal invite inbox if Talia later introduces a user-to-user relationship model

These extensions must not be pre-built in V1 unless required by a proven implementation dependency.

## 31. Final Product Positioning

This feature is not a generic social-share button and not a social network.

It is a **worship invitation loop** built around:

**Companionship → Participation → Completion → Privacy-respecting impact → Passing the invitation forward.**

The desired user feeling is:

> "أنا لم أشارك بوستًا؛ أنا دعوت شخصًا لفعل خير، وتالية ساعدتني أرى أثر الدعوة بدون أن تحوّل العبادة إلى منافسة."
