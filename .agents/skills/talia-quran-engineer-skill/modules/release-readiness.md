# Release Readiness

Release review can include analyzer/tests, release build, critical-flow smoke, permissions, notifications, privacy disclosures, account deletion when applicable, background/audio behavior, deep links, offline/poor-network behavior, signing/build variants, Supabase compatibility, and upgrade from an existing install/data state.

Refresh target SDK, store policy, privacy, platform, and signing requirements from official current sources. A fresh install alone is not sufficient when users upgrade from persisted local/remote state.

Use `Release Verified` only when the release-specific checks actually run; otherwise report what remains not verified.
