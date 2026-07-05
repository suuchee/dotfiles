---
name: archive-to-canonical
description: 完了した `.notes/<NNN>_.../` コンテキストから普遍化すべき決定・知見を抽出し、`intent/decisions/` の軽量 ADR、`docs/` への正式昇格、`~/.claude/rules/` への昇格候補として整理する。失敗ケースを eval（manual-cases.json / pdca-cases）として記録するときにも使う。ユーザーが「コンテキストを archive」「決定を昇格」「knowledge を canonical に戻す」「失敗を eval に残す」等と依頼したときに使用する。
allowed-tools: "Read,Write,Edit,Grep,Glob,Bash"
---

# archive-to-canonical

完了したコンテキストの学びを「次の開発サイクルに恒久的に効く形」に還流させる。

## いつ使うか

- 機能実装が完了し、テストを通過してマージされたタイミング
- コンテキストの `status` を `done` に変えるタイミング
- インシデント対応が一段落し、再発防止策を仕組みに戻すタイミング
- 失敗・修正指示を eval として記録するタイミング（`failure-feedback` rule の具体層）

## 入力

- 対象コンテキスト: `.worktrees/notes/.notes/<NNN>_<prefix>_<name>/`

## 手順

### 1. コンテキストを読む

以下を `Read` / `Glob` で網羅する：

- `CONTEXT.md`（目的・背景・status）
- `intent/decisions/`（既存の軽量 ADR。運用しているコンテキストのみ）
- `deliberation/` / `research/`（検討・調査ログ、失敗ログ・運用知見を含む）

### 2. 4種類に分類

学びを以下の 4 種類に振り分ける。

| 種別 | 行き先 | 判断基準 |
| --- | --- | --- |
| **コンテキスト固有の決定** | そのまま `intent/decisions/<YYYY-MM-DD>-<topic>.md` に軽量 ADR として記録 | このコンテキスト内のみで効く判断 |
| **プロジェクト横断の決定** | プロジェクト repo の `docs/adr/` への昇格を提案 | このプロジェクトの他のコンテキストにも効く判断 |
| **個人横断の原則・ノウハウ** | `~/.claude/rules/` への追記を提案 | プロジェクトを跨いで効く、自分の運用ルール |
| **再発防止の仕組み** | hook / lint rule / test / skill の追加を提案 | 「同じ失敗を物理的に再発させない」に直結するもの |

### 3. 軽量 ADR フォーマット（intent/decisions/）

```markdown
# <topic>

- **Date**: <YYYY-MM-DD>
- **Status**: accepted | superseded | deprecated
- **Context**: 何が起きていたか（1〜3文）
- **Decision**: 何を決めたか（1〜3文）
- **Consequences**: 何が変わるか・何を諦めたか（1〜3文）
```

長文の Why は不要。後で読んだときに「何を決めたか」「なぜ」が一目で分かれば足りる。

### 4. 提案書を作って人間に確認

このスキルは **直接 `docs/` や `~/.claude/rules/` を書き換えない**。代わりに以下を作る：

```text
.worktrees/notes/.notes/<NNN>_.../intent/decisions/<YYYY-MM-DD>-archive-summary.md
```

内容：

```markdown
# Archive Summary (<YYYY-MM-DD>)

## このコンテキストで確定した決定

- <軽量 ADR を直接ここに、または別ファイルへ>

## docs/adr への昇格候補

- <内容と推奨先>

## ~/.claude/rules/ への昇格候補

- <内容と推奨先>

## 仕組みに戻す候補

- <hook / lint / test / skill の追加提案>
```

人間が承認した項目のみ、後続の編集タスク（rules編集や docs/adr 追加）に進める。

### 5. CONTEXT.md の status 更新

承認・反映後、`CONTEXT.md` の frontmatter を更新する：

```yaml
status: done
updated_at: <YYYY-MM-DD>
```

## 失敗ケース（eval）の記録先

`failure-feedback` rule の二層運用のうち、具体（eval）側の置き場所とフォーマット。

| ケース性質 | 置き場所 | 形式 |
| --- | --- | --- |
| 該当スキルが既に存在する | `~/.claude/skills/<skill>/evals/manual-cases.json` | skill-creator スキーマ準拠 JSON。アンチパターンは `expectations[]` に「〜が含まれていない」命題として記述 |
| 該当スキルが存在しない | chezmoi リポジトリの notes worktree: `~/.local/share/chezmoi/.worktrees/notes/.notes/pdca-cases/inbox/<area>/YYYY-MM-DD_<slug>.md` | 1 ケース 1 ファイル Markdown。フォーマットは `pdca-cases/README.md` 参照 |

運用上の注意:

- スキルあり側のケースは `pdca-cases/INDEX.md` にパスを 1 行追記する（シンボリックリンクは作らない。両者とも git 管理されるため二重化不要）
- eval ファイル名は `manual-cases.json` のように、skill-creator が自動生成・更新しうる `evals.json` と衝突しない名前にする
- 「該当スキルなし」ケースを memory や `~/.claude/` 直下に置かない。memory は毎セッションロードされコンテキストを圧迫する。skill 内 eval は呼出時のみロードされる。`~/.claude/` 直下の新規ディレクトリは Claude Code の予約名・更新と衝突するリスクがある
- 1 度目の失敗は eval を残すだけで止めてよい。skill 本文への抽象化は 2 度目以降、または抽象化のパターンが見えた時点で行う
- inbox 配下で半年以上 promoted（skill 化）も dropped（捨てる）もされないケースは削除候補（lossy 運用、`pdca-cases/README.md` 参照）

## やらないこと

- archive-summary 提案を作っただけで rules / docs を勝手に編集しない
- 「念のため全部 ADR 化」をしない。1コンテキストで普遍化に値する決定は通常 0〜2 件
- 既存 ADR の supersede 判定はこのスキルではなく `adr:supersede` skill に委ねる
