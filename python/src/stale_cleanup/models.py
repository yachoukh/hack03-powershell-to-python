from dataclasses import dataclass
from datetime import date

CSV_COLUMNS = [
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
]


@dataclass(frozen=True)
class ResourceGroup:
    name: str
    location: str
    tags: dict[str, str]


@dataclass(frozen=True)
class Classification:
    status: str
    reason: str
    eligible_for_delete: bool


@dataclass(frozen=True)
class ReportRow:
    subscription_id: str
    resource_group: str
    location: str
    owner: str
    expires_on: str
    last_reviewed: str
    resource_count: int
    status: str
    reason: str
    action: str


def parse_tag_date(value: str | None) -> date | None:
    raise NotImplementedError("Challenge 3: port the PowerShell date parsing logic.")
