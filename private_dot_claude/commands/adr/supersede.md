---
description: 既存ADRを新しいADRで置き換えます（Supersede）。
allowed-tools:
  - "Read"
  - "Write"
  - "Edit"
  - "Glob"
  - "Grep"
  - "Bash(ls:*)"
  - "Bash(mkdir:*)"
---

## Context

- **既存ADRディレクトリ**: `!ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1`
- **既存ADR一覧**: `!ls docs/adr/*.md docs/decisions/*.md doc/arch/*.md adr/*.md 2>/dev/null | sort`
- **対象ADR**: $ARGUMENTS

## 参照資料

- **`~/.claude/skills/adr/references/adr-conventions.md`** - Supersedeプロセスの詳細

## Your task

既存ADRを新しいADRで置き換えてください。

公式 MADR では `status` フィールド自体に置き換え関係を記録する形式（`status: "superseded by ADR-NNNN"`）を採用している。本スキルもこれに従う。

### 0. supersede が必要かの判定（最優先）

ADRは原則 immutable。`accepted` 後の変更は次の3レーンに振り分ける：

#### supersede へ進むケース

採用案（Chosen option）または採用理由（justification）が入れ替わる場合のみ supersede：

- 採用する選択肢そのものを変える（例: Redis → DynamoDB）
- 採用理由を別の根拠に差し替える（例: 「速度」→「運用コスト」）
- Y-Statement の品質目標 / 受け入れる欠点 / 採用案のいずれかが変わる

#### `Consequences` の Updates へ追記して終了するケース

決定の妥当性を補強する事後観測のみ。本コマンドは使わず、ADRの `Consequences` セクションに `#### Updates` サブセクションを設けて1行追記（frontmatter の `date` も更新）：

- 想定通りの効果が観測された（「p99 が想定通り 30% 改善」「Bad で挙げた懸念は顕在化しなかった」）
- 別方面の検証でも採用案が優位だった
- 採用理由の補強事実（元の理由を否定せず裏付けるデータ）

#### 「決定時の不備」として原則 supersede を提案するケース

以下は**決定時に揃えるべきだった**項目。後から追記したくなった時点で「決定時に詰めきれていなかった」というシグナルなので、原則は supersede（決定をきちんと再起票し直す）を提案する：

- 後から確認手段・自動テスト・運用基準を足したい（Confirmation 不足）
- 後発の別案を Considered Options に足したい（採用案を覆すなら supersede、覆さないなら Consequences の Updates に「Option X を確認したが採用案維持」と事実記録）
- 見直し条件を後から追加したい（Revisit Triggers 不足）
- 関連リンクを後から足したい（More Information 不足）

やむを得ず追記する場合も本体の該当セクションは触らず、`Consequences` の Updates に理由を添えて記録する（不備の所在を読者が追えるように）。

#### 境界の見極め例

- 「Redis 採用、別計測でも採用案が優位だった」 → **Consequences の Updates に追記**（補強）
- 「Redis 採用、理由は速度」→「Redis 採用、理由は運用コスト」 → **supersede**（採用案は同じでも根拠が入れ替わっている）
- 「後日 Cloudflare KV が登場、採用案は Redis のまま」 → **Consequences の Updates に事実記録**（候補増加だけ）
- 「再評価して採用案を Cloudflare KV に変える」 → **supersede**

判断に迷う場合は supersede を選ぶ（保守的な側へ倒す）。詳細は `~/.claude/skills/adr/references/adr-conventions.md` の「受理済みADRの変更ルール」を参照。

### 1. 置き換え対象の特定

$ARGUMENTS で指定された、または対話で特定された旧ADRを確認する。

対象が不明な場合:
1. 既存ADRの一覧を表示する
2. ユーザーに置き換え対象を選択してもらう

### 2. 旧ADRの内容確認

旧ADRを読み取り、以下を確認する:

- 現在のステータスが `accepted` であること（proposed の場合は直接編集を提案）
- 決定内容とその背景

### 3. 新ADRの作成

`/adr:create` と同じプロセスで新しいADRを作成する。ただし以下を追加する:

- 「Context and Problem Statement」に旧ADRの決定がなぜ変更されるかを記述
- 「More Information」に旧ADRへのリンクを記載
- ステータスは通常通り `proposed` で作成（accepted への変更は人間が行う）

### 4. 旧ADRの更新

旧ADRの frontmatter の `status` フィールドを以下に書き換える:

```yaml
status: "superseded by ADR-NNNN"
```

NNNN は新ADRの4桁ゼロ埋め番号。本文は変更しない（不変性の原則）。

### 5. 確認

変更内容をユーザーに提示する:

```
Supersede完了:
- 旧ADR: <旧ファイル名> → status: "superseded by ADR-NNNN"
- 新ADR: <新ファイル名> → status: "proposed"
- 新ADRの「More Information」に旧ADRへのリンクを記載済み
```
