#!/usr/bin/env python3
"""
Merge multiple collection.json files into one.

Usage:
    uv run python3 scripts/merge_collections.py file1.json file2.json ... --out merged.json

Duplicates are detected by (type, name, vendor, caliberInch, weightGrain) for ammo,
and by (name, vendor) for sights/weapons. Duplicates from later files are skipped.
IDs are reassigned sequentially to avoid collisions.
"""

import argparse
import json
import sys
from pathlib import Path


def _ammo_key(a: dict) -> tuple:
    return (
        a.get("type", ""),
        (a.get("name") or "").strip().lower(),
        (a.get("vendor") or "").strip().lower(),
        round(a.get("caliberInch") or 0, 3),
        round(a.get("weightGrain") or 0, 1),
    )


def _named_key(item: dict) -> tuple:
    return (
        (item.get("name") or "").strip().lower(),
        (item.get("vendor") or "").strip().lower(),
    )


def _caliber_key(c: dict) -> tuple:
    return ((c.get("caliberName") or "").strip().lower(),)


def merge(paths: list[Path]) -> dict:
    ammo: list[dict] = []
    sights: list[dict] = []
    weapons: list[dict] = []
    calibers: list[dict] = []

    seen_ammo: set[tuple] = set()
    seen_sights: set[tuple] = set()
    seen_weapons: set[tuple] = set()
    seen_calibers: set[tuple] = set()

    for path in paths:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        for a in data.get("ammo", []):
            k = _ammo_key(a)
            if k not in seen_ammo:
                seen_ammo.add(k)
                ammo.append(a)

        for s in data.get("sights", []):
            k = _named_key(s)
            if k not in seen_sights:
                seen_sights.add(k)
                sights.append(s)

        for w in data.get("weapon", []):
            k = _named_key(w)
            if k not in seen_weapons:
                seen_weapons.add(k)
                weapons.append(w)

        for c in data.get("calibers", []):
            k = _caliber_key(c)
            if k not in seen_calibers:
                seen_calibers.add(k)
                calibers.append(c)

    # Reassign IDs sequentially
    for i, a in enumerate(ammo, start=1):
        a["id"] = i
    for i, s in enumerate(sights, start=1):
        s["id"] = i
    for i, w in enumerate(weapons, start=1):
        w["id"] = i

    calibers.sort(key=lambda c: (c.get("caliberName") or ""))

    return {"sights": sights, "weapon": weapons, "ammo": ammo, "calibers": calibers}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="Input collection JSON files")
    parser.add_argument("--out", required=True, help="Output file path")
    args = parser.parse_args()

    paths = [Path(p) for p in args.files]
    for p in paths:
        if not p.exists():
            print(f"ERROR: not found: {p}", file=sys.stderr)
            sys.exit(1)

    result = merge(paths)
    out = Path(args.out)

    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"ammo:     {len(result['ammo'])}")
    print(f"sights:   {len(result['sights'])}")
    print(f"weapons:  {len(result['weapon'])}")
    print(f"calibers: {len(result['calibers'])}")
    print(f"→ {out}")


if __name__ == "__main__":
    main()
