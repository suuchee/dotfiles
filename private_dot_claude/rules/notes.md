# .notes

作業コンテキスト（ブランチ相当の作業単位）を管理するディレクトリ。
`.notes/` は専用の `notes` ブランチ上で管理し、worktree 経由でアクセスする。

正式なドキュメントは `docs/` 配下に配置し、検討中・個人作業のメモ・ノート類はこの `.notes/` 配下にコンテキスト単位で集約する。
メモ・research・deliberation 等もすべてこのコンテキスト配下に集約する（コンテキストとの紐づきを切らないため、別ディレクトリには切り出さない）。

## セットアップ

`.notes/` ディレクトリを使う前に、以下の手順で環境を準備する。
既にセットアップ済みの場合はスキップする。

### 1. notes ブランチの作成（存在しない場合）

```bash
# orphan ブランチとして作成（コードの履歴と完全に分離）
git switch --orphan notes
git commit --allow-empty -m "chore: notes ブランチを初期化"

# 元のブランチに戻る
git switch -
```

### 2. .gitignore への追加（現在のブランチで）

`.worktrees/` がまだ `.gitignore` に含まれていない場合は、worktree 展開前に追加しておく。
これは現在の作業ブランチ（main 等）で行う。

```bash
echo '.worktrees/' >> .gitignore
```

### 3. worktree の展開

```bash
# .worktrees/notes に worktree を展開
git worktree add .worktrees/notes notes
```

### 4. （任意）素材（メディア）を扱う場合の LFS 設定

`assets/` 配下に動画・画像・PDF など大容量バイナリを置く予定なら、**notes ブランチ側で Git LFS を有効化する**。notes は orphan ブランチで作るため、main 側の `.gitattributes` を継承しない（また main 側に `.gitattributes` が無いケースもあるため、notes 側で独立に設定する）。

トラッキング対象の拡張子は `~/.claude/skills/git/references/init-checklist.md` と揃えており、メディア（動画・音声・画像）と PDF を含む。

```bash
# notes worktree 内で LFS を有効化し .gitattributes を作成・コミット
git -C .worktrees/notes lfs install --local
git -C .worktrees/notes lfs track "*.mp4" "*.mov" "*.mp3" "*.m4a" "*.wav" "*.png" "*.jpg" "*.jpeg" "*.pdf"
git -C .worktrees/notes add .gitattributes
git -C .worktrees/notes commit -m "chore(notes): Git LFS の .gitattributes を追加"
```

これを忘れて先にメディアをコミットすると履歴に直接埋め込まれ、後からの LFS 移行は `git lfs migrate import` での履歴書き換えが必要になる（詳細は `~/.claude/rules/git-tips.md` の LFS 節）。

### セットアップ後のパス

- **worktree ルート**: `.worktrees/notes/`
- **コンテキスト格納先**: `.worktrees/notes/.notes/context/`
- CLAUDE.md 等で `.notes/...` と記載されているパスは、すべて `.worktrees/notes/.notes/...` に読み替える

## 構造

```text
.notes/
└── context/
    └── <NNN>_<prefix>_<name>/
        ├── CONTEXT.md           # メタ情報（目的、背景、ステータス等）
        ├── intent/              # 意思決定レイヤー
        │   ├── goal.md          #   outcome / opportunities
        │   ├── constraints.md   #   制約
        │   └── decisions/       #   軽量ADR（YYYY-MM-DD-<topic>.md）
        ├── plan/                # 計画・実装設計
        ├── research/            # 調査・技術検証
        ├── requirements/        # 要望・要件
        ├── deliberation/        # 検討・比較
        ├── conversation/        # 会話ログ
        ├── spec/                # 仕様（検討中。正式版は docs/ へ）
        ├── evidence/            # 検証・学びの集積レイヤー
        │   ├── tests/           #   eval task 群（実失敗 20–50 件）
        │   ├── incidents/       #   失敗ログ
        │   └── ops-learnings.md #   運用知見
        └── assets/              # 素材レイヤー（動画/画像/参考メモ等、必要時のみ）
            ├── recordings/      #   画面収録・録画
            ├── screenshots/     #   スクリーンショット（日付などで階層化）
            └── references/      #   外部ドキュメント・配布資料
```

