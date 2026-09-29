# Seed resource groups

Facilitators run `seed-stale-rgs.ps1` after logging in with Azure CLI. The script creates exactly four resource groups in `swedencentral`, all tagged `purpose=copilot-hackathon`.

Run the seed script shortly before the event. `rg-copilot-hack-stale-02` and `rg-copilot-hack-stale-04` use the seed date for `lastReviewed`; after 30 days, `-02` no longer demonstrates the intended `Ok` status.

| Resource group | Key tags | Expected status |
| --- | --- | --- |
| `rg-copilot-hack-stale-01` | `expiresOn=2025-01-01`, owner present | `Expired` |
| `rg-copilot-hack-stale-02` | future `expiresOn`, `lastReviewed` today, owner present | `Ok` |
| `rg-copilot-hack-stale-03` | `lastReviewed=2025-06-01`, owner present | `Stale` |
| `rg-copilot-hack-stale-04` | no owner tag | `MissingOwner` |

Teardown uses `teardown-stale-rgs.ps1` and deletes only this exact numbered set.
