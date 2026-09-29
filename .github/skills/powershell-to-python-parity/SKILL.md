---
name: powershell-to-python-parity
description: Use when porting a PowerShell automation script to Python and behaviour parity matters, especially for Azure scripts with ShouldProcess, WhatIf, CSV output, tags, dates, and destructive operations.
---

# PowerShell to Python parity

Use this skill before accepting a Python port of a PowerShell automation script. The goal is not idiomatic Python first; it is **observable behaviour parity first**, then safe refactoring.

## Start with a behaviour contract

- Identify parameters, defaults, validation, environment fallbacks, and exit behaviour.
- List every output shape: objects, streams, files, CSV headers, ordering, and log messages that callers depend on.
- Freeze time-dependent logic with an explicit `as_of` argument in both implementations.
- Separate pure logic from runtime calls so parity can be tested offline.

## `ShouldProcess`, `-WhatIf`, and `-Confirm`

PowerShell functions with `SupportsShouldProcess` can be called with `-WhatIf` and `-Confirm`. In Python, model this explicitly:

- Default to dry-run/report-only.
- Require a positive intent flag for destructive operations, such as `--delete`.
- Require a second confirmation flag, such as `--yes`, for unattended deletion.
- Return or report `WouldDelete` separately from `Deleted` and `Skipped`.

Watch the cascade trap: PowerShell `-WhatIf` propagates to every nested cmdlet that supports `ShouldProcess`, including `New-Item` and `Export-Csv`. If the PowerShell script uses `-WhatIf:$false` for report-writing cmdlets, the Python dry-run must mirror that intent: **skip deletes, but still create directories and write reports**.

## `$ErrorActionPreference` and exceptions

PowerShell may continue on non-terminating errors unless `-ErrorAction Stop` or `$ErrorActionPreference = 'Stop'` is used. Python SDK calls normally raise exceptions. Map the intended behaviour deliberately:

- Fail fast for setup errors such as authentication or subscription selection.
- Catch per-item failures only when the original script continues per item.
- Preserve report writing after a recoverable item failure.
- Do not swallow exceptions and report success unless the original script truly did so.

## Case sensitivity

PowerShell hashtables and many comparisons are case-insensitive by default. Python dictionaries and string equality are case-sensitive.

- Normalize tag keys for lookup, but preserve original values for report output when required.
- Compare Azure tag keys case-insensitively.
- Compare Azure tag filter values according to the original script; many PowerShell `-eq` / `-ne` comparisons are case-insensitive.
- Add tests with mixed-case keys such as `LastReviewed`, `OWNER`, and `DoNotDelete`.

## Pipeline and streaming semantics

PowerShell pipelines stream objects, but many scripts materialize with `@(...)` to count or sort. Python ports should decide intentionally:

- Use iterators/generators for large data when order is not important.
- Materialize when you need sorting, stable reporting, or multiple passes.
- Azure SDK list operations are often paged iterators; consume the full iterator, not just the first page.

## CSV parity

PowerShell `Export-Csv` writes headers from object properties and quotes fields predictably. Python should use `csv.DictWriter`.

- Define field names explicitly and test the exact header order.
- Use `newline=""` when opening files for `csv`.
- Decide how `None`, empty strings, numbers, and dates are serialized.
- Sort rows if the original report sorted rows.

## Dates and culture

PowerShell may use culture-sensitive parsing unless `TryParseExact` with `InvariantCulture` is used. Python ports should avoid locale surprises.

- Prefer `datetime.strptime(value, "%Y-%m-%d").date()` for strict tag dates.
- Treat blank or missing tags as missing, not invalid, if the source does.
- Record malformed non-blank date tags and test their priority relative to other rules.
- Avoid `date.today()` in tests; pass a fixed date.

## Parity testing strategy

- Port existing Pester tests into table-driven pytest cases.
- Add fixtures for edge cases PowerShell hides, such as mixed-case tag keys.
- Use fakes for Azure clients; do not call cloud APIs in unit tests.
- Generate golden reports from known fixtures and compare CSV output by content and column order.
- Include negative tests for destructive operations: dry-run writes the report, delete requires explicit confirmation, and failed deletes do not become false successes.
