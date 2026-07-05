---
name: adr
description: This skill should be used when the user asks to "ADR作成", "アーキテクチャ決定記録", "設計判断を記録", "技術選定を文書化", "ADR一覧", "ADR確認", "決定を置き換え", or when making architecturally significant decisions like choosing frameworks, databases, API designs, authentication strategies, deployment patterns, or data models. Also use when the user mentions "ADR", "architecture decision", "design decision", discusses technology trade-offs, or asks about past architectural decisions in the project. Use this skill proactively when you detect the user is making an important design choice that should be recorded.
---

# Architecture Decision Record (ADR)

アーキテクチャ上の重要な決定を記録・管理するためのスキル。

## Purpose

- アーキテクチャ上重要な決定（ASR: Architecturally Significant Requirement）を検知し、ADR作成を提案する
- MADR形式でADRを作成する
- 既存ADRのライフサイクル管理（ステータス変更、置き換え）
- ADRの一覧表示と検索

## ADRの定義

ADR（Architecture Decision Record）は、**今後の設計・実装・運用の前提になる意思決定** を記録する文書。設計書・仕様書・作業ログ・調査メモ・TODOリストとは別物。ADRに書くのは「**なぜ**その判断をしたか」であり、「どう実装するか」「どう振る舞うか」ではない。

### 他の置き場との切り分け

| 置き場 | 何を書くか |
| --- | --- |
| **ADR**（`docs/adr/`） | **なぜ**その判断をしたか（背景・選択肢・採用理由・トレードオフ） |
| **設計書**（`docs/design/` 等） | その判断を**どう実現するか**（実装方針・内部ロジック設計） |
| **仕様書**（`docs/spec/` 等） | **外部から見える振る舞い・契約**（CLI 引数一覧、JSON 出力形式、エラーコード網羅） |
| **research**（notes の `context/<NNN>/research/`） | 判断の根拠になった**事実・調査結果**（公式仕様確認、ベンチマーク、引用） |
| **Issue / plan / TODO** | **これからやる作業**（未確定事項、Phase X で検討、未実装タスク） |

ADR本体から notes への参照リンクは書かない（公開境界の方向性。詳細は品質ガードレール参照）。research の要点は ADR に要約として再記述する。

### ADRに書いてよい how の粒度（C-1.5 基準）

ADRには「**判断の理解に必要な最小限のスケッチ**」までは含めてよい。書きすぎたら設計書・仕様書・research へ逃がす：

- **OK**（ADR本体に置く）: 採用案を表現する CLI 例 1〜2 個、TypeScript インターフェース定義 1 個、JSON サンプル 1 件、決定の根拠となる主要数値・引用元URL・重要事実
- **NG**（設計書/仕様書/research へ）: 全コマンドの引数網羅、JSON 出力形式の網羅定義、エラーコード一覧、内部処理分岐の詳細表、調査ログ全文

書いていて網羅的になり始めたら、ADRから外すシグナル。

## 運用原則

1. **粒度をアトミックに保つ** — 1つのADRが扱う判断は1件のみ。複数の判断を束ねたい場合はそれぞれ別のADRに分割する
2. **受理済みは原則 immutable。例外は「結論補強の事実追記」のみ** — ADRに記載する＝調査・検討が完了して決定済みのはず。本体は基本的に書き換えない。`accepted` 後の変更は以下の最小ルールに従う：
   - **追記レーン**: `Consequences` の末尾に `#### Updates` サブセクションを設け、**決定の妥当性を補強する事後観測**（「想定通り p99 が 30% 改善」「別方面の計測でも採用案が優位だった」「Bad で挙げた懸念は顕在化しなかった」等）のみ追記する。frontmatter の `date` を更新
   - **supersede レーン**: 採用案そのものの入れ替え、採用理由（justification）の差し替え、Y-Statement の品質目標 / 受け入れる欠点 / 採用案の変更は本体を書き換えず必ず新ADRを起票
   - **原則禁止**: Confirmation / Considered Options / Revisit Triggers / More Information の事後追記は **決定時に揃えるべきだった不備**。やむを得ず追記する場合も `Consequences` の Updates に「決定時の Confirmation 不足を補う形で確認手段を後付けした」等と理由を添えて記録し、本体の該当セクションは触らない
   - 誤字脱字や明白な誤りの修正は意味を変えない範囲で可。判断に迷う場合は supersede 側に倒す
   - 詳細は `references/adr-conventions.md` の「受理済みADRの変更ルール」を参照
