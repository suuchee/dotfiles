# notes システムのセットアップ

notes worktree を使う前に、以下の手順で環境を準備する。既にセットアップ済みの場合はスキップする。

前提として `.worktrees/` は global gitignore (`~/.config/git/ignore`) で除外されている想定。個別 repo の `.gitignore` には書かない（`~/.claude/skills/git/SKILL.md` の「.gitignore の置き場所」参照）。

## 1. notes ブランチの作成（存在しない場合）

```bash
# orphan ブランチとして作成（コードの履歴と完全に分離）
git switch --orphan notes
git commit --allow-empty -m "chore: notes ブランチを初期化"

# 元のブランチに戻る
git switch -
```

## 2. worktree の展開

```bash
# .worktrees/notes に worktree を展開
git worktree add .worktrees/notes notes
```

## 3. LFS 設定

notes ブランチでは Git LFS を有効化する（バイナリ素材を予定していなくても必ず実施）。notes は orphan ブランチで作るため、main 側の `.gitattributes` を継承しない（また main 側に `.gitattributes` が無いケースもあるため、notes 側で独立に設定する）。

LFS 化の対象：

- **バイナリ（動画 / 音声 / 画像 / ドキュメント / アーカイブ / データ / デザイン / フォント）**: 全て LFS 化する。
- **テキスト（Markdown / JSONL / CSV 等）**: 原則 LFS 外。Git の差分・grep が効くメリットを優先する。

```bash
# notes worktree 内で LFS を有効化し .gitattributes を作成・コミット
# パターンは大文字小文字を吸収するブラケット表記（カメラ由来の .JPG など大文字拡張子もカバー）
git -C .worktrees/notes lfs install --local
git -C .worktrees/notes lfs track \
  "*.[Mm][Pp]4" "*.[Mm][Oo][Vv]" "*.[Ww][Ee][Bb][Mm]" \
  "*.[Mm][Pp]3" "*.[Mm]4[Aa]" "*.[Ww][Aa][Vv]" "*.[Ff][Ll][Aa][Cc]" "*.[Oo][Gg][Gg]" "*.[Aa][Aa][Cc]" \
  "*.[Pp][Nn][Gg]" "*.[Jj][Pp][Gg]" "*.[Jj][Pp][Ee][Gg]" "*.[Gg][Ii][Ff]" "*.[Ww][Ee][Bb][Pp]" "*.[Hh][Ee][Ii][Cc]" "*.[Hh][Ee][Ii][Ff]" \
  "*.[Pp][Dd][Ff]" \
  "*.[Dd][Oo][Cc]" "*.[Dd][Oo][Cc][Xx]" "*.[Xx][Ll][Ss]" "*.[Xx][Ll][Ss][Xx]" "*.[Pp][Pp][Tt]" "*.[Pp][Pp][Tt][Xx]" \
  "*.[Oo][Dd][Tt]" "*.[Oo][Dd][Ss]" "*.[Oo][Dd][Pp]" \
  "*.[Zz][Ii][Pp]" "*.[Tt][Aa][Rr]" "*.[Gg][Zz]" "*.[Tt][Gg][Zz]" "*.[Bb][Zz]2" "*.[Xx][Zz]" "*.7[Zz]" "*.[Rr][Aa][Rr]" "*.[Zz][Ss][Tt]" "*.[Ll][Zz]4" "*.[Ll][Zz][Mm][Aa]" "*.[Ll][Zz]" \
  "*.[Pp][Aa][Rr][Qq][Uu][Ee][Tt]" \
  "*.[Pp][Ss][Dd]" "*.[Aa][Ii]" "*.[Ff][Ii][Gg]" "*.[Ss][Kk][Ee][Tt][Cc][Hh]" \
  "*.[Tt][Tt][Ff]" "*.[Oo][Tt][Ff]" "*.[Ww][Oo][Ff][Ff]" "*.[Ww][Oo][Ff][Ff]2"
git -C .worktrees/notes add .gitattributes
git -C .worktrees/notes commit -m "chore(notes): Git LFS の .gitattributes を追加"
```

セットアップ前にバイナリをコミットしてしまった場合は、`git lfs migrate import` で履歴書き換えが必要。

## セットアップ後のパス

content ルート（`<ROOT>`）の定義・読み替えは `../SKILL.md` の「content ルート（`<ROOT>`）」節を参照する。
