# Memorization Remediation Decisions

| ID | Date | Decision | Rationale | Status |
|----|------|----------|-----------|--------|
| D4 | 2026-07-09 | Defer FSRS activation; production scheduling remains `ScheduleNextReviewUsecase` SM-2. | The V2 write path calls `ScheduleNextReviewUsecase` through `V2SessionReviewAdapter`; FSRS fields and analytics remain unwired to saves. | Accepted for Sprint 5 cleanup |