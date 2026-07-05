---
name: notes-system
description: "notes システム（notes ブランチ・worktree・Git LFS）のセットアップ手順、ディレクトリ構造、CONTEXT.md フォーマット、命名規則、運用、worktree 内 Bash 操作の注意をまとめたリファレンス。"
---

# notes システムのリファレンス

常時効く判断（パスの読み替え・公開境界・notes は push しない）は `~/.claude/rules/notes.md` にある。本ファイルはセットアップと構造の詳細を扱う。

## セットアップ

notes worktree を使う前に、以下の手順で環境を準備する。既にセットアップ済みの場合はスキップする。

前提として `.worktrees/` は global gitignore (`~/.config/git/ignore`) で除外されている想定。個別 repo の `.gitignore` には書かない（`~/.claude/skills/git/SKILL.md` の「.gitignore の置き場所」参照）。

### 1. notes ブランチの作成（存在しない場合）

```bash
# orphan ブランチとして作成（コードの履歴と完全に分離）
git switch --orphan notes
git commit --allow-empty -m "chore: notes ブランチを初期化"

# 元のブランチに戻る
git switch -
```

### 2. worktree の展開

```bash
# .worktrees/notes に worktree を展開
git worktree add .worktrees/notes notes
```

### 3. LFS 設定

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

### セットアップ後のパス（content ルート）

notes worktree の **content ルート** は、以下で決まる（本ファイルでは `<ROOT>` と表記）。

- **新規（フラット構成）**: `<ROOT>` = `.worktrees/notes/`（worktree ルート直下がそのまま content ルート）
- **旧構成の互換**: 既存 repo に `.worktrees/notes/.notes/` があれば、その内側を `<ROOT>` とする（既存は移行しない）

- **worktree ルート**: `.worktrees/notes/`
- **コンテキスト格納先**: `<ROOT>/context/`
- CLAUDE.md 等の notes 側パス（`context/...` 等）は `<ROOT>/...` に読み替える（`<ROOT>` ≡ content ルート）

## 構造

```text
<ROOT>/                          # notes worktree の content ルート（新規: .worktrees/notes/）
└── context/
    └── <NNN>_<prefix>_<name>/
        ├── CONTEXT.md           # メタ情報（目的、背景、ステータス等）
        ├── intent/              # 意思決定レイヤー（goal / constraints / decisions 等。使い方は各自）
        ├── plan/                # 計画・実装設計
        ├── research/            # 調査・技術検証
        ├── requirements/        # 要望・要件
        ├── deliberation/        # 検討・比較
        ├── conversation/        # 会話ログ
        ├── spec/                # 仕様（検討中。正式版は docs/ へ）
        ├── evidence/            # 証跡・検証の集積レイヤー（使い方は各自。下は例）
        │   ├── forensic/        #   例: マルウェア/インシデント調査の証跡（改変せず保持）
        │   └── trail/           #   例: 監査証跡・操作ログ
        └── assets/              # 素材レイヤー（動画/画像/参考メモ等、必要時のみ）
            ├── recordings/      #   画面収録・録画
            ├── screenshots/     #   スクリーンショット（日付などで階層化）
            └── references/      #   外部ドキュメント・配布資料
```

コンテキストは必ず `<ROOT>/context/` 配下に置く。`<ROOT>` 直下にコンテキストディレクトリを作らない（将来 `<ROOT>` 直下を別用途に使えるよう、中間層 `context/` を維持する）。

各レイヤーは必要に応じて追加するもので、すべてのコンテキストで揃える必要はない（軽いタスクなら plan/ や research/ だけでよい）。

`assets/` は元素材（動画・画像・配布資料など）を集めるためのもので、コンテキスト独自の派生ファイル（要約・対応表など）は `research/` 等の通常レイヤーに置く。素材と分析を分けることで原本を変更せず参照できる。

## CONTEXT.md フォーマット

```markdown
---
status: not_started  # not_started | in_progress | done | on_hold | canceled
branch: feature/add-auth
issue: "#123"
pr: "#456"
tags: [auth, security]
created_at: 2026-02-15
updated_at: 2026-02-15
---

## 目的

このコンテキストで達成したいこと。

## 背景

なぜこの作業が必要になったか。
```

## 公開境界（notes ↔ `docs/`）の詳細

方向のルール（notes → `docs/` の一方向のみ）は `~/.claude/rules/notes.md` にある。理由と実務適用は以下。

### 理由

- notes 側は流動的（削除・移動・renumber 対象、ブランチ自体が orphan）
- `docs/` は安定的（ADR は append-only、設計資料は確定版）
- 公開 docs が個人 notes に依存すると、notes 側の変更で参照が壊れ、保守コストが公開側に染み出す
- 公開ドキュメントは他人が notes を持っていなくても理解できる単独完結である必要がある

### 実務での適用

- ADR / 設計資料に「検討経緯」「実機検証結果」を書きたい場合は、要点を `docs/` 配下に正式版として保存する（個別の notes ファイルにリンクしない）
- notes 側の CONTEXT.md / research / spec / evidence では、関連する `docs/` を「関連ドキュメント」「関連 ADR」セクションでリンクする（逆方向は OK）
- 「notes の `.../foo.md` を参照」と書きたくなったら、その内容を `docs/` に昇格させるか、要約して `docs/` の本文に取り込むかを検討する

## 命名規則

- **コンテキスト**: `<連番>_<prefix>_<name>`（例: `context/001_feature_add-auth`）
- **ファイル**: `<対象名>_YYYY-MM-DD.md`

### prefix 一覧

| prefix | 用途 |
| --- | --- |
| `feature` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `docs` | ドキュメント |
| `chore` | その他 |

## 運用

- 新しい作業を始める際、連番を振ってコンテキストを作成
- ブランチを作成する場合、コンテキスト名とブランチ名を一致させる
- ブランチを作成しない場合でも、同じ形式で命名
- 既存コンテキストへの追記は、その番号のディレクトリに行う
- plan 確定後、plan ファイルを該当コンテキストの `plan/` に保存
- コンテキストへの変更は notes ブランチ上でコミットする（worktree 内で `git add` / `git commit`）
- worktree が展開されていない場合（`.worktrees/notes/` が存在しない場合）は、セットアップ手順に従って展開してから作業する
- 検討が固まり正式化する内容は `docs/` 配下へ昇格させる

## worktree 内での Bash 操作

`.worktrees/notes/` を出入りしながら作業する際は、Claude Code の Bash ツールが **CWD をコマンド間で持続する** 点を意識する。原則は「**現在地が目的地と一致していれば cd しない**」。

**失敗例**（既に notes worktree 内にいるのに、再度同じ相対パスで cd を書いてしまうケース）:

- 1回目: `cd .worktrees/notes && git status` → 成功（CWD が `.worktrees/notes/` に移動）
- 2回目: `cd .worktrees/notes && git add ...` → 失敗（`no such file or directory: .worktrees/notes`。既に notes worktree 内にいるので、相対パス `.worktrees/notes` は存在しない）

**対策**:

- 各コマンド実行前に「現在地はどこか」「目的地はどこか」を意識する。一致していれば cd 不要
- worktree 外（メイン作業ブランチ等）に出てから再度 notes worktree で作業する場合は、改めて `cd <repo-root>/.worktrees/notes`（または絶対パス）で入り直す
- worktree 外に出る時はメインの作業ディレクトリへ絶対パスで `cd`
