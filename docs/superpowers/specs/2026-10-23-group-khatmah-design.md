# Group khatmah: K0 design for owner review

Date: 2026-10-23. Status: **reviewed design; owner explicitly approved this concrete document and local implementation on 2026-10-23**. This approval follows the independent review and corrections recorded below. Deployment remains separately gated at K5. No database queries, migrations, deployment, or application edits were performed for K0.

## Scope and evidence

Implements the intended contract of [roadmap §10](2026-10-13-talia-differentiation-roadmap.md) and [Phase 3 K0–K5](../plans/2026-10-22-roadmap-phase-3.md). `groupKhatmah` stays off by default. Adults only; separate group reading, never personal khatmah progress, SRS, XP, certificates, or memorization mutations.

Repository patterns inspected:

- `supabase/migrations/20261020203344_roadmap_phase2_child_policy_v2.sql`: caller-derived identity, authorization row locking, explicit CAS version, empty search path and signature-specific revokes/grants. Reuse the principles, not its child-specific authority.
- `supabase/migrations/20261001235630_harden_delete_current_user_session.sql`: checks live session ownership, then deletes `auth.users`; lost acknowledgement is an intentional successful no-op.
- `lib/core/sync/cloud_sync_queue.dart`: one row per kind/account, captured owner for failures, eight-attempt retry budget, retained dead letters. It is a wake-up queue, not a per-operation durable outbox.
- `lib/core/memorization/kids_progress_cloud_merge.dart`: existing merge is aggregate-oriented. Group parts require CAS/operation identity, not a greatest-value merge.
- `lib/core/identity/account_data_reset.dart`: extend account-scoped cleanup for the new cache/outbox prefix.
- `lib/features/settings/data/user_profile.dart`: optional editable `age`; it is not server authorization evidence.
- `lib/features/khatmah/data/datasources/khatm_dua_datasource.dart`: existing approval gate; reuse it without adding religious text.

This is local-source investigation, not a claim about deployed database state. Current adult eligibility authority, exposed schemas, grants, PostgreSQL version, and production migrations remain unverified.

## Proposed records and invariants

All timestamps are server UTC. Use UUIDs and bigint versions; reject null/negative versions rather than coalescing them into a valid request. Group versions start at 1 and increase on every visible mutation; part versions start at 1 and never reset. No client-supplied user ID is authoritative.

| Record | Proposed contract |
|---|---|
| `public.group_khatmah` | UUID PK, unique six-character invitation `code`, trimmed `title`, `owner_id`, `max_members` checked 1..30 (v1 fixed 30), `status` active/completed, positive `version`, `created_at`, nullable `completed_at`; status and completion timestamp agree. Proposed title limit 1..80 Unicode code points. |
| `public.group_khatmah_member` | PK `(group_id,user_id)`, display name 2..24 Unicode code points after trim, `joined_at`, nullable `left_at`, server-generated UUID `membership_epoch`. Active means `left_at IS NULL`. A rejoin replaces the epoch, never reuses it. |
| `public.group_khatmah_part` | PK `(group_id,juz)`, check juz 1..30, status open/claimed/completed, nullable `claimed_by`, nullable `claim_epoch`, positive `version`, `updated_at`. Exactly 30 rows created transactionally; clients cannot insert/delete parts. Open implies both claim fields null; claimed requires both; completed may be anonymized during privacy cleanup. |
| Private operation receipt | Unique `(actor_id,operation_id)`, request fingerprint, group/epoch, result status and resulting version. No emails or names. Stores committed success for create/join/claim/complete/release/leave, in the same transaction as the mutation. Needed for lost acknowledgements. Not client-readable. |
| Private adult eligibility | Server-controlled account eligibility and policy version, default denied/unknown. No client writes. New dependency needing approval, not inferred from local age or account existence. |
| Private invitation throttle | Per-account rolling attempt counters, inaccessible to clients; failed attempts must commit their counter rather than raise and roll back the transaction. Proposed 5 attempts/minute and 30/day. |

