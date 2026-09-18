# Runtime Investigation Workflow

Build an environment matrix only as wide as the incident requires:

- Debug / Profile / Release.
- fresh install/data / existing user state.
- online / offline / degraded network.
- Arabic / English.
- cold / warm start.
- relevant device / OS / platform version.

Narrow one variable at a time. Record which combinations reproduce the issue. Gather logs/state at component boundaries before changing code. Do not bundle multiple speculative fixes because that destroys causal evidence.
