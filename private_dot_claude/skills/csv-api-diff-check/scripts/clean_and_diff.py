# /// script
# requires-python = ">=3.11"
# dependencies = ["pandas>=2.0"]
# ///
"""api/ (A 側) と csv/ (B 側) のペアを突き合わせ、空列削除 → キーマージ → 差分集計を行う。

スクリプトは雛形。利用時は PAIRS 配列を対象ファイル・キー・日付列に合わせて書き換える。
出力は集計値（行数・差分件数・キー集合サイズ・日付別行数）のみで、中身は出さない。

出力:
    _work/cleaned/<name>__{api,csv}.csv  — クリーンアップ済み CSV（後段の検証で再利用）
    _work/report.json                     — 集計結果（詳細）
    標準出力                              — コンパクトサマリ
"""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

import pandas as pd

# === ユーザーが書き換える箇所 ====================================
WORK = Path(__file__).resolve().parent
ROOT = WORK.parent  # 通常は base/_work/ 配下に置く想定
OUT_DIR = WORK / "cleaned"
OUT_DIR.mkdir(parents=True, exist_ok=True)


@dataclass
class Pair:
    name: str
    api_file: str  # ROOT/api/<api_file>
    csv_file: str  # ROOT/csv/<csv_file>
    keys: list[str]
    date_col: str  # 日付別行数集計の代表列（report に出る）
    date_keys: list[str] = field(default_factory=list)  # マージ前に日付正規化するキー列


# 例: 実際のペア定義に書き換えること
PAIRS: list[Pair] = [
    # Pair(
    #     name="deals",
    #     api_file="api_deals.csv",
    #     csv_file="csv_deals.csv",
    #     keys=["案件ID"],
    #     date_col="契約予定日",
    # ),
]
# ==================================================================


def is_blank_series(s: pd.Series) -> bool:
    if s.isna().all():
        return True
    s2 = s.astype("string").fillna("").str.strip()
    return bool((s2 == "").all())


def blank_columns(df: pd.DataFrame) -> list[str]:
    return [c for c in df.columns if is_blank_series(df[c])]


def normalize_for_compare(s: pd.Series) -> pd.Series:
    """文字列の余白・数値表現のゆらぎを軽く吸収する。
    例: "1.0" と "1" を同一視。形式の本格的な揃えは shim 側の責務。
    """
    out = s.astype("string").fillna("").str.strip()
    mask_num = out.str.fullmatch(r"-?\d+(\.\d+)?")

    def _norm_num(x: str) -> str:
        try:
            f = float(x)
            if f.is_integer():
                return str(int(f))
            return "%g" % f
        except Exception:
            return x

    out = out.where(~mask_num, out.map(_norm_num))
    return out


def safe_to_datetime(s: pd.Series) -> pd.Series:
    """和暦表記 (YYYY年MM月DD日) も吸収して datetime に変換。失敗は NaT。"""
    pre = (
        s.astype("string")
        .fillna("")
        .str.replace("年", "-", regex=False)
        .str.replace("月", "-", regex=False)
        .str.replace("日", "", regex=False)
        .str.strip()
    )
    return pd.to_datetime(pre, errors="coerce")


