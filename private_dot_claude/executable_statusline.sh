#!/bin/bash
# 標準入力からJSON形式のデータを読み込む
input=$(cat)

# 各種情報を取得
session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // "unknown"')
# ホームディレクトリをチルダ表記に置換
cwd="${cwd/#$HOME/~}"
input_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // "0"')
output_tokens=$(echo "$input" | jq -r '.context_window.total_output_tokens // "0"')
used=$(echo "$input" | jq -r '.context_window.used_percentage // "0"')
duration_ms=$(echo "$input" | jq -r '.cost.total_api_duration_ms // "0"')

# ステータスライン表示（1行目: セッションID＋トークン等 / 2行目: cwd）
printf '%s\n%s\n' \
  "${session_id} | ${input_tokens}/${output_tokens} tokens | ctx: ${used}% used | api: ${duration_ms}ms" \
  "${cwd}"
