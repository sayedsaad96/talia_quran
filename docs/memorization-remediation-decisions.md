# Memorization Remediation Decisions

| ID | Date | Decision | Rationale | Status |
|----|------|----------|-----------|--------|
| D4 | 2026-07-09 | **Option A:** Defer FSRS activation; production scheduling remains `ScheduleNextReviewUsecase` (SM-2). Keep FSRS shadow classes for unit tests / future analytics; do **not** register them in DI or chain them on `saveReviewRecord`. | V2 write path is SM-2-only via `V2SessionReviewAdapter`. Grep confirms `FsrsStateTrackerUsecase` / `FsrsPredictionUsecase` are never DI-registered and never called on the production save path. Activating FSRS would be a separate product project. | Accepted — Sprint 5 (2026-07-12) |