#!/usr/bin/env python3
"""Admit measured stride layouts; print C initializers for one architecture."""
import argparse
import csv
import statistics
import math
import gzip
from collections import defaultdict

OPERATIONS = {"add": 0, "add-scalar": 0, "subtract": 1, "multiply": 2, "divide": 3,
              "negate": 4, "abs": 5, "min": 8, "max": 9,
              "scale": 14, "axpy": 15, "fma": 16,
              "sum": 32, "dot": 33, "sum-wide": 96, "dot-wide": 97}


def load(paths):
    rows = {}
    for path in paths:
        with (gzip.open(path, "rt", newline="") if str(path).endswith(".gz") else open(path, newline="")) as stream:
            for row in csv.DictReader(stream):
                layout = tuple(int(row[k]) for k in ("d", "left", "right", "c"))
                key = (row["type"], row["operation"], layout, int(row["count"]),
                       row["mode"], int(row["offset"]), int(row["trial"]), row["variant"])
                if key in rows:
                    raise ValueError(f"duplicate measurement: {key}")
                value = float(row["time_us"])
                if not math.isfinite(value) or value <= 0:
                    raise ValueError(f"invalid timing: {key}")
                rows[key] = value
    return rows


def admissions(rows, variant):
    comparisons = defaultdict(list)
    for key, baseline in rows.items():
        if key[-1] != "general":
            continue
        other = (*key[:-1], variant)
        if other not in rows:
            raise ValueError(f"missing {variant} measurement: {key[:-1]}")
        comparisons[key[:-2]].append((key[-2], 1 - rows[other] / baseline))
    groups = defaultdict(dict)
    for (type_, operation, layout, count, mode, offset), trials in comparisons.items():
        if any(s < -2 or s > 2 for s in layout) or all(s >= 0 and s <= 1 for s in layout):
            continue
        gains = [gain for _, gain in trials]
        if {trial for trial, _ in trials} != set(range(5)):
            raise ValueError("each case needs five distinct paired trials")
        groups[type_, operation, layout][count, mode, offset] = (
            statistics.median(gains) >= (.10 if mode in ("pointer", "view") else -.05)
            and (mode not in ("pointer", "view") or sum(g >= .10 for g in gains) >= 4))
    accepted = []
    for (type_, operation, layout), cases in sorted(groups.items()):
        counts = sorted({key[0] for key in cases})
        if counts != [16, 64, 256, 1024, 4096, 16384, 65536]:
            raise ValueError(f"incomplete size sweep: {type_} {operation} {layout}")
        expected = {(count, mode, offset) for count in counts
                    for mode in (("pointer", "copy", "view", "alias") if variant == "dispatch" else
                                 ("pointer", "copy", "view") if count in (1024, 65536) else ("pointer",))
                    for offset in (0, 1)}
        if set(cases) != expected:
            raise ValueError(f"incomplete access/offset sweep: {type_} {operation} {layout}")
        for threshold in counts:
            eligible = [passes for (count, mode, _), passes in cases.items()
                        if count >= threshold and (variant == "dispatch" or mode != "copy")]
            if eligible and all(eligible):
                code = 0
                for stride in layout:
                    code = code * 5 + stride + 2
                key = (OPERATIONS[operation] * 2 + (type_ == "f64")) * 625 + code
                accepted.append((key, threshold, type_, operation, layout))
                break
    return sorted(accepted)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", nargs="+")
    parser.add_argument("--variant", choices=("candidate", "dispatch"), default="candidate")
    parser.add_argument("--lisp", action="store_true", help="emit benchmark case data")
    parser.add_argument("--header", choices=("arm64", "x86-64"), help="emit an architecture-gated C header")
    args = parser.parse_args()
    accepted = admissions(load(args.csv), args.variant)
    if args.lisp:
        print("(")
        for _, count, type_, operation, layout in accepted:
            print(f"(:{type_} :{operation} ({' '.join(map(str, layout))}) {count})")
        print(")")
        return
    if args.header:
        condition = "defined(__aarch64__) || defined(_M_ARM64)" if args.header == "arm64" else "defined(__x86_64__) || defined(_M_X64)"
        print(f"#if {condition}")
        print(f"#define TS_STRIDED_MEMORY_MIN_COUNT {min(row[1] for row in accepted) if accepted else 'SIZE_MAX'}")
    for key, count, type_, operation, layout in accepted:
        print(f"{{{key}, {count}}}, /* {type_} {operation} {','.join(map(str, layout))} */")
    if not accepted:
        print("{UINT32_MAX, SIZE_MAX}")
    if args.header:
        print("#else\n#define TS_STRIDED_MEMORY_MIN_COUNT SIZE_MAX\n{UINT32_MAX, SIZE_MAX}\n#endif")


if __name__ == "__main__":
    main()
