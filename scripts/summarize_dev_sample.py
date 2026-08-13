#!/usr/bin/env python3
"""Print entity-scale checks for the fixed 1M development sample."""

from pathlib import Path


SAMPLE = Path(__file__).resolve().parents[1] / "data" / "sample" / "user_behavior_1m.csv"


def main() -> None:
    users: set[bytes] = set()
    items: set[bytes] = set()
    categories: set[bytes] = set()

    with SAMPLE.open("rb") as handle:
        for raw_line in handle:
            fields = raw_line.rstrip(b"\r\n").split(b",")
            users.add(fields[0])
            items.add(fields[1])
            categories.add(fields[2])

    print(f"users={len(users)}")
    print(f"items={len(items)}")
    print(f"categories={len(categories)}")


if __name__ == "__main__":
    main()

