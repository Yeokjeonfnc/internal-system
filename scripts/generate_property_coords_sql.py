#!/usr/bin/env python3
"""Generate SQL to update property_mst.latitude/longitude from store_map_points.json."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def load_stores(json_path: Path) -> list[dict]:
    text = json_path.read_text(encoding="utf-8")
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        fixed, count = re.subn(
            r'("lng":[-\d.]+),","polygon"',
            r'\1,"type":"POLYGON","polygon"',
            text,
        )
        if count == 0:
            raise
        data = json.loads(fixed)
    stores = data.get("stores", [])
    if not stores:
        raise ValueError(f"No stores found in {json_path}")
    return stores


def sql_literal(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def generate_sql(stores: list[dict]) -> str:
    lines = [
        "BEGIN;",
        "",
        "-- property_mst 좌표를 store_map_points.json 의 lat/lng 로 갱신",
        "-- 매칭: store_mst.store_nm = JSON name -> store_mst.prop_idx -> property_mst",
        "",
        "CREATE TEMP TABLE _store_map_coords (",
        "    store_nm varchar(100) PRIMARY KEY,",
        "    latitude numeric(10,7) NOT NULL,",
        "    longitude numeric(10,7) NOT NULL",
        ");",
        "",
        "INSERT INTO _store_map_coords (store_nm, latitude, longitude) VALUES",
    ]

    values: list[str] = []
    seen: set[str] = set()
    for store in stores:
        name = (store.get("name") or "").strip()
        lat = store.get("lat")
        lng = store.get("lng")
        if not name or lat is None or lng is None:
            continue
        if name in seen:
            continue
        seen.add(name)
        values.append(
            f"({sql_literal(name)}, {float(lat):.7f}, {float(lng):.7f})"
        )

    if not values:
        raise ValueError("No valid store coordinates to export")

    for i, value in enumerate(values):
        suffix = "," if i < len(values) - 1 else ";"
        lines.append(f"    {value}{suffix}")

    lines.extend(
        [
            "",
            "-- property_mst + store_mst 둘 다 갱신 (지도는 store_mst 좌표를 우선 사용)",
            "UPDATE property_mst pm",
            "   SET latitude = c.latitude,",
            "       longitude = c.longitude,",
            "       update_dt = CURRENT_TIMESTAMP",
            "  FROM store_mst sm",
            "  JOIN _store_map_coords c ON c.store_nm = sm.store_nm",
            " WHERE pm.prop_idx = sm.prop_idx",
            "   AND sm.prop_idx IS NOT NULL;",
            "",
            "UPDATE store_mst sm",
            "   SET latitude = c.latitude,",
            "       longitude = c.longitude,",
            "       updated_at = CURRENT_TIMESTAMP",
            "  FROM _store_map_coords c",
            " WHERE c.store_nm = sm.store_nm;",
            "",
            "DROP TABLE _store_map_coords;",
            "",
            "COMMIT;",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--json",
        type=Path,
        default=root / "assets" / "data" / "store_map_points.json",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=root / "deploy" / "db" / "007_property_mst_coords_from_store_map.sql",
    )
    args = parser.parse_args()

    stores = load_stores(args.json)
    sql = generate_sql(stores)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(sql, encoding="utf-8")
    print(f"stores: {len(stores)}")
    print(f"written: {args.out}")


if __name__ == "__main__":
    main()
