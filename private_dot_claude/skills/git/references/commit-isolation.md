# コミット対象の切り分け・隔離

index（ステージング領域）はブランチとは独立している。`git switch -c <new>` でブランチを切り替えても index の内容は持続する。

`git commit`（path 指定なし）は **index 全体**をコミットする。コミット対象を限定するには、事前に index の内容を確認し、必要なら pathspec を使う。

## 前提: index と commit の関係

| 操作 | index への影響 |
| --- | --- |
| `git add <path>` | 指定 path の変更を index に載せる |
| `git switch -c <branch>` | index は変わらない |
| `git commit` | index 全体がコミット対象 |
| `git commit -- <path>...` | 指定 path に該当する **index 上の変更のみ**がコミット対象。他の staged 変更は index に残る |

## コミット前の確認

`git status --short` の **左列（index 列）** が空でなければ、その行の path は次の `git commit`（path なし）に含まれる。

| 表示 | 意味 |
| --- | --- |
| `A ` / `AM` | 新規ファイルが index に add 済み |
| `M ` / `MM` | 既存ファイルの変更が index に add 済み |
| `D ` | 削除が index に add 済み |

index 列に、今回コミットする意図と一致しない path があれば、下記の対処パターンを検討する。

`AM` / `MM` は index と worktree で状態が異なる行。コミット対象の見落としが起きやすい。

## 対処パターン

| パターン | 条件 | コマンド例 |
| --- | --- | --- |
| pathspec 指定コミット | index に他の staged 変更を残したい | `git commit -m "..." -- <path>...` |
| 一時 unstage → コミット → 再 stage | 部分 hunk staging など pathspec で表現しづらい | `git restore --staged <other>` → commit → `git add <other>` |
| `git stash --keep-index` | 未ステージの worktree 変更を一時退避し、staged のみ残したい | `git stash --keep-index` |

pathspec 指定コミットは index 上の他の staged 変更を触らない。

### pathspec 指定コミットの注意点

- `--` 区切りを必ず置く（オプションとパスの解釈を明示的に分ける）
- pathspec に含めた path については、index にあるモード変更（chmod 等）も取り込まれる
- pathspec はディレクトリ単位の指定も可能（例: `-- docs/`）

## よくある失敗

### ブランチ切替だけで隔離されると見なす

`git switch -c <new>` 後も index は持続する。`git add <path>` → `git commit`（path なし）すると、切替前から index にあった変更も含まれる。

→ ブランチ切替の前後で `git status` を確認する。

### コミット後に範囲ミスに気付いた場合

`git reset --soft HEAD~1` でコミットを取り消すと、変更は index に復元される（worktree は不変）。pathspec で再コミットする。

```bash
git reset --soft HEAD~1
git status --short
git commit -m "..." -- <path>...
```

### `git add .` / `git add -A` で index を広くする

worktree 内の追跡対象ファイルの変更を一括で index に載せる。意図しない path まで staged になる。

→ `git add <path>` で対象を個別指定する（SKILL.md「ステージング」参照）。

## index 列のみを一覧する

`git status --short` の出力が多い場合、index 列に変化がある行だけを抽出する：

```bash
git status --short | grep -v '^ ' | grep -v '^??'
```

1 列目が空白でなく `??` でもない行 = 次の `git commit`（path なし）に含まれる path。

## 関連

- SKILL.md「ステージング」（個別指定の推奨）
- SKILL.md「コミット前の確認」（4 項目チェック）
- SKILL.md「コミット設計」（未コミット変更はそのまま、対象のみコミットする方針）
- `references/branch-strategy.md`（ブランチ単位での作業分離）