Group child rows reference group with cascade delete. `group.owner_id` references `auth.users(id) ON DELETE RESTRICT`; `member.user_id` references `auth.users(id)` with non-deferrable ON DELETE RESTRICT. Cleanup explicitly deletes every membership first, including inactive rows, so a claimless member cannot be deleted outside the group revision/privacy transaction. Parts have a composite FK `(group_id,claimed_by)` to membership `(group_id,user_id) ON DELETE NO ACTION`; nullable claim identity is cleared before deleting membership, and parts never cascade from a user/member deletion. The membership epoch is checked by RPC under the group lock, not an FK whose rejoin update could rewrite history. Private receipts reference actor with ON DELETE CASCADE, but have **no cascading group FK**: an opaque group UUID may survive as a minimal gone receipt. Eligibility/throttle actor FKs cascade on account deletion. The controlled deletion sequence below satisfies restrictive FKs before auth deletion. Index active membership by user/group and by group; index group owner; PK covers part lookup. Receipt and throttle indexes cover actor; invitation uniqueness is enforced by the database.

Names are plain text, never markup. Client and server use the same Unicode-code-point length contract (not UTF-16 code units); reject control characters and bidi overrides while permitting ordinary Arabic letters/diacritics. Do not silently truncate. No profile/email joins or email fields in responses, logs, caches, or shared cards. Display names may themselves contain voluntarily entered personal information; label them as visible to the group.

## Authorization and RLS without recursion

Enable RLS on all three public tables and private records as defense in depth. Explicitly revoke all table privileges from PUBLIC, anon, authenticated, and service_role; restore only authenticated SELECT on approved public columns. Direct INSERT/UPDATE/DELETE/TRUNCATE is denied. No public/anonymous reads, invitation lookup endpoint, broad owner bypass, or security-definer views.

Each public SELECT policy is `TO authenticated` with a private membership predicate bound to `auth.uid()`, checking active membership and current trusted adult eligibility. Member roster SELECT additionally filters the target row to active members; departed names are not exposed. The group owner also requires active membership.

The membership predicate is a narrow `SECURITY DEFINER` helper in an unexposed `private` schema, with `search_path=''`, schema-qualified names, and no caller-supplied user ID. Its controlled owner can read membership without re-entering membership RLS. Prefer a dedicated NOLOGIN role owning only feature tables/functions; verify actual owner privileges in K1. Do not apply FORCE RLS in a way that reintroduces recursion. Avoid membership policies that query group policies and vice versa. The helper returns only whether the caller can access the specified group; a random UUID gives false.

Grant authenticated only schema USAGE and EXECUTE on the exact policy/helper entry points needed; revoke PUBLIC/anon execute and schema CREATE. Private schema must remain outside Data API exposure. Never grant the client the definer role or its table privileges.

**Proposed deviation from K0's literal public definer RPC wording:** expose the six named public RPCs as thin SECURITY INVOKER wrappers; keep their privileged implementations in private SECURITY DEFINER functions. Every privileged function has empty search path, qualified objects, fixed parameter types, explicit caller/session/eligibility checks, and no dynamic SQL. Revoke EXECUTE from PUBLIC, anon, authenticated, and service_role on every new signature before restoring only the needed authenticated wrapper/implementation grants. The private implementation remains an authorization boundary even when called directly over SQL. This follows current Supabase guidance against exposed definer functions; owner approval must accept this layout or request a documented alternative.

Every mutation requires a non-anonymous authenticated caller, an existing account, a live session matching JWT session_id and uid, and current server eligibility. Authorization reads never return email or profile payloads. JWT user_metadata is forbidden; stale app_metadata alone is also insufficient. Anonymous Auth users carry authenticated role, so role membership alone does not qualify.

### Adult eligibility decision (blocking policy)

Proposed default: fail closed unless a server-owned eligibility record explicitly permits group khatmah. Trusted administrative provisioning for the initial cohort is the smallest safe launch path. Do not automatically provision from local age, absence of parent-child links, or editable metadata. Product owner must approve what constitutes adult eligibility and who may provision/revoke it; broader self-service age assurance requires a separate concrete policy. Revocation blocks reads/mutations immediately on the next server request. Local child-mode routing is an additional UX guard, never the security control.

## Transactions, RPC contracts and races

Extend draft RPC arguments with `operation_id` UUID; part mutations and leave also require `membership_epoch`. Receipt request fingerprints bind every relevant input including expected version. Reusing an ID with different inputs is terminal `invalid_operation` for a live receipt; the minimal gone tombstone takes precedence and always returns `gone` without payload comparison. Clients persist IDs before network calls.

Response envelope: `applied`, stable `code`, operation ID, authorized current group/part versions, membership epoch where applicable. `conflict` may include the current row only after membership authorization. `not_member`, `not_eligible`, and invalid invitations never include protected rows. Expected business denials are structured results; unexpected server errors stay retryable failures without exposing SQL details.

