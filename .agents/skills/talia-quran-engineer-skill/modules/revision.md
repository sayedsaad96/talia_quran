# Revision

Own review scheduling, weak-ayah queues, due/overdue logic, mastery maintenance, persistence, and migration compatibility.

Changes affecting stored review state are High risk by default. Define the scheduling invariant before modifying algorithms; use deterministic tests for due dates, ordering, completion, weakness updates, and restoration. Preserve old user state or provide an explicit migration/recovery design.