3. **AI生成は `proposed` で固定** — AI が作るADRのステータスは常に `proposed`。`accepted` への昇格は人間の判断に限定する。ステータス変更を依頼されても AI 側で書き換えず「人間が確認のうえ変更してください」と返す
4. **却下した選択肢も保存する** — 採用しなかった案こそ、将来の再検討時に「なぜそちらにしなかったか」を補う文脈になる。Considered Options / Pros and Cons of the Options に残す

## ADR保存先の決定

プロジェクトのADR保存ディレクトリを以下の順序で検出する:

1. 既存ディレクトリの検索: `docs/adr/`, `docs/decisions/`, `doc/arch/`, `adr/`
2. CLAUDE.mdやREADMEにADRパスの記述がないか確認
3. いずれも見つからない場合、`docs/adr/` をデフォルトとしてユーザーに確認

## ADR-0000 の生成（初回のみ）

ADR保存ディレクトリに既存ADRがない場合、ADR-0000「ADRフォーマットの採用」を生成する。これによりプロジェクト固有の書式選択を明示的に記録する。

`AskUserQuestion` で以下を確認する:

- **Y-Statement を使うか**（はい / いいえ）

回答を踏まえて ADR-0000 を作成し、本文に Y-Statement の採用可否を記録する。

Confirmation セクションと Revisit Triggers セクションは公式 MADR / 本スキルの任意セクションとして書き手判断に委ねる（ADR-0000 で制御しない）。

詳細な手順は `references/adr-conventions.md` を参照。

## ADR起票の判定フロー

変更や判断を検知した際、以下の順に判定する。**「カテゴリに該当するか」ではなく「意思決定があるか」で判定する**（DB変更・ライブラリ追加だけで機械的にADR起票しないため）。

### Step 1: 意思決定か？

単なる作業・修正・実装ではなく、方針を選ぶ判断があったか？

- **YES**: Step 2へ
- **NO**: ADR不要

### Step 2: 複数の現実的な選択肢があったか？

他にも妥当な選択肢があり、その中から選んだか？

- **YES**: Step 3へ
- **NO**: ADR不要（理由が重要なら設計メモ・コミットメッセージに残す）

### Step 3: 影響範囲は横断するか？

判断が複数の機能・レイヤー・コンポーネント・運用・将来の変更に影響するか？

- **YES**: Step 4へ
- **NO**: ADR不要（局所的な判断なら設計メモまたはコメントで十分）

### Step 4: 既存ADRで説明済みか？

既存ADR・設計文書で判断理由がすでに説明されているか？

- **YES**: 新規ADRは作成しない（必要なら既存ADRへの参照を追加）
- **NO**: Step 5へ

### Step 5: 将来、理由が問題になりそうか？

理由を残さないと、将来同じ議論・逆方向の実装・誤解が起きそうか？

- **YES**: ADRドラフト（status: `proposed`）を作成
- **NO**: ADR不要（必要なら作業ログに残す）

### 圧縮形

> 現実的な選択肢があり、後続の判断を縛り、理由を忘れると再議論になりそうなら、ADRを書く。

### ADR候補になる代表例（参考）

以下は ADR 候補になりうる変更の代表例。**ただし、上記の判定フローを通った場合のみ起票する**（カテゴリに該当するだけでは起票しない）：

#### 技術選定

