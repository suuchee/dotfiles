# ADR Conventions

ADRの規約とライフサイクル管理。

## 保存先ディレクトリ

### 検出順序

プロジェクトのADR保存ディレクトリを以下の順序で検出する:

1. `docs/adr/`
2. `docs/decisions/`
3. `doc/arch/`
4. `adr/`

いずれも見つからない場合、`docs/adr/` をデフォルトとしてユーザーに確認する。

### ディレクトリ初期化

新しいプロジェクトでADRを始める場合:

```
docs/adr/
├── 0000-use-madr-for-adr-format.md  # ADR #0: ADR形式自体の決定
├── 0001-first-decision.md
└── ...
```

## ファイル命名規則

`NNNN-title-in-kebab-case.md`

- **NNNN**: 4桁ゼロ埋め連番（0000から開始）
- **title**: ケバブケース（小文字、ハイフン区切り）
- **拡張子**: `.md`

### 連番の決定

1. ADRディレクトリ内の既存ファイルをスキャン
2. 最大の連番を取得
3. +1 した番号を使用

### タイトルの付け方

- 問題と解決策を要約する短い名詞句
- 動詞で始めるのが一般的: 「use-redis-for-caching」「choose-jwt-over-session」
- 日本語でも可（ただしファイル名は英語のケバブケース推奨）

## ライフサイクル

### ステータス遷移図

```
proposed ──┬──→ accepted ──┬──→ deprecated
           │               └──→ superseded (by new ADR)
           └──→ rejected
```

### 各ステータスの意味

公式 MADR の status フィールド書式: `proposed | rejected | accepted | deprecated | … | superseded by ADR-NNNN`

| ステータス | 意味 | 次の遷移 |
| --- | --- | --- |
| `proposed` | 提案中。レビュー・議論待ち | accepted, rejected |
| `accepted` | 承認済み。チームが従うべき決定 | deprecated, superseded by ADR-NNNN |
| `rejected` | 却下。理由を明記して保存 | なし（終了状態） |
| `deprecated` | 非推奨。もう適用しないが歴史的記録として残す | なし（終了状態） |
| `superseded by ADR-NNNN` | 新ADRに置き換え済み（NNNN は新ADRの番号） | なし（終了状態） |

### 受理済みADRの変更ルール

ADRは原則 **immutable**。ADRに記載する＝調査・検討が完了して決定済み、という前提のため、本体は基本的に書き換えない。`accepted` 後の変更は次の最小ルールに従う。

#### 1. 事実追記レーン（`Consequences` のみ）

唯一許される追記は、**決定の妥当性を補強する事後観測** を `Consequences` に記録するケースのみ：

- 想定通りの効果が観測された（「p99 が想定通り 30% 改善した」「Bad で挙げた懸念は顕在化しなかった」）
- 別方面の検証でも同じ結論が支持された（「別計測でも採用案が優位だった」「他チームの運用知見でも同様の効果」）
- 実装後の運用で得た裏付け事実

採用理由の補強もここに含める（Decision Outcome の `because …` 自体は書き換えず、Consequences の Updates に「想定通り別計測でも採用案が優位だった」等の事実として残す）。

##### 追記時の作法

`Consequences` セクション末尾に `Updates` サブセクションを設け、日付付きで集約する。見出しレベルは親セクション（h3）から1段下げて h4：

```markdown
## Decision Outcome

Chosen option: ..., because ...

### Consequences

* Good, because <決定時点で挙げた利点>
* Bad, because <決定時点で挙げた欠点>

#### Updates

* 2026-05-09: 実運用で p99 レイテンシが想定通り 30% 改善したことを確認
* 2026-08-12: Bad で挙げた接続枯渇は顕在化せず、想定範囲内で推移
```

- 既に `Updates` がある場合は同じセクションに行を足す
- frontmatter の `date` を追記日に更新する（MADR では `date` は "when the decision was last updated"）
- 元の決定文（Decision Outcome / Y-Statement / Good/Bad の本文等）は書き換えない
- 結論や根拠を否定する事実が出た場合は追記ではなく supersede

#### 2. supersede レーン（新ADR起票）

採用案または採用理由が入れ替わる場合は本体を直接書き換えず、新ADRを起票して supersede する。具体例：

- 採用する選択肢そのものを変える（例: Redis → DynamoDB）
- 採用理由（Decision Outcome の justification）を別の根拠に差し替える（例: 「速度が必要だから」→「運用コストが安いから」）
- Y-Statement の品質目標・受け入れる欠点・採用案のいずれかが変わる

