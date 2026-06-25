# Talia Quran Supabase Runtime Readiness Checklist

This checklist is for staging/production verification before enabling account
deletion, guardian linking, parent dashboard, or cloud sync features. Do not use
real production credentials in automated tests.

## Source Contracts

- Parent/child linking and kids cloud sync schema: `supabase_schema.sql`
- Account deletion RPC: `docs/backend/delete_current_user_rpc.sql`
- Flutter callers:
  - `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - `lib/features/memorization_plus/data/repositories/memorization_plus_repository_impl.dart`

## Required RPC Functions

These functions must exist in `public`, revoke `anon`, and grant execute to
`authenticated`:

- `delete_current_user()`
- `create_child_link_request_with_hash(text)`
- `accept_child_link_token_with_hash(text)`
- `upsert_kids_progress_cloud(integer, integer, integer, integer, integer, timestamptz)`
- `insert_kids_session_log(text, integer, integer, integer, integer, timestamptz)`
- `upsert_ayah_progress(jsonb)`
- `upsert_streak(integer, integer, date, integer)`
- `upsert_xp(integer)`
- `upsert_daily_activities_batch(jsonb)`

## Required Tables

- `profiles`
- `ayah_progress`
- `streaks`
- `xp`
- `daily_activities`
- `child_link_requests`
- `parent_child_links`
- `kids_progress_cloud`
- `kids_session_logs`
- `parent_rewards`

## Required RLS Policies

RLS must be enabled on all user-data tables. Verify these effective behaviors:

- Users can read/write only their own `ayah_progress`, `streaks`, `xp`, and
  `daily_activities`.
- Children can read their own pending child link requests.
- Parents and children can read active rows in `parent_child_links` that include
  their own `auth.uid()`.
- Children can read their own `kids_progress_cloud` and `kids_session_logs`.
- Parents can read linked child progress/logs only through an active
  `parent_child_links` row.
- Parents can manage `parent_rewards` only for actively linked children.
- Children can read their own `parent_rewards`.
- Linked parents can read the linked child `profiles.display_name`.

## Required Indexes

- `idx_ayah_progress_user` on `ayah_progress(user_id)`
- `idx_ayah_progress_review` on `ayah_progress(user_id, next_review_date)`
- `idx_daily_activities_user` on `daily_activities(user_id, day_key DESC)`
- `idx_child_link_requests_child` on
  `child_link_requests(child_user_id, created_at DESC)`
- `idx_child_link_requests_token` on `child_link_requests(token_hash)` where
  `used_at IS NULL`
- `idx_parent_child_links_child` on `parent_child_links(child_user_id)`
- `idx_kids_session_logs_child` on
  `kids_session_logs(child_user_id, completed_at DESC)`
- `idx_parent_rewards_child` on `parent_rewards(child_user_id, created_at DESC)`

## Staging Smoke Checks

Run these checks with staging accounts only:

- Signed-out client cannot execute any authenticated RPC.
- Signed-in user can create and accept a child link token from a different
  account.
- A child account cannot link to itself as parent.
- A parent can see only children linked through active `parent_child_links`.
- A child can sync kids progress and one unsynced session log.
- A parent can add/list rewards only for an actively linked child.
- `delete_current_user()` deletes only the current authenticated user and returns
  an error when no authenticated user is present.
- When `delete_current_user()` fails, the app must keep local auth-scoped state
  instead of pretending deletion succeeded.

## Known Follow-Ups

- `supabase_schema.sql` and `docs/backend/delete_current_user_rpc.sql` are
  separate contracts today. Before release, apply both to staging and production
  or merge them into one ordered migration set.
- Email confirmation is intentionally not required by the app configuration.
