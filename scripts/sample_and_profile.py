#!/usr/bin/env python3
"""Stream a large UserBehavior CSV/ZIP, profile it, and reservoir-sample it."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import random
import sys
import time
import zipfile
from collections import Counter
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import BinaryIO, Iterator
from zoneinfo import ZoneInfo


COLUMNS = ("user_id", "item_id", "category_id", "behavior", "timestamp")
VALID_BEHAVIORS = {b"pv", b"fav", b"cart", b"buy"}
SHANGHAI = ZoneInfo("Asia/Shanghai")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Profile and reservoir-sample UserBehavior.csv without loading it into Pandas."
    )
    parser.add_argument("--input", required=True, type=Path, help="CSV or ZIP input path")
    parser.add_argument("--rows", type=int, default=1_000_000, help="development sample rows")
    parser.add_argument("--smoke-rows", type=int, default=10_000, help="smoke sample rows")
    parser.add_argument("--seed", type=int, default=42, help="fixed random seed")
    parser.add_argument("--output-dir", type=Path, default=Path("data/sample"))
    parser.add_argument("--profile", type=Path, default=Path("docs/profile.md"))
    return parser.parse_args()


@contextmanager
def open_source(path: Path) -> Iterator[tuple[BinaryIO, str]]:
    if path.suffix.lower() == ".zip":
        archive = zipfile.ZipFile(path)
        csv_entries = [n for n in archive.namelist() if n.lower().endswith(".csv")]
        if len(csv_entries) != 1:
            archive.close()
            raise ValueError(f"ZIP must contain exactly one CSV, found: {csv_entries}")
        stream = archive.open(csv_entries[0], "r")
        try:
            yield stream, csv_entries[0]
        finally:
            stream.close()
            archive.close()
    else:
        with path.open("rb") as stream:
            yield stream, path.name


def display_time(timestamp: int | None) -> str:
    if timestamp is None:
        return "N/A"
    try:
        # datetime.fromtimestamp() on Windows can reject negative Unix values.
        # Epoch arithmetic still lets us display them and classify them as
        # parseable-but-business-invalid timestamps.
        utc_value = datetime(1970, 1, 1, tzinfo=timezone.utc) + timedelta(seconds=timestamp)
        return utc_value.astimezone(SHANGHAI).isoformat(sep=" ")
    except (OverflowError, OSError, ValueError):
        return "invalid"


def write_atomic(path: Path, lines: list[bytes]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    with temp.open("wb") as handle:
        for line in lines:
            handle.write(line.rstrip(b"\r\n") + b"\n")
    temp.replace(path)


def count_duplicates(lines: list[bytes]) -> int:
    normalized = (line.rstrip(b"\r\n") for line in lines)
    seen: set[bytes] = set()
    duplicates = 0
    for line in normalized:
        if line in seen:
            duplicates += 1
        else:
            seen.add(line)
    return duplicates


def main() -> int:
    args = parse_args()
    if args.rows <= 0 or args.smoke_rows <= 0:
        raise ValueError("--rows and --smoke-rows must be positive")
    if args.smoke_rows > args.rows:
        raise ValueError("--smoke-rows cannot be larger than --rows")
    if not args.input.is_file():
        raise FileNotFoundError(args.input)

    rng = random.Random(args.seed)
    started = time.perf_counter()
    total_rows = 0
    valid_column_rows = 0
    bad_column_rows = 0
    reservoir: list[bytes] = []
    reservoir_weight: float | None = None
    rows_until_replacement = 0

    print(f"Input: {args.input}", flush=True)
    print(f"Sample rows: {args.rows:,}; seed: {args.seed}", flush=True)

    with open_source(args.input) as (stream, entry_name):
        for raw_line in stream:
            total_rows += 1
            # Keep the full-file pass cheap. Detailed field parsing is done on
            # the uniform 1M sample and later repeated on full data in Hive.
            if raw_line.count(b",") != len(COLUMNS) - 1:
                bad_column_rows += 1
                continue

            valid_column_rows += 1
            if len(reservoir) < args.rows:
                reservoir.append(raw_line)
                if len(reservoir) == args.rows:
                    # Vitter's Algorithm L keeps an exact uniform reservoir while
                    # skipping most random-number work after the reservoir is full.
                    reservoir_weight = math.exp(math.log(rng.random()) / args.rows)
                    rows_until_replacement = math.floor(
                        math.log(rng.random()) / math.log1p(-reservoir_weight)
                    )
            else:
                if rows_until_replacement > 0:
                    rows_until_replacement -= 1
                else:
                    reservoir[rng.randrange(args.rows)] = raw_line
                    assert reservoir_weight is not None
                    reservoir_weight *= math.exp(math.log(rng.random()) / args.rows)
                    rows_until_replacement = math.floor(
                        math.log(rng.random()) / math.log1p(-reservoir_weight)
                    )

            if total_rows % 5_000_000 == 0:
                elapsed = time.perf_counter() - started
                rate = total_rows / elapsed if elapsed else 0
                print(
                    f"Processed {total_rows:,} rows | {elapsed:.1f}s | {rate:,.0f} rows/s",
                    flush=True,
                )

    if len(reservoir) < args.rows:
        print(
            f"Warning: requested {args.rows:,} rows but source supplied {len(reservoir):,} valid rows.",
            file=sys.stderr,
        )

    output_dir = args.output_dir.resolve()
    profile_path = args.profile.resolve()
    dev_path = output_dir / "user_behavior_1m.csv"
    smoke_path = output_dir / "user_behavior_10k.csv"
    manual_path = output_dir / "manual_check_20.csv"

    write_atomic(dev_path, reservoir)
    smoke_rng = random.Random(args.seed + 1)
    smoke_count = min(args.smoke_rows, len(reservoir))
    smoke_lines = smoke_rng.sample(reservoir, smoke_count)
    write_atomic(smoke_path, smoke_lines)

    null_counts = [0] * len(COLUMNS)
    behavior_counts: Counter[str] = Counter()
    invalid_integer_rows = 0
    min_timestamp: int | None = None
    max_timestamp: int | None = None
    for raw_line in reservoir:
        fields = raw_line.rstrip(b"\r\n").split(b",")
        if len(fields) != len(COLUMNS):
            continue
        for index, value in enumerate(fields):
            if value.strip() == b"":
                null_counts[index] += 1
        behavior = fields[3].strip()
        behavior_counts[behavior.decode("utf-8", errors="replace")] += 1
        try:
            int(fields[0])
            int(fields[1])
            int(fields[2])
            timestamp = int(fields[4])
        except ValueError:
            invalid_integer_rows += 1
        else:
            min_timestamp = timestamp if min_timestamp is None else min(min_timestamp, timestamp)
            max_timestamp = timestamp if max_timestamp is None else max(max_timestamp, timestamp)

    sample_duplicates = count_duplicates(reservoir)
    smoke_duplicates = count_duplicates(smoke_lines)
    manual_count = min(20, len(reservoir))
    manual_lines = random.Random(args.seed + 2).sample(reservoir, manual_count)
    manual_path.parent.mkdir(parents=True, exist_ok=True)
    with manual_path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.writer(handle)
        writer.writerow((*COLUMNS, "event_time_shanghai"))
        for raw_line in manual_lines:
            fields = raw_line.rstrip(b"\r\n").decode("utf-8").split(",")
            try:
                converted = display_time(int(fields[4]))
            except (IndexError, ValueError):
                converted = "invalid"
            writer.writerow((*fields, converted))

    invalid_behavior_rows = sum(
        count for behavior, count in behavior_counts.items() if behavior.encode() not in VALID_BEHAVIORS
    )
    elapsed = time.perf_counter() - started
    profile_path.parent.mkdir(parents=True, exist_ok=True)
    profile_text = f"""# UserBehavior 数据画像

