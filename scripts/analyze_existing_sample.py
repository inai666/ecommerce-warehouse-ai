#!/usr/bin/env python3
"""Analyze the generated sample without rescanning the source ZIP."""

from collections import Counter
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


SAMPLE = Path(__file__).resolve().parents[1] / "data" / "sample" / "user_behavior_1m.csv"
TZ = ZoneInfo("Asia/Shanghai")
START = int(datetime(2017, 11, 25, tzinfo=TZ).timestamp())
END_EXCLUSIVE = int(datetime(2017, 12, 4, tzinfo=TZ).timestamp())


def main() -> None:
    inside = before = after = invalid = 0
    dates: Counter[str] = Counter()
    outlier_examples: list[str] = []

    with SAMPLE.open("rb") as handle:
        for raw_line in handle:
            fields = raw_line.rstrip(b"\r\n").split(b",")
            try:
                timestamp = int(fields[4])
            except (IndexError, ValueError):
                invalid += 1
                continue

            if START <= timestamp < END_EXCLUSIVE:
                inside += 1
                date = datetime.fromtimestamp(timestamp, TZ).date().isoformat()
                dates[date] += 1
            elif timestamp < START:
                before += 1
                if len(outlier_examples) < 5:
                    outlier_examples.append(raw_line.decode("utf-8").strip())
            else:
                after += 1
                if len(outlier_examples) < 10:
                    outlier_examples.append(raw_line.decode("utf-8").strip())

    total = inside + before + after + invalid
    print(f"sample={SAMPLE}")
    print(f"total={total:,}")
    print(f"main_range={inside:,}")
    print(f"before_range={before:,}")
    print(f"after_range={after:,}")
    print(f"invalid_timestamp={invalid:,}")
    print(f"outlier_rate={(before + after + invalid) / total:.6%}")
    print("date_distribution:")
    for date, count in sorted(dates.items()):
        print(f"  {date}: {count:,}")
    print("outlier_examples:")
    for row in outlier_examples:
        print(f"  {row}")


if __name__ == "__main__":
    main()

