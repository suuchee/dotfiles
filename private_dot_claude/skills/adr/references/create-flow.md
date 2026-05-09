# ADR 作成フロー

新規ADRを作成する際の対話フロー。SKILL.md の「ADR起票の判定フロー」（Step 1〜5）を通って起票が必要と判定された後、または「ADR を作成したい」とユーザーが明示した場合にこのフローに従う。

判定フローを通過していない場合は、先に SKILL.md の「ADR起票の判定フロー」へ戻ること。

## Context（実行前に取得する情報）

```bash
# 現在のブランチ
git rev-parse --abbrev-ref HEAD

# 既存ADRディレクトリ
ls -d docs/adr/ docs/decisions/ doc/arch/ adr/ 2>/dev/null | head -1

# 既存ADR一覧
ls docs/adr/*.md docs/decisions/*.md doc/arch/*.md adr/*.md 2>/dev/null | sort
```

## Step 1: ADR保存先の確定と ADR-0000 の確認

### 保存先の確定

既存ADRディレクトリを以下の順序で検索：

1. `docs/adr/`
2. `docs/decisions/`
3. `doc/arch/`
4. `adr/`

いずれも存在しない場合は `docs/adr/` をデフォルトとしてユーザーに確認し、ディレクトリを作成する。

### ADR-0000 の確認

- **存在する** → 読み込んで「このプロジェクトでの書式選択」（Y-Statement の使用可否）を取得
- **存在しない** → ADR-0000 を先に生成する。`AskUserQuestion` で以下を確認：
  - **Y-Statement を使うか**（はい / いいえ）

  回答に基づいて ADR-0000「ADRフォーマットの採用」を作成する（詳細は `adr-conventions.md` の「ADR #0 について」を参照）。

## Step 2: コンテキストの収集

ユーザーと対話して以下の情報を収集する。情報が不足している場合は質問して補完し、すべて揃ってから次のステップに進む：

1. **問題の背景**: 何が起きていて、なぜ決定が必要か。決定の対象範囲も明示
2. **決定の推進要因（Decision Drivers）**: 判断に影響する品質要件・制約・force 等
3. **検討した選択肢**: 比較した代替案（最低2つ）
4. **選ばれた選択肢と理由**: なぜその選択肢を選んだか（採用理由 = justification）
5. **トレードオフ**: 受け入れる欠点やリスク
6. **見直しトリガー**: この決定を再考すべき条件（Revisit Triggers）
7. **遵守の確認手段**（任意）: 決定が守られているかを測る fitness function（Confirmation）

TODO や未確定項目が残っている場合は、ADRを起票せず `.notes/<NNN>/deliberation/` で詰めるよう案内する（SKILL.md「ADRを作成しない場面」参照）。

## Step 3: 連番の決定

ADRディレクトリ内の既存ファイルから最大の連番を取得し、+1 した番号を使用する。

## Step 4: ADRファイルの作成

公式 MADR v4.0.0 + 本スキルの拡張に従ってADRファイルを作成する。

### ファイル命名

`NNNN-title-in-kebab-case.md`（4桁ゼロ埋め連番）

### frontmatter

```yaml
---
status: "proposed"
date: YYYY-MM-DD
decision-makers: [name1]
consulted: []           # optional
informed: []            # optional
# ADR-0000 で「Y-Statement を使う」が選択されている場合のみ:
y-statement: >
  <ユースケース>の文脈において、
  <懸念事項>に直面したため、
  <品質目標>を達成するために、
  <欠点>を受け入れ、
  <選択肢>を採用することを決定した。
---
```

Y-Statement の詳細は `y-statement-guide.md` を参照。

### 本文セクション構成

完全なテンプレートは `madr-template.md` を参照。必須/任意の区別：

| セクション | 必須/任意 | 内容 |
| --- | --- | --- |
| Title | 必須 | 問題と解決策を要約する短い名詞句 |
| Context and Problem Statement | 必須 | 状況・問題（散文）。決定の対象範囲も明示 |
| Decision Drivers | 任意 | 判断に影響する要因 |
| Considered Options | 必須 | 検討した選択肢の見出し列挙（最低2つ） |
| Decision Outcome | 必須 | 採用する選択肢 + 1-2文の理由 |
| Consequences (h3) | 任意 | Decision Outcome のサブ。Good/Bad で結果を記述 |
| Confirmation (h3) | 任意 | Decision Outcome のサブ。fitness function を記述 |
| Pros and Cons of the Options | 任意 | 各選択肢の詳細分析 |
| Revisit Triggers | 任意 | 本スキル独自セクション。決定を見直すべき条件 |
| More Information | 任意 | 関連ADR、参照リンク等 |

`Confirmation` と `Revisit Triggers` の書き分けは `madr-template.md` の「Confirmation と Revisit Triggers の書き分け」セクションを参照。

how の粒度（C-1.5 基準）は SKILL.md の「ADRの定義 → ADRに書いてよい how の粒度」を参照。

## Step 5: 既存ADRとの関連付け

1. **ADR-0000 を必ず参照**: Y-Statement 採用設定を frontmatter に反映
2. 関連する既存ADRがあれば `More Information` セクションにリンク
3. 既存の決定を置き換える場合は `supersede-flow.md` のフローへ

## Step 6: 確認

作成したADRをユーザーに提示し、修正の要望を確認する。ステータスは必ず `proposed` のまま提示し、`accepted` への変更は人間が行うよう案内する（SKILL.md 運用原則 #3）。

## 出力フォーマット

```
ADR作成完了:
- ファイル: <ADRディレクトリ>/NNNN-title.md
- ステータス: proposed（accepted への変更は人間が行ってください）
- Y-Statement: <生成したY-Statement または "未使用">
```
