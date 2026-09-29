from collections.abc import Iterable
from pathlib import Path

from stale_cleanup.models import ReportRow


def write_csv_report(path: Path, rows: Iterable[ReportRow]) -> None:
    raise NotImplementedError("Challenge 6: write CSV rows matching the legacy script.")
