# Judging rubric

| Criterion | Weight | What judges look for |
|---|---:|---|
| Behaviour parity with the original | 30% | Classification priority, case-insensitive tags, CSV column order, action values, and CLI behavior match the PowerShell contract. |
| Test quality | 25% | Tests are offline, fixture-driven, meaningful, and prove parity rather than only covering happy paths. Golden report comparison catches real regressions. |
| Copilot leverage | 20% | The team used Copilot prompts effectively, verified suggestions against docs/MCP, and caught the `-WhatIf` cascade, case-sensitive tag, paged iterator, and SDK import traps. |
| Safety of destructive operations | 15% | Dry-run/report-only is the default, delete requires explicit confirmation, scope filters are strict, delete failures are handled, and no live destructive tests were run. |
| Demo and storytelling | 10% | The demo clearly explains the migration risk, evidence gathered, tradeoffs made, and how the final solution would be operated. |

## What judges will ask

- Which behaviours did you preserve exactly, and where are they tested?
- How did you prove Azure tag keys are handled case-insensitively?
- How does your Python design avoid the PowerShell `-WhatIf` report-writing cascade bug?
- What prevents a participant or pipeline from deleting arbitrary resource groups?
- How do you handle malformed or missing `lastReviewed` and `expiresOn` tags?
- Which Copilot suggestion did you reject or correct, and why?
- Did you check the `azure-mgmt-resource` 26+ import path against current documentation?
- How would you extend this for scheduled report-only operation without increasing blast radius?