- 主要なライブラリ・フレームワーク・外部サービスをプロジェクトの標準として採用・変更する
- 認証・認可方式の決定
- API プロトコル・設計方針の決定（REST vs GraphQL 等）
- メッセージング・キューイング方式の選択
- 今後の実装方針に影響する依存関係の追加

#### アーキテクチャ

- マイクロサービス vs モノリス
- レイヤー構成、責務分割、依存方向、API 方式
- データモデル・所有者・整合性ルールの構造的判断
- キャッシュ戦略
- 同期 / 非同期、イベント駆動、バッチ処理の方針

#### インフラ・運用

- デプロイ方式、実行基盤、ネットワーク構成、認証方式
- 監視、ログ、バックアップ、リカバリ、障害対応方針
- 運用コスト・可用性・セキュリティに影響する構成

#### 非機能要件

- セキュリティ、パフォーマンス、可用性、拡張性、保守性に関する方針
- ある非機能要件を優先し、別の要件を妥協する判断

#### 既存方針からの逸脱

- 既存ADRと異なる方針の採用
- 既存ADRの例外、廃止、更新

### 検知のシグナル

以下のシグナルを検知した場合、判定フローを通したうえで ADR 提案を検討する：

- 「〜にした」「〜を使うことにした」「〜を採用する」などの決定を示す表現
- 複数の選択肢を比較検討している議論
- トレードオフの議論（「〜の方が速いが、〜の方が保守しやすい」）
- 将来の開発に影響を与える構造的な変更

シグナルを検知しても、判定フローを通らなければADRにしない。**変更種別だけで自動的にADR化しない**。

## ADR操作フロー

判定フローを通って起票が確定した後の対話フローは、用途別に `references/` 配下のフローファイルに集約している。SKILL.md は判断軸を定義する場所、フロー本体は references が単一ソース：

| 操作 | フロー定義 |
| --- | --- |
| 新規ADRの作成 | `references/create-flow.md` |
| 既存ADRの置き換え（Supersede） | `references/supersede-flow.md` |
| 既存ADR一覧の表示 | `references/list-flow.md` |

