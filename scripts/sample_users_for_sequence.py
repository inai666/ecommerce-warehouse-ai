#!/usr/bin/env python3
"""Create a deterministic user-level sample while preserving every selected user's events."""

from __future__ import annotations

import argparse
import hashlib
import json
import time
import zipfile
from collections import Counter
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo


SHANGHAI = ZoneInfo("Asia/Shanghai")
HASH_SPACE = 10_000


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", type=Path, default=Path("data/sample/user_sequence_1pct.csv"))
    parser.add_argument("--manifest", type=Path, default=Path("docs/user_sequence_sample_manifest.json"))
    parser.add_argument("--basis-points", type=int, default=100, help="100 basis points = 1 percent")
    parser.add_argument("--seed", type=int, default=20260812)
    return parser.parse_args()


def selected(user_id: int, seed: int, basis_points: int) -> bool:
    # A fast deterministic 64-bit mixer. Selection is stable across Python versions.
    value = (user_id ^ seed) & 0xFFFFFFFFFFFFFFFF
    value ^= value >> 30
    value = (value * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    value ^= value >> 27
    value = (value * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    value ^= value >> 31
    return value % HASH_SPACE < basis_points


def main() -> int:
    args = parse_args()
    if not 1 <= args.basis_points <= HASH_SPACE:
        raise ValueError("--basis-points must be between 1 and 10000")
    if not args.input.is_file():
        raise FileNotFoundError(args.input)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    temp_output = args.output.with_suffix(args.output.suffix + ".tmp")
    started = time.perf_counter()
    source_rows = output_rows = malformed_rows = 0
    users: set[int] = set()
    behaviors: Counter[str] = Counter()
    minimum_ts: int | None = None
    maximum_ts: int | None = None

    with zipfile.ZipFile(args.input) as archive:
        entries = [name for name in archive.namelist() if name.lower().endswith(".csv")]
        if len(entries) != 1:
            raise ValueError(f"ZIP must contain exactly one CSV, found: {entries}")
        with archive.open(entries[0], "r") as source, temp_output.open("wb") as output:
            for raw_line in source:
                source_rows += 1
                fields = raw_line.rstrip(b"\r\n").split(b",")
                if len(fields) != 5:
                    malformed_rows += 1
                    continue
                try:
                    user_id = int(fields[0])
                except ValueError:
                    malformed_rows += 1
                    continue
                if selected(user_id, args.seed, args.basis_points):
                    output.write(raw_line.rstrip(b"\r\n") + b"\n")
                    output_rows += 1
                    users.add(user_id)
                    behaviors[fields[3].decode("ascii", errors="replace")] += 1
                    try:
                        timestamp = int(fields[4])
                    except ValueError:
                        pass
                    else:
                        minimum_ts = timestamp if minimum_ts is None else min(minimum_ts, timestamp)
                        maximum_ts = timestamp if maximum_ts is None else max(maximum_ts, timestamp)

                if source_rows % 10_000_000 == 0:
                    elapsed = time.perf_counter() - started
                    print(
                        f"Processed {source_rows:,}; selected {output_rows:,}; "
                        f"{source_rows / elapsed:,.0f} rows/s",
                        flush=True,
                    )

    temp_output.replace(args.output)
    elapsed = time.perf_counter() - started
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    manifest = {
        "input": str(args.input.resolve()),
        "output": str(args.output.resolve()),
        "sampling_unit": "user_id",
        "selection": "deterministic 64-bit mixed hash threshold",
        "seed": args.seed,
        "basis_points": args.basis_points,
        "nominal_user_rate": args.basis_points / HASH_SPACE,
        "source_rows": source_rows,
        "output_rows": output_rows,
        "selected_users": len(users),
        "malformed_rows": malformed_rows,
        "behavior_counts": dict(behaviors),
        "min_event_ts": minimum_ts,
        "max_event_ts": maximum_ts,
        "sha256": digest,
        "elapsed_seconds": round(elapsed, 3),
        "generated_at": datetime.now(SHANGHAI).isoformat(),
    }
    temp_manifest = args.manifest.with_suffix(args.manifest.suffix + ".tmp")
    temp_manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    temp_manifest.replace(args.manifest)

    print(f"Completed in {elapsed:.1f}s", flush=True)
    print(f"Rows: {output_rows:,}; users: {len(users):,}", flush=True)
    print(f"SHA-256: {digest}", flush=True)
    print(f"Output: {args.output.resolve()}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

