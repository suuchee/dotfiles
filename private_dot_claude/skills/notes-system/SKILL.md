---
name: notes-system
description: "notes システム（notes ブランチ・worktree・Git LFS）のセットアップ手順、ディレクトリ構造、CONTEXT.md フォーマット、命名規則、運用、worktree 内 Bash 操作の注意をまとめたリファレンス。"
---

# notes システムのリファレンス

常時効く判断（パスの読み替え・公開境界・notes は push しない）は `~/.claude/rules/notes.md` にある。本スキルは notes システムの構造と手順の詳細リファレンスで、詳細トピックは `references/` に分割している。頻出の `<ROOT>` 定義・CONTEXT.md フォーマット・命名規則、および notes を読み書きする限り常に意識すべき公開境界は本ファイルに残す。

## リファレンス索引

| 読むべき状況 | 参照先 |
| --- | --- |
| notes ブランチ / worktree / LFS を初めて用意する | `references/setup.md` |
| どのレイヤーに何を置くか（ディレクトリ構造）・日々の運用 | `references/structure.md` |

## 公開境界（main 側 ↔ notes）

方向のルール（notes → main 側の一方向のみ。main/master 及び派生ブランチにコミットされるファイルから notes への参照・リンクは書かない）は `~/.claude/rules/notes.md` にある。理由と実務適用は以下。

### 理由

- notes 側は流動的（削除・移動・renumber 対象、ブランチ自体が orphan・push しないローカル専用）
- main 側は安定的かつ共有物（他コントリビューターと共有される。`docs/` の ADR は append-only、設計資料は確定版）
- 共有される main 側ファイルが notes に依存すると、notes は他者が持たず push もされないため参照が壊れ、保守コストが染み出す
- main 側のファイルは他人が notes を持っていなくても理解できる単独完結である必要がある

### 実務での適用

- ADR / 設計資料に「検討経緯」「実機検証結果」を書きたい場合は、要点を `docs/` 配下に正式版として保存する（個別の notes ファイルにリンクしない）
- notes 側の CONTEXT.md / research / spec / evidence では、関連する `docs/` を「関連ドキュメント」「関連 ADR」セクションでリンクする（逆方向は OK）
- 「notes の `.../foo.md` を参照」と書きたくなったら、その内容を `docs/` に昇格させるか、要約して `docs/` の本文に取り込むかを検討する

## content ルート（`<ROOT>`）

notes worktree の **content ルート** は、以下で決まる（本スキルでは `<ROOT>` と表記）。

- **新規（フラット構成）**: `<ROOT>` = `.worktrees/notes/`（worktree ルート直下がそのまま content ルート）
- **旧構成の互換**: 既存 repo に `.worktrees/notes/.notes/` があれば、その内側を `<ROOT>` とする（既存は移行しない）

- **worktree ルート**: `.worktrees/notes/`
- **コンテキスト格納先**: `<ROOT>/context/`
- CLAUDE.md 等の notes 側パス（`context/...` 等）は `<ROOT>/...` に読み替える（`<ROOT>` ≡ content ルート）

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

- **コンテキスト**: `<連番>_<prefix>_<name>`（例: `context/001_feature_add-auth`）
- **ファイル**: `<対象名>_YYYY-MM-DD.md`

`<prefix>` はブランチの種別セグメント（`<prefix>/<name>`）に対応する。種別の一覧と選び方は git skill の「ブランチ命名規則」（`~/.claude/skills/git/references/commit-rules.md`）を単一ソースとして従う（Git-Flow の repo なら `feature` / `bugfix` 等、それ以外なら `feat` / `fix` / `refactor` / `docs` / `chore` 等、その repo の規約に合わせる）。notes 独自の prefix 一覧は持たない（二重管理・ドリフトを避けるため）。