def process_pair(pair: Pair) -> dict:
    api_path = ROOT / "api" / pair.api_file
    csv_path = ROOT / "csv" / pair.csv_file

    api_df = pd.read_csv(api_path, dtype=str, keep_default_na=True)
    csv_df = pd.read_csv(csv_path, dtype=str, keep_default_na=True)

    api_blanks = blank_columns(api_df)
    csv_blanks = blank_columns(csv_df)

    # 空列削除ルール: A 起点で B にあれば両方削除、B 独自空列も削除（A に同名あれば A も削除）
    drop_from_api = set(api_blanks)
    drop_from_csv: set[str] = set()
    for c in api_blanks:
        if c in csv_df.columns:
            drop_from_csv.add(c)
    for c in csv_blanks:
        drop_from_csv.add(c)
        if c in api_df.columns:
            drop_from_api.add(c)

    api_clean = api_df.drop(columns=[c for c in drop_from_api if c in api_df.columns])
    csv_clean = csv_df.drop(columns=[c for c in drop_from_csv if c in csv_df.columns])

    api_clean.to_csv(OUT_DIR / f"{pair.name}__api.csv", index=False)
    csv_clean.to_csv(OUT_DIR / f"{pair.name}__csv.csv", index=False)

    common_cols = [c for c in api_clean.columns if c in csv_clean.columns]
    api_only_cols = [c for c in api_clean.columns if c not in csv_clean.columns]
    csv_only_cols = [c for c in csv_clean.columns if c not in api_clean.columns]

    missing_keys_api = [k for k in pair.keys if k not in api_clean.columns]
    missing_keys_csv = [k for k in pair.keys if k not in csv_clean.columns]
    key_ok = not missing_keys_api and not missing_keys_csv

    summary: dict = {
        "pair": pair.name,
        "api_file": pair.api_file,
        "csv_file": pair.csv_file,
        "rows": {"api": int(len(api_df)), "csv": int(len(csv_df))},
        "drop": {
            "api_blank_columns": api_blanks,
            "csv_blank_columns": csv_blanks,
            "dropped_from_api": sorted(drop_from_api),
            "dropped_from_csv": sorted(drop_from_csv),
        },
        "columns_after_clean": {
            "common": common_cols,
            "api_only": api_only_cols,
            "csv_only": csv_only_cols,
        },
        "keys": pair.keys,
        "key_ok": key_ok,
        "missing_keys": {"api": missing_keys_api, "csv": missing_keys_csv},
    }

    if not key_ok:
        summary["error"] = "key columns missing after cleanup"
        return summary

    # キー正規化
    api_k = api_clean.copy()
    csv_k = csv_clean.copy()
    for k in pair.keys:
        if k in pair.date_keys:
            api_k[k] = safe_to_datetime(api_k[k]).dt.strftime("%Y-%m-%d").fillna("<NaT>")
            csv_k[k] = safe_to_datetime(csv_k[k]).dt.strftime("%Y-%m-%d").fillna("<NaT>")
        else:
            api_k[k] = normalize_for_compare(api_k[k])
            csv_k[k] = normalize_for_compare(csv_k[k])

    api_dup = api_k.duplicated(subset=pair.keys).sum()
    csv_dup = csv_k.duplicated(subset=pair.keys).sum()
    summary["key_duplicates"] = {"api": int(api_dup), "csv": int(csv_dup)}

    api_keyset = api_k[pair.keys].apply(lambda r: "␟".join(r.values), axis=1)
    csv_keyset = csv_k[pair.keys].apply(lambda r: "␟".join(r.values), axis=1)
    only_api_keys = set(api_keyset) - set(csv_keyset)
    only_csv_keys = set(csv_keyset) - set(api_keyset)
    summary["key_diff"] = {
        "only_in_api_count": len(only_api_keys),
        "only_in_csv_count": len(only_csv_keys),
        "intersect_count": int(len(set(api_keyset) & set(csv_keyset))),
    }

    # 値差分（inner join）
    api_use = api_k[pair.keys + [c for c in common_cols if c not in pair.keys]].copy()
    csv_use = csv_k[pair.keys + [c for c in common_cols if c not in pair.keys]].copy()
    api_use = api_use.drop_duplicates(subset=pair.keys, keep="first")
    csv_use = csv_use.drop_duplicates(subset=pair.keys, keep="first")

    merged = api_use.merge(csv_use, on=pair.keys, how="inner", suffixes=("__api", "__csv"))

    value_cols = [c for c in common_cols if c not in pair.keys]
    diff_per_col: dict[str, int] = {}
    for col in value_cols:
        a = normalize_for_compare(merged[f"{col}__api"])
        c = normalize_for_compare(merged[f"{col}__csv"])
        diff_per_col[col] = int((a != c).sum())

    rows_with_any_diff = 0
    if value_cols:
        diff_mask = pd.Series(False, index=merged.index)
        for col in value_cols:
            a = normalize_for_compare(merged[f"{col}__api"])
            c = normalize_for_compare(merged[f"{col}__csv"])
            diff_mask |= a != c
        rows_with_any_diff = int(diff_mask.sum())

    summary["value_diff"] = {
        "merged_rows": int(len(merged)),
        "columns_compared": value_cols,
        "diff_count_per_column": diff_per_col,
        "rows_with_any_diff": rows_with_any_diff,
    }

    # 日付別行数集計
    if pair.date_col in api_clean.columns and pair.date_col in csv_clean.columns:
        def to_date_str(s: pd.Series) -> pd.Series:
            dt = safe_to_datetime(s)
            return dt.dt.strftime("%Y-%m-%d").fillna("<NaT>")

        api_dt = to_date_str(api_clean[pair.date_col])
        csv_dt = to_date_str(csv_clean[pair.date_col])
        api_g = api_dt.value_counts(dropna=False).sort_index()
        csv_g = csv_dt.value_counts(dropna=False).sort_index()
        all_dates = sorted(set(api_g.index) | set(csv_g.index))
        rows = []
        for d in all_dates:
            ac = int(api_g.get(d, 0))
            cc = int(csv_g.get(d, 0))
            if ac != cc:
                rows.append({"date": str(d), "api_rows": ac, "csv_rows": cc, "delta": ac - cc})
        summary["date_row_diff"] = {
            "date_col": pair.date_col,
            "mismatch_dates": rows,
            "api_total": int(api_g.sum()),
            "csv_total": int(csv_g.sum()),
        }
    else:
        summary["date_row_diff"] = {
            "date_col": pair.date_col,
            "note": "date_col missing in api or csv after clean",
            "api_has_col": pair.date_col in api_clean.columns,
            "csv_has_col": pair.date_col in csv_clean.columns,
        }

    return summary


def main() -> None:
    if not PAIRS:
        raise SystemExit(
            "PAIRS が空です。ファイル名・キー・日付列に合わせて PAIRS を書き換えてから再実行してください。"
        )
    report = {p.name: process_pair(p) for p in PAIRS}
    out = WORK / "report.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2))

    compact: dict = {}
    for name, r in report.items():
        compact[name] = {
            "rows": r.get("rows"),
            "dropped_from_api": r.get("drop", {}).get("dropped_from_api"),
            "dropped_from_csv": r.get("drop", {}).get("dropped_from_csv"),
            "api_only_columns": r.get("columns_after_clean", {}).get("api_only"),
            "csv_only_columns": r.get("columns_after_clean", {}).get("csv_only"),
            "key_ok": r.get("key_ok"),
            "key_duplicates": r.get("key_duplicates"),
            "key_diff": r.get("key_diff"),
            "value_diff_summary": {
                "merged_rows": r.get("value_diff", {}).get("merged_rows"),
                "rows_with_any_diff": r.get("value_diff", {}).get("rows_with_any_diff"),
                "diff_count_per_column": r.get("value_diff", {}).get("diff_count_per_column"),
            },
            "date_row_diff_mismatch_count": len(
                r.get("date_row_diff", {}).get("mismatch_dates", []) or []
            ),
        }
    print(json.dumps(compact, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
