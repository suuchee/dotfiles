# /// script
# requires-python = ">=3.11"
# dependencies = ["pandas>=2.0"]
# ///
"""差分の性質を切り分けるためのサンプル抽出テンプレート。

clean_and_diff.py の集計で「特定列の差が多い」「N 件で複数列同時に空」のような
パターンが見つかったら、本テンプレートをコピーして TARGETS / 対象ペア / キーを
書き換えて実行する。

中身を見るのは「差分の性質を判別する」局面に限定する。出力では文字列を 80 字に
切ってプライバシー保護とコンテキスト節約を両立させる。

2 つのモード:
  1. main_sample: 列ごとの差分上位 5 件を表示（表記差 / 実値差の切り分け）
  2. main_pattern: 特定列が空になっている全行で他列の値を並べる（データ欠損深掘り）
"""

from __future__ import annotations

from pathlib import Path

import pandas as pd

# === ユーザーが書き換える箇所 ====================================
ROOT = Path(__file__).resolve().parent.parent  # base/ を指す想定
API_FILE = "api/<file>.csv"
CSV_FILE = "csv/<file>.csv"
KEYS: list[str] = ["案件ID"]  # マージキー
TARGETS: list[str] = ["契約確度", "契約予定日"]  # サンプル対象列
EMPTY_TRIGGER_COL = "グループ"  # main_pattern で「この列が空」を起点に深掘り
META_COLS_FOR_PATTERN = [
    "アクション登録先種別",
    "アクション担当者",
    "案件名",
    "実施結果",
]  # main_pattern で並べて出すメタ列
TRIM_LEN = 80
HEAD_N = 5
# ==================================================================


def norm(s: pd.Series) -> pd.Series:
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


def _trim(x: object) -> str:
    s = "" if pd.isna(x) else str(x)
    s = s.replace("\n", " ")
    return s if len(s) <= TRIM_LEN else s[: TRIM_LEN - 3] + "..."


def load_and_merge() -> pd.DataFrame:
    api = pd.read_csv(ROOT / API_FILE, dtype=str, keep_default_na=True)
    csv = pd.read_csv(ROOT / CSV_FILE, dtype=str, keep_default_na=True)
    for k in KEYS:
        api[k] = norm(api[k])
        csv[k] = norm(csv[k])
    api = api.drop_duplicates(subset=KEYS, keep="first")
    csv = csv.drop_duplicates(subset=KEYS, keep="first")
    common = [c for c in api.columns if c in csv.columns and c not in KEYS]
    return api[KEYS + common].merge(
        csv[KEYS + common], on=KEYS, how="inner", suffixes=("__api", "__csv")
    )


def main_sample() -> None:
    """TARGETS 各列について、差分のある上位 HEAD_N 件を api / csv 並列表示。"""
    merged = load_and_merge()
    for col in TARGETS:
        if f"{col}__api" not in merged.columns:
            print(f"--- [{col}] column missing ---")
            continue
        a = norm(merged[f"{col}__api"])
        c = norm(merged[f"{col}__csv"])
        diff = merged[a != c].head(HEAD_N).copy()
        if diff.empty:
            print(f"--- [{col}] no diff ---")
            continue
        print(f"--- [{col}] top {HEAD_N} sample (api -> csv) ---")
        for _, row in diff[KEYS + [f"{col}__api", f"{col}__csv"]].iterrows():
            key_part = " | ".join(str(row[k]) for k in KEYS)
            print(
                f"  {key_part} | api={_trim(row[f'{col}__api'])} | "
                f"csv={_trim(row[f'{col}__csv'])}"
            )
        print()


def main_pattern() -> None:
    """EMPTY_TRIGGER_COL が api 側で空 / csv 側に値あり、の行を全件表示。
    同時に他列の空状況をカウントし、META_COLS_FOR_PATTERN の値を並べる。
    """
    merged = load_and_merge()
    if f"{EMPTY_TRIGGER_COL}__api" not in merged.columns:
        print(f"trigger column {EMPTY_TRIGGER_COL} missing")
        return

    mask = (norm(merged[f"{EMPTY_TRIGGER_COL}__api"]) == "") & (
        norm(merged[f"{EMPTY_TRIGGER_COL}__csv"]) != ""
    )
    target = merged[mask].copy()
    print(
        f"==== {EMPTY_TRIGGER_COL}__api が空 / {EMPTY_TRIGGER_COL}__csv に値あり: "
        f"{len(target)} 件 ====\n"
    )

    # 他列の空状況カウント
    suffixed_cols = [c for c in merged.columns if c.endswith("__api")]
    print("=== ターゲット行のうち、api 側 / csv 側で空になっている列の件数 ===")
    for c_api in suffixed_cols:
        base = c_api[: -len("__api")]
        c_csv = f"{base}__csv"
        if c_csv not in target.columns:
            continue
        n_api = (norm(target[c_api]) == "").sum()
        n_csv = (norm(target[c_csv]) == "").sum()
        if n_api > 0 or n_csv > 0:
            print(f"  {base}: api空={n_api}, csv空={n_csv}")
    print()

    # メタ列を並べて表示
    print("=== 全行 (主要列) ===")
    header_parts = [*KEYS] + [f"{c}__api" for c in META_COLS_FOR_PATTERN]
    print(" | ".join(header_parts))
    print("-" * 160)
    for _, row in target.iterrows():
        key_part = " | ".join(str(row[k]) for k in KEYS)
        meta_part = " | ".join(_trim(row.get(f"{c}__api", "")) for c in META_COLS_FOR_PATTERN)
        print(f"{key_part} | {meta_part}")


if __name__ == "__main__":
    # 必要なモードを呼ぶ。1 回の調査ではどちらか一方で OK。
    main_sample()
    print("\n\n")
    main_pattern()
