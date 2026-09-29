# Hack 03: PowerShell to Python stale-resource cleanup

Beginner GitHub Copilot hackathon repo for converting a real Azure cleanup automation from PowerShell to Python. The legacy script, `legacy/Invoke-StaleResourceCleanup.ps1`, scans Azure resource groups, classifies stale or policy-violating groups from tags, writes a CSV report, and can delete eligible groups only when explicitly requested.

- Azure DevOps org: <https://dev.azure.com/azultechlab>
- Participant project: `Copilot-Hackathon`
- Facilitator project: `Copilot-Hackathon-Facilitator`
- Repo: `hack03-powershell-to-python`
- Region: `swedencentral`
- Service connection: `sc-copilot-hack-sandbox`

## Why this scenario works for a hackathon

- **Real migration work** — teams port a production-shaped PowerShell runbook, not a toy kata.
- **Small but deep** — the core is tag filtering, date parsing, classification, CSV parity, and safe deletion boundaries.
- **Safe by design** — the participant path is report-only; destructive behavior is guarded and tested offline.
- **Great Copilot lesson** — Copilot can accelerate the port, but participants must verify SDK imports, PowerShell `-WhatIf` semantics, case-insensitive Azure tags, paged iterators, and date parsing.
- **Demoable** — a final dry run produces reports that can be compared against the legacy script with `tools/compare_reports.py` on the `solution` branch.

## Prerequisites

| Need | Notes |
|---|---|
| GitHub Copilot | Individual, Business, or Enterprise with Chat enabled in VS Code. |
| Python 3.12.x | Use Python 3.12 explicitly. The hosted pipeline uses 3.12, and newer local runtimes such as 3.13/3.14 can force Azure SDK native dependencies to build from source instead of installing wheels. |
| PowerShell 7 + Pester | Needed to inspect and run the legacy non-destructive unit tests. |
| Azure CLI login | Required only for report-only Azure dry runs against the seeded sandbox groups. |
| Contributor on sandbox RGs | Contributor is limited to `rg-copilot-hack-stale-01` through `rg-copilot-hack-stale-04`; do not run deletes during the hackathon. |
| VS Code + recommended extensions | Install the recommendations in `.vscode/extensions.json`. |
| MCP in VS Code | `.vscode/mcp.json` wires Microsoft Learn MCP and Azure MCP so Copilot can ground PowerShell cmdlet semantics and Azure SDK shapes in real docs instead of guessing. |

## Branches

| Branch | Purpose |
|---|---|
| `main` | Participant starter: legacy PowerShell, behaviour docs, starter Python stubs, and skipped pytest placeholders. |
| `solution` | Facilitator/reference implementation: completed Python, full test suite, golden report fixture, and `tools/compare_reports.py`. |
| `ready/<team>` | Participant completion branch. The Azure DevOps parity stage runs on `solution` and `ready/*` only. |

## Starter kit

| File or folder | What it is |
|---|---|
| `legacy/Invoke-StaleResourceCleanup.ps1` | Original PowerShell script to explain, test, and port. |
| `legacy/tests/` | Offline Pester tests for classification priority. |
| `docs/behavior-spec.md` | The migration contract: scope filtering, classification priority, actions, and CSV columns. |
| `docs/conversion-checklist.md` | PowerShell-to-Python idiom map, including the `-WhatIf` report-writing trap. |
| `python/src/stale_cleanup/` | Starter Python package with TODOs on `main` and a complete implementation on `solution`. |
| `python/tests/test_starter_skips.py` | Starter skipped tests that participants should replace while solving the challenges. |
| `playground/` | Planted-defect review exercise: a naive port that is importable but deliberately unsafe and wrong. |
| `.github/skills/` | Copilot skills for Azure sandbox conventions and PowerShell-to-Python parity work. |
| `.vscode/mcp.json` | Microsoft Learn MCP and Azure MCP configuration for VS Code Copilot Chat. |
| `azure-pipelines.yml` | Lint/test pipeline; report parity dry run for `solution` and `ready/*` branches. |

## Quick start

```powershell
git checkout main
# Use a Python 3.12 interpreter explicitly; `python --version` must print 3.12.x.
python --version
python -m venv .venv
.\.venv\Scripts\Activate.ps1
cd python
python -m pip install --upgrade pip
python -m pip install -e ".[dev]"
ruff check .
ruff format --check .
pytest
```

Run legacy non-destructive checks if PowerShell modules are available:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
Install-Module Pester -Scope CurrentUser -Force -SkipPublisherCheck
Invoke-ScriptAnalyzer -Path legacy -Recurse -Severity Error,Warning
Invoke-Pester legacy\tests
```

The pipeline and the participant exercises never delete resources. Facilitators create and remove seed resource groups with scripts in `seed/`; participants should not run `seed/teardown-stale-rgs.ps1`.

## Challenge path and judging

- Start with [CHALLENGES.md](CHALLENGES.md) for the 5-level ladder and suggested Copilot prompts.
- Judges use [RUBRIC.md](RUBRIC.md) for weighted scoring.
- Facilitators use [FACILITATOR.md](FACILITATOR.md) for setup, demos, seeded resources, and teardown.

## Suggested one-day agenda

| Time | Item |
|---|---|
| 09:00 | Kickoff: why migration parity matters and how Copilot helps without replacing verification. |
| 09:30 | Preflight: create venv, install package, run starter pytest, inspect Pester tests. |
| 10:00 | Level 1: explain the PowerShell script and behaviour spec. |
| 11:00 | Level 2: port pure models, classification, and report writing. |
| 13:00 | Level 3: prove parity with golden reports and the planted-defect playground. |
| 14:30 | Level 4: CLI parity, safe Azure report-only run, and pipeline cleanup. |
| 16:00 | Level 5 wildcards and polish. |
| 16:45 | Demos, judging, and wrap-up. |

## What good looks like

A strong submission keeps behaviour parity ahead of refactoring. It has fixture-driven tests for every classification status, handles Azure tag keys case-insensitively, always writes the report during dry runs, requires explicit `--delete --yes` before destructive calls, continues after one delete failure, and can explain every Copilot suggestion it accepted or rejected.

## Reference material

- PowerShell `ShouldProcess`, `-WhatIf`, and `-Confirm`: <https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute>
- Azure Resource Management client library for Python: <https://learn.microsoft.com/python/api/overview/azure/mgmt-resource-readme>
- `azure-mgmt-resource` package: <https://pypi.org/project/azure-mgmt-resource/>
- pytest: <https://docs.pytest.org/>
- Microsoft Learn MCP server: <https://learn.microsoft.com/api/mcp>
- Azure MCP server: <https://github.com/Azure/azure-mcp>
