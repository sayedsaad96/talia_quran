# Talia Share Good / Good Impact V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a privacy-first worship invitation loop in which signed-in users create invitations and guests can resolve, open, start, and complete eligible Quran and Azkar activities without registration, with exact activity targeting, reusable branded sharing, aggregate Good Chain impact, and no social-network or religious-reward mechanics.

**Architecture:** Add one feature-first `lib/features/share_good/` subsystem using the repository's existing domain/data/presentation, Cubit, GetIt, GoRouter, Supabase RPC, SharedPreferences, and secure-storage conventions. Existing Quran, Azkar, and Khatmah logic remains authoritative; thin presentation callbacks report only already-committed completion boundaries into Share Good. Existing `SocialShareSheet`, `SocialShareData`, renderer, image capture, and native share dependencies are extended rather than duplicated.

**Tech Stack:** installed Flutter 3.47.1 / Dart 3.12.2, `flutter_bloc`, `get_it`, `go_router`, `dartz`, `equatable`, Supabase/Postgres with RLS, public `SECURITY INVOKER` RPC wrappers, non-exposed `private`-schema `SECURITY DEFINER` helpers, `shared_preferences`, `flutter_secure_storage`, `share_plus`, `screenshot`, `flutter_local_notifications`, and direct `app_links: ^7.2.1` for installed-app links only. The lock already resolves `app_links 7.2.1` through `supabase_flutter 2.16.0`, but the project still declares Dart `^3.11.4` while `app_links 7.2.1` requires Dart 3.12. Task 8 promotes the package to direct and raises the truthful project floor to Dart `^3.12.0` after a dependency/test gate.

**Spec:** Requested source: `docs/superpowers/specs/2026-09-11-talia-share-good-design.md`. Repository finding: that path does not exist; the approved tracked document is `docs/superpowers/plans/2026-09-11-talia-share-good-design.md` (introduced at `754088c`). This plan treats that content as the approved product source of truth and does not move or modify it.

**Reconciliation baseline (2026-09-28):** reviewed at Git `3f2b9ad` plus the current uncommitted working tree. Commit `7998eda` landed the design-system foundations and `3f2b9ad` added the approved, not-yet-implemented Dawn social-share redesign specification. The working tree currently contains unrelated localization, typography, auth, onboarding, splash, and tutorial edits; implementation must begin from that stabilized baseline and preserve them. Re-run the repository-delta checks if HEAD or those files change before execution.

## Review Focus

- Creation and Good Impact authorization, anonymous recipient privacy, and the account-deletion behavior of the full `A -> B -> C` chain.
- Cold/warm link arbitration across `TaliaApp`, `LaunchDestination`, `AppRouter`, password recovery, onboarding, and `PrayerCompanionController`.
- Exact reuse of current Quran/Azkar/Khatmah completion authority without duplicate progress or duplicate confirmation UI.
- Current notification settings/scheduler, quiet-hours, route guards, and iOS notification-budget behavior.
- Supabase migration order, grants/RLS, fixed empty `search_path`, deployment verifier coverage, and fail-closed old-backend compatibility.
- Current tracked theme primitives (`TaliaTokens`, `TaliaAppBar`, `PureBlackCubit`) and framework text scaling, while preserving the separate dirty typography/onboarding work.

## Global Constraints

- Talia remains a mobile-only application; do not add a Quran web reader or general Talia web application.
- Worship comes before growth. Invite UI must never block starting or continuing worship.
- Never calculate, estimate, promise, or imply quantities of religious reward.
- Privacy is default. No name is returned or displayed unless the inviter selected it or the recipient explicitly consented after completion.
- Do not add friends, contacts, search, feeds, chat, leaderboards, rankings, profile photos, live rooms, or public identity graphs.
- Guests can resolve, open, start, and complete an invited activity without registration.
- Authentication is required for creating every invite, continuing a Good Chain, named completion disclosure, and account-level Good Impact history. V1 has no anonymous invite-creation path.
- Existing Quran text, parser validation, `QuranPageCubit.confirmRead`, `QuranReadConfirmationGate`, `AzkarCubit`, `AzkarCompletionStore`, `KhatmahCubit.recordDigitalPage`, and Khatmah repository/use cases remain authoritative.
- Invite links, notification payloads, analytics, and the Share Good invitation template contain activity identifiers/labels only—never Quran ayah text or Azkar content. Existing approved social-share sacred-text templates remain unchanged.
- General Azkar and Duas are not eligible in V1 because their current library screens do not have the counted collection-completion contract used by morning/evening Azkar.
- Smart Wird is not eligible in V1 because its time-sensitive composed item set is not represented by the locked target schema; do not snapshot or reconstruct its religious content in this feature.
- Public-share destination is never inferred from the OS share sheet. The user chooses personal/public before it opens.
- Invite expiration is calculated once by the backend creation RPC and returned as `expiresAt`; screens must not hard-code their own durations.
- Product participation metrics are not worship points, piety measures, or religious-value metrics.
- No push provider is introduced in V1. The only notification added is one optional local incomplete-invite reminder on the recipient device.
- Account deletion removes identity/disclosure but must not erase aggregate invitation lineage or downstream participation.
- A new app against an undeployed/older Share Good backend fails closed with a localized unavailable state; it never attempts direct table access or fabricates local success.
- Automatic deferred restoration after App Store/Play Store installation is not advertised in this V1. Installed-app App/Universal Links are implemented; an uninstalled recipient gets a minimal install/reopen-link fallback.
- All new user-visible copy is generated from `app_ar.arb` and `app_en.arb`, supports RTL/LTR, framework text scaling without a new app-wide cap, screen readers, reduced motion, and 48dp touch targets.

---

## Repository Findings That Determine the Design

| Area | Actual repository evidence | Architectural consequence |
|---|---|---|
| Feature layout | Substantial features use `data/domain/presentation` under `lib/features`; cross-cutting code is under `lib/core`. | Create `lib/features/share_good/`; keep only link ingress in that feature's application layer and modify core startup/router narrowly. |
| State management | Cubits are injected through `lib/core/di/injection.dart`; app-wide Cubits use `BlocProvider.value`, page Cubits use factories. | Use factory `InviteCreateCubit`, `InviteParticipationCubit`, and `GoodImpactCubit`; no new state-management library. |
| Sharing | `lib/core/widgets/social_share/` owns `SocialShareData`, `SocialShareSheet.show`, capture/export, and `SharePlus`; its current name toggle defaults to visible. HEAD now also contains the approved Dawn redesign spec at `docs/superpowers/specs/2026-09-28-social-share-card-redesign-design.md`, which replaces themes with moods/palettes, adds a signature bar/QR, and deletes `social_share_theme.dart`, but that redesign is not implemented yet. | Do not extend the soon-to-be-deleted theme stack. Task 7 is gated on Dawn landing, then adds Share Good through the Dawn palette/signature/template extension points. Share Good bypasses the legacy/default name toggle and uses only the explicitly selected identity. |
| Guest model | Supabase anonymous Auth sign-in is disabled. Signed-out API calls use the Postgres `anon` role, and current database objects revoke its access by default. | Grant `anon` only resolve/open/start/private-complete/event RPC execution; never grant table DML and never create anonymous Auth users. Invite creation is authenticated-only. |
| Account safety | `RecordOwnerProvider`, `AccountDataBarrier`, `AccountDataReset`, and `CloudSyncQueue` prevent cross-account ownership errors. `CloudSyncQueue` explicitly refuses guest work. | Invite sessions stay installation/invite scoped in secure storage and never auto-bind on auth changes. Do not put guest invite mutations into account-owned `CloudSyncQueue`. |
| Quran page | `QuranPageCubit.confirmRead` commits ordinary page progress, streak, reading log, and activity event after `QuranReadConfirmationGate`. | Call Share Good only after `confirmRead` succeeds. Add a separate explicit invited-target confirmation at the target boundary; do not change ordinary completion semantics. |
| Surah | `/quran/surah/:surahId` resolves `SurahDetail`; pages and exact text come from bundled local Quran assets. | Serialize only `surah_id`; resolve start/end pages locally through `QuranRepository.getSurahDetail`. Never serialize Quran text in invite metadata. |
| Daily wird / Smart Wird | `GetDailyWirdUsecase` returns one Quran page; active Khatmah exposes `KhatmahPlan.dailyTargetFor()` with a page range. The new `SmartWirdPage` dynamically composes a separate time-sensitive Azkar session from approved records and owns its own progress/share flow. | Support the ordinary one-page daily wird and a generic Khatmah range only. Explicitly skip Smart Wird in V1; snapshotting its composed item set/provenance is a separate design. Recipient invite reading never mutates recipient Khatmah state. |
| Azkar | Only morning/evening use `AzkarCubit` + day-scoped `AzkarCompletionStore` and reach `AzkarLoaded.allDone`; load can begin already completed. General/Duas are libraries. | Observe a fresh `false -> true` transition at a stable page owner, ignore an initially restored `allDone == true`, and do not reproduce counts or change day rollover/serialized tap behavior. |
| Identity | `UserProfile` has local `name`; `AppUser` has Supabase `displayName` and `avatarUrl`; no sharing identity preferences exist. | Add Share Good identity preferences and an explicit resolver. Ignore avatar URLs. Treat fallback strings such as `مستخدم`/`مستخدم تالية` as absence, never as disclosed identity. |
| Achievements | `AchievementService` and `XpService` track worship/certificate systems. | Good Impact milestones are a separate pure read-model policy with no XP, certificates, points, or unlock calls. |
| Notifications | A mature local stack now spans `NotificationSettingsCubit`, `NotificationSettingsState`, `NotificationSettingTile`, `TaliaNotificationService`, `NotificationScheduler`, quiet hours, route guards, prayer-companion actions, timezone resolution, and notification-budget helpers. There is still no FCM/APNs server push. | Add at most one opt-in local incomplete-invite reminder through those extension points. Preserve quiet hours, prayer-companion semantics, route validity, permission handling, and platform notification budgets. |
| Analytics | No product analytics SDK or consent pipeline exists. Existing `ActivityEventRecorder` is a local Home activity feed, not product analytics. | Keep a separate allow-listed Share Good event ledger behind an RPC; never route it through `ActivityEventRecorder`, expose analytics identifiers, or claim OS share completion/install attribution. |
| Startup | `AppInitializer` initializes services; `TaliaApp._applyLaunchNavigation` consumes notification launches, prioritizes onboarding for first-time users, and delegates prayer-companion payloads. `LaunchDestination` and the top-level redirect on `AppRouter.router` apply additional routing rules. | Integrate pending invites across all three decision points. Preserve password recovery and prayer-companion handling, let a validated invite bypass onboarding, and prove cold/warm delivery occurs exactly once. |
| Links | Android/iOS only register `taliaquran://auth/update-password`; no App Links, Associated Domains, association files, or deferred-link SDK exists. Android is `com.talia.quran`, iOS is `com.example.taliaQuran`, and Android release uses debug signing. | Installed HTTPS links require new platform configuration and production identity/signing inputs. Pure App/Universal Links do not guarantee post-install restoration. |
| Backend | Supabase migrations are the database source of truth. Modern migrations such as the ayah-review ledger use RLS, direct-DML revocation, explicit grants, empty `search_path`, strict JSON/idempotency, SQL tests, and contract verification. `supabase/config.toml` exposes only `public` and `graphql_public`; no Supabase file changed since the original plan. | Generate a new current timestamp migration, not the stale `20260911120000` filename. Keep public RPC wrappers invoker-safe and move privileged helpers into non-exposed `private`; add no direct client DML, schema-qualify all helper references, and update verifier checks/query count. |
| Account deletion | `public.delete_current_user()` deletes the current `auth.users` row; local cleanup preserves usable progress as guest and clears owner-scoped metadata/preferences. Existing account-owned server rows commonly cascade. | Share Good lineage must be deliberately different: `creator_user_id ON DELETE SET NULL`, identity/disclosure rows disappear, and invite/participation descendants survive so `A -> B -> C` aggregate reach remains coherent. |
| UI system | HEAD provides `TaliaTokens`, `TaliaAppBar`, `PureBlackCubit`, and `context.tokens`; settings are organized through `SettingsHubBody` and subpages. | Reuse these current primitives and the notification subpage/Cubit. Do not duplicate colors, app bars, pure-black behavior, or add settings directly to the legacy page body. |

### Recent history that constrains the plan

- Quran reader work at `f018685` established the current reader components, while `a1fe94a`, `087e5f8`, and `69e61b2` hardened the reader/Khatmah completion boundary. The plan therefore adds callbacks around those boundaries and does not replace them.
- Azkar work at `98eebf5`, `e4ddf99`, `acc18d8`, and `768f011` recently changed recitation UX, auto-advance, and preferences. Share Good observes `AzkarLoaded.allDone` instead of duplicating these behaviors.
- Social sharing began at `3c894ec`; `2613dda` added specialized templates and `19c63b4` added Khatmah sharing. Those commits confirm that `lib/core/widgets/social_share/` is the extension point.
- Backend hardening at `7ef2b25` and `1f54308` established the current migration, event, privilege, and verification patterns. The Share Good migration follows those patterns instead of introducing a second backend access style.
- Changes after the original plan added Prayer Companion, notification quiet-hours/budget/route safety, Smart Wird, settings subpages, account-deletion cleanup, the Talia design-token work, and broad Quran/memorization tests. Tasks 8–16 below are reconciled to those extension points.
- `7998eda` made `TaliaTokens`, `TaliaAppBar`, and `PureBlackCubit` tracked production primitives. `3f2b9ad` then approved Dawn as the next social-share architecture; Share Good must sequence after it instead of editing `social_share_theme.dart` that Dawn removes.

