# Testing & QA

Select tests by domain and risk:

- unit/domain: deterministic business logic, mappings, schedulers, serializers.
- widget: UI behavior, state presentation, accessibility-sensitive interactions.
- integration: persistence, repository boundaries, plugins, Supabase/RLS, migrations.
- runtime/E2E: lifecycle, navigation, audio, primary Quran journeys, upgrade paths.

For reproducible bugs, add a regression test when practical. For UI changes, explicitly validate Arabic RTL and English LTR, text scaling, long content, small screens, loading/empty/error states, and navigation/back behavior where relevant.
