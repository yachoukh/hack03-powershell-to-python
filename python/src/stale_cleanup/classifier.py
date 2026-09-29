from datetime import date

from stale_cleanup.models import Classification


def classify_resource_group(
    tags: dict[str, str],
    *,
    stale_after_days: int = 30,
    protected_tag_name: str = "doNotDelete",
    as_of_date: date | None = None,
) -> Classification:
    raise NotImplementedError("Challenge 3: port Get-ResourceGroupClassification.")
