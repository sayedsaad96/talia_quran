# Bug Fix Workflow

1. **Reproduce** the exact symptom; record environment, state, frequency, error/stack, and recent relevant changes.
2. Collect component-boundary evidence and trace the **Root cause** backward from symptom to origin.
3. Compare with a known working pattern and state one hypothesis.
4. Add a failing **Regression test** when practical and verify it fails for the intended reason.
5. Apply the **Minimal fix** at the source of the problem; avoid unrelated refactors.
6. **Verify** the original symptom, the regression test, and nearby behavior that shares state/data.
7. Update prevention/knowledge only with verified findings.