Lock order for every feature mutation: transaction-scoped advisory lock for the authenticated actor (one stable namespace/key derivation), caller eligibility row, group rows in ascending UUID order, affected membership rows in deterministic UUID order, then parts in juz order, then receipt writes. The actor lock serializes same-actor operations, including concurrent first create requests with the same operation ID; it is not an authorization substitute. Creation has no existing group row. Membership join/leave and all part transitions serialize through the same group row lock. Do not acquire other actors' advisory/eligibility locks while holding a group lock. Eligibility revocation takes the subject's actor lock before its eligibility row. Existing receipt lookup before group locking is read-only; no receipt row lock may invert the group-before-receipt write order. Transactions retry serialization/deadlock with the same operation ID. K1 must exercise actual concurrent transactions.

Receipt handling has explicit branches. After authenticating, acquiring the actor lock and checking current eligibility, look up `(auth.uid(),operation_id)` privately. A gone tombstone returns terminal `gone` immediately, without fingerprint comparison or group data; otherwise compare the stored fingerprint. This lookup does not return group data. For create/join retries the receipt supplies the group ID that the client may never have received; lock that group and authorize its current active membership (create additionally requires current ownership). If concurrent deletion removed the group, re-read its now-gone receipt and return gone. Return saved success only if current membership epoch equals the receipt epoch. If no active membership remains return `not_member`; if a different epoch is active return terminal `stale_operation` with no snapshot/epoch. Never rerun a previously recorded join/create to repair a stale epoch.

For part/leave requests also check the supplied epoch under the group lock; old part receipts cannot bypass epoch validation. For an authorized matching epoch a matching receipt returns committed success without another write, including after completion. Only then reject new mutations to completed groups. The successful receipt includes immutable operation outcome/versions and epoch, not a historical full group snapshot; return a fresh authorized snapshot if needed. New receipt and domain change commit atomically. Same-actor serialization plus the unique key makes duplicate first requests execute once; unexpected uniqueness conflicts must reload the receipt, never reapply intent. A new operation ID is required for an intentional rejoin. The client cannot replace a newer epoch using a stale response.

| RPC | State transition and result |
|---|---|
| create(title, displayName, operationId) | Validate inputs/eligibility; generate code using cryptographically secure uniform selection from exact R5 alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, length 6. Unique constraint and bounded retry (e.g. 10 collisions) precede retryable failure. Create group, owner membership, 30 parts, receipt atomically. Lost acknowledgement reuses original group/code. |
| join(code, displayName, operationId) | Trim/uppercase ASCII input; reject any non-R5 character or wrong length. Throttle before lookup. Invalid/nonexistent/closed code uses a generic denial. Lock group, recheck active status, count active members including owner; >=30 denies. Existing active member is idempotent and does not consume another slot or alter name. Rejoin checks capacity and creates a fresh epoch. |
| claim(group,juz,expectedVersion,epoch,operationId) | Active group, active matching epoch; CAS requires open and exact part version. Set claimed_by=caller, claim_epoch=current epoch and version+1. Competing requests produce one success; loser gets `applied:false,code:conflict` and authorized current row. No silent rebase/retry with a new version. |
| complete(group,juz,expectedVersion,epoch,operationId) | CAS requires claimed by caller in this epoch and exact version. Set completed, increment version. Count completed parts under group lock; final part sets group completed/completed_at in this same transaction. Another member's claim is never completable. |
| release(group,juz,expectedVersion,epoch,operationId) | CAS requires own claimed part and exact version. Set open, clear claim identity, increment version. Completed parts cannot be released. |
| leave(group,epoch,operationId) | Online only. Mark membership left, erase its display name from public-visible use, release its unfinished claims with version increments. Completed parts remain completed with attribution cleared. Increment group version. A repeat after leave returns minimal terminal `not_member`/already-left acknowledgement with no group payload. |

Revision rule, applied under the group lock: creation sets group version 1; each successful new join/rejoin, claim, release, and complete increments group version exactly once. Final completion increments it once for both the last part and group status transition, not twice. Leave increments once even when it releases several claims; each changed part increments its own version once, including completed-attribution erasure. Member account cleanup increments each surviving affected group once. Receipt replay, already-active join, validation denial, and CAS conflict do not increment versions. Group deletion produces gone receipts and absence in the authoritative membership list, not a surviving revision. Part versions govern part CAS; group versions govern snapshot freshness.

