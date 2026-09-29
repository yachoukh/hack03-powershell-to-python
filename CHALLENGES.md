# Challenges

Teams climb the ladder as far as they can. Keep evidence as you go: prompts, rejected Copilot suggestions, tests, reports, and pipeline links. The maximum score is 100 points.

## Level 1 — Understand the original (20 pts)

### Challenge 1.1 — Explain the legacy script

**Goal:** Use Copilot to explain `legacy/Invoke-StaleResourceCleanup.ps1`, then restate the behaviour in your own words.

**Suggested Copilot prompts:**

- `@workspace /explain legacy/Invoke-StaleResourceCleanup.ps1`
- `@workspace summarize the classification priority, delete flow, and CSV output columns`

**Success criteria:** You can explain scope filtering, classification priority, dry-run/delete behavior, CSV columns, and why Azure calls must be isolated from unit tests.

**Hints:** Focus on `Get-ResourceGroupClassification`, `Test-TagFilter`, `ConvertTo-CleanupReportRow`, and `ShouldProcess`.

### Challenge 1.2 — Verify the behaviour spec

**Goal:** Compare the script and Pester tests with `docs/behavior-spec.md` and note any gaps before porting.

**Suggested Copilot prompts:**

- `@workspace compare docs/behavior-spec.md with legacy/tests/Invoke-StaleResourceCleanup.Tests.ps1`
- `Which behaviours are acceptance criteria for a Python port?`

**Success criteria:** You identify the six statuses, the exact CSV column order, cleanup candidate statuses, and the action values `Skipped`, `WouldDelete`, and `Deleted`.

**Hints:** The behaviour spec is the contract. Refactors are fine only after parity is protected.

### Challenge 1.3 — Run the starter checks

**Goal:** Get the starter Python package importable and run the offline tests.

**Suggested Copilot prompts:**

- `@workspace what is the smallest local setup for this Python package?`
- `Why are the starter tests skipped on main?`

**Success criteria:** `python -m pip install -e ".[dev]"` succeeds from `python/`, `pytest` runs, and the skipped starter tests remain skipped until you implement the challenges.

**Hints:** If available, run `Invoke-Pester legacy\tests` too. Do not run Azure deployments, deletes, or teardown scripts.

## Level 2 — Port the logic (25 pts)

### Challenge 2.1 — Implement the data model and date parsing

**Goal:** Complete the model helpers so Python can represent resource groups, classifications, report rows, and strict `yyyy-MM-dd` tag dates.

**Suggested Copilot prompts:**

- `Port ConvertTo-TagDate to Python using datetime.date and strict yyyy-MM-dd parsing`
- `Generate pytest boundary cases for blank, missing, valid, and malformed tag dates`

**Success criteria:** Blank or missing date tags behave like PowerShell `$null`; malformed non-blank dates are detected without crashing the whole run.

**Hints:** Use an explicit `as_of_date` in tests to avoid date-dependent failures.

### Challenge 2.2 — Port classification exactly

**Goal:** Implement `classify_resource_group` so `Protected`, `Expired`, `Stale`, `MissingOwner`, `Invalid`, and `Ok` match the documented priority.

**Suggested Copilot prompts:**

- `/explain Get-ResourceGroupClassification and port only the pure logic`
- `Generate table-driven pytest cases from the Pester examples plus invalid-date priority cases`

**Success criteria:** Classifications match the spec exactly, including protected truthy values, malformed/missing `lastReviewed`, and the rule that invalid dates are reported after owner checks.

**Hints:** Azure tag keys are case-insensitive. A naive Python `tags["lastReviewed"]` lookup misclassifies groups tagged `LastReviewed`, `lastreviewed`, or `LASTREVIEWED`.

### Challenge 2.3 — Write reports with legacy CSV parity

**Goal:** Convert classifications to CSV rows with the same values and column order as the PowerShell script.

**Suggested Copilot prompts:**

- `Use csv.DictWriter with the exact field order from stale_cleanup.models.CSV_COLUMNS`
- `Write pytest coverage for report directory creation and empty tag values`

**Success criteria:** The CSV header and row values match `docs/behavior-spec.md`, directories are created as needed, and the report is still written during dry runs.

**Hints:** PowerShell `-WhatIf` cascades to every `ShouldProcess` cmdlet, including `Export-Csv` and `New-Item`. The legacy script uses `-WhatIf:$false` on those cmdlets so dry runs still write reports. Your Python dry-run must also skip deletes but always write the report.

## Level 3 — Prove parity (25 pts)

