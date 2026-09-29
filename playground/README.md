# Planted-defect playground

`naive_port.py` is a realistic first pass at porting the legacy cleanup script. It was written in a hurry, imports cleanly, and has guardrails so it cannot call live Azure or delete resources in the shipped state.

Your exercise:

1. Ask Copilot to review the file for behaviour-parity and safety defects.
2. Rank the issues by severity and blast radius.
3. Write failing tests that prove each issue.
4. Fix the implementation while preserving the contract in `docs/behavior-spec.md`.
5. Compare your findings with the answer key on the `solution` branch.

Hints for the review:

- Think about PowerShell behaviours that do not translate directly to Python.
- Check how Azure tags behave compared with Python dictionaries.
- Separate report-only runs from destructive operations.
- Look for failures that would be hidden from the final CSV report.

Do not run this against Azure. The module is intentionally not a supported CLI.
