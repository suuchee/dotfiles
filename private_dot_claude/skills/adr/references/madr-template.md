# MADR Template (v4.0.0)

MADR (Markdown Architectural Decision Records) テンプレート。

## テンプレート

```markdown
---
status: {proposed | accepted | rejected | deprecated | superseded}
date: YYYY-MM-DD
decision-makers: [name1, name2]
consulted: [name3]     # optional
informed: [name4]      # optional
y-statement: >         # Y-Statement形式の要約
  ...
supersedes: ""         # optional: 置き換え元のADRファイル名
superseded-by: ""      # optional: 置き換え先のADRファイル名
---

# タイトル（問題と解決策の短い要約）

## Context and Problem Statement

{2-3文で問題の背景を説明する。何が起きていて、なぜ決定が必要か。}

## Decision Drivers

* {driver 1: 決定に影響を与える要因}
* {driver 2: ...}
* ...

## Considered Options

* {option 1}
* {option 2}
* {option 3}
* ...

## Decision Outcome

Chosen option: "{option N}", because {1-2文で理由を説明}。

### Consequences

* Good, because {肯定的な結果}
* Good, because {肯定的な結果}
* Bad, because {否定的な結果（トレードオフ）}
* …

### Confirmation

{決定がどのように検証・確認されるか。コードレビュー、テスト、メトリクス等}

## Pros and Cons of the Options

### {option 1}

{option 1の説明（1-2文）}

* Good, because {argument a}
* Good, because {argument b}
* Neutral, because {argument c}
* Bad, because {argument d}
* …

### {option 2}

{option 2の説明}

* Good, because {argument a}
* Good, because {argument b}
* Bad, because {argument c}
* …

## More Information

{追加の根拠、参照リンク、関連ADRへのリンク、チームでの合意事項等}
```

## セクション記述ガイド

### Title

- 問題と解決策を短く要約する名詞句
- 例: 「APIレスポンスのキャッシュにRedisを使用」「認証方式にJWTを採用」

### Context and Problem Statement

- 2-3文で簡潔に記述
- 何が起きていて、なぜこの決定が必要か
- 技術的な制約だけでなく、ビジネス上の背景も含める

### Decision Drivers

- 決定に影響を与えた要因を箇条書きで列挙
- 技術的要因: パフォーマンス、保守性、学習コスト等
- ビジネス要因: コスト、スケジュール、チームスキル等

### Considered Options

- 最低2つの選択肢を列挙
- 「何もしない（現状維持）」も有効な選択肢

### Decision Outcome

- 「Chosen option: "選択肢名", because 理由。」の形式
- 理由は簡潔に1-2文

### Consequences

- Good / Bad / Neutral で分類
- Bad（否定的な結果）も正直に記録する
- トレードオフとして受け入れる欠点を明記

### Confirmation

- 決定の遵守をどう確認するか
- 例: コードレビュー、CI/CDチェック、アーキテクチャテスト

### Pros and Cons of the Options

- 各選択肢の詳細な長所・短所を記述
- Good / Bad / Neutral で重み付け

### More Information

- 参照リンク、関連ADR、チームでの議論の記録等
- 関連するADRがあれば相互リンクを記載

## 必須セクションとオプションセクション

| セクション | 必須/オプション |
| --- | --- |
| Title | 必須 |
| Context and Problem Statement | 必須 |
| Decision Drivers | オプション（推奨） |
| Considered Options | 必須 |
| Decision Outcome | 必須 |
| Consequences | オプション（推奨） |
| Confirmation | オプション |
| Pros and Cons of the Options | オプション（推奨） |
| More Information | オプション |