### Challenge 3.1 — Turn Pester intent into pytest evidence

**Goal:** Build a fixture-driven pytest suite that proves the Python port preserves PowerShell behavior.

**Suggested Copilot prompts:**

- `/tests generate pytest cases from legacy/tests/Invoke-StaleResourceCleanup.Tests.ps1`
- `Add cases for case-insensitive tag keys and malformed dates without changing the public API`

**Success criteria:** Tests cover every status, priority tie, safe action, and CSV column. Tests do not call Azure.

**Hints:** Keep Azure behind `AzureResourceClient` or fakes. Mock paged iterators rather than using live subscriptions.

### Challenge 3.2 — Compare golden reports

**Goal:** On the `solution` branch, use `tools/compare_reports.py` to compare a PowerShell report and a Python report generated for the same inputs.

**Suggested Copilot prompts:**

- `@workspace explain how tools/compare_reports.py decides parity`
- `Create a minimal golden CSV fixture that proves status, reason, and action parity`

**Success criteria:** Golden report comparison fails on meaningful differences and passes when the reports are equivalent after sorting.

**Hints:** Use the same `--as-of-date` / `-AsOfDate` for both implementations.

### Challenge 3.3 — Planted-defect playground

**Goal:** Review `playground/naive_port.py` with Copilot, rank the issues by severity, write failing tests that prove each bug, then fix them.

**Suggested Copilot prompts:**

- `Review playground/naive_port.py for behavior parity and safety defects; rank by blast radius`
- `Write tests that prove the dry-run report bug and case-sensitive tag bug before fixing them`

**Success criteria:** You can explain at least five defects, including the two real migration traps: `-WhatIf`-style report suppression and case-sensitive Azure tag lookup.

**Hints:** Use `.vscode/mcp.json` to ask Microsoft Learn MCP about PowerShell `ShouldProcess` and Azure SDK docs instead of trusting an ungrounded guess.

## Level 4 — Production-shaped (20 pts)

### Challenge 4.1 — CLI parity and validation

**Goal:** Make the Python CLI mirror the PowerShell parameters while staying safe by default.

**Suggested Copilot prompts:**

- `Implement argparse options matching the PowerShell params and validate --stale-after-days 1..3650`
- `Define CLI exit codes for success, validation errors, and unexpected failures`

**Success criteria:** `stale-cleanup --help` shows expected options, `--stale-after-days` rejects invalid values, and deletion requires both `--delete` and `--yes`.

**Hints:** Default behavior is report-only. Never make delete the default.

### Challenge 4.2 — Resilience and Azure boundaries

**Goal:** Keep processing and writing the report even when one confirmed delete fails.

**Suggested Copilot prompts:**

- `Use the AzureResourceClient protocol to fake delete failures and assert the report still writes`
- `Check the azure-mgmt-resource import path against current docs`

**Success criteria:** A failed delete logs a warning, that row remains `Skipped`, later rows continue, and the final CSV is written.

**Hints:** `azure-mgmt-resource` 26+ uses `from azure.mgmt.resource.resources import ResourceManagementClient`. Copilot often suggests the older import path, which fails at runtime.

### Challenge 4.3 — Report-only Azure run and pipeline green

**Goal:** Run against the seeded `rg-copilot-hack-stale-0*` groups in report-only mode, then get the pipeline green.

**Suggested Copilot prompts:**

- `@workspace explain azure-pipelines.yml parity stage and why it runs only on solution/ready branches`
- `Use Azure MCP to confirm the SDK list and count calls without inventing parameters`

**Success criteria:** The local or pipeline run targets only `rg-copilot-hack-stale-` with `purpose=copilot-hackathon`, produces a report, and never deletes anything.

**Hints:** Do not run `seed/teardown-stale-rgs.ps1`. Do not test delete paths against live Azure, even with `-WhatIf`.

## Level 5 — Wildcards (10 pts)

### Challenge 5.1 — Choose a production enhancement

**Goal:** Add one useful improvement without weakening parity or safety.

**Suggested Copilot prompts:**

- `Add packaging metadata for a wheel and console script while preserving editable install`
- `Add structured logging with no secrets in log output`
- `Add --output json alongside CSV and keep CSV as the default`
- `Draft a GitHub Actions or Azure DevOps schedule that runs report-only`
- `Generate a Pester-to-pytest mapping report from the two test suites`

**Success criteria:** The enhancement is tested, documented, and does not change default report-only behavior.

**Hints:** A good wildcard improves operations or evaluator confidence; it does not add risky Azure mutation paths.