各フローは公式 [MADR v4.0.0](https://adr.github.io/madr/) + 本スキルの拡張（`y-statement` frontmatter / `Revisit Triggers` セクション / `Updates` サブセクション）に従う。テンプレートと書式は `references/madr-template.md` を参照。

## ライフサイクル管理

### ステータス一覧

公式 MADR の status フィールド書式: `proposed | rejected | accepted | deprecated | … | superseded by ADR-NNNN`

| ステータス | 意味 | 遷移 |
| --- | --- | --- |
| `proposed` | 提案中（レビュー待ち） | → accepted / rejected |
| `accepted` | 承認済み | → deprecated / superseded by ADR-NNNN |
| `rejected` | 却下（理由を明記） | 終了状態 |
| `deprecated` | 非推奨（もう適用しない） | 終了状態 |
| `superseded by ADR-NNNN` | 新ADRに置き換え済み（NNNN は新ADRの番号） | 終了状態 |

### 受理済みADRへの事実追記

ADRは原則 immutable。例外として、決定の妥当性を補強する事後観測のみ `Consequences` への追記を許す：

1. `Consequences` セクション末尾に `#### Updates` サブセクションを設ける（既にあれば再利用）
2. `- YYYY-MM-DD: <観測事実>` の形式で1行追記する
3. frontmatter の `date` を追記日に更新する（MADR の `date` は "when the decision was last updated"）
4. 元の決定文（Decision Outcome / Y-Statement / Pros and Cons の Good/Bad 等）には触らない

`Consequences` 以外（Confirmation / Considered Options / Revisit Triggers / More Information）への事後追記は原則禁止。これらは決定時に揃えるべきセクション。詳細は `references/adr-conventions.md` の「受理済みADRの変更ルール」を参照。

### Supersede（置き換え）プロセス

採用案または採用理由が入れ替わる場合のみ supersede する。入れ替わらないなら上記の事実追記レーンを使う。公式 MADR では `status` フィールド自体に置き換え関係を記録する形式を採用しており、本スキルもこれに従う（旧ADRの `status` を `"superseded by ADR-NNNN"` に書き換える）。

具体的な対話フローは `references/supersede-flow.md` を参照（判定ガード Step 0 で3レーンに振り分け、補強と差し替えの境界例を含む）。

## Important Guidelines

### 品質ガードレール

1. **事実に基づく記録**: 推測や仮定ではなく、実際の議論や決定に基づいて記録する
2. **トレードオフの明記**: 選ばれた選択肢の欠点も客観的に記録する
3. **代替案の公平な評価**: 採用されなかった選択肢も、それぞれの長所・短所を記録する
4. **断定的な言語**: 決定セクションは「〜を使用する」「〜を採用する」など断定形で記述する
5. **調査結果は要点を本体に書く** — 採用理由を裏付ける主要な調査結果（数値・引用元URL・重要事実）は `Decision Outcome` の `because …` と `Pros and Cons of the Options` に要約として含める。試行錯誤のログや全候補の細かい計測など個人作業領域の素材は ADR に持ち込まない（個人作業として notes の `context/<NNN>/research/` に残す）
6. **公開境界を守る（ADR から notes への参照禁止）** — ADR はチーム向け公開ドキュメント、notes は個人作業領域。**`docs/`（ADR含む）→ notes 方向のリンクは書かない**。notes → ADR の片方向のみ。ADR本体に書く外部リンクは `docs/` 配下・GitHub・公式ドキュメント等の公開リソースに限定する
7. **TODO や調査途中の項目を持ち込まない** — ADRに記載する＝調査・検討は完了している前提。TODO・未確定の比較・検討途中のメモは notes の `context/<NNN>/deliberation/` 等で扱い、決まってから ADR を起票する
8. **how の粒度を保つ（C-1.5 基準）** — ADR本体に書くのは「**判断の理解に必要な最小限のスケッチ**」まで（CLI 例 1〜2 個、インターフェース定義 1 個、JSON サンプル 1 件等）。**網羅的な how**（全コマンドの引数一覧、JSON 出力形式の網羅定義、エラーコード一覧、内部処理分岐表）は **設計書・仕様書** に逃がす。書いていて網羅的になり始めたらADRから外すシグナル。詳細は冒頭の「ADRの定義」セクション参照

### ADRを作成しない場面

- **既存ADR・設計文書で判断済みのケース** — 既存方針に従った実装はADR不要。**変更種別だけで機械的に起票しない**（DB変更・ライブラリ追加・コード変更があっても、既存方針の範囲内なら新規ADRは作らない。判定フロー Step 4 で「既存ADRで説明済み」と判定される）
- 日常的なバグ修正、小さなリファクタリング
- 1ファイル・1関数・1画面に閉じた局所的な変更
- UI 文言、余白、色、表示順などの細かい調整
- 一時的な修正やワークアラウンド
- 明白な実装詳細（変数名の選択等）
- 単なる作業メモ、TODO、調査メモ
- 調査・検討が未完了で、TODO や未確定項目が残っている段階（先に notes の `context/<NNN>/` で詰めてから起票）
- README やコメントで十分な実装説明

## Additional Resources

### Reference Files

#### 規約・テンプレート

- **`references/madr-template.md`** - MADRテンプレート、各セクションの記述ガイド、Confirmation と Revisit Triggers の書き分け
- **`references/adr-conventions.md`** - ADR規約（保存先、命名、連番、ライフサイクル、受理済みADRの変更ルール、ADR-0000生成）
- **`references/y-statement-guide.md`** - Y-Statement形式の作成ガイド

#### 操作フロー

- **`references/create-flow.md`** - 新規ADR作成の対話フロー
- **`references/supersede-flow.md`** - 既存ADR置き換え（Supersede）の対話フロー（Step 0 判定ガード含む）
- **`references/list-flow.md`** - 既存ADR一覧表示の対話フロー

### Example Files

- **`examples/example-adr.md`** - ADRの完成例