生成时间：{datetime.now(SHANGHAI).isoformat(sep=' ', timespec='seconds')}  
输入文件：`{args.input.resolve()}`  
ZIP 内 CSV：`{entry_name}`  
抽样方法：Vitter Algorithm L 蓄水池随机抽样（等概率、跳跃式）  
固定随机种子：`{args.seed}`  
扫描耗时：`{elapsed:.1f}` 秒

## 1. 全量轻量统计

| 项目 | 结果 |
|---|---:|
| 总物理行数 | {total_rows:,} |
| 正好 5 列的行数 | {valid_column_rows:,} |
| 非 5 列行数 | {bad_column_rows:,} |
| 详细字段画像 | 在固定随机 100 万样本上统计；全量字段质量在 Hive 阶段复核 |

## 2. 固定随机 100 万样本画像

| 项目 | 结果 |
|---|---:|
| 整数字段解析失败行数 | {invalid_integer_rows:,} |
| 非法 behavior 行数 | {invalid_behavior_rows:,} |
| 最小时间戳 | {min_timestamp if min_timestamp is not None else 'N/A'} |
| 最小时间（Asia/Shanghai） | {display_time(min_timestamp)} |
| 最大时间戳 | {max_timestamp if max_timestamp is not None else 'N/A'} |
| 最大时间（Asia/Shanghai） | {display_time(max_timestamp)} |

