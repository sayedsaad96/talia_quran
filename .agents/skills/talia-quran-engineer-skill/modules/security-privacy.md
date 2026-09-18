# Security & Privacy

Protect secrets, auth tokens, user progress/history, recordings, family/kids data, and personal identifiers.

Never commit or log secrets. Never expose server/admin/service credentials to the Flutter client. Verify authorization server-side (for example RLS) rather than trusting client UI state.

For external AI/services ask: what leaves the device, is it personal/audio/Quran-related, is transfer necessary, can deterministic/local handling solve it, and how is retention/consent handled? Minimize data and redact diagnostics.
