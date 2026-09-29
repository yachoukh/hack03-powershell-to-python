# Behavior specification

## Scope

Resource groups are evaluated only when their name starts with `-NamePrefix` / `--name-prefix` and all tag filter key-value pairs match. Name-prefix checks, tag-filter key lookups, and tag-filter value comparisons are case-insensitive to match the PowerShell script's `OrdinalIgnoreCase` prefix comparison, case-insensitive hashtables, and default case-insensitive `-ne` comparison. Hackathon runs use:

- Name prefix: `rg-copilot-hack-stale-`
- Tag filter: `purpose=copilot-hackathon`

## Classification priority

Apply the first matching rule:

1. `Protected`: protected tag name (default `doNotDelete`) has value `true`, `1`, or `yes`.
2. `Expired`: `expiresOn` is a valid `yyyy-MM-dd` date earlier than `AsOfDate`.
3. `Stale`: `lastReviewed` is a valid `yyyy-MM-dd` date earlier than `AsOfDate - StaleAfterDays`.
4. `MissingOwner`: `owner` tag is missing or blank.
5. `Invalid`: `expiresOn` or `lastReviewed` is present but not parseable as `yyyy-MM-dd`.
6. `Ok`: no policy condition matched.

`Expired`, `Stale`, and `MissingOwner` are cleanup candidates. `Protected`, `Invalid`, and `Ok` are skipped.

Classification tag names (`owner`, `expiresOn`, `lastReviewed`, and the configured protected tag name) are looked up case-insensitively. Truthy protected-tag values are also case-insensitive.

## Actions

- `Skipped`: no delete intent or the status is not a cleanup candidate.
- `WouldDelete`: delete intent was supplied but execution was prevented by WhatIf/dry-run confirmation.
- `Deleted`: delete intent and confirmation were supplied and the deletion call succeeded.

Python requires both `--delete` and `--yes` before deletion.

If a confirmed Python deletion call fails for one resource group, the failure is logged as a warning, that row's action remains `Skipped`, and processing continues so the CSV report is still written.

## CSV columns

The report column order is exact: `SubscriptionId`, `ResourceGroup`, `Location`, `Owner`, `ExpiresOn`, `LastReviewed`, `ResourceCount`, `Status`, `Reason`, `Action`.
