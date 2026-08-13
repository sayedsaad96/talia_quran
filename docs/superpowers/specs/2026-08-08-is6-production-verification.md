# IS-6 Production Verification — Memorization Identity Isolation

**Date:** 2026-08-08  
**Branch:** `fix/memorization-identity-isolation`  
**Auditor:** production-auditor + source reachability / isolation / security agents  
**Decision:** **CONDITIONAL GO** (cloud blockers B1–B3 cleared; residual warnings remain)

## Exit gate answers

| Question | Answer | Gate |
|---|---|---|
| One Memorization Plus system for visible Adult/Kids? | Yes | PASS |
| Full Adult/Kids and user isolation locally? | Yes | PASS |
| Full Adult/Kids cloud uniqueness live remotely? | Yes — `unique_user_audience_ayah_review` applied on `Talia_Quran` | PASS |
| No legacy Hifz UI/writes affecting production? | Yes (data/migration retained by design) | PASS with WARN |
| Complete restore + conflict-safe sync in client? | Yes for reviews/plans/certs/kids | PASS |
| Complete restore on live backend? | Yes — 0007 + 0008 applied and verified | PASS |

## Production readiness score

**Client isolation track: 8.5 / 10**  
**Cloud production readiness: 8.5 / 10** (0007/0008 live; advisor WARNs are pre-existing SECURITY DEFINER RPC pattern)  
**Overall release decision: CONDITIONAL GO**

## Remote apply evidence (2026-08-08)

Project: `Talia_Quran` (`vxsqwozctxkvhgxkciua`) — restored to `ACTIVE_HEALTHY`.

Applied via Supabase MCP:

| Migration | Remote name | Version |
|---|---|---|
| 0007 | `review_record_audience_identity` | `20260808022034` |
| 0008 | `custom_plans_cloud` | `20260808022042` |

Verified live:

- `ayah_review_records_cloud.audience` generated column present
- Unique constraint `UNIQUE (user_id, audience, surah_id, ayah_number)`
- `upsert_ayah_review_records` targets `unique_user_audience_ayah_review`
- `custom_plans_cloud` exists with RLS enabled and 2 policies

## Automated client evidence

Focused suites + IS-6 checklist test remain green for identity, sync, auth restore order, and Hifz retirement.

## Advisors after apply

- **Security:** WARN on intentional `SECURITY DEFINER` RPCs callable by `authenticated` (including `upsert_ayah_review_records`) — expected app pattern; anon execute revoked. Also WARN: leaked password protection disabled in Auth ([docs](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)).
- **Performance:** INFO unused indexes (fresh restore); WARN multiple permissive SELECT policies for owner+parent (by design).

No new ERROR-level advisors from 0007/0008.

## Remaining warnings (non-blocking)

1. Legacy Hifz data/migration package retained until upgrade window is proven complete.
2. Certificate cloud mirror has no audience column (adult merge + local kids recompute by design).
3. Daily/custom plan clouds are one row per user (adult product surface).
4. Enable Auth leaked-password protection when convenient.
5. Uncommitted IS-2…IS-5 client work still needs commit/ship.

## Go / No-Go

**CONDITIONAL GO** for cloud-backed production of the isolation track, pending:

- Shipping the uncommitted client changes on `fix/memorization-identity-isolation`
- Accepting deferred Hifz package retention and cert-audience design
