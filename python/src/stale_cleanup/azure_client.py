from typing import Protocol

from stale_cleanup.models import ResourceGroup


class AzureResourceClient(Protocol):
    def list_resource_groups(
        self, *, name_prefix: str, tag_filter: dict[str, str]
    ) -> list[ResourceGroup]: ...

    def count_resources(self, resource_group_name: str) -> int: ...

    def delete_resource_group(self, resource_group_name: str) -> None: ...


class AzureSdkResourceClient:
    def __init__(self, subscription_id: str) -> None:
        self.subscription_id = subscription_id
        raise NotImplementedError("Challenge 5: wire azure-identity and azure-mgmt-resource here.")