Proposed owner-leave policy: reject `owner_has_members` while any other active member exists; v1 has no transfer or removal RPC. If owner is sole active member, delete the group and cascaded feature records after an explicit destructive confirmation. This avoids an ownerless group and hidden succession. Member removal is outside v1; if later added it must use exactly the leave/epoch invalidation transaction.

Completed means no new join, claim, complete, release, name/title edits, or reopening. Membership privacy exit and account deletion are exceptions: users can still leave; this can erase attribution but cannot uncomplete parts. Owner leave restriction still applies. Completion read-only is a domain-state invariant, not a prohibition on privacy erasure.

## Invitation security and privacy retention

The six-character code is a bearer invitation, not authentication. Require eligible signed-in accounts, enforced server attempt limits, no public lookup, generic errors, and no code in analytics/logging. Codes are visible to members and may be shared by them in v1. Owner-only sharing/rotation/expiry are not silently added. Proposed defaults need approval: fixed code until completion/deletion, no discovery, account throttling above, and infrastructure abuse controls verified before launch. Per-account throttling does not defeat mass-account abuse; that residual risk is a launch review item.

For ordinary member account deletion, preserve completed group progress but remove name/user attribution, release outstanding claims, explicitly remove memberships, then cascade eligibility, throttles, and operation receipts through account deletion. For owner account deletion, proposed v1 policy deletes owned groups and all their feature data, with a clear account-deletion warning that other members lose this shared group. This policy requires explicit approval; otherwise owner deletion handling remains unresolved and K1 cannot finalize its FKs. No deletion may leave stale claims or block the existing account-deletion RPC unexpectedly.

Receipts persist for the actor account lifetime. On group deletion, convert its receipts to minimal terminal tombstones in the same transaction: actor/operation ID, operation kind, opaque group ID and `gone`, with no title, name, code, membership epoch, snapshot or request fingerprint. A known gone operation returns gone regardless of resubmitted payload and can never become a new intent. In particular a delayed create retry after sole-owner deletion cannot create a replacement group. Tombstones have no group FK and survive group deletion; account deletion cascades the deleted actor's receipts/tombstones because that actor can no longer authenticate. Other actors' gone receipts survive their account lifetimes. Ordinary live receipts retain only the fingerprint and minimal result metadata, not name/code plaintext. This longer minimal retention is an explicit owner approval item. Server backups follow existing retention policy, unverified in K0. Offline device caches cannot be remotely erased; purge them on next authorization refresh.

### Concrete account-deletion integration (proposal for K1)

Extend the existing `public.delete_current_user()` body, preserving its current auth/session checks and already-deleted successful no-op. After authentication, acquire the same actor advisory lock **before** any deletion/eligibility/group locks; recheck account/session after acquiring it. Call a private cleanup helper executable only by the deletion function's controlled owner (not authenticated, anon or PUBLIC), passing the validated uid. No client calls a separate cleanup endpoint. This extension is part of K1's reviewed scope; the existing Flutter RPC call stays the entry point.

The helper enumerates owned groups and all groups containing this user's membership, locks the complete union in ascending group UUID order, then rechecks the set/state. Same-actor serialization prevents this account joining/creating while deletion runs; other members' operations serialize on each group. In owned groups, convert all actors' receipts to gone and delete the group (cascading parts/members). In surviving groups, lock this user's membership then its parts in juz order: release claimed parts, anonymize completed attribution, bump each changed part version and group version once, then delete membership. Finally delete `auth.users` so eligibility, throttles and this actor's receipts cascade. All steps share the original RPC transaction; any failure rolls back cleanup and auth deletion together. Account deletion does not require adult eligibility, so revoked/unknown users can still erase their account.

`owner_id RESTRICT`, `member.user_id RESTRICT` and claim/member-reference NO ACTION deliberately prevent unsafe bypass of cleanup. K1 must additionally prove that direct Auth-admin deletion of a non-owner with no claims/attribution is rejected by the membership FK, while the cleanup procedure and existing deletion RPC succeed. Administrative account deletions must use this same private cleanup-before-delete procedure in one transaction; direct Auth-admin deletion of a group participant is unsupported and may be rejected by FK constraints rather than silently corrupting progress. No generic auth trigger with a conflicting lock order is proposed. K1 must document this operational restriction and test the actual deletion RPC against concurrent claim/join/leave and another account's deletion. Broader direct Auth-admin deletion support would require a separately reviewed trigger/locking design.

