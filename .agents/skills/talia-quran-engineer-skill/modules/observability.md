# Observability

Collect only what is necessary to diagnose failures and performance: app version, device/OS, feature state, non-sensitive breadcrumbs, timings, error codes, and non-sensitive identifiers.

Do not log secrets, auth tokens, unnecessary personal data, private content, or unnecessary detailed worship/reading behavior.

Prioritize crashes, uncaught exceptions, critical-flow failures, startup/migration failures, audio errors, Supabase failures, and measured performance traces. Production-only bugs require better evidence, not guessed fixes.
