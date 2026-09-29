# Conversion checklist

| PowerShell idiom | Python mapping |
| --- | --- |
| `param` blocks | `argparse` options and environment fallbacks |
| `ShouldProcess` / `WhatIf` | dry-run default; require `--delete --yes` for destructive calls |
| Splatting | keyword arguments / dictionaries (`**kwargs`) |
| `Where-Object` | comprehensions or generator filters |
| `Export-Csv` | `csv.DictWriter` with explicit field names |
| `Write-Verbose` | `logging` debug/info calls |
| `try` / `catch` | `try` / `except` |
| hashtable | `dict[str, str]` |

> **Gotcha:** `-WhatIf` propagates to every cmdlet that supports `ShouldProcess`, including `Export-Csv` and `New-Item`. The legacy script passes `-WhatIf:$false` to both so that the report is still written during a dry run. The Python port should keep that behavior: `--dry-run` skips deletes but always writes the report.

