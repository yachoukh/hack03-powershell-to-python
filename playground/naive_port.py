"""Naive stale-resource cleanup port used for review practice.

The file is importable for tests, but it is not a supported CLI and cannot reach Azure in
this repository state.
"""

from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Protocol

ALLOW_LIVE_AZURE = False
ALLOW_DELETE_PATH = False


@dataclass(frozen=True)
class ResourceGroup:
    name: str
    location: str
    tags: dict[str, str] | None


class CleanupClient(Protocol):
    def list_resource_groups(self) -> list[ResourceGroup]: ...

    def count_resources(self, resource_group_name: str) -> int: ...

    def delete_resource_group(self, resource_group_name: str) -> None: ...


def classify(tags: dict[str, str] | None, *, as_of: date, stale_after_days: int = 30) -> tuple[str, str, bool]:
    if tags["doNotDelete"].lower() in {"true", "1", "yes"}:
        return "Protected", "doNotDelete tag is true", False

    expires_on = datetime.strptime(tags["expiresOn"], "%Y-%m-%d").date() if tags.get("expiresOn") else None
    last_reviewed = datetime.strptime(tags["lastReviewed"], "%Y-%m-%d").date()

    if expires_on and expires_on < as_of:
        return "Expired", f"expiresOn {expires_on:%Y-%m-%d} is before {as_of:%Y-%m-%d}", True

    cutoff = as_of - timedelta(days=stale_after_days)
    if last_reviewed < cutoff:
        return "Stale", f"lastReviewed {last_reviewed:%Y-%m-%d} is before {cutoff:%Y-%m-%d}", True

    if not tags.get("owner", "").strip():
        return "MissingOwner", "owner tag is missing or blank", True

    return "Ok", "Resource group is within policy", False


def write_report(path: Path, rows: list[dict[str, object]], *, dry_run: bool) -> None:
    if dry_run:
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "SubscriptionId",
                "ResourceGroup",
                "Location",
                "Owner",
                "ExpiresOn",
                "LastReviewed",
                "ResourceCount",
                "Status",
                "Reason",
                "Action",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def run_cleanup(
    client: CleanupClient,
    *,
    subscription_id: str,
    report_path: Path,
    dry_run: bool = True,
    as_of: date | None = None,
) -> list[dict[str, object]]:
    as_of = as_of or date.today()
    rows: list[dict[str, object]] = []

    for group in client.list_resource_groups():
        if not group.name.startswith("rg-"):
            continue
        if group.tags and group.tags.get("purpose") != "copilot-hackathon":
            continue

        status, reason, eligible = classify(group.tags, as_of=as_of)
        action = "Skipped"

        if eligible:
            action = "Deleted"
            if ALLOW_DELETE_PATH:
                try:
                    client.delete_resource_group(group.name)
                except Exception:
                    pass

        rows.append(
            {
                "SubscriptionId": subscription_id,
                "ResourceGroup": group.name,
                "Location": group.location,
                "Owner": group.tags.get("owner", "") if group.tags else "",
                "ExpiresOn": group.tags.get("expiresOn", "") if group.tags else "",
                "LastReviewed": group.tags.get("lastReviewed", "") if group.tags else "",
                "ResourceCount": client.count_resources(group.name),
                "Status": status,
                "Reason": reason,
                "Action": action,
            }
        )

    write_report(report_path, rows, dry_run=dry_run)
    return rows


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Unsafe review playground; not a real CLI.")
    parser.add_argument("--i-understand-this-is-a-broken-playground", action="store_true")
    args = parser.parse_args(argv)
    if not args.i_understand_this_is_a_broken_playground or not ALLOW_LIVE_AZURE:
        raise SystemExit("This playground cannot run against Azure. Review it statically and with fakes.")
    raise SystemExit("Live Azure execution is disabled in the shipped playground.")


if __name__ == "__main__":
    main()
