# Performance

Performance claims require measurement.

`Define behavior → Baseline → Profile → Locate bottleneck → Change meaningful cause → Measure again → Report measured result`

Possible signals include startup, frame timing/jank, memory growth, database latency, duplicate network calls, audio start latency, expensive rebuilds, image decoding, and synchronous work on the UI path.

Static code review can identify a **risk**, not a measured defect. Report one of: `Measured improvement`, `Measured regression`, `No meaningful difference`, or `Not measured`.
