# /// script
# requires-python = ">=3.11"
# dependencies = ["pandas>=2.0"]
# ///
"""api/ と csv/ 配下の全 CSV について、ヘッダ列名と「全行が空文字または欠損」の列を抽出する。
中身（実データ）は出力に含めない。中身を見る前にペア対応・空列分布を機械的に確認するためのスクリプト。

使い方:
    uv run inspect_headers.py --api-dir <path> --csv-dir <path>

出力 (JSON):
    {
      "api": [{file, rows, n_cols, columns, blank_columns, date_hint_columns}, ...],
      "csv": [...]
    }

date_hint_columns は「date / time / 日 / 時 / year / month」を列名に含む列のリスト。
マージキー or 日付集計列の候補としてユーザーに提示する。
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import pandas as pd


def is_blank_series(s: pd.Series) -> bool:
    """ヘッダ以外の全セルが空文字または欠損なら True。"""
    if s.isna().all():
        return True
    s2 = s.astype("string").fillna("").str.strip()
    return bool((s2 == "").all())


def inspect(path: Path) -> dict:
    df = pd.read_csv(path, dtype=str, keep_default_na=True)
    cols = list(df.columns)
    blanks = [c for c in cols if is_blank_series(df[c])]
    date_hints = [
        c
        for c in cols
        if any(k in c.lower() for k in ["date", "日", "時", "year", "month", "time"])
    ]
    return {
        "file": path.name,
        "rows": len(df),
        "n_cols": len(cols),
        "columns": cols,
        "blank_columns": blanks,
        "date_hint_columns": date_hints,
    }


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--api-dir", required=True, type=Path, help="API ダンプ CSV のディレクトリ")
    p.add_argument("--csv-dir", required=True, type=Path, help="CSV エクスポートのディレクトリ")
    args = p.parse_args()

    out: dict[str, list[dict]] = {"api": [], "csv": []}
    for sub, dir_ in [("api", args.api_dir), ("csv", args.csv_dir)]:
        files = sorted([p for p in dir_.glob("*.csv") if not p.name.startswith(".")])
        for fp in files:
            out[sub].append(inspect(fp))
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
