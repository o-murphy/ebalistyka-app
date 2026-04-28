#!/usr/bin/env python3
"""
Merge multiple collection.json files into one.

Usage:
    uv run python3 scripts/merge_collections.py file1.json file2.json ... --out merged.json [--map map.json] [--near-dupes]

--map map.json      Normalize caliberName values using a key→canonical alias map.
--near-dupes        After merging, print a report of potential partial duplicate ammo entries.

Duplicates are detected by (type, name, vendor, caliberInch, weightGrain) for ammo,
and by (name, vendor) for sights/weapons. Duplicates from later files are skipped.
IDs are reassigned sequentially to avoid collisions.

Partial duplicates strategy (--near-dupes):
  Ammo entries are grouped by (type, caliberInch±0.001, weightGrain±0.5).
  Within each group, pairs whose name tokens share a Jaccard similarity ≥ 0.5
  (or one name is a substring of the other) are reported as near-duplicates.
"""

import argparse
import json
import sys
from pathlib import Path


class FieldMaps:
    def __init__(self, caliber: dict[str, str], vendor: dict[str, str]) -> None:
        self.caliber = caliber
        self.vendor = vendor

    @classmethod
    def load(cls, map_path: Path) -> "FieldMaps":
        with open(map_path, encoding="utf-8") as f:
            raw = json.load(f)
        # Support both old flat format and new sectioned format
        if "caliberName" in raw or "vendor" in raw:
            return cls(
                caliber=raw.get("caliberName", {}),
                vendor=raw.get("vendor", {}),
            )
        return cls(caliber=raw, vendor={})

    def map_caliber(self, value: str | None) -> str | None:
        return self.caliber.get(value, value) if value else value

    def map_vendor(self, value: str | None) -> str | None:
        return self.vendor.get(value, value) if value else value


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


def merge(paths: list[Path], maps: FieldMaps) -> dict:
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
            a["caliberName"] = maps.map_caliber(a.get("caliberName"))
            a["vendor"] = maps.map_vendor(a.get("vendor"))
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
            c["caliberName"] = maps.map_caliber(c.get("caliberName"))
            k = _caliber_key(c)
            if k not in seen_calibers:
                seen_calibers.add(k)
                calibers.append(c)

    ammo.sort(key=lambda a: ((a.get("vendor") or "").lower(), (a.get("name") or "").lower()))
    sights.sort(key=lambda s: ((s.get("vendor") or "").lower(), (s.get("name") or "").lower()))
    weapons.sort(key=lambda w: ((w.get("vendor") or "").lower(), (w.get("name") or "").lower()))

    # Reassign IDs sequentially
    for i, a in enumerate(ammo, start=1):
        a["id"] = i
    for i, s in enumerate(sights, start=1):
        s["id"] = i
    for i, w in enumerate(weapons, start=1):
        w["id"] = i

    calibers.sort(key=lambda c: (c.get("caliberName") or ""))

    return {"sights": sights, "weapon": weapons, "ammo": ammo, "calibers": calibers}


# ---------------------------------------------------------------------------
# Partial-duplicate detection
# ---------------------------------------------------------------------------

def _token_set(text: str) -> set[str]:
    return set(text.lower().split())


def _jaccard(a: set, b: set) -> float:
    if not a and not b:
        return 1.0
    union = a | b
    return len(a & b) / len(union)


def find_near_dupes(ammo: list[dict], jaccard_threshold: float = 0.5) -> list[dict]:
    """
    Group ammo by (type, caliberInch bucket, weightGrain bucket) and return
    pairs whose names are suspiciously similar.

    caliberInch is bucketed to 2 decimal places (±0.005").
    weightGrain is bucketed to the nearest 0.5 gr.
    """
    from collections import defaultdict

    def _bucket(a: dict) -> tuple:
        return (
            a.get("type", ""),
            round(a.get("caliberInch") or 0, 2),
            round((a.get("weightGrain") or 0) * 2) / 2,  # nearest 0.5
        )

    groups: dict[tuple, list[dict]] = defaultdict(list)
    for a in ammo:
        groups[_bucket(a)].append(a)

    candidates = []
    for bucket, entries in groups.items():
        if len(entries) < 2:
            continue
        for i in range(len(entries)):
            for j in range(i + 1, len(entries)):
                a, b = entries[i], entries[j]
                name_a = (a.get("name") or "").strip()
                name_b = (b.get("name") or "").strip()
                tok_a = _token_set(name_a)
                tok_b = _token_set(name_b)
                sim = _jaccard(tok_a, tok_b)
                substring = name_a.lower() in name_b.lower() or name_b.lower() in name_a.lower()
                if sim >= jaccard_threshold or substring:
                    candidates.append({
                        "similarity": round(sim, 2),
                        "bucket": bucket,
                        "a": {"id": a.get("id"), "name": name_a, "vendor": a.get("vendor"), "caliberName": a.get("caliberName")},
                        "b": {"id": b.get("id"), "name": name_b, "vendor": b.get("vendor"), "caliberName": b.get("caliberName")},
                    })

    candidates.sort(key=lambda x: -x["similarity"])
    return candidates


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+", help="Input collection JSON files")
    parser.add_argument("--out", required=True, help="Output file path")
    parser.add_argument("--map", dest="map_file", help="Key→canonical alias map JSON (e.g. map.json)")
    parser.add_argument("--near-dupes", action="store_true", help="Print near-duplicate ammo report")
    parser.add_argument(
        "--near-dupes-threshold",
        type=float,
        default=0.5,
        metavar="T",
        help="Jaccard similarity threshold for near-dupe detection (default: 0.5)",
    )
    args = parser.parse_args()

    paths = [Path(p) for p in args.files]
    for p in paths:
        if not p.exists():
            print(f"ERROR: not found: {p}", file=sys.stderr)
            sys.exit(1)

    maps = FieldMaps(caliber={}, vendor={})
    if args.map_file:
        map_path = Path(args.map_file)
        if not map_path.exists():
            print(f"ERROR: map not found: {map_path}", file=sys.stderr)
            sys.exit(1)
        maps = FieldMaps.load(map_path)
        print(f"map:      {len(maps.caliber)} caliber aliases, {len(maps.vendor)} vendor aliases from {map_path}")

    result = merge(paths, maps)
    out = Path(args.out)

    with open(out, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=2)

    print(f"ammo:     {len(result['ammo'])}")
    print(f"sights:   {len(result['sights'])}")
    print(f"weapons:  {len(result['weapon'])}")
    print(f"calibers: {len(result['calibers'])}")
    print(f"→ {out}")

    if args.near_dupes:
        dupes = find_near_dupes(result["ammo"], jaccard_threshold=args.near_dupes_threshold)
        if not dupes:
            print("\nNo near-duplicate ammo found.")
        else:
            print(f"\nNear-duplicate ammo pairs ({len(dupes)} found, threshold={args.near_dupes_threshold}):")
            for d in dupes:
                t, ci, wg = d["bucket"]
                print(
                    f"  sim={d['similarity']:.2f} | {t} {ci}\" {wg}gr\n"
                    f"    [{d['a']['id']:>4}] {d['a']['vendor']} / {d['a']['name']}  [{d['a']['caliberName']}]\n"
                    f"    [{d['b']['id']:>4}] {d['b']['vendor']} / {d['b']['name']}  [{d['b']['caliberName']}]"
                )


if __name__ == "__main__":
    main()
