# Password Recovery Redirect Contract

The app uses Supabase password recovery with an in-app redirect.

## Supabase URL Configuration

Add this URL to Supabase Dashboard:

- Authentication > URL Configuration > Redirect URLs
- `taliaquran://auth/update-password`

The app passes this value to `resetPasswordForEmail` as `redirectTo`.

Also verify the project Site URL is not set to an unrelated URL such as
`https://google.com`. If Supabase rejects or cannot match the `redirectTo`
value, the recovery email can fall back to the Site URL, which makes the reset
button open a blank browser page instead of returning to the app.

For alternate environments, override it at build time:

```bash
flutter build apk --dart-define=SUPABASE_PASSWORD_RECOVERY_REDIRECT_TO=taliaquran://auth/update-password
```

## Flow

1. User taps "Forgot password?".
2. Supabase sends a recovery email.
3. The recovery link opens `taliaquran://auth/update-password`.
4. `supabase_flutter` detects the recovery session from the link.
5. The app opens `/auth/update-password`.
6. User enters a new password.
7. The app calls `Supabase.auth.updateUser(UserAttributes(password: ...))`.
8. The user is signed out and returned to Login.

If the redirect URL is not allowed in Supabase, the email link may not return
to the app correctly.

## Troubleshooting

If tapping "Reset password" opens a browser at `google.com` or another unrelated
website:

1. In Supabase Dashboard, open Authentication > URL Configuration.
2. Add `taliaquran://auth/update-password` to Redirect URLs.
3. Remove unrelated values from Site URL, or set Site URL to a real app/web
   landing page that explains the app should open.
4. Send a fresh password recovery email after saving the Supabase settings.

The old email link can keep using the previous redirect settings, so always test
with a newly generated reset email.