### 空值统计

| 字段 | 空值行数 |
|---|---:|
"""
    for column, count in zip(COLUMNS, null_counts):
        profile_text += f"| {column} | {count:,} |\n"

    profile_text += "\n### behavior 枚举\n\n| behavior | 行数 |\n|---|---:|\n"
    for behavior, count in behavior_counts.most_common():
        profile_text += f"| `{behavior}` | {count:,} |\n"

    profile_text += f"""

## 3. 样本文件

| 文件 | 行数 | 样本内完整重复行数 | 用途 |
|---|---:|---:|---|
| `data/sample/user_behavior_10k.csv` | {len(smoke_lines):,} | {smoke_duplicates:,} | 建表、导入、SQL 冒烟测试 |
| `data/sample/user_behavior_1m.csv` | {len(reservoir):,} | {sample_duplicates:,} | 指标开发与分布观察 |
| `data/sample/manual_check_20.csv` | {manual_count:,} | - | 人工检查字段和时区 |

说明：完整重复行数是在样本内精确计算的，不代表全量文件的重复总数。全量字段质量和重复检查放到 Hive/DWD 阶段完成，避免用单机 Python 为全量画像付出不成比例的时间与内存。

## 5. 需要你人工填写的结论

- [ ] 是否存在字段错位：
- [ ] behavior 是否只有四种合法枚举：
- [ ] 主要时间范围与异常时间判断：
- [ ] 抽查 20 行的时区转换是否正常：
- [ ] 这份数据不能支持哪些业务指标：
"""
    temp_profile = profile_path.with_suffix(profile_path.suffix + ".tmp")
    temp_profile.write_text(profile_text, encoding="utf-8")
    temp_profile.replace(profile_path)

    manifest = {
        "input": str(args.input.resolve()),
        "zip_entry": entry_name,
        "seed": args.seed,
        "total_rows": total_rows,
        "sample_rows": len(reservoir),
        "smoke_rows": len(smoke_lines),
        "generated_at": datetime.now(SHANGHAI).isoformat(),
        "outputs": {
            "development_sample": str(dev_path),
            "smoke_sample": str(smoke_path),
            "manual_check": str(manual_path),
            "profile": str(profile_path),
        },
        "sha256": {
            "development_sample": hashlib.sha256(dev_path.read_bytes()).hexdigest(),
            "smoke_sample": hashlib.sha256(smoke_path.read_bytes()).hexdigest(),
        },
    }
    manifest_path = profile_path.parent / "source_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Completed in {elapsed:.1f}s", flush=True)
    print(f"Profile: {profile_path}", flush=True)
    print(f"Development sample: {dev_path}", flush=True)
    print(f"Smoke sample: {smoke_path}", flush=True)
    print(f"Manual check: {manual_path}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