K3 also updates the existing settings account-deletion confirmation (`lib/features/settings/presentation/widgets/settings_account_tiles.dart`) to warn that owned shared groups will be deleted for all members. The warning must appear even if the group feature flag is off or group lookup fails; it must not block deletion on eligibility or connectivity beyond the existing remote-delete requirement.

## Client cache, outbox and synchronization

Use feature-first domain entities, repository/use cases, data implementation, and Cubit. Presentation never calls Supabase. Reuse SharedPreferences under `group_khatmah_cache_v1|<owner>`; include a versioned snapshot, per-group membership epoch, pending operation journal, group revision, and account/session generation. No new Isar model. Register the entire prefix with AccountDataReset and exclude group snapshots/outbox from personal backup import/export.

The two existing-style queue kinds `group_khatmah_pull` and `group_khatmah_push` only wake repository work. Persist per-operation data in the account cache journal, including actor, group, epoch, juz, expected part version, operation ID and creation time. Write pending intent and optimistic overlay together before acknowledging local completion; enqueue afterwards. On startup reconcile durable pending intents and restore a missing wake-up item, covering a crash between the two stores. Serialize per-account cache writes and never overwrite a newer intent on delayed response.

Capture owner and account/session generation once before each async operation; validate before each request and before local publication. A response for A cannot render/cache/enqueue under B, even if A→B→A occurs. New work must use a session whose uid matches captured owner. Explicit-owner queue APIs are required where existing enqueue/markSuccess semantics are insufficient; do not derive identity again after awaits.

Claim/create/join/release/leave require connectivity. Only completion of a confirmed own claim can be queued offline. Mark it visibly pending; do not celebrate authoritative group completion until server confirmation. Never mutate personal khatmah.

Server snapshots win by part/group version. Pending completion is an overlay, not a replacement for authoritative rows. Keep it only while caller's claim and membership epoch still match. Conflict, released/reassigned claim, or membership revocation invalidates it; do not let generic dirty-key precedence resurrect an unauthorized claim. Receipt acknowledgement clears only that operation ID, not unrelated newer intents.

Terminal outcomes `not_member`, epoch mismatch/`stale_operation`, `gone`, `not_eligible`, `invalid_operation`, forbidden transition, and conflict remove/quarantine the specific intent, refresh authorized data, and stop automatic retries. `not_member`/`gone` additionally purge that group's snapshot, cursor, names and all pending intents. Expired sessions await recovery rather than exhausting unchanged credentials.

For group pushes, retries are **per operation**, not the existing aggregate row's attempt budget: journal each operation's attemptCount, nextRetryAt and pending/deadLetter status, using the existing eight-attempt/backoff policy. A delivery pass attempts eligible intents independently, persists each result, and excludes dead letters from future automatic delivery. Failure of A cannot consume B's budget. Dead letters remain visible until explicit recovery/cancellation; a new intent never rearms an old one.

K2 requires a narrow owner-bound aggregate-wake reconciliation API for these group kinds: compute the earliest nextRetryAt among pending intents, then replace/re-arm the group push wake row even if its legacy attempt counter is exhausted, without changing any journal operation's retry status. This is scheduling new/pending work, not recovering dead letters. A successful processing pass acknowledges the wake then reconciles again under the same account mutex; every new intent/startup does the same. When only dead letters remain, clear the aggregate wake while retaining journal evidence. If the dispatcher itself crashes before journaling results, startup reconciliation can re-arm the wake; lost acknowledgements are safe through server receipts. Generic queue retry behavior for other features is unchanged. Test one exhausted A, a new B, and app restart: B runs, A remains dead until explicit recovery.

Leave then rejoin is a new membership epoch; old cached work cannot complete even if the same user reclaims the same juz. Acknowledgement loss after final completion returns the stored receipt while membership is still valid; acknowledgement loss followed by leaving is terminal not_member, with no compensating server write.

Pull needs an authoritative complete list of current memberships, not only an updated_at cursor: revoked rows disappear under RLS and otherwise cannot invalidate caches. Reconcile absence only after a successful complete/paginated response, never after network failure or partial page. Start with full membership/group snapshots (30 parts per group) and group versions; defer timestamp cursors until scale requires them. Revalidate membership before displaying cached member names after login/rejoin. Offline within an existing validated session can show last-known data labeled stale; this is not proof of current access. Owner approval must accept offline privacy limitations or require online-only roster display.

## Religious content and UI boundary

