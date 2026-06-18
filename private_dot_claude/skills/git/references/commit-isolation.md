# コミット対象の切り分け・隔離

自分のタスク外の変更がコミットに巻き込まれるのを防ぐ。`git switch -c <new>` で新規ブランチを切っても index は持続するため、ブランチ作成だけでは隔離されない。

## コミット前の確認

`git status --short` の **左列（index 列）** を確認し、今回のタスクと無関係なパスがステージされていないか見る。

| 表示 | 意味 |
| --- | --- |
| `A ` / `AM` | 新規ファイルが index に add 済み |
| `M ` / `MM` | 既存ファイルの変更が index に add 済み |
| `D ` | 削除が index に add 済み |

特に注意するサイン：

- 自分が触っていないディレクトリ階層のファイルがステージされている
- `AM` / `MM`（index と worktree で別状態のファイル）が混在
- セッション開始前から残っていた可能性のあるファイル

## 巻き込みが見つかった際の対処パターン

次の順で検討する。

### 1. pathspec 指定コミット（第一選択）

**適する場合**: コミット対象の path がファイル／ディレクトリ単位で切れる。混入 path が複数ファイルにまたがっても、対象 path を列挙すれば足りる。

**なぜ第一選択か**: 他作業の index を一切触らないため、最も非侵襲。

```sh
git commit -m "..." -- <path>...
```

#### pathspec 指定コミットの注意点

- `--` 区切りを必ず置く（オプションとパスの解釈を明示的に分ける）
- pathspec に含めたパスについては、index にあるモード変更（chmod 等）も取り込まれる
- pathspec はディレクトリ単位の指定も可能（例: `-- docs/`）

### 2. hunk 単位の切り分け（pathspec では不可）

**適する場合**: 同一ファイル内で、コミット対象の hunk と対象外 hunk が index に混在している。pathspec は path 単位までしか切れない。

**非対話でできそうなら**、次を試す：

| 手段 | 向く状況 | コマンド例 |
| --- | --- | --- |
| `git apply --cached` | 載せたい／外したい hunk をパッチで明示できる | `git diff [--cached] <file> > /tmp/p.patch` → 編集 → `git apply --cached /tmp/p.patch` |
| stdin 注入 | hunk の数・順序が分かっている | `printf 'y\nn\n' \| git add -p <file>` |

`git add -p` / `git restore --staged -p` は対話前提。Claude Code からは stdin 注入か `git apply --cached` で非対話化する。`s`（hunk 分割）が要る場合は stdin 注入では足りないことが多い。

### 3. それでも切り分けできない場合

- **編集ツールで対応** — ファイル数が少ないときのみ。多いとトークン・時間の無駄なので避ける
- **諦めてユーザーに確認** — 混在ファイルは今回のコミットから外す、ユーザーに対話的な `-p` を依頼する、等

### 作業ツリー側の退避（別件）

未ステージの worktree 変更まで隔離したい場合は `git stash --keep-index`（ステージ済みのみ残る）。

## よくある失敗

### 新規ブランチを切れば隔離されると判断してしまう

`git switch -c <new>` しても index は前のブランチから持続する。新規ブランチで `git add <自分の対象>` → `git commit` すると、既存ステージも巻き込まれる。

→ ブランチ切替の前後で `git status` を確認する。

### コミット後に気付いた場合

`git reset --soft HEAD~1` でコミットを取り消し、index 状態を復元できる（非破壊・worktree 不変）。その後 pathspec で再コミットする。

```bash
git reset --soft HEAD~1
git status --short                 # 巻き込みファイルを再確認
git commit -m "..." -- <path>...   # pathspec で再コミット
```

### `git add .` / `git add -A` で広範囲に拾う

作業ツリー全体の追跡対象外ファイルまで add される。
タスク外の新規追加・削除があれば同じく巻き込まれる。

→ `git add <path>` で対象を個別指定する（SKILL.md「ステージング」参照。Claude Code では `git add -A` は deny 済み）。

## 検出が難しいケース

セッション開始時の `git status` 出力が長大で、ユーザーの作業途中分とノイズ（大量の削除済みファイル等）が混ざっている場合、コミット直前に index 列のみを抽出して確認する：

```bash
git status --short | grep -v '^ ' | grep -v '^??'   # index に変化のある行のみ
```

このフィルタで残った行が「次の commit に入る予定のファイル」。タスク外が混じっていれば pathspec へ切替える。

## 関連

- SKILL.md「ステージング」（個別指定の推奨）
- SKILL.md「コミット前の確認」（4 項目チェック）
- SKILL.md「コミット設計」（未コミット変更はそのまま、対象のみコミットする方針）
- `references/branch-strategy.md`（ブランチ単位での作業分離）