#### 3. 原則禁止：他セクションへの事後追記

`Confirmation` / `Considered Options` / `Revisit Triggers` / `More Information` への事後追記は **決定時に揃えるべきだった不備**として原則禁止。これらは「調査・検討が完了した」状態の ADR で本来揃っているべきセクション。

- **Confirmation** が後から必要になる → 決定時の Confirmation 設計が不十分だった
- **Considered Options** に後発候補が出てきて再評価したい → supersede（採用案を維持するなら本体を触らず Consequences の Updates に「Option C が登場したが採用案は維持」等の事実だけ残す）
- **Revisit Triggers** を後から追加したい → 決定時の Revisit Triggers 設計が不十分だった
- **More Information** にリンクを足したい → 決定時の参考資料整理が不十分だった

不備として認識した場合、原則は supersede か decision-makers のレビューを経ての見直し。やむを得ず追記する場合も本体の該当セクションは触らず、`Consequences` の `Updates` に「決定時の Confirmation 不足を補い、自動テスト X を追加」等と理由を添えて記録する（不備の所在を読者が追えるように）。

#### 補強と差し替えの境界

| 変更内容 | 扱い | 理由 |
| --- | --- | --- |
| Redis 採用、想定通り p99 が改善した（事後観測） | 追記（Consequences の Updates） | 結論も根拠も不変 |
| Redis 採用、別計測でも採用案が優位だった（補強） | 追記（Consequences の Updates） | 元の根拠を否定せず、補強しているだけ |
| Redis 採用、理由「速度」 → Redis 採用、理由「運用コスト」 | supersede | 採用案は同じでも根拠が入れ替わっている |
| Redis 採用 → DynamoDB 採用 | supersede | 採用案そのものの入れ替え |
| 後日 Cloudflare KV が登場、採用案は Redis のまま | 追記（Consequences の Updates に「Cloudflare KV を確認したが採用案は維持」と事実記録） | 結論不変。Considered Options 本体は触らない |
| 再評価して採用案を Cloudflare KV に変える | supersede | 結論が入れ替わる |
| 後から自動テスト基準が必要になった | 原則 supersede（不備の解消）。やむを得ない場合は Consequences の Updates に理由付きで記録 | Confirmation は決定時に揃えるべき |

判定に迷う場合は supersede 側に倒す（保守的な側へ）。

### Supersedeプロセス

公式 MADR では `status` フィールド自体に置き換え関係を記録する形式を採用している:

1. **新ADRを作成**: 新しい決定を通常のADR作成プロセスで記録（`status: "proposed"`）
2. **旧ADRのステータス変更**: `status: "superseded by ADR-NNNN"` に書き換える（NNNN は新ADRの番号）
3. **新ADRから旧ADRへのリンク（推奨）**: 新ADRの More Information セクションに旧ADRへのリンクを記載する

## ADR #0 について

プロジェクトで最初に作成するADR（0000番）は、「ADRフォーマットの採用」という決定自体を記録する。これにより:

- チームがADRの存在と形式を認識する
- ADRディレクトリの初期化が行われる
- ADRプラクティスの採用が明示的に記録される
- そのプロジェクトでの**書式選択**（Y-Statement / Confirmation 等）が明示される

### ADR-0000 自動生成フロー

ADR保存ディレクトリに既存ADRがない場合、ADR-0000 をスキル側で自動生成する。生成時に `AskUserQuestion` で以下の書式選択を確認する。

#### 質問項目

1. **Y-Statement を使うか**
   - はい — すべてのADRの frontmatter に `y-statement` を含める
   - いいえ — `y-statement` は使わない

frontmatter に入る要素のため、プロジェクト内で一貫性を保つ目的で ADR-0000 で確定する。本文の任意セクション（Confirmation / Revisit Triggers 等）は ADR ごとの書き手判断に委ねるため、ここでは聞かない。

#### 回答の記録

ADR-0000 の本文に、選択した書式を明示的に記録する:

```markdown
## Decision Outcome

Chosen option: "MADR形式 + 本スキルのカスタマイズ", because ...

### このプロジェクトでの書式選択

- Y-Statement: 使う / 使わない
```

#### 以降のADRへの適用

ADR-0001以降を新規作成する際は、**必ず最初に ADR-0000 を読み**、Y-Statement の採用設定を取得してから frontmatter を組む。
