import argparse


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Report stale Azure resource groups.")
    parser.add_argument("--subscription-id")
    parser.add_argument("--name-prefix", default="rg-")
    parser.add_argument("--tag-filter", action="append", default=[])
    parser.add_argument("--stale-after-days", type=int, default=30)
    parser.add_argument("--report-path", default="stale-resource-groups.csv")
    parser.add_argument("--delete", action="store_true")
    parser.add_argument("--yes", action="store_true")
    parser.add_argument("--protected-tag-name", default="doNotDelete")
    parser.add_argument("--as-of-date")
    return parser


def main(argv: list[str] | None = None) -> int:
    build_parser().parse_args(argv)
    raise NotImplementedError("Challenge 6: implement the CLI orchestration.")