コンテキストは必ず `.notes/context/` 配下に置く。`.notes/` 直下にコンテキストディレクトリを作らない（将来 `.notes/` 直下を別用途に使えるよう、中間層 `context/` を維持する）。

`intent/`、`evidence/`、`assets/` は必要に応じて追加するもので、すべてのコンテキストで揃える必要はない（軽いタスクなら従来通り plan/ や research/ だけでよい）。

`assets/` は元素材（動画・画像・配布資料など）を集めるためのもので、コンテキスト独自の派生ファイル（要約・対応表など）は `research/` 等の通常レイヤーに置く。素材と分析を分けることで原本を変更せず参照できる。なお `assets/` にメディアを置く場合は事前に「セットアップ 4」で notes ブランチ側の LFS を有効化しておくこと。

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

## 命名規則

- **コンテキスト**: `<連番>_<prefix>_<name>`（例: `.notes/context/001_feature_add-auth`）
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

## notes ブランチは push しない

`notes` ブランチは **ローカル専用**。リモート（`origin`）には push しない。

### 理由

- `.notes/` は個人の作業メモ・検討経緯であり、共有を前提としない
- orphan ブランチでコード履歴と完全分離されているため、リモートに置く必然性がない
- 公開リポジトリの場合、検討途中のメモや内部情報がリモートに漏れるリスクがある
- 流動的（削除・移動・renumber 対象）なため、リモートとの整合維持コストに見合わない

### 守るべきこと

- `git push origin notes` / `git push -u origin notes` を実行しない
- push 系コマンドは常に**独立実行**し、`&&` などで他コマンドの後ろに連結しない（対象ブランチを毎回明示的に確認できる状態を保つ）
- 共同作業者間で notes 内容を共有したい場合は、`docs/` 昇格や別途の手段で行う

## docs / notes の依存方向

公式ドキュメント (`docs/`) と個人検討 (`.notes/`) の参照は **一方向のみ許容**する。

- ✅ `.notes/` → `docs/` への参照は推奨（個人検討から公式 ADR / 設計資料を参照する）
- ❌ `docs/` → `.notes/` への参照は禁止（公式 docs は個人 notes に依存させない）

### 理由

- `.notes/` は流動的（削除・移動・整理・renumber の対象、ブランチ自体が orphan）
- `docs/` は安定的（ADR は append-only、設計資料は確定版）
- 公式 docs が個人 notes に依存すると、notes 側の変更で公式 docs の参照が壊れる
- 公式 docs は単独で完結するべき（他人が `.notes/` を持っていなくても理解できる）

### 実務での適用

- ADR / 設計資料に「検討経緯」「実機検証結果」を書きたい場合は、要点を `docs/` 配下に正式版として保存する（個別の `.notes/` ファイルにリンクしない）
- `.notes/` 側の CONTEXT.md / research / spec / evidence では、関連する `docs/` を「関連ドキュメント」「関連 ADR」セクションでリンクする（逆方向は OK）
- 「`.notes/.../foo.md` を参照」と書きたくなったら、その内容を `docs/` に昇格させるか、要約して `docs/` の本文に取り込むかを検討する

## worktree 内での Bash 操作

`.worktrees/notes/` を出入りしながら作業する際は、Claude Code の Bash ツールが **CWD をコマンド間で持続する** 点を意識する。原則は「**現在地が目的地と一致していれば cd しない**」。

**失敗例**（既に notes worktree 内にいるのに、再度同じ相対パスで cd を書いてしまうケース）:

- 1回目: `cd .worktrees/notes && git status` → 成功（CWD が `.worktrees/notes/` に移動）
- 2回目: `cd .worktrees/notes && git add ...` → 失敗（`no such file or directory: .worktrees/notes`。既に notes worktree 内にいるので、相対パス `.worktrees/notes` は存在しない）

**対策**:

- 各コマンド実行前に「現在地はどこか」「目的地はどこか」を意識する。一致していれば cd 不要
- worktree 外（メイン作業ブランチ等）に出てから再度 notes worktree で作業する場合は、改めて `cd <repo-root>/.worktrees/notes`（または絶対パス）で入り直す
- worktree 外に出る時はメインの作業ディレクトリへ絶対パスで `cd`
