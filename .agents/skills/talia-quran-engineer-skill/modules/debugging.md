# Debugging

**No fixes without root cause investigation first.**

## Phase 1 — Root-cause investigation

Read the exact error/stack, reproduce, inspect recent changes, gather evidence at component boundaries, and trace bad data/state backward to its origin.

## Phase 2 — Pattern analysis

Find similar working code, compare assumptions/configuration/dependencies, and list meaningful differences.

## Phase 3 — Single-hypothesis testing

State one hypothesis and its evidence. Test the smallest possible change/experiment. Change one variable at a time.

## Phase 4 — Minimal fix and verification

Create a regression test when practical, implement the smallest root-cause fix, verify the original symptom and nearby regressions.

If **three** fix attempts fail, stop guessing and reevaluate the **architecture** and underlying assumptions before any fourth fix.
