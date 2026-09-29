# Agent guidance

Copilot CLI and Copilot coding agent read this file. Follow it before changing this repository.

## Conversion conventions

- Behaviour parity comes first; tests come before refactors.
- Treat `docs/behavior-spec.md` as the migration contract.
- Keep Azure SDK access behind `python/src/stale_cleanup/azure_client.py` and unit-test the rest with fakes.
- Preserve the legacy CSV columns and order from `stale_cleanup.models.CSV_COLUMNS`.
- Use explicit `as_of_date` values in tests to avoid time-dependent failures.

## Classification rules

Apply the first matching rule:

1. `Protected`: protected tag name, default `doNotDelete`, is `true`, `1`, or `yes`.
2. `Expired`: `expiresOn` is a valid `yyyy-MM-dd` date before `as_of_date`.
3. `Stale`: `lastReviewed` is a valid `yyyy-MM-dd` date before `as_of_date - stale_after_days`.
4. `MissingOwner`: `owner` tag is missing or blank.
5. `Invalid`: `expiresOn` or `lastReviewed` exists but is not parseable as `yyyy-MM-dd`.
6. `Ok`: no policy condition matched.

`Expired`, `Stale`, and `MissingOwner` are cleanup candidates. `Protected`, `Invalid`, and `Ok` are skipped.

## Sandbox resource groups

Hackathon Azure work is limited to the seeded `swedencentral` groups:

- `rg-copilot-hack-stale-01`
- `rg-copilot-hack-stale-02`
- `rg-copilot-hack-stale-03`
- `rg-copilot-hack-stale-04`

Filter by the `rg-copilot-hack-*` prefix and `purpose=copilot-hackathon` before considering any destructive operation.

## Always verify Copilot suggestions

- `azure-mgmt-resource` 26+ import path: `from azure.mgmt.resource.resources import ResourceManagementClient`.
- Azure tag keys are case-insensitive, while Python `dict` lookups are case-sensitive.
- PowerShell `-WhatIf` cascades to all `ShouldProcess` cmdlets, including `Export-Csv` and `New-Item`; reports must still be written during dry runs.
- Azure SDK resource listings are paged; consume the full iterator.
- Date parsing must be strict `yyyy-MM-dd` / `datetime.date`, not locale-dependent parsing.
- CSV writing should use `csv.DictWriter` with explicit columns and predictable quoting/newlines.

## Never do this

- Never delete outside the `rg-copilot-hack-*` prefix.
- Never make delete the default.
- Never run `seed/teardown-stale-rgs.ps1` during the hackathon, not even with `-WhatIf`.
- Never execute live Azure delete paths as validation.
- Never commit credentials, PATs, tenant IDs, subscription IDs, connection strings, or secret values.