Thirty numbered parts are identifiers, not generated Quran content. Any navigation uses the existing canonical juz mapping. Group actions do not call personal KhatmahRepository, progress use cases, SRS or achievements. Add boundary tests plus before/after persisted personal-state tests.

Completion card loads existing KhatmDuaDatasource and displays dua only when its existing approval contract passes. Missing/pending/unapproved content shows no dua and cannot be opened through a fallback/deep link. Do not create, paraphrase, import, translate, or change approved religious assets. Standard localized UI labels, Arabic RTL, 320dp layout, accessibility, and both ARB languages apply.

## Required approval and validation gates

The owner approved these proposed defaults together with this document on 2026-10-23 before K1:

1. Trusted adult eligibility source/provisioner (proposed: administrative initial cohort, unknown denied).
2. Private definer implementations plus public invoker wrappers, operation receipts, membership epochs, and extended RPC arguments beyond the original draft.
3. Owner cannot leave with other members; sole-owner leave deletes group; owner account deletion deletes owned groups. Completed groups allow privacy exit only.
4. Code lifetime/sharing, throttle defaults, retention, Unicode length contract/title limit, and stale offline roster policy.

Architecture review in `.superpowers/sdd/2026-10-22-roadmap-phase-3/task-K0-review.md` identified three P1 and three P2 gaps. This revision addresses them with create-specific receipt lookup, account-lifetime gone tombstones, concrete deletion-RPC/FK ordering, epoch-bound replay, explicit revisions and per-operation retries. Reviewer recheck is pending; these are design resolutions, not tested implementations. K0 document completion is not K0 gate completion.

After approval, K1 must test on isolated PostgreSQL with at least owner A, member B, outsider C, child/unknown/anonymous, and expired/deleted sessions:

- Every SELECT and public/private function grant; direct writes denied; no recursive-policy error; members who are not owners can read, outsiders cannot. No hidden broad grants or stale overloads after rerun.
- Concurrent claims and 30th/31st joins with separate sessions/transactions; exactly one winner. SQL text inspection alone is insufficient.
- Complete versus leave/release/final completion; eligibility revocation; epoch change on rejoin; stale work never revives.
- Lost acknowledgements and duplicate operation IDs including conflicting payloads and creation; success commits once and survives restart.
- Lost create acknowledgement → sole-owner deletion → retry original operation returns gone without a new group. Old join/part receipts after leave/rejoin return stale_operation and cannot replace the current epoch.
- Group revision advances exactly once for every specified visible transition and stays unchanged for replay/conflict; part revisions advance on release/anonymization cleanup.
- Full 30-part creation, constraints, code collisions, malformed inputs, names, rate limit counters that survive denials.
- Member/owner account deletion and FK cascades preserve intended progress/privacy; no deletion deadlocks or orphan claims; stale JWT denied.
- Migration twice, advisor checks, exact signature grants/search paths, and contract scripts. No new exposed definer functions.

K2–K4 cover offline persistence/restart, queue terminal handling with unrelated pending groups, A→B→A, backup exclusion, membership disappearance/pagination, approved-dua gate, UI conflicts and personal-data immutability. K5 requires its own owner approval at execution. Feature activation also retains Phase 2 and real-device gates.

## Current primary sources checked

Checked 2026-10-23. The lightweight `changelog.md` fetch failed (unsupported Markdown in browser; shell DNS unavailable). The HTML [Supabase changelog](https://supabase.com/changelog) was read instead, including breaking-change entries. Its April 28 Data API exposure change is directly relevant: explicit privileges must be tested rather than assuming public tables are exposed. The linked detail could not be opened in this session; recheck it before K1. This does not establish the project's actual configuration.

- [RLS guidance](https://supabase.com/docs/guides/database/postgres/row-level-security): active-membership policies need a private, caller-bound helper to avoid recursion; its execution role must actually bypass the recursive policy.
- [Database functions](https://supabase.com/docs/guides/database/functions): empty search path, qualification, privilege revocation, and explicit authorization are independent requirements; definer functions can bypass RLS.
- [Securing the API](https://supabase.com/docs/guides/api/securing-your-api): grants control reachability separately from RLS; default function EXECUTE is a privilege hazard.
- [User management](https://supabase.com/docs/guides/auth/managing-user-data): use auth-user references and deliberate deletion behavior. This design's owner-deletion policy is a product proposal, not a Supabase requirement.

Verification status: source-inspected design only. No SQL executed, no runtime/security/concurrency claims, and no deployment approval implied.
