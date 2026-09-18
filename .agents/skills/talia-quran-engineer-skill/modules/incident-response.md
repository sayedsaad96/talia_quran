# Incident Response

## Incident Types

Crash, runtime exception, data corruption, state inconsistency, performance regression, build/dependency regression, Supabase/auth/database failure, Quran integrity, audio/background lifecycle, navigation, platform-specific, release regression, unknown.

## Severity

`SEV-0` critical integrity/security/data loss; `SEV-1` major user-impacting failure; `SEV-2` limited/intermittent degradation; `SEV-3` low-impact issue.

## Reproducibility

`R0` not reproduced; `R1` once; `R2` intermittent; `R3` consistent.

Containment is not a fix. First limit further damage when needed, then gather evidence, measure blast radius, compare environment dimensions (build mode, fresh/existing data, locale, network, device/OS), and trace root cause.

For data corruption, preserve recoverable data and understand the corruption mechanism before repair. Quran integrity incidents use Critical handling and deterministic broader-range verification. Add an incident record only when future prevention/learning value is material.
