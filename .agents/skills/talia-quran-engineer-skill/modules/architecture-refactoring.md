# Architecture Refactoring

Use this decision order:

`local fix → minimal enabling refactor → architectural proposal`

Architecture change requires evidence of architectural pain: recurring defects, untestable coupling, duplicated responsibilities, unsafe data flow, or a change radius that cannot be contained locally.

Do not rewrite Talia because a newer framework or pattern exists. Follow current repository conventions unless there is measured or repeatedly observed pain.

If a small task unexpectedly expands across unrelated files/subsystems, stop the edit, reevaluate the root cause and change radius, and separate required enabling refactor from unrelated technical debt.
