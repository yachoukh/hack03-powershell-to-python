import pytest


@pytest.mark.challenge
@pytest.mark.skip(reason="Challenge 3: remove skip after porting classification logic")
def test_classifies_expired_resource_group() -> None:
    raise AssertionError("Write the parity assertion here.")


@pytest.mark.challenge
@pytest.mark.skip(reason="Challenge 4: remove skip after generating parity cases from Pester")
def test_classification_priority_matches_pester_cases() -> None:
    raise AssertionError("Write generated parity cases here.")


@pytest.mark.challenge
@pytest.mark.skip(reason="Challenge 6: remove skip after implementing CSV report parity")
def test_writes_csv_with_legacy_columns() -> None:
    raise AssertionError("Write the CSV parity assertion here.")
