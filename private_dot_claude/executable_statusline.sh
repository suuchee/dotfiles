#!/bin/bash
# 標準入力からJSON形式のデータを読み込む
input=$(cat)

# 各種情報を取得
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // "unknown"')
# ホームディレクトリをチルダ表記に置換
cwd="${cwd/#$HOME/~}"
model_id=$(echo "$input" | jq -r '.model.id // "unknown"')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // "0"')
effort=$(echo "$input" | jq -r '.effort.level // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // "0"')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // "0"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // "0"')

# モデル表示を組み立て（例: "claude-opus-4-8[1m] w/ xhigh"）
# model.id をそのまま使う。1M コンテキスト有効かつ id に [1m] を含まない場合だけ
# [1m] を補い、id が既に持つ場合の二重付与を防ぐ。effort 対応モデルのみ "w/ <level>" を付与。
model_display="${model_id}"
if [ "$ctx_size" = "1000000" ] && [[ "$model_id" != *"[1m]"* ]]; then
  model_display="${model_display}[1m]"
fi
[ -n "$effort" ] && model_display="${model_display} w/ ${effort}"

# ステータスライン表示（1行目: セッションID＋モデル＋トークン等 / 2行目: cwd）
printf '%s\n%s\n' \
  "${session_id} | ${model_display} | ${input_tokens}/${output_tokens} tokens | ctx: ${used}% used | api: ${duration_ms}ms" \
  "${cwd}"