### External freshness checks completed 2026-09-28

- [Supabase Database Functions](https://supabase.com/docs/guides/database/functions) and [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security) require explicit function grants, empty `search_path` for definer functions, schema-qualified references, and keeping privileged definer helpers out of exposed schemas. The public-wrapper/private-helper contract below follows that guidance.
- [Supabase Database Migrations](https://supabase.com/docs/guides/deployment/database-migrations) uses `supabase migration new`, timestamp ordering, and fresh reset/testing; this is why the old fixed migration timestamp is removed.
- [`app_links 7.2.1`](https://pub.dev/packages/app_links) remains current and recommends early instantiation for cold-start links; its [version table](https://pub.dev/packages/app_links/versions) declares Dart 3.12, so Task 8 aligns the project SDK floor instead of hiding the mismatch.

### Deliberately unchanged production files

- `lib/features/quran/domain/entities/quran_entities.dart`
- `lib/features/quran/data/datasources/quran_local_datasource.dart`
- `lib/features/quran/data/models/ayah_model.dart`
- `lib/features/quran/data/models/surah_model.dart`
- `lib/features/quran/presentation/cubits/quran_page_cubit.dart`
- `lib/features/quran/presentation/services/quran_read_confirmation_gate.dart`
- `lib/features/azkar/domain/entities/azkar_entities.dart`
- `lib/features/azkar/data/models/zikr_model.dart`
- `lib/features/azkar/data/datasources/azkar_completion_store.dart`
- `lib/features/azkar/presentation/cubits/azkar_cubit.dart`
- `lib/features/azkar/presentation/pages/smart_wird_page.dart`
- `lib/features/azkar/domain/usecases/compose_smart_wird_usecase.dart`
- `lib/features/azkar/data/datasources/smart_wird_progress_store.dart`
- `lib/features/khatmah/domain/entities/khatmah_plan.dart`
- `lib/features/khatmah/domain/usecases/record_khatmah_reading_usecase.dart`
- `lib/features/khatmah/presentation/cubits/khatmah_cubit.dart`
- `lib/core/services/achievement_service.dart`
- `lib/core/services/xp_service.dart`
- `lib/core/sync/cloud_sync_queue.dart`
- `lib/features/auth/domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `web/` in its entirety

## Locked V1 Domain Contracts

### Activity target serialization

`InviteActivityTarget.fromJson` accepts only these versioned shapes and rejects extra/missing keys, invalid ranges, unsupported Azkar categories, and non-integer numbers:

```json
{"v":1,"type":"quran_page","page":42}
{"v":1,"type":"quran_surah","surah_id":18}
{"v":1,"type":"quran_wird","start_page":120,"end_page":124}
{"v":1,"type":"azkar_collection","category":"morning"}
```

- Quran page: `1..604`.
- Surah: `1..114`.
- Wird: `1 <= start_page <= end_page <= 604`.
- Azkar: `morning` or `evening` only.
- Quran/Azkar text, user IDs, names, emails, phone numbers, local Khatmah IDs, and completion data are never included in target JSON.

`InviteContext` is the creation request and contains exactly:

```dart
class InviteContext extends Equatable {
  const InviteContext({
    required this.target,
    required this.moment,
    required this.mode,
    required this.identity,
    this.parentParticipationId,
  });
  final InviteActivityTarget target;
  final InviteMoment moment; // beforeActivity | afterActivity
  final InviteMode mode; // personal | public
  final InviterIdentity identity;
  final String? parentParticipationId;
}
```

The remaining public domain signatures are fixed before implementation so later tasks cannot invent incompatible variants:

```dart
final class QuranPageInviteTarget extends InviteActivityTarget {
  const QuranPageInviteTarget(this.pageNumber);
  final int pageNumber;
}

final class QuranSurahInviteTarget extends InviteActivityTarget {
  const QuranSurahInviteTarget(this.surahId);
  final int surahId;
}

final class QuranWirdInviteTarget extends InviteActivityTarget {
  const QuranWirdInviteTarget(this.startPage, this.endPage);
  final int startPage;
  final int endPage;
}

final class AzkarCollectionInviteTarget extends InviteActivityTarget {
  const AzkarCollectionInviteTarget(this.category);
  final AzkarCategory category; // morning | evening only
}

enum InviteMode { personal, public }
enum InviteMoment { beforeActivity, afterActivity }
enum InviteIdentityMode { fullName, firstName, displayName, anonymous }
enum CompletionDisclosure { keepPrivate, shareIdentity }

final class CreatedInvite {
  const CreatedInvite({
    required this.id,
    required this.token,
    required this.shareUrl,
    required this.context,
    required this.createdAt,
    required this.expiresAt,
    required this.rootInviteId,
  });
  final String id;
  final String token;
  final Uri shareUrl;
  final InviteContext context;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String rootInviteId;
}

final class ResolvedInvite {
  const ResolvedInvite({
    required this.inviteId,
    required this.target,
    required this.moment,
    required this.mode,
    required this.identity,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });
  final String inviteId;
  final InviteActivityTarget target;
  final InviteMoment moment;
  final InviteMode mode;
  final InviterIdentity identity;
  final InviteLifecycleStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
}

final class InviteParticipation {
  const InviteParticipation({
    required this.id,
    required this.inviteId,
    required this.status,
    required this.openedAsGuest,
    required this.openedAt,
    this.startedAt,
    this.completedAt,
  });
  final String id;
  final String inviteId;
  final InviteParticipationStatus status;
  final bool openedAsGuest;
  final DateTime openedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

final class GoodImpact {
  const GoodImpact({
    required this.invites,
    required this.uniqueResponses,
    required this.uniqueCompletions,
    required this.downstreamReach,
    required this.acknowledgements,
  });
  final List<InviteImpactSummary> invites;
  final int uniqueResponses;
  final int uniqueCompletions;
  final int downstreamReach;
  final List<NamedAcknowledgement> acknowledgements;
}

final class ShareGoodAnalyticsEvent {
  const ShareGoodAnalyticsEvent({
    required this.kind,
    required this.occurredAt,
    this.inviteId,
    this.participationId,
  });
  final ShareGoodAnalyticsEventKind kind;
  final DateTime occurredAt;
  final String? inviteId;
  final String? participationId;
}
```

`InviterIdentity`, `InviteLifecycleStatus`, `InviteParticipationStatus`, `InviteImpactSummary`, `NamedAcknowledgement`, `GoodImpactMilestone`, and `ShareGoodAnalyticsEventKind` are immutable `Equatable` value types/enums defined in the Task 1 files below. No public domain type contains a Supabase client, auth object, raw participant key, avatar URL, or localized display text.

For an authenticated creator, personal defaults to the saved personal identity preference when a real name is available; otherwise anonymous. Public always defaults to anonymous and requires an explicit tap to reveal a name. A signed-out user who chooses Share Good is offered sign-in with a safe return path; worship and existing non-invite social sharing remain available. The stored inviter identity is an immutable, separately deletable snapshot.

### Invite and participation state machine

Server invite lifecycle is `active` or derived `expired/revoked`; participation status is monotonic:

```text
created invite
  -> opened
  -> started
  -> completed_private OR completed_shared_identity
  -> continued_as_new_invite
```

The client adds `completionAwaitingConsent` as a local presentation phase between activity completion and either server completion choice. Dismissing/interruption preserves that phase; it does not infer consent. Invalid transitions are idempotent no-ops when repeated and errors when they attempt a backward or conflicting transition.

- `resolve` never creates participation.
- `open` upserts by `(invite_id, participant_key_hash)`.
- `start` is allowed from opened and is idempotent from started/completed.
- `complete_private` is available to guests and authenticated users.
- `complete_shared_identity` requires `auth.uid()` and creates a separate disclosure row.
- The only allowed post-completion disclosure transition is `completedPrivate -> completedSharedIdentity`, through a new explicit authenticated disclosure action. It updates/adds the separate disclosure row and leaves the aggregate completion count at one; auth changes alone never trigger it.
- Reopening or rereading is allowed but the unique completion count remains one.
- Completion after `expires_at` is rejected and the UI offers an uncounted fresh personal activity.
- Chain continuation requires an authenticated completed participation and creates a child invite transactionally. A signed-in recipient may continue after a private completion without disclosing their completion identity to the inviter.
- Auth stream changes never mutate participant ownership. The account active at explicit disclosure/continuation is validated by the RPC.

### Central expiration rules

`private.share_good_expires_at_v1(target JSONB, created_at TIMESTAMPTZ, timezone TEXT)` is the sole creation authority and is not a Data API RPC:

- Morning Azkar: the first 15:30 local boundary strictly after creation (same day when created before 15:30, otherwise next day), matching `AzkarTimeContext`'s morning-end boundary.
- Evening Azkar: the first 04:00 local boundary strictly after creation (same day when created before 04:00, otherwise next day), matching `AzkarTimeContext`'s evening-end boundary.
- Ordinary daily wird and Khatmah daily range: next local midnight.
- Quran page and Surah: exactly 7 days after creation.
- Invalid/IANA-unknown timezone: reject invite creation; do not silently calculate in server UTC.

Clients display the returned `expiresAt` and compare against an injected clock for UI only. Server RPCs re-check database time on every transition.

### Backend data and privacy boundary

Run `supabase migration new share_good_v1` during Task 3 and use the generated current filename `supabase/migrations/<generated_timestamp>_share_good_v1.sql`. Never backdate the migration to `20260911120000`. It adds:

- `share_good_invites`: authenticated creator at insert, stored as nullable `creator_user_id REFERENCES auth.users(id) ON DELETE SET NULL`, token hash, mode/moment/identity mode, validated target JSON, stable parent/root lineage IDs, creation/expiry/revocation timestamps. Revocation is a timestamp transition, not row deletion.
- `share_good_invite_identities`: optional one-to-one creator identity snapshot linked to both invite and creator account; it is absent for anonymous identity mode and cascades away on account deletion while the invite remains.
- `share_good_participations`: invite, participant-key hash, `opened_as_guest`, and monotonic status/timestamps. It stores no automatically inferred participant account identity. Unique `(invite_id, participant_key_hash)`.
- `share_good_completion_disclosures`: one-to-one participation disclosure with authenticated `user_id` and visible-name snapshot; `ON DELETE CASCADE` removes the name if the account is deleted while participation remains aggregate.
- `share_good_analytics_events`: allow-listed event kind, server-resolved invite/participation references when applicable, installation-key hash, and timestamp. It contains no visible names, raw invite/participant IDs supplied for attribution, target content text, email, phone, or religious-value field.
- `share_good_rate_limits`: hashed scope, action, fixed window, attempt count, and expiry for transactional RPC throttling. It stores no raw token/key and is pruned opportunistically.

All tables enable RLS and revoke all direct access from `PUBLIC`, `anon`, and `authenticated`. Public RPC wrappers are `SECURITY INVOKER SET search_path = ''`; privileged operations live in narrowly scoped `private.*` `SECURITY DEFINER SET search_path = ''` helpers, and `private` is not added to `supabase/config.toml` exposed schemas. Only the public wrappers receive Data API execution grants:

```sql
create_share_good_invite_v1(jsonb, text, text, text, text, text) -> jsonb             -- authenticated only
resolve_share_good_invite_v1(text, text) -> jsonb                                  -- anon, authenticated
open_share_good_invite_v1(text, text, boolean) -> jsonb                             -- anon, authenticated
start_share_good_participation_v1(text, text) -> jsonb                              -- anon, authenticated
complete_share_good_participation_v1(text, text) -> jsonb                           -- anon, authenticated; always private first
disclose_share_good_completion_v1(text, text, text, text) -> jsonb                   -- authenticated only
create_share_good_chain_invite_v1(text, text, jsonb, text, text, text, text, text) -> jsonb -- authenticated
get_share_good_impact_v1() -> jsonb                                                 -- authenticated
record_share_good_client_event_v1(text, text, text, text) -> void                     -- anon, authenticated
```

The standalone creation arguments are target, moment, mode, identity mode, visible-name snapshot, and IANA timezone. It rejects a null `auth.uid()` and any attempt to smuggle lineage into target JSON; parent/root lineage is accepted only through the separate chain RPC. Standalone and chain creation share a rolling maximum of 30 creations per authenticated account per 24 hours. Resolve receives raw token plus installation key; open/start/complete receive the raw token and installation-scoped participant key. The private helpers hash secrets before lookup/storage and enforce these transactional caps: resolve 60/hour and 200/day per installation; open 30/hour per invite/participant; start and complete 20/day per invite/participant; client events 200/day per installation. These are defense in depth against accidental/low-effort abuse, not trusted attribution. Disclosure requires an already completed participation and current `auth.uid()`. Chain creation verifies the completed parent before deriving stable parent/root IDs. Analytics accepts an allow-listed event plus raw token/participant key where attribution is needed, resolves references server-side, and uses a server timestamp; the client cannot submit arbitrary invite/participation UUID attribution.

All public RPC wrappers and private helpers explicitly revoke `PUBLIC` execution; wrappers grant only the roles shown, while exact `private` schema usage/helper execution is limited to the roles needed by those wrappers. No app role receives table DML and no private helper is exposed through PostgREST. Old app clients remain unaffected because the migration is additive; a new app talking to a backend without these RPCs must map missing-function/schema-cache errors to `featureUnavailable` and hide/disable create/mutate actions rather than falling back to direct DML.

Rollout order is backend first: apply the generated migration through the normal Supabase migration pipeline in staging, run SQL/static/deployed contract verification, then deploy the app with fail-closed unavailable handling. Deploy production migration and verify grants before enabling/advertising external invitations. Existing app versions continue unchanged because no existing table or RPC contract is removed.

Raw invite and participant keys are never stored; PostgreSQL stores lowercase SHA-256 hex. Invite tokens are 32 random bytes encoded base64url without padding and returned once. Resolver responses expose only target, activity-safe labels/metadata, invite mode/moment, permitted inviter identity, status, and expiry. Good Impact returns named acknowledgements only for direct invites created by `auth.uid()`; downstream lineage is aggregate-only.

### Good Impact read model

`GoodImpact` contains active invites, recently expired invites (last 30 days), unique opens, starts, private/shared completions, direct named acknowledgements, direct responses, downstream aggregate reach, and derived symbolic milestones. It never returns participant hashes, analytics installation hashes, undisclosed identities, emails, auth IDs, lineage depth, or a chain tree. Any internal chain-depth success metric stays in restricted analytics/backend operations and is not returned to or ranked in the product UI.

Milestones are pure labels (`firstChain`, `fiveResponses`, `tenResponses`, `twentyFiveReach`) derived by `GoodImpactMilestonePolicy`. They do not call `AchievementService`, `XpService`, certificate services, or worship progress services.

### Link guarantees

- Guaranteed by code/unit tests: strict URI parsing, pending-link persistence, correct internal route, no Home fallback, invalid/expired UI, and startup priority.
- Requires hosted/domain evidence: `taliaapp.com` HTTPS routing, Android `assetlinks.json`, iOS AASA, store URLs, production application IDs, signing certificate fingerprints, and Apple Team ID.
- Requires real-device verification: cold/warm/background App Links on signed Android builds; Universal Links on signed iOS builds; external share applications; install-page fallback; locale/direction; notification permissions.
- Not guaranteed or advertised: automatic token recovery after installing from Play Store/App Store. `app_links` handles installed App/Universal Links, not deferred attribution. The fallback page tells the recipient to install and reopen the same invitation link. Adding Branch/AppsFlyer/another deferred provider is a separate product/privacy decision and plan.

The current repository still uses `com.talia.quran`, `com.example.taliaQuran`, and Android debug signing. Platform-link release work must stop until approved production identifiers, Android SHA-256 signing fingerprints, Apple Team ID, production store URLs, and domain deployment ownership are available; examples must not be shipped.

## Error and Interruption Matrix

| Case | Required behavior |
|---|---|
| Invalid/malformed token | Show localized invalid invite; do not fabricate target or inviter. Offer Quran/Azkar hubs only as generic choices. |
| Expired token | Show expiry plus exact recovered activity label; “start fresh” opens the local activity without participation callbacks. |
| Deleted/unavailable target | `InviteActivityResolver` validates bundled repository content. Show unavailable state and nearest safe section; no completion mutation. |
| First offline open | If no cached resolved snapshot exists, show retry and keep pending token. Never route Home. |
| Repeated offline open | Use cached safe snapshot and local content; queue monotonic open/start/completion mutation under the same participant key. |
| Mutation retry | Replay in order, stop at first network failure, treat server idempotent response as success, retain expired/rejected mutation for visible recovery. |
| Repeated completion | Re-reading allowed; server unique participation and monotonic status keep one unique completion. |
| Account switch | Participation key/session stays fixed. Named disclosure shows current account identity and requires a fresh explicit confirmation. |
| Sign-in cancelled | Return to pending consent/continuation, preserve private option, and never block worship. |
| Interrupted activity | Persist started state and target. Resume exact activity; if expired meanwhile, offer uncounted fresh activity. |
| App process death during consent | Restore `completionAwaitingConsent`; no identity or aggregate completion is inferred until a choice. |
| Invite expires mid-session | Existing personal progress remains; invite completion is rejected and not counted. |
| Share-sheet cancel | Invite remains active in Good Impact; analytics records sheet opened, not “shared/sent.” |
| Account deletion | The account's inviter-identity and completion-disclosure rows disappear. Its authored invite rows are anonymized with `creator_user_id = NULL`; participations and descendants remain. SQL tests must prove `A -> B -> C`: deleting B hides B, preserves B's invite and C's branch, keeps A's downstream aggregate, and reveals nothing to an unrelated user. |

## File Map

### New application files

```text
lib/features/share_good/
  application/incoming_invite_link_service.dart
  application/share_good_notification_intent.dart
  data/datasources/share_good_local_datasource.dart
  data/datasources/share_good_remote_datasource.dart
  data/models/share_good_models.dart
  data/repositories/share_good_repository_impl.dart
  domain/entities/good_impact.dart
  domain/entities/invite_activity_target.dart
  domain/entities/share_good_analytics_event.dart
  domain/entities/invite_context.dart
  domain/entities/invite_identity.dart
  domain/entities/invite_participation.dart
  domain/repositories/share_good_repository.dart
  domain/services/good_impact_milestone_policy.dart
  domain/services/invite_activity_resolver.dart
  domain/services/share_prompt_policy.dart
  domain/usecases/share_good_usecases.dart
  presentation/cubits/good_impact_cubit.dart
  presentation/cubits/invite_create_cubit.dart
  presentation/cubits/invite_participation_cubit.dart
  presentation/pages/good_impact_page.dart
  presentation/pages/invite_activity_page.dart
  presentation/pages/invite_preview_page.dart
  presentation/widgets/invite_completion_consent_sheet.dart
  presentation/widgets/invite_mode_sheet.dart
  presentation/widgets/share_good_action.dart
  presentation/widgets/share_good_identity_settings_tile.dart
  presentation/widgets/share_good_notification_setting_tile.dart
lib/core/widgets/social_share/social_share_payload.dart
lib/core/widgets/social_share/templates/share_good_template.dart
lib/core/services/device_timezone_resolver.dart
supabase/migrations/<generated_timestamp>_share_good_v1.sql
supabase/tests/share_good_v1_test.sql
supabase/functions/share-good-link/index.ts
test/features/share_good/application/incoming_invite_link_service_test.dart
test/features/share_good/application/share_good_notification_intent_test.dart
test/features/share_good/data/share_good_local_datasource_test.dart
test/features/share_good/data/share_good_models_test.dart
test/features/share_good/data/share_good_remote_datasource_test.dart
test/features/share_good/data/share_good_repository_impl_test.dart
test/features/share_good/domain/good_impact_milestone_policy_test.dart
test/features/share_good/domain/invite_activity_resolver_test.dart
test/features/share_good/domain/invite_activity_target_test.dart
test/features/share_good/domain/invite_participation_test.dart
test/features/share_good/domain/share_good_usecases_test.dart
test/features/share_good/domain/share_prompt_policy_test.dart
test/features/share_good/presentation/azkar_invite_completion_test.dart
test/features/share_good/presentation/quran_invite_completion_test.dart
test/features/share_good/presentation/wird_invite_completion_test.dart
test/features/share_good/presentation/cubits/good_impact_cubit_test.dart
test/features/share_good/presentation/cubits/invite_create_cubit_test.dart
test/features/share_good/presentation/cubits/invite_participation_cubit_test.dart
test/features/share_good/presentation/pages/good_impact_page_test.dart
test/features/share_good/presentation/pages/invite_preview_page_test.dart
test/features/share_good/presentation/widgets/invite_completion_consent_sheet_test.dart
test/features/share_good/presentation/widgets/invite_mode_sheet_test.dart
test/features/share_good/presentation/widgets/share_good_action_test.dart
test/features/share_good/presentation/widgets/share_good_identity_settings_tile_test.dart
test/features/share_good/platform_link_contract_test.dart
test/features/share_good/share_good_analytics_test.dart
test/features/share_good/share_good_localization_test.dart
test/core/di/share_good_injection_test.dart
test/app_launch_navigation_test.dart
test/core/services/device_timezone_resolver_test.dart
test/core/services/notification_scheduler_share_good_test.dart
test/supabase/share_good_contract_test.dart
test/integration/share_good_guest_flow_test.dart
test/integration/share_good_account_switch_test.dart
test/integration/share_good_worship_regression_test.dart
qa/share_good_runtime_qa.md
scripts/run_share_good_android_link_qa.ps1
ios/Runner/Runner.entitlements
```

### Existing files modified

```text
pubspec.yaml
pubspec.lock
lib/main.dart
lib/app.dart
lib/core/di/injection.dart
lib/core/router/app_router.dart
lib/core/router/launch_destination.dart
lib/core/l10n/app_ar.arb
lib/core/l10n/app_en.arb
lib/core/l10n/app_localizations.dart
lib/core/l10n/app_localizations_ar.dart
lib/core/l10n/app_localizations_en.dart
lib/core/l10n/cubit_message_codes.dart
lib/core/l10n/localization_helpers.dart
lib/core/services/notification_service.dart
lib/core/services/notification_scheduler.dart
lib/core/widgets/social_share/social_share_model.dart
lib/core/widgets/social_share/social_share_copy.dart
lib/core/widgets/social_share/social_share_presentation.dart
lib/core/widgets/social_share/social_share_sheet.dart
lib/core/widgets/social_share/social_share_card.dart
lib/core/widgets/social_share/talia_share_tokens.dart
lib/core/widgets/social_share/share_card_shell.dart
lib/core/widgets/social_share/share_card_template_resolver.dart
lib/features/auth/presentation/pages/login_page.dart
lib/features/quran/presentation/pages/quran_reader_page.dart
lib/features/quran/presentation/widgets/reader_overflow_sheet.dart
lib/features/azkar/presentation/pages/azkar_category_page.dart
lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart
lib/features/home/presentation/widgets/daily_wird_card.dart
lib/features/settings/presentation/widgets/settings_hub_body.dart
lib/features/settings/presentation/pages/subpages/notification_settings_page.dart
lib/features/settings/presentation/cubits/notification_settings_cubit.dart
lib/features/settings/presentation/cubits/notification_settings_state.dart
lib/features/settings/presentation/widgets/settings_notification_tiles.dart
android/app/src/main/AndroidManifest.xml
android/app/build.gradle.kts
ios/Runner/Info.plist
ios/Runner.xcodeproj/project.pbxproj
scripts/verify_supabase_contract.ps1
test/scripts/verify_supabase_contract_security_test.ps1
test/core/router/app_router_route_policy_test.dart
test/core/router/launch_destination_test.dart
test/core/router/notification_payload_route_guard_test.dart
test/core/widgets/social_share_test.dart
test/core/widgets/social_share_export_test.dart
test/features/quran/presentation/pages/quran_reader_page_mode_test.dart
test/features/azkar/presentation/azkar_category_page_test.dart
test/features/khatmah/presentation/pages/khatmah_dashboard_page_test.dart
test/features/settings/settings_page_test.dart
test/features/settings/presentation/cubits/notification_settings_cubit_test.dart
test/features/settings/presentation/widgets/settings_notification_tiles_test.dart
```

### Dawn prerequisite files consumed by Task 7 after that redesign lands

These paths are specified by the approved Dawn design but do not exist at the reconciliation baseline. They are not Share Good-owned scaffolding and must come from the Dawn implementation first:

```text
lib/core/widgets/social_share/share_card_palette.dart
lib/core/widgets/social_share/share_card_links.dart
lib/core/widgets/social_share/share_signature_bar.dart
test/core/widgets/share_card_palette_test.dart
test/core/widgets/share_card_links_test.dart
```

---

## Phase 1 — Domain, Persistence, and Backend Contracts

### Task 1: Define versioned invite, identity, participation, and impact domain types

**Files:**
- Create: `lib/features/share_good/domain/entities/invite_activity_target.dart`
- Create: `lib/features/share_good/domain/entities/invite_context.dart`
- Create: `lib/features/share_good/domain/entities/invite_identity.dart`
- Create: `lib/features/share_good/domain/entities/invite_participation.dart`
- Create: `lib/features/share_good/domain/entities/good_impact.dart`
- Create: `lib/features/share_good/domain/entities/share_good_analytics_event.dart`
- Create: `lib/features/share_good/domain/services/good_impact_milestone_policy.dart`
- Create: `test/features/share_good/domain/invite_activity_target_test.dart`
- Create: `test/features/share_good/domain/invite_participation_test.dart`
- Create: `test/features/share_good/domain/good_impact_milestone_policy_test.dart`

**Interfaces:**
- Consumes: existing `Equatable`, `AzkarCategory`, Quran numeric ranges, no persistence/UI.
- Produces: `InviteActivityTarget`, `QuranPageInviteTarget`, `QuranSurahInviteTarget`, `QuranWirdInviteTarget`, `AzkarCollectionInviteTarget`, `InviteContext`, `InviteMode`, `InviteMoment`, `InviteIdentityMode`, `InviterIdentity`, `InviteLifecycleStatus`, `InviteParticipationStatus`, `CompletionDisclosure`, `InviteParticipation`, `ResolvedInvite`, `CreatedInvite`, `InviteImpactSummary`, `NamedAcknowledgement`, `GoodImpact`, `GoodImpactMilestone`, `ShareGoodAnalyticsEventKind`, and `ShareGoodAnalyticsEvent`.

- [ ] **Step 1: Write failing serialization and validation tests**

```dart
expect(InviteActivityTarget.fromJson({'v': 1, 'type': 'quran_page', 'page': 42}), const QuranPageInviteTarget(42));
expect(() => const QuranWirdInviteTarget(10, 9), throwsArgumentError);
expect(() => InviteActivityTarget.fromJson({'v': 1, 'type': 'azkar_collection', 'category': 'general'}), throwsFormatException);
expect(InviteParticipationStatus.completedPrivate.canTransitionTo(InviteParticipationStatus.started), isFalse);
expect(GoodImpactMilestone.values.map((value) => value.name), isNot(contains('worshipPoints')));
```

- [ ] **Step 2: Run the tests and confirm they fail because the types do not exist**

Run: `flutter test test/features/share_good/domain`

Expected: compilation failure naming the missing Share Good domain types.

- [ ] **Step 3: Implement immutable types and strict `toJson`/`fromJson`**

Use the locked JSON shapes above. `InviterIdentity.visibleName` must be null for anonymous mode and 1–80 trimmed Unicode characters otherwise. Define monotonic transition helpers and aggregate-only milestone thresholds exactly as specified.

- [ ] **Step 4: Verify the domain suite**

Run: `flutter test test/features/share_good/domain`

Expected: all domain tests pass; invalid targets and reverse/conflicting transitions are rejected.

- [ ] **Step 5: Commit the domain contract**

```powershell
git add lib/features/share_good/domain test/features/share_good/domain
git commit -m "feat(share-good): define invitation domain contracts"
```

### Task 2: Add secure invite-session storage, offline snapshots, mutation outbox, identity preferences, and prompt state

**Files:**
- Create: `lib/features/share_good/data/datasources/share_good_local_datasource.dart`
- Create: `lib/features/share_good/data/models/share_good_models.dart`
- Create: `test/features/share_good/data/share_good_local_datasource_test.dart`
- Create: `test/features/share_good/data/share_good_models_test.dart`

**Interfaces:**
- Consumes: Task 1 domain JSON; existing `SharedPreferences`; existing `flutter_secure_storage` dependency.
- Produces: `ShareGoodLocalDataSource`, `SecureShareGoodLocalDataSource`, `InviteLocalSession`, `ResolvedInviteSnapshot`, `PendingInviteMutation`, `ShareIdentityPreferences`, `SharePromptRecord`.

```dart
abstract interface class ShareGoodLocalDataSource {
  Future<String> installationKey();
  Future<String> participantKeyFor(String inviteId);
  Future<void> savePendingToken(String token);
  Future<String?> readPendingToken();
  Future<bool> acknowledgePendingToken(String expectedToken);
  Future<void> saveResolvedSnapshot(ResolvedInviteSnapshot snapshot);
  Future<ResolvedInviteSnapshot?> readResolvedSnapshot(String token);
  Future<void> saveSession(InviteLocalSession session);
  Future<InviteLocalSession?> readSession(String inviteId);
  Future<void> enqueue(PendingInviteMutation mutation);
  Future<List<PendingInviteMutation>> pendingMutations(String inviteId);
  Future<void> removeMutation(String mutationId);
  ShareIdentityPreferences readIdentityPreferences();
  Future<void> writeIdentityPreferences(ShareIdentityPreferences value);
  SharePromptRecord readPromptRecord();
  Future<void> writePromptRecord(SharePromptRecord value);
}
```

- [ ] **Step 1: Write failing tests for stable keys, non-destructive pending-token semantics, encrypted session JSON, ordered outbox replay, and preference defaults**

Tests must prove participant keys are stable per invite, different between invites, and not written to SharedPreferences. A pending token must survive restart and repeated reads; `acknowledgePendingToken(expectedToken)` removes only the exact current token after successful route handoff, while a stale/mismatched acknowledgement leaves a newer token intact. Snapshots reject unsupported target versions, outbox preserves `opened -> started -> completion`, public identity defaults anonymous, and prompt state survives reload.

- [ ] **Step 2: Run the local data tests and observe missing implementations**

Run: `flutter test test/features/share_good/data/share_good_local_datasource_test.dart test/features/share_good/data/share_good_models_test.dart`

Expected: compilation failure for missing datasource/model classes.

- [ ] **Step 3: Implement minimal local storage**

Use `FlutterSecureStorage` for installation key, participant keys, pending token, resolved snapshots, sessions, and mutation outbox. Use `SharedPreferences` only for non-sensitive identity-mode/display-alias preferences and prompt timestamps/counters. Serialize UTC timestamps with `toIso8601String`; cap cached sessions at 20 and prune completed/expired sessions older than 30 days without deleting pending mutations.

- [ ] **Step 4: Verify local persistence**

Run: `flutter test test/features/share_good/data`

Expected: all local/model tests pass and no raw token or participant key appears in the SharedPreferences fake.

- [ ] **Step 5: Commit persistence**

```powershell
git add lib/features/share_good/data/datasources/share_good_local_datasource.dart lib/features/share_good/data/models/share_good_models.dart test/features/share_good/data
git commit -m "feat(share-good): persist private invite sessions"
```

### Task 3: Add Supabase schema, privacy-safe RPCs, deletion-safe lineage, indexes, and contract verification

**Files:**
- Generate: `supabase/migrations/<generated_timestamp>_share_good_v1.sql` via `supabase migration new share_good_v1`
- Create: `supabase/tests/share_good_v1_test.sql`
- Create: `test/supabase/share_good_contract_test.dart`
- Modify: `scripts/verify_supabase_contract.ps1`
- Modify: `test/scripts/verify_supabase_contract_security_test.ps1`

**Interfaces:**
- Consumes: Task 1 JSON/status contracts and the repository's migration/RPC security conventions.
- Produces: the six tables, indexes, private `share_good_expires_at_v1`, validation/rate-limit helpers, and the nine locked public RPCs listed above.

- [ ] **Step 1: Write failing static contract tests**

```dart
final normalizedSql = sql.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
expect(sql, contains('enable row level security'));
expect(sql, contains('unique (invite_id, participant_key_hash)'));
expect(sql, contains("grant execute on function public.resolve_share_good_invite_v1(text, text) to anon, authenticated"));
expect(sql, contains("grant execute on function public.disclose_share_good_completion_v1(text, text, text, text) to authenticated"));
expect(
  normalizedSql,
  contains('grant execute on function public.create_share_good_invite_v1(jsonb, text, text, text, text, text) to authenticated'),
);
expect(
  normalizedSql,
  isNot(contains('grant execute on function public.create_share_good_invite_v1(jsonb, text, text, text, text, text) to anon')),
);
expect(sql, contains("revoke all on table public.share_good_invites from public, anon, authenticated"));
expect(sql, isNot(contains('religious_reward')));
```

Also assert public wrappers are `SECURITY INVOKER`, privileged helpers are in non-exposed `private` with `SECURITY DEFINER SET search_path = ''`, all helper relations/functions are schema-qualified, SHA-256 storage is used, target validation is strict, no direct DML grants exist, and no `anon` create/disclosure/chain/impact grant exists. Cover the authenticated creation cap and exact lifecycle/event caps above, direct-only disclosure query, aggregate-only downstream query, auth requirement for creation/named disclosure/chain/impact, idempotent completion, `creator_user_id ON DELETE SET NULL`, deletable identity/disclosure rows, non-cascading lineage, and indexes on token hash, creator/created time, root lineage, invite/status, rate-limit windows, and event time.

- [ ] **Step 2: Run the contract tests and confirm the migration is absent**

Run: `flutter test test/supabase/share_good_contract_test.dart`

Expected: failure because the migration/RPC text is missing.

- [ ] **Step 3: Implement the migration and database tests**

First generate the migration with `supabase migration new share_good_v1`; never rename it to the old plan date. The SQL test must execute with role changes for `anon`, authenticated users A/B/C, and a fourth unrelated user. It must prove: anon creation denial, authenticated creation/cap enforcement, token resolution projection, rate-limited private guest lifecycle, named completion denial to anon, authenticated creator-only impact, duplicate open/completion idempotency, expiry rejection, no identity in downstream aggregates, and invalid target/timezone rejection. It must then create `A -> B -> C`, delete B through the current account-deletion path, and prove B's identity/disclosure are gone while B's invite, C's participation/descendants, A's aggregate reach, and unrelated-user privacy remain intact.

- [ ] **Step 4: Extend the deployment verifier**

Add all six tables to the verifier's table list and add exact wrapper/helper security modes, RPC signatures/grants, non-exposed-private-schema assertion, forbidden direct privileges, empty search paths, foreign-key deletion actions, and required indexes to `verify_supabase_contract.ps1`. The current script test starts from a hard-coded expected contract-query count of 54; update it by the exact number of checks added rather than replacing it with a loose assertion.

- [ ] **Step 5: Run static and script contract tests**

Run: `flutter test test/supabase/share_good_contract_test.dart test/supabase/migration_history_test.dart`

Run: `pwsh -NoProfile -File test/scripts/verify_supabase_contract_security_test.ps1`

Expected: Dart and PowerShell contract suites pass.

- [ ] **Step 6: Run a fresh-database verification against an empty local/staging database**

Run: `pwsh -NoProfile -File scripts/verify_supabase_migrations.ps1`

Expected: every migration applies in lexical order; `supabase/tests/share_good_v1_test.sql` passes; the contract verifier reports all Share Good tables, deletion actions, indexes, RLS, grants, search paths, and RPC signatures as PASS. This step requires `TALIA_SUPABASE_FRESH_DB_URL` and PostgreSQL client tools.

- [ ] **Step 7: Commit the backend contract**

```powershell
git add 'supabase/migrations/*_share_good_v1.sql' supabase/tests/share_good_v1_test.sql test/supabase/share_good_contract_test.dart scripts/verify_supabase_contract.ps1 test/scripts/verify_supabase_contract_security_test.ps1
git commit -m "feat(share-good): add secure invitation backend"
```

### Task 4: Implement remote datasource, repository, use cases, offline replay, and GetIt wiring

**Files:**
- Create: `lib/features/share_good/data/datasources/share_good_remote_datasource.dart`
- Create: `lib/features/share_good/data/repositories/share_good_repository_impl.dart`
- Create: `lib/features/share_good/domain/repositories/share_good_repository.dart`
- Create: `lib/features/share_good/domain/usecases/share_good_usecases.dart`
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/core/l10n/cubit_message_codes.dart`
- Create: `test/features/share_good/data/share_good_remote_datasource_test.dart`
- Create: `test/features/share_good/data/share_good_repository_impl_test.dart`
- Create: `test/features/share_good/domain/share_good_usecases_test.dart`
- Create: `test/core/di/share_good_injection_test.dart`
- Create: `lib/core/services/device_timezone_resolver.dart`
- Create: `test/core/services/device_timezone_resolver_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3; lazy `Supabase.instance.client` convention; `Failure` from `lib/core/error/app_failure.dart`.
- Produces: `ShareGoodRepository` and use cases consumed by all Cubits.

```dart
abstract interface class ShareGoodRepository {
  Future<Either<Failure, CreatedInvite>> createInvite(InviteContext context, {required String timezone});
  Future<Either<Failure, ResolvedInvite>> resolveInvite(String token);
  Future<Either<Failure, InviteParticipation>> openInvite(String token, {required bool openedAsGuest});
  Future<Either<Failure, InviteParticipation>> startParticipation(String token);
  Future<Either<Failure, InviteParticipation>> completePrivate(String token);
  Future<Either<Failure, InviteParticipation>> discloseCompletionIdentity(
    String token, {
    required InviteIdentityMode identityMode,
    required String visibleName,
  });
  Future<Either<Failure, CreatedInvite>> continueChain(String token, InviteContext child, {required String timezone});
  Future<Either<Failure, GoodImpact>> getGoodImpact();
  Future<Either<Failure, Unit>> replayPendingMutations(String inviteId);
  Future<Either<Failure, Unit>> recordAnalytics(ShareGoodAnalyticsEvent event);
}
```

- [ ] **Step 1: Write failing RPC-mapping and repository tests**

Cover exact RPC names/parameter maps, rejection of `createInvite` when `parentParticipationId` is present, chain-only lineage mapping through `continueChain`, stable participant key reuse, private-completion-before-disclosure ordering, strict response parsing, sanitized failures, offline cached resolution, ordered mutation enqueue/replay, server idempotent responses, expired mutation retention, disclosure never queued without an authenticated session, and absence of automatic account binding. Missing RPC/schema-cache errors must map to `featureUnavailable`; no code path attempts table DML.

- [ ] **Step 2: Run tests and observe missing layers**

Run: `flutter test test/features/share_good/data test/features/share_good/domain/share_good_usecases_test.dart test/core/di/share_good_injection_test.dart test/core/services/device_timezone_resolver_test.dart`

Expected: compilation failures for datasource/repository/use cases.

- [ ] **Step 3: Implement datasource and repository minimally**

Remote datasource accepts an injectable `SupabaseClient` in tests and uses a lazy provider in production. Add stable `CubitMessageCodes.shareGoodUnavailable`; map missing Supabase configuration and PostgREST missing-function/schema-cache failures to `ServerFailure(CubitMessageCodes.shareGoodUnavailable)`. `createInvite` accepts only `InviteContext.parentParticipationId == null`; `continueChain` is the sole client path to the chain RPC. Repository writes a safe resolved snapshot after online resolution and queues only monotonic participation mutations on network failure. Invalid/expired/server-validation/unavailable failures are never queued. Extract the existing `FlutterTimezone`/IANA/last-known-zone resolution from `TaliaNotificationService.configureLocalTimezone` into `DeviceTimezoneResolver`: notifications retain their final UTC safety fallback, while invite creation requires a valid IANA name and fails closed with localized guidance when none is available. Do not add another timezone package or a Riyadh fallback.

- [ ] **Step 4: Register dependencies**

Register secure/local and remote datasources, repository, use cases, policies, resolver, and three Cubit factories in `configureDependencies`. Do not add Share Good kinds to `CloudSyncQueueKind` because that queue is authenticated-owner scoped.

- [ ] **Step 5: Verify all layer tests**

Run: `flutter test test/features/share_good/data test/features/share_good/domain/share_good_usecases_test.dart test/core/di/share_good_injection_test.dart test/core/services/device_timezone_resolver_test.dart`

Expected: all pass with Supabase uninitialized, online, offline-cache, and replay cases covered.

- [ ] **Step 6: Commit repository wiring**

```powershell
git add lib/features/share_good/data lib/features/share_good/domain/repositories lib/features/share_good/domain/usecases lib/core/di/injection.dart lib/core/l10n/cubit_message_codes.dart lib/core/services/device_timezone_resolver.dart test/features/share_good test/core/di/share_good_injection_test.dart test/core/services/device_timezone_resolver_test.dart
git commit -m "feat(share-good): connect invite repository and offline replay"
```

---

## Phase 2 — Cubits, Localization, Sharing, Preview, and Guest Entry

### Task 5: Implement creation, participation, and impact Cubit state machines

**Files:**
- Create: `lib/features/share_good/presentation/cubits/invite_create_cubit.dart`
- Create: `lib/features/share_good/presentation/cubits/invite_participation_cubit.dart`
- Create: `lib/features/share_good/presentation/cubits/good_impact_cubit.dart`
- Create: `test/features/share_good/presentation/cubits/invite_create_cubit_test.dart`
- Create: `test/features/share_good/presentation/cubits/invite_participation_cubit_test.dart`
- Create: `test/features/share_good/presentation/cubits/good_impact_cubit_test.dart`

**Interfaces:**
- Consumes: Task 4 use cases and Task 2 local session store.
- Produces: explicit Equatable states for UI; `activityReachedCompletion()` creates only local `completionAwaitingConsent`.

- [ ] **Step 1: Write failing Cubit tests**

Test personal/public defaults, signed-out creation returning `requiresAuthentication` without invoking the repository, authenticated anonymous/named creation, resolve/open/start, cached-offline resolve, invalid/expired/unavailable/feature-unavailable states, interrupted restore, completion pending consent, private completion, shared completion auth requirement, account switch no-auto-bind, repeat completion, authenticated chain continuation, impact loading/refresh/error, and closed-Cubit async safety.

- [ ] **Step 2: Run Cubit tests and confirm missing implementations**

Run: `flutter test test/features/share_good/presentation/cubits`

Expected: compilation failures for the three Cubits.

- [ ] **Step 3: Implement minimal Cubits**

`InviteParticipationCubit` must expose `resolve(token)`, `start()`, `activityReachedCompletion()`, `completePrivate()`, `completeWithCurrentAccount(identity)`, `continueChain(context)`, `startFresh()`, and `retry()`. `completeWithCurrentAccount` records the idempotent private completion first, then calls the authenticated disclosure RPC; if disclosure fails, completion safely remains private and retry requires another explicit tap. It stores the session after each state change and never obtains identity from an auth stream without a user action.

- [ ] **Step 4: Verify Cubit transitions**

Run: `flutter test test/features/share_good/presentation/cubits`

Expected: all state-machine tests pass with no duplicate repository mutations.

- [ ] **Step 5: Commit Cubits**

```powershell
git add lib/features/share_good/presentation/cubits test/features/share_good/presentation/cubits
git commit -m "feat(share-good): add invite lifecycle cubits"
```

### Task 6: Add Arabic/English copy, stable error codes, RTL/LTR, and accessibility vocabulary

**Files:**
- Modify: `lib/core/l10n/app_ar.arb`
- Modify: `lib/core/l10n/app_en.arb`
- Modify: `lib/core/l10n/cubit_message_codes.dart`
- Modify: `lib/core/l10n/localization_helpers.dart`
- Generated: `lib/core/l10n/app_localizations.dart`
- Generated: `lib/core/l10n/app_localizations_ar.dart`
- Generated: `lib/core/l10n/app_localizations_en.dart`
- Create: `test/features/share_good/share_good_localization_test.dart`
- Modify: `test/core/l10n/localization_regression_test.dart`

**Interfaces:**
- Consumes: Task 5 states.
- Produces: all copy for before/after invitation, mode, identity, preview, activity, expiry, errors, consent, continuation, impact, milestones, prompts, settings, and reminder notification.

- [ ] **Step 1: Write failing localization tests**

Assert every Share Good key exists in Arabic and English, placeholder signatures match, Arabic resolves RTL and English LTR, forbidden reward/ranking phrases are absent, and invalid/expired/offline/unavailable/repeat/account-conversion cases have distinct strings.

- [ ] **Step 2: Run localization tests and observe missing keys**

Run: `flutter test test/features/share_good/share_good_localization_test.dart test/core/l10n/localization_regression_test.dart`

Expected: failure for missing generated getters/ARB keys.

- [ ] **Step 3: Add ARB entries and stable message-code mapping**

Use “شارك الخير / أثر الخير” and “Share Good / Good Impact”. Before copy conveys companionship; after copy conveys passing the activity on. Copy may describe opens, responses, completions, and reach only as product participation. Include Semantics labels/hints for share, mode, visible identity, anonymous identity, start, complete, private completion, named acknowledgement, retry, and start fresh.

- [ ] **Step 4: Generate localization output**

Run: `flutter gen-l10n`

Expected: generated localization files update without generator errors.

- [ ] **Step 5: Verify localization**

Run: `flutter test test/features/share_good/share_good_localization_test.dart test/core/l10n/localization_regression_test.dart`

Expected: both locales pass key parity, directionality, placeholder, and forbidden-copy assertions.

- [ ] **Step 6: Commit localized copy**

```powershell
git add lib/core/l10n test/features/share_good/share_good_localization_test.dart test/core/l10n/localization_regression_test.dart
git commit -m "feat(share-good): localize privacy-first invite copy"
```

### Task 7: Extend the existing social-share sheet and build personal/public invite creation

**Prerequisite gate:** the approved Dawn redesign in `docs/superpowers/specs/2026-09-28-social-share-card-redesign-design.md` must be implemented, tested, and merged first. Stop this task if `SocialShareMood`, `SharePalette`, `ShareSignatureBar`, and `ShareCardLinks` do not exist or if `social_share_theme.dart` is still the active customization path. Do not implement Share Good against code Dawn is specified to delete. The Dawn font assets also retain their separate owner-approval gate. Tasks 8 onward that do not touch the share renderer may proceed while this gate is unresolved, but Phase 2 cannot exit without Task 7.

**Files:**
- Create: `lib/core/widgets/social_share/social_share_payload.dart`
- Create: `lib/core/widgets/social_share/templates/share_good_template.dart`
- Create: `lib/features/share_good/presentation/widgets/invite_mode_sheet.dart`
- Create: `lib/features/share_good/presentation/widgets/share_good_action.dart`
- Modify: `lib/core/widgets/social_share/social_share_model.dart`
- Modify: `lib/core/widgets/social_share/social_share_copy.dart`
- Modify: `lib/core/widgets/social_share/social_share_presentation.dart`
- Modify: `lib/core/widgets/social_share/social_share_sheet.dart`
- Modify after Dawn lands: `lib/core/widgets/social_share/social_share_card.dart`
- Modify after Dawn lands: `lib/core/widgets/social_share/share_card_palette.dart`
- Modify after Dawn lands: `lib/core/widgets/social_share/share_card_links.dart`
- Modify after Dawn lands: `lib/core/widgets/social_share/share_signature_bar.dart`
- Modify: `lib/core/widgets/social_share/talia_share_tokens.dart`
- Modify: `lib/core/widgets/social_share/share_card_shell.dart`
- Modify: `lib/core/widgets/social_share/share_card_template_resolver.dart`
- Modify: `test/core/widgets/social_share_test.dart`
- Modify: `test/core/widgets/social_share_export_test.dart`
- Modify after Dawn lands: `test/core/widgets/share_card_palette_test.dart`
- Modify after Dawn lands: `test/core/widgets/share_card_links_test.dart`
- Modify: `test/design_system/design_token_guard_test.dart`
- Create: `test/features/share_good/presentation/widgets/invite_mode_sheet_test.dart`
- Create: `test/features/share_good/presentation/widgets/share_good_action_test.dart`

**Interfaces:**
- Consumes: `SocialShareSheet.show`, `SocialShareData`, `SharePlus`, Task 5 `InviteCreateCubit`, Task 6 copy.
- Produces: backward-compatible `SocialSharePayload` and `SocialShareData.shareGood`; `ShareGoodAction` invokes the existing sheet after invite creation.

```dart
class SocialSharePayload {
  const SocialSharePayload({
    required this.initialEditableBody,
    required this.immutableSuffix,
    required this.qrUri,
    this.allowBodyEditing = false,
    this.allowNameToggle = true,
    this.initialShowName = true,
  });

  final String initialEditableBody;
  final String immutableSuffix;
  final Uri qrUri;
  final bool allowBodyEditing;
  final bool allowNameToggle;
  final bool initialShowName;

  String compose(String editedBody) {
    final body = (allowBodyEditing ? editedBody : initialEditableBody).trim();
    return body.isEmpty ? immutableSuffix : '$body\n$immutableSuffix';
  }
}
```

Change the public API compatibly to `SocialShareSheet.show(BuildContext context, SocialShareData data, {SocialSharePayload? payload})`. Existing callers pass no payload and retain Dawn's mood/palette, signature-bar, static category link, and exact-content behavior. Share Good passes the same immutable invite URI as both `qrUri` and the immutable text suffix; no editable content can replace either.

- [ ] **Step 1: Write failing compatibility, privacy, editing, export, and mode-selection tests**

Prove every existing Dawn category/mood/export dimension remains unchanged; existing cards keep their static category QR URLs; the invite card renders activity/CTA without sacred text and its QR decodes to the exact immutable invite URI; edited body cannot remove/change that link; personal/public selection happens before `SharePlus`; public defaults anonymous; a signed-out Share Good action offers authentication and never creates an invite or opens `SharePlus`; existing non-invite sharing and worship remain usable; OS target is not inferred/stored; card and plain text use the same explicit identity choice; cancelling leaves worship/navigation usable. The design-token guard may only stay equal or improve outside the two new Share Good files.

- [ ] **Step 2: Run focused tests and observe missing APIs**

Run: `flutter test test/core/widgets/social_share_test.dart test/features/share_good/presentation/widgets`

Expected: failure for missing payload/category/widgets.

- [ ] **Step 3: Implement the minimal extension**

Add `SocialShareCategory.shareGood`, `SocialShareData.shareGood`, Dawn palette/link/signature/template/copy branches, an optional editable text field in the current sheet, and immutable suffix composition for image and text shares. Update every exhaustive category switch in `social_share_model.dart`, `social_share_copy.dart`, `share_card_palette.dart`, `share_card_links.dart`, `share_card_template_resolver.dart`, `share_card_shell.dart`, and `social_share_presentation.dart`. `ShareSignatureBar` uses `payload.qrUri` only for Share Good and retains `ShareCardLinks.forCategory` for existing cards. Share Good is invitation marketing content, not Quran/Azkar sacred-text layout. Disable the name toggle for invitation payloads because identity was explicitly selected in `InviteModeSheet`; pass the selected value directly so Dawn's default cannot expose a name.

- [ ] **Step 4: Run renderer/export tests**

Run: `flutter test test/core/widgets/social_share_test.dart test/core/widgets/social_share_quran_exactness_test.dart test/core/widgets/social_share_export_test.dart test/core/widgets/share_card_palette_test.dart test/core/widgets/share_card_links_test.dart test/design_system/design_token_guard_test.dart test/features/share_good/presentation/widgets`

Expected: all Dawn and existing share tests pass; existing category QR links are unchanged; the Share Good QR contains only the invite URI; new Arabic/English invite exports are exactly 1080px wide in portrait/square/story; Quran exactness remains unchanged.

- [ ] **Step 5: Commit reuse-first sharing**

```powershell
git add lib/core/widgets/social_share lib/features/share_good/presentation/widgets test/core/widgets test/design_system test/features/share_good/presentation/widgets
git commit -m "feat(share-good): extend existing share cards for invites"
```

### Task 8: Add strict link ingress, startup precedence, public routes, Invite Preview, and guest start

**Files:**
- Create: `lib/features/share_good/application/incoming_invite_link_service.dart`
- Create: `lib/features/share_good/domain/services/invite_activity_resolver.dart`
- Create: `lib/features/share_good/presentation/pages/invite_preview_page.dart`
- Create: `lib/features/share_good/presentation/pages/invite_activity_page.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `lib/main.dart`
- Modify: `lib/app.dart`
- Modify: `lib/core/di/injection.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/core/router/launch_destination.dart`
- Create: `test/features/share_good/application/incoming_invite_link_service_test.dart`
- Create: `test/features/share_good/domain/invite_activity_resolver_test.dart`
- Create: `test/features/share_good/presentation/pages/invite_preview_page_test.dart`
- Create: `test/app_launch_navigation_test.dart`
- Modify: `test/core/router/app_router_route_policy_test.dart`
- Modify: `test/core/router/launch_destination_test.dart`

**Interfaces:**
- Consumes: Tasks 1–6, existing `QuranRepository`, `AzkarRepository`, `AppRouter`, `LaunchDestination`; it is independent of the blocked Dawn renderer work in Task 7.
- Produces: external URI parser/service; public `/invite/:token` and `/invite/:token/activity`; protected `/good-impact` route constant; exact target-to-page resolution.

- [ ] **Step 1: Align the SDK floor, promote `app_links: ^7.2.1` to direct, and write failing URI/startup/route tests**

Change `environment.sdk` from `^3.11.4` to `^3.12.0`, matching the installed Dart 3.12.2 and the already-locked transitive package; then add direct `app_links: ^7.2.1`. Do not downgrade the copy used by `supabase_flutter`. Accept only `https://taliaapp.com/i/<43-char-base64url-token>` and `taliaquran://invite/<token>`. Reject other hosts, schemes, paths, query-token variants, fragments, oversized values, and decoded separators. Test password recovery first, then a valid pending invite ahead of first-time onboarding and ordinary notification fallback, while prayer-companion payloads still use `PrayerCompanionController` when no invite wins. Test exact-prefix public matching for `/invite/:token` and `/invite/:token/activity`; test a dedicated authenticated guard for `/good-impact` because the current router protects only its explicit remote-protected set.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `flutter pub get`

Run: `flutter test test/features/share_good/application test/features/share_good/domain/invite_activity_resolver_test.dart test/core/router`

Expected: `flutter pub get` resolves `app_links 7.2.1` without changing `supabase_flutter`; tests fail only for missing service/routes/priority. If any supported build environment cannot provide Dart 3.12, stop and align the project toolchain instead of silently pinning a second link-handler version.

- [ ] **Step 3: Implement early buffering and launch arbitration**

Call `IncomingInviteLinkService.instance.start()` before `runApp`; it instantiates `AppLinks`, subscribes once, strictly parses URIs, and holds valid tokens in memory until dependencies are ready. Register that same singleton in GetIt. After `configureDependencies`, attach `ShareGoodLocalDataSource` and persist only the newest validated token. Integrate arbitration in `TaliaApp._applyLaunchNavigation`, `LaunchDestination`, and the top-level redirect on `AppRouter.router`: password recovery remains highest priority; `readPendingToken()` may navigate a valid invite ahead of onboarding/legacy notification fallback; acknowledge that exact token only after the router accepts `/invite/<token>`. Preserve a mismatched/newer token, existing raw notification response handling, and `PrayerCompanionController`. Never save invite routes through `AppSessionService`.

- [ ] **Step 4: Implement resolver and preview/activity shells**

`InviteActivityResolver` validates local availability and returns exact route/build data: page; Surah start/end derived from `SurahDetail.ayahs`; wird range; morning/evening category. Preview shows permitted identity, activity label, mode/status/expiry, and primary Start. Guest Start calls `startParticipation` and opens `InviteActivityPage`; no login or onboarding gate appears.

- [ ] **Step 5: Verify route, preview, offline, and guest behavior**

Run: `flutter test test/features/share_good/application test/features/share_good/domain/invite_activity_resolver_test.dart test/features/share_good/presentation/pages/invite_preview_page_test.dart test/core/router`

Expected: valid cold/foreground links reach preview exactly once, first-time invite bypasses onboarding, password recovery and prayer-companion regressions pass, invalid/offline/expired/unavailable states never route Home, and only Good Impact remains auth-protected.

- [ ] **Step 6: Commit link and preview foundation**

```powershell
git add pubspec.yaml pubspec.lock lib/main.dart lib/app.dart lib/core/di/injection.dart lib/core/router lib/features/share_good/application lib/features/share_good/domain/services/invite_activity_resolver.dart lib/features/share_good/presentation/pages test/features/share_good test/core/router
git commit -m "feat(share-good): route guest invite links to preview"
```

---

## Phase 3 — Worship Completion Adapters and Consent

### Task 9: Integrate Quran page and Surah invitations without replacing reader completion

**Files:**
- Modify: `lib/features/quran/presentation/pages/quran_reader_page.dart`
- Modify: `lib/features/quran/presentation/widgets/reader_overflow_sheet.dart`
- Modify: `lib/features/share_good/presentation/pages/invite_activity_page.dart`
- Modify: `test/features/quran/presentation/pages/quran_reader_page_mode_test.dart`
- Create: `test/features/share_good/presentation/quran_invite_completion_test.dart`
- Create: `test/integration/share_good_worship_regression_test.dart`

**Interfaces:**
- Consumes: existing `QuranReadConfirmationGate`, `QuranPageCubit.confirmRead`, Task 8 resolved start/end pages, Task 5 `activityReachedCompletion()`.
- Produces: optional `QuranReaderPage` parameters `int? invitedTargetEndPage` and `Future<void> Function()? onInvitedTargetConfirmed`; normal callers remain unchanged.

- [ ] **Step 1: Write failing reader-adapter tests**

Prove the invite action is unavailable before the existing automatic read confirmation succeeds, appears only at the exact target end page, requires one explicit invited-target tap, fires once per invite session, does not fire on persistence failure, survives rereading without duplicate completion, and does not alter Khatmah mode or ordinary page confirmation tests. There must be no second visible generic “confirm page read” step.

- [ ] **Step 2: Run focused reader tests and observe failure**

Run: `flutter test test/features/quran/presentation/pages/quran_reader_page_mode_test.dart test/features/share_good/presentation/quran_invite_completion_test.dart`

Expected: failure because invite completion hooks do not exist.

- [ ] **Step 3: Add the narrow reader hook**

Keep `_confirmThenRecordKhatmah` as the only ordinary progress authority. After `_quranPageCubit.confirmRead(pageNumber)` succeeds and the loaded state is confirmed, preserve current streak/log/daily-wird/Khatmah behavior. When `pageNumber == invitedTargetEndPage`, render a localized semantic “I completed the invited reading” action in the existing footer/bottom area; its once-only state is owned by the invite session, not inferred from `confirmRead` returning true on an already-confirmed page. The tap calls `onInvitedTargetConfirmed` once. Add a non-prominent before/after `ShareGoodAction` to the existing `ReaderOverflowSheet`; keep the ayah-specific `AyahOptionsSheet` share behavior unchanged and never reconstruct Quran models or text.

- [ ] **Step 4: Verify Quran and Khatmah regression boundaries**

Run: `flutter test test/features/quran test/features/khatmah/integration test/features/share_good/presentation/quran_invite_completion_test.dart test/integration/share_good_worship_regression_test.dart`

Expected: existing Quran exact text, reader gate, ordinary progress, audio, and Khatmah tests pass; invited page/Surah completion only reports after the existing commit plus explicit invite confirmation.

- [ ] **Step 5: Commit Quran adapters**

```powershell
git add lib/features/quran/presentation lib/features/share_good/presentation/pages/invite_activity_page.dart test/features/quran test/features/share_good/presentation/quran_invite_completion_test.dart test/integration/share_good_worship_regression_test.dart
git commit -m "feat(share-good): connect Quran completion boundaries"
```

### Task 10: Integrate morning/evening Azkar invitations with the current counted completion

**Files:**
- Modify: `lib/features/azkar/presentation/pages/azkar_category_page.dart`
- Modify: `lib/features/share_good/presentation/pages/invite_activity_page.dart`
- Modify: `test/features/azkar/presentation/azkar_category_page_test.dart`
- Create: `test/features/share_good/presentation/azkar_invite_completion_test.dart`
- Modify: `test/integration/share_good_worship_regression_test.dart`

**Interfaces:**
- Consumes: existing `AzkarLoaded.allDone`, Task 5 `activityReachedCompletion()`.
- Produces: optional `Future<void> Function()? onCollectionCompleted` on `AzkarCategoryPage`; normal route remains unchanged.

- [ ] **Step 1: Write failing integration tests around the real Cubit/page**

Prove empty/general/duas categories cannot become invite-complete; morning/evening callback fires only on the first fresh false-to-true `allDone` transition; rapid taps, undo, midnight rollover, restored completed state, explicit replay/reset, and auto-advance preserve existing behavior; reopened completed participation does not increment aggregate again.

- [ ] **Step 2: Run focused tests and observe missing callback**

Run: `flutter test test/features/azkar/presentation/azkar_category_page_test.dart test/features/share_good/presentation/azkar_invite_completion_test.dart`

Expected: failure because `AzkarCategoryPage` has no completion callback.

- [ ] **Step 3: Add a `BlocListener`-based adapter**

Observe `AzkarLoaded.allDone` from a stable owner without changing `AzkarCubit` or `AzkarCompletionStore`. Seed the observer from the first loaded state, ignore an initially restored `allDone == true`, and fire once only after a later `false -> true` transition. If the collection was already completed today, show an explicit “repeat for this invitation” action that calls the existing reset path; never auto-count the restored completion. Then let `InviteActivityPage` move to completion consent. Add before-activity and completion-screen `ShareGoodAction` entries with morning/evening target only.

- [ ] **Step 4: Verify all Azkar regression tests**

Run: `flutter test test/features/azkar test/features/share_good/presentation/azkar_invite_completion_test.dart test/integration/share_good_worship_regression_test.dart`

Expected: existing count persistence/content governance/midnight/auto-advance tests pass; invitation completion derives only from the existing collection contract.

- [ ] **Step 5: Commit Azkar adapter**

```powershell
git add lib/features/azkar/presentation/pages/azkar_category_page.dart lib/features/share_good/presentation/pages/invite_activity_page.dart test/features/azkar test/features/share_good/presentation/azkar_invite_completion_test.dart test/integration/share_good_worship_regression_test.dart
git commit -m "feat(share-good): connect Azkar collection completion"
```

### Task 11: Add supported daily-wird and Khatmah-range invitation entry points

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/home/presentation/widgets/daily_wird_card.dart`
- Modify: `lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart`
- Modify: `lib/features/share_good/presentation/pages/invite_activity_page.dart`
- Modify: `test/core/services/get_daily_wird_usecase_test.dart`
- Modify: `test/features/home/presentation/widgets/daily_wird_card_test.dart`
- Modify: `test/features/khatmah/presentation/pages/khatmah_dashboard_page_test.dart`
- Create: `test/features/share_good/presentation/wird_invite_completion_test.dart`

**Interfaces:**
- Consumes: `GetDailyWirdUsecase.call()`, `HomeLoaded.dailyWirdPageDetail`, `KhatmahPlan.dailyTargetFor()`, Task 9 explicit end-page completion.
- Produces: ordinary one-page `QuranWirdInviteTarget(page,page)` and Khatmah daily `QuranWirdInviteTarget(start,end)`.

- [ ] **Step 1: Write failing target and regression tests**

Assert `/quran/daily` preserves `origin=daily_wird`; the home card shares exactly its already-resolved page; Khatmah dashboard shares exactly `dailyTargetFor(date).startPage..endPage`; paused/completed/invalid plans do not expose a start invite; recipient completion never calls the recipient's `KhatmahCubit`; the last target page enables explicit invite completion. Assert `/azkar/smart` and `SmartWirdPage` expose no Share Good entry in V1.

- [ ] **Step 2: Run tests and observe missing context/entry points**

Run: `flutter test test/core/services/get_daily_wird_usecase_test.dart test/features/home/presentation/widgets/daily_wird_card_test.dart test/features/khatmah/presentation/pages/khatmah_dashboard_page_test.dart test/features/share_good/presentation/wird_invite_completion_test.dart`

Expected: new expectations fail while existing wird/Khatmah tests remain green.

- [ ] **Step 3: Add target-preserving entry points**

Retain the current `AppRoutes.quranDaily` resolution priority. Preserve `origin=daily_wird` when redirecting, use `HomeLoaded.dailyWirdPageDetail`, and build Khatmah range context from `KhatmahPlan.dailyTargetFor(date)`. Recipient `InviteActivityPage` opens `QuranReaderPage` in `QuranReaderMode.free`; this records the recipient's ordinary reading only. Smart Wird remains explicitly out of scope because its time-sensitive generated session is not represented by the locked target schema.

- [ ] **Step 4: Verify wird/Khatmah behavior**

Run: `flutter test test/core/services/get_daily_wird_usecase_test.dart test/features/home test/features/khatmah test/features/share_good/presentation/wird_invite_completion_test.dart`

Expected: all tests pass; source user's Khatmah remains authoritative and recipient invite reading cannot mutate it.

- [ ] **Step 5: Commit wird integration**

```powershell
git add lib/core/router/app_router.dart lib/features/home/presentation/widgets/daily_wird_card.dart lib/features/khatmah/presentation/pages/khatmah_dashboard_page.dart lib/features/share_good/presentation/pages/invite_activity_page.dart test/core/services/get_daily_wird_usecase_test.dart test/features/home test/features/khatmah test/features/share_good/presentation/wird_invite_completion_test.dart
git commit -m "feat(share-good): preserve daily wird invite targets"
```

### Task 12: Implement explicit recipient disclosure, identity preferences, account conversion, and chain continuation

**Files:**
- Create: `lib/features/share_good/presentation/widgets/invite_completion_consent_sheet.dart`
- Create: `lib/features/share_good/presentation/widgets/share_good_identity_settings_tile.dart`
- Modify: `lib/features/share_good/presentation/pages/invite_activity_page.dart`
- Modify: `lib/features/share_good/presentation/pages/invite_preview_page.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_hub_body.dart`
- Create: `test/features/share_good/presentation/widgets/invite_completion_consent_sheet_test.dart`
- Create: `test/features/share_good/presentation/widgets/share_good_identity_settings_tile_test.dart`
- Modify: `test/features/auth/presentation/pages/login_page_test.dart`
- Modify: `test/features/settings/settings_page_test.dart`
- Create: `test/integration/share_good_guest_flow_test.dart`
- Create: `test/integration/share_good_account_switch_test.dart`

**Interfaces:**
- Consumes: Task 2 identity preferences/session; Task 5 completion/continuation methods; existing `ProfileCubit`, `AuthCubit`, `AppUser`, `LoginPage` post-sync routing.
- Produces: explicit private/named choice, safe post-auth return, persisted identity defaults, and next-link invitation.

- [ ] **Step 1: Write failing privacy and conversion tests**

Prove no identity is sent before a choice; dismiss/process death preserves pending consent; guest private completion succeeds; guest named choice explains sign-in and returns to the same consent; login `returnTo` accepts only an internal invite/Good Impact path; account switch requires renewed confirmation with current name; fallback profile strings are anonymous; public invite remains anonymous by default; continuation requires authenticated completion and carries `parentParticipationId`.

- [ ] **Step 2: Run tests and observe missing UI/return behavior**

Run: `flutter test test/features/share_good/presentation/widgets test/features/auth/presentation/pages/login_page_test.dart test/features/settings/settings_page_test.dart test/integration/share_good_guest_flow_test.dart test/integration/share_good_account_switch_test.dart`

Expected: failures for missing consent/settings and safe return-to support.

- [ ] **Step 3: Implement identity resolver and consent sheet**

Resolve full name from real `UserProfile.name`, first name from its first Unicode whitespace-delimited component, and display name from an explicitly saved Share Good alias or non-placeholder authenticated `AppUser.displayName`. Never read/use `avatarUrl`. Render generated initial/neutral avatar only. Keep aggregate completion and name disclosure as separate repository actions.

- [ ] **Step 4: Implement safe account conversion and continuation**

Add optional `returnTo` to `LoginPage`; accept only a strictly parsed internal `/invite/<43-character-token>` or `/good-impact` destination and fall back to the current memorization-aware post-login route otherwise. Signed-out creators do not persist or auto-resume a create request across authentication; after sign-in they may invoke the persistent Share Good action again. After recipient value delivery, show a dismissible “continue the chain/save your impact” CTA. A child invite uses the same activity target and a new personal/public/identity selection; backend derives root lineage.

- [ ] **Step 5: Verify guest, privacy, and account-switch flows**

Run: `flutter test test/features/share_good test/features/auth/presentation/pages/login_page_test.dart test/features/settings/settings_page_test.dart test/integration/share_good_guest_flow_test.dart test/integration/share_good_account_switch_test.dart`

Expected: guests complete without registration; identity is disclosed only after explicit authenticated confirmation; account changes never reattribute prior participation.

- [ ] **Step 6: Commit consent and conversion**

```powershell
git add lib/features/share_good lib/features/auth/presentation/pages/login_page.dart lib/features/settings/presentation/widgets/settings_hub_body.dart test/features/share_good test/features/auth/presentation/pages/login_page_test.dart test/features/settings/settings_page_test.dart test/integration/share_good_guest_flow_test.dart test/integration/share_good_account_switch_test.dart
git commit -m "feat(share-good): require consent for completion identity"
```

---

## Phase 4 — Good Impact, Prompts, Notifications, and Analytics

### Task 13: Build Good Impact and symbolic milestones without rewards or identity graphs

**Files:**
- Create: `lib/features/share_good/presentation/pages/good_impact_page.dart`
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_hub_body.dart`
- Create: `test/features/share_good/presentation/pages/good_impact_page_test.dart`
- Modify: `test/features/share_good/domain/good_impact_milestone_policy_test.dart`
- Modify: `test/core/router/app_router_route_policy_test.dart`
- Modify: `test/features/settings/settings_page_test.dart`

**Interfaces:**
- Consumes: `GoodImpactCubit`, `GoodImpact`, `GoodImpactMilestonePolicy`, protected route from Task 8.
- Produces: lightweight aggregate dashboard and active/recent invite views.

- [ ] **Step 1: Write failing dashboard/privacy tests**

Test loading/error/empty/content states; active and last-30-day expired invites; direct response/completion counts; downstream aggregate reach; named acknowledgements only when returned as direct consented items; no participant tree; no ranking; no XP/points/reward language; milestone rendering separate from `AchievementService`. Route tests must prove `/good-impact` redirects signed-out users safely while `/invite/:token` and `/invite/:token/activity` remain public.

- [ ] **Step 2: Run tests and confirm page is absent**

Run: `flutter test test/features/share_good/presentation/pages/good_impact_page_test.dart test/core/router/app_router_route_policy_test.dart test/features/settings/settings_page_test.dart`

Expected: failures for missing page/route behavior.

- [ ] **Step 3: Implement the page with existing theme/layout primitives**

Use `TaliaAppBar`, `context.tokens`/`TaliaTokens`, existing typography/spacing, directional padding, semantic headings, pull-to-refresh, and a clear distinction between product counts and symbolic milestones. Verify light, dark, and `PureBlackCubit` OLED states. Do not make it a shell tab or social feed; add a restrained destination in `SettingsHubBody` and post-completion. Add `/good-impact` to a dedicated authenticated route set instead of relying on the current remote-protected route list.

- [ ] **Step 4: Verify dashboard and reward isolation**

Run: `flutter test test/features/share_good/presentation/pages/good_impact_page_test.dart test/features/share_good/domain/good_impact_milestone_policy_test.dart test/core/services/achievement_service_test.dart test/core/router/app_router_route_policy_test.dart test/features/settings/settings_page_test.dart`

Expected: all pass; achievement service tests are unchanged and no Good Impact code imports XP/achievement services.

- [ ] **Step 5: Commit Good Impact**

```powershell
git add lib/features/share_good/presentation/pages/good_impact_page.dart lib/core/router/app_router.dart lib/features/settings/presentation/widgets/settings_hub_body.dart test/features/share_good/presentation/pages/good_impact_page_test.dart test/features/share_good/domain/good_impact_milestone_policy_test.dart test/core/router/app_router_route_policy_test.dart test/features/settings/settings_page_test.dart
git commit -m "feat(share-good): add aggregate Good Impact dashboard"
```

### Task 14: Add exact smart-prompt policy, one local reminder, settings, and sanitized analytics

**Files:**
- Create: `lib/features/share_good/domain/services/share_prompt_policy.dart`
- Create: `lib/features/share_good/application/share_good_notification_intent.dart`
- Create: `lib/features/share_good/presentation/widgets/share_good_notification_setting_tile.dart`
- Modify: `lib/core/services/notification_service.dart`
- Modify: `lib/core/services/notification_scheduler.dart`
- Modify: `lib/app.dart`
- Modify: `lib/core/router/launch_destination.dart`
- Modify: `lib/features/settings/presentation/pages/subpages/notification_settings_page.dart`
- Modify: `lib/features/settings/presentation/cubits/notification_settings_cubit.dart`
- Modify: `lib/features/settings/presentation/cubits/notification_settings_state.dart`
- Modify: `lib/features/settings/presentation/widgets/settings_notification_tiles.dart`
- Create: `test/features/share_good/domain/share_prompt_policy_test.dart`
- Create: `test/features/share_good/application/share_good_notification_intent_test.dart`
- Create: `test/features/share_good/share_good_analytics_test.dart`
- Create: `test/core/services/notification_scheduler_share_good_test.dart`
- Modify: `test/core/router/notification_payload_route_guard_test.dart`
- Modify: `test/core/router/launch_destination_test.dart`
- Modify: `test/features/settings/presentation/cubits/notification_settings_cubit_test.dart`
- Modify: `test/features/settings/presentation/widgets/settings_notification_tiles_test.dart`

**Interfaces:**
- Consumes: Task 2 prompt/outbox data, Task 4 analytics repository method, existing local notification service/scheduler.
- Produces: deterministic `SharePromptDecision`, invite notification preference/state, one reminder ID per participation, opaque `sgi1|<local-session-id>` notification intent, sanitized event calls.

Exact prompt policy:

- Education appears once, inline/non-blocking, after the first eligible activity completion.
- Proactive prompt: at most once in 7 days and 3 times in rolling 30 days.
- After 1 dismissal: 14-day cooldown; after 2: 30 days; after 3+: 90 days.
- Two user-initiated Share Good actions in 30 days suppress proactive prompts for 60 days.
- Never prompt before/during worship, on invite-recipient completion consent, when accessibility focus is active on a completion control, or while another modal is open.
- The persistent Share Good action remains available regardless of suppression.

Notification policy:

- Preference key: `notifications_share_good`, default false.
- Schedule at most one local reminder after opened/started and before expiry; choose `min(startedAt + 6 hours, expiresAt - 30 minutes)` and skip if that time is not in the future.
- Pass the candidate through the existing local-timezone and quiet-hours policy. If adjustment lands at/after expiry, skip it. Respect the existing pending-notification budget instead of evicting prayer-companion or higher-priority worship notifications.
- Cancel on completion, expiry, start-fresh, or opt-out.
- Notification payload contains only `sgi1|<opaque-local-session-id>`. It is not a GoRouter path. The raw-response handler recognizes it before legacy routing, resolves the session ID to the raw token from `FlutterSecureStorage`, constructs `/invite/<token>` only in memory, and marks the raw event handled exactly once. `LaunchDestination` and its route guard treat `sgi1` like `pc1`: never navigate it as a route and never double-handle it. Neither notification text nor plugin payload contains the bearer token. The backend never sends “invite received”.
- Do not add milestone or named-completion push behavior in V1 because no push delivery stack exists.

- [ ] **Step 1: Write failing clock-driven prompt, reminder, and analytics tests**

Test every cap/cooldown, UTC prompt-state storage, no prompt before worship, stable reminder replacement/cancellation, timezone/quiet-hours adjustment, expiry skip, notification-budget behavior, permission denial, opt-out, `sgi1` raw-response handling, prayer-companion and legacy-route non-regression, no anonymous-open inviter notifications, and analytics payload rejection when it contains a name/email/content text/reward field or client-supplied UUID attribution.

- [ ] **Step 2: Run focused tests and observe failures**

Run: `flutter test test/features/share_good/domain/share_prompt_policy_test.dart test/features/share_good/application/share_good_notification_intent_test.dart test/features/share_good/share_good_analytics_test.dart test/core/services/notification_scheduler_share_good_test.dart test/core/router/notification_payload_route_guard_test.dart test/features/settings/presentation/cubits/notification_settings_cubit_test.dart test/features/settings/presentation/widgets/settings_notification_tiles_test.dart`

Expected: missing policy/service branches fail.

- [ ] **Step 3: Implement prompt and notification policies**

Inject clocks in policy tests. Add `shareGoodReminder` to `NotificationSettingsState` and load/toggle it through `NotificationSettingsCubit`; update enabled/total counts and render it inside the existing notification subpage. Add a dedicated channel/category and schedule/cancel methods without changing daily Quran/Azkar/kids/prayer-companion schedules. Reuse the extracted timezone resolver, quiet-hours helper, pending-notification budget, raw-response callback, and existing scheduler refresh path. Prompt UI is inline in existing completion surfaces, never a blocking pre-worship modal.

- [ ] **Step 4: Implement sanitized event recording**

Allow only `education_shown`, `prompt_shown`, `prompt_dismissed`, `share_sheet_opened`, `invite_resolved`, `activity_started`, `activity_completed_private`, `activity_completed_shared`, `account_converted_after_completion`, and `chain_continued`. Backend state remains authoritative for conversion counts. Document that `share_sheet_opened` is not proof the OS share was sent and that install attribution is unavailable.

- [ ] **Step 5: Verify policy integration**

Run: `flutter test test/features/share_good test/core/services/notification_scheduler_share_good_test.dart test/core/services/notification_scheduler_kids_test.dart test/core/services/notification_service_companion_test.dart test/core/router/notification_payload_route_guard_test.dart test/core/router/launch_destination_test.dart test/features/settings/presentation/cubits/notification_settings_cubit_test.dart test/features/settings/presentation/widgets/settings_notification_tiles_test.dart`

Expected: all Share Good policy tests and pre-existing notification tests pass; only one optional recipient reminder is scheduled.

- [ ] **Step 6: Commit prompts, reminder, and analytics**

```powershell
git add lib/features/share_good lib/app.dart lib/core/router/launch_destination.dart lib/core/services/notification_service.dart lib/core/services/notification_scheduler.dart lib/features/settings test/features/share_good test/core/services test/core/router/notification_payload_route_guard_test.dart test/core/router/launch_destination_test.dart test/features/settings
git commit -m "feat(share-good): cap prompts and invitation reminders"
```

---

## Phase 5 — Platform Links, Minimal Install Fallback, and Release Verification

### Task 15: Configure installed App/Universal Links and the minimal install/reopen fallback

**Release gate:** The repository does not contain production Android/iOS application identifiers, Android release fingerprints/signing, Apple Team ID, store URLs, or proof that `taliaapp.com` can deploy association files and route `/i/*`. Stop this task until those approved values and access are supplied. Do not commit the current `com.talia.quran`/`com.example.taliaQuran` identifiers, debug fingerprints, sample Team IDs, or invented store URLs as production configuration.

**Files:**
- Create: `ios/Runner/Runner.entitlements`
- Create: `supabase/functions/share-good-link/index.ts`
- Create: `scripts/run_share_good_android_link_qa.ps1`
- Create: `qa/share_good_runtime_qa.md`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Create: `test/features/share_good/platform_link_contract_test.dart`

**External artifacts not present in this repository:**
- `https://taliaapp.com/.well-known/assetlinks.json`
- `https://taliaapp.com/.well-known/apple-app-site-association`
- DNS/CDN/reverse-proxy mapping for `https://taliaapp.com/i/*` to `share-good-link`
- Production Play Store and App Store listings

**Interfaces:**
- Consumes: Task 8 `IncomingInviteLinkService`, approved release identity/domain values.
- Produces: verified installed-app links and a generic install/reopen fallback with no reader/content page.

- [ ] **Step 1: Write failing static platform contract tests**

Assert Android has `VIEW`, `DEFAULT`, `BROWSABLE`, HTTPS host, `/i/` path prefix, `android:autoVerify="true"`, and `<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />`; iOS has Associated Domains, `FlutterDeepLinkingEnabled` set to false for `app_links`, and the current password-recovery scheme retained. Assert production configuration contains no `com.example` or debug signing. Assert the edge function never returns Quran/Azkar content or inviter identity and always offers explicit “install then reopen this link” fallback.

- [ ] **Step 2: Run static tests and confirm the release gate fails**

Run: `flutter test test/features/share_good/platform_link_contract_test.dart`

Expected: failure identifies placeholder bundle/application IDs, debug signing, missing entitlements, and missing hosted-artifact evidence.

- [ ] **Step 3: Apply approved native identifiers/signing and link declarations**

Update the exact native project files with supplied production values. Preserve `taliaquran://auth/update-password`. Limit HTTPS association to `/i/*`; do not claim all domain paths. Set Android `flutter_deeplinking_enabled=false` and iOS `FlutterDeepLinkingEnabled=false`, making `app_links` the only Flutter link handler and preventing duplicate delivery.

- [ ] **Step 4: Implement the minimal redirect function**

For valid-looking token paths, return a small localized install page with platform store buttons and instruction to reopen the same link after installation. For invalid paths return 404. Apply `Cache-Control: no-store`, `Referrer-Policy: no-referrer`, a restrictive CSP, no third-party analytics, no target lookup, and no identity rendering. This is link infrastructure, not a web reader.

- [ ] **Step 5: Deploy and verify association artifacts outside the repository**

Run: `Invoke-WebRequest -UseBasicParsing https://taliaapp.com/.well-known/assetlinks.json`

Run: `Invoke-WebRequest -UseBasicParsing https://taliaapp.com/.well-known/apple-app-site-association`

Expected: HTTP 200, correct JSON content type, production package/app IDs, release certificate fingerprint/Team ID, and path limited to `/i/*`.

- [ ] **Step 6: Verify Android installed links**

Run: `pwsh -NoProfile -File scripts/run_share_good_android_link_qa.ps1 -InviteUrl $env:TALIA_SHARE_GOOD_TEST_URL`

Expected on a release-signed physical device: cold, background, and foreground launches each open Invite Preview exactly once; invalid/expired/offline scenarios match the matrix; no browser chooser appears for a verified domain.

- [ ] **Step 7: Verify iOS installed links on macOS**

Run: `xcrun simctl openurl booted "$TALIA_SHARE_GOOD_TEST_URL"`

Expected on simulator for route handling and on a production-signed physical device for association: Invite Preview opens exactly once in cold/background/foreground states. Record AASA CDN propagation timing and device evidence in `qa/share_good_runtime_qa.md`.

- [ ] **Step 8: Verify the uninstalled fallback explicitly**

On one physical Android and one physical iPhone with Talia removed, open the same URL from Messages/WhatsApp. Expected: minimal install page; after installation the app does not claim automatic restoration; reopening the original URL opens Invite Preview. If automatic post-install restoration occurs through later infrastructure, do not advertise it until a separate privacy review and repeatable device matrix passes.

- [ ] **Step 9: Commit platform configuration only after evidence passes**

```powershell
git add android/app/src/main/AndroidManifest.xml android/app/build.gradle.kts ios/Runner/Info.plist ios/Runner/Runner.entitlements ios/Runner.xcodeproj/project.pbxproj supabase/functions/share-good-link/index.ts scripts/run_share_good_android_link_qa.ps1 qa/share_good_runtime_qa.md test/features/share_good/platform_link_contract_test.dart
git commit -m "feat(share-good): verify mobile invitation links"
```

### Task 16: Run full regression, accessibility, privacy, backend, and runtime acceptance

**Files:**
- Modify: `test/integration/share_good_guest_flow_test.dart`
- Modify: `test/integration/share_good_account_switch_test.dart`
- Modify: `test/integration/share_good_worship_regression_test.dart`
- Modify: `qa/share_good_runtime_qa.md`
- Modify only if failures reveal an in-scope defect: files introduced/modified in Tasks 1–15.

**Interfaces:**
- Consumes: every preceding task.
- Produces: release evidence for all V1 acceptance criteria and explicit recorded platform limitations.

- [ ] **Step 1: Complete the failing end-to-end test matrix before fixes**

Cover authenticated personal/public before/after creation; signed-out creation refusal without blocking ordinary share/worship; exact page/Surah/wird/Azkar target; installed link; guest preview/start/completion; private and named completion; continuation; deletion-safe `A -> B -> C` aggregate lineage; invalid/expired/offline/old-backend-unavailable; repeat completion; account switch; process interruption; prompt caps; notification opt-out/quiet-hours/budget; Arabic RTL/English LTR; framework text scaling at 200% on Share Good surfaces while preserving Quran's existing local layout constraints; TalkBack/VoiceOver labels; pure-black theme; reduced motion; and no excluded social features.

- [ ] **Step 2: Run all automated tests**

Run: `flutter test`

Expected: all existing and new tests pass with zero failures.

- [ ] **Step 3: Run static analysis**

Run: `flutter analyze`

Expected: no analyzer errors or warnings.

- [ ] **Step 4: Rebuild and verify the backend from scratch**

Run: `pwsh -NoProfile -File scripts/verify_supabase_migrations.ps1`

Expected: fresh migration chain, database SQL tests, and all contract checks pass.

- [ ] **Step 5: Run focused sacred-content and worship regressions**

Run: `flutter test test/features/quran/quran_local_datasource_parse_test.dart test/features/quran/quran_reader_sacred_text_test.dart test/core/widgets/social_share_quran_exactness_test.dart test/features/azkar/data/azkar_local_datasource_release_test.dart test/features/azkar/presentation/azkar_cubit_test.dart test/features/khatmah/integration`

Expected: exact Quran text, approved Azkar content, counts/day rollover, and Khatmah authority/completion remain unchanged.

- [ ] **Step 6: Execute and record physical-device runtime QA**

Follow `qa/share_good_runtime_qa.md` on production-signed Android and iOS builds, using at least WhatsApp plus one SMS/Messages path and one public/status-capable destination. Record build IDs, OS versions, link state, install state, locale, result, and screenshots/log references. Expected: every advertised installed-link path passes; automatic deferred installation remains explicitly unsupported.

- [ ] **Step 7: Perform the final scope/privacy audit**

Run: `rg -n -i "friend|leaderboard|ranking|chat|live room|profile photo|religious reward|ثواب|حسنات" lib/features/share_good supabase/migrations/*_share_good_v1.sql`

Expected: only explicit prohibition/test text or carefully reviewed devotional copy; no friends/feed/chat/ranking/photo/live/reward implementation. Confirm Good Impact does not import `AchievementService` or `XpService` and no web reader files changed.

- [ ] **Step 8: Commit acceptance evidence/fixes**

```powershell
git add test/integration qa/share_good_runtime_qa.md
git commit -m "test(share-good): verify guest privacy and worship regressions"
```

---

## Spec Coverage Map

| Design requirement | Repository-grounded implementation task(s) |
|---|---|
| Worship-first, no reward claims, no social pressure | Global constraints; Tasks 6, 13, 14, 16 |
| Quran page, Surah, supported ordinary daily wird/Khatmah range | Tasks 1, 8, 9, 11; Smart Wird explicitly skipped in V1 |
| Morning/evening and fitting Azkar collections | Tasks 1, 10; general/duas deliberately excluded because current flows lack collection completion |
| Before/after entry points | Tasks 7, 9, 10, 11 |
| Personal/public selection before OS sheet | Task 7 |
| Dynamic text, branded card, editable body, immutable token | Task 7 using existing social-share infrastructure |
| Exact activity context | Tasks 1, 8–11 |
| Installed recipient preview and exact activity | Tasks 8, 15 |
| Uninstalled recipient/mobile-only fallback | Task 15; no reader or general web app |
| Deferred restoration | Explicitly unsupported/not advertised with `app_links`; Task 15 records fallback and evidence gate |
| Authenticated creation plus guest completion without onboarding/auth | Tasks 3, 5, 7, 8–12, 16 |
| Inviter identity modes/no photos | Tasks 1, 2, 7, 12 |
| Recipient identity consent | Tasks 3, 5, 12 |
| Completion-specific semantics | Quran Task 9; Azkar Task 10; wird Task 11; Khatmah source logic deliberately unchanged |
| Central smart expiration/useful expired path | Tasks 3, 5, 8 |
| Good Chain lineage/private graph protection | Tasks 3, 4, 12, 13 |
| Good Impact aggregate metrics/named direct acknowledgements | Tasks 3, 4, 13 |
| Symbolic milestones separate from worship points | Tasks 1, 13 |
| Limited notifications/configurable opt-out | Task 14 |
| Participation states and duplicate protection | Tasks 1–5, 12 |
| Analytics separated from religious value | Tasks 3, 4, 14 |
| Smart prompt caps/dismissal behavior | Tasks 2, 14 |
| Account conversion after value | Task 12 |
| Invalid/expired/deleted/offline/account-switch/repeated/interrupted cases | Error matrix; Tasks 4, 5, 8, 12, 16 |
| Arabic RTL, English LTR, accessibility | Tasks 6, 7, 8, 12–16 |
| Backend migrations, security rules, indexes | Task 3 |
| Unit/Cubit/repository/widget/integration/runtime/deep-link tests | Every task; final matrix in Task 16 |
| Excluded V1 scope | Global constraints and Task 16 scope scan |

## Phase Exit Gates

1. **Phase 1:** pure domain/local/backend/repository tests pass; no UI or worship code changed.
2. **Phase 2:** Dawn prerequisite tests pass; a valid installed/internal link reaches guest Preview; native sharing uses Dawn's card/sheet/signature stack with the immutable invite QR; ordinary app startup still works.
3. **Phase 3:** all four supported completion paths report through existing worship boundaries and privacy consent; Quran/Azkar/Khatmah regression suites pass.
4. **Phase 4:** Good Impact, milestones, prompts, reminder, and analytics are testable and non-competitive; no push or reward coupling exists.
5. **Phase 5:** production identities/domain artifacts and signed-device evidence pass; otherwise the feature remains non-advertised/disabled for external HTTPS links.

## Self-Review Results

- **Full spec coverage:** every V1 section maps to a task above. General/Duas are explicitly excluded from invite eligibility because repository behavior does not provide the required counted completion. Automatic deferred installation is explicitly not advertised because the selected installed-link package cannot guarantee it.
- **Duplicate architecture:** no second card renderer, screenshot exporter, gallery saver, OS share wrapper, Quran progress engine, Azkar counter, Khatmah progress engine, auth system, achievement system, or account-owned cloud queue is created.
- **Existing vs new APIs:** every claimed existing path/class was verified in the repository. Every Share Good type/file/RPC is labeled Create or introduced with an exact signature before consumption.
- **Privacy leaks:** token/participant keys are hashed server-side and stored securely client-side; creation requires authentication; public defaults anonymous; names live in separately deletable snapshots; named completions require explicit authenticated consent; downstream lineage is aggregate-only; analytics is isolated from UI and cannot accept arbitrary client UUID attribution.
- **Guest regressions:** invite routes are public, a validated first-time invite takes precedence over onboarding after password recovery, private completion does not require Supabase Auth, and auth changes do not auto-bind participation. Guests cannot create invitations.
- **Quran/Azkar regressions:** completion adapters observe successful existing boundaries; restored Azkar completion does not auto-count; sacred text, parsers, Cubits/stores, Smart Wird, and Khatmah use cases remain unchanged.
- **Deferred-link assumptions:** App/Universal Links are described only for installed apps. Store fallback requires reopening the original link. Production association and physical-device verification are release blockers.
- **Type consistency:** Task 1 entity names, Task 4 repository signatures, Task 5 Cubit methods, Tasks 7–12 consumers, SQL target/status strings, and JSON keys use the same spelling throughout.
- **V1 scope:** no guest invite creation, Smart Wird invitation, friend graph, feed, chat, leaderboard, profile photo, live session, web reader, push stack, deferred-link provider, or worship-point integration is planned.

## Risks and External Blockers

1. The approved spec is stored at a different tracked path than requested; preserve that path or resolve a separate documentation move before implementation.
2. Production Android/iOS identifiers and signing are absent; current `com.talia.quran`/`com.example.taliaQuran` and debug-signing configuration cannot support release-verified links.
3. Android `assetlinks.json`, iOS AASA, `taliaapp.com/i/*`, store listings, DNS/CDN, and domain deployment are outside this repository and require owners/access.
4. App/Universal Link behavior and the share sheet must be verified on signed physical devices; simulator/debug success is insufficient.
5. Pure installed-link handling provides no reliable post-install token restoration. V1 must not advertise deferred restoration.
6. No push provider exists; named acknowledgement and milestone push are not implementable without a separately approved backend/device-token privacy design.
7. Authenticated creation caps and installation/token-scoped guest lifecycle limits reduce accidental duplicate/spam inflation but cannot prevent a determined attacker from rotating installation state. Deployed anomaly monitoring is still required; counts are participation metrics, not trusted religious facts.
8. Supabase fresh-database and deployed-role verification require a safe empty/staging database and PostgreSQL tooling.
9. The current worktree contains uncommitted localization and `LoginPage` changes that directly overlap Tasks 6 and 12, plus unrelated typography/onboarding/splash/tutorial work. Stabilize or deliberately carry them forward before implementation; never overwrite them from this plan.
10. Dawn is approved but not implemented. Task 7 remains blocked until its renderer/mood/palette/signature/QR contract and tests land; implementing Share Good on the old theme stack would create immediate rework and conflicting file ownership.

## Ordered Implementation Phases

1. Domain contracts, secure local state, backend/RLS, repository/use cases.
2. Cubits and localization; startup/link preview and guest start may proceed while Dawn lands; then complete authenticated reuse-first invite creation on Dawn before the phase exit.
3. Quran page/Surah, Azkar, daily-wird/Khatmah-range adapters, identity consent, account conversion, chain continuation.
4. Good Impact, symbolic milestones, prompt policy, one local reminder, sanitized analytics.
5. Production platform links, minimal install/reopen fallback, full automated and real-device acceptance.
