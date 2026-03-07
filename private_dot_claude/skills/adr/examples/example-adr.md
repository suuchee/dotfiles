---
status: accepted
date: 2026-03-08
decision-makers: [hayakawa]
consulted: [team-lead]
y-statement: >
  プロジェクトのアーキテクチャ決定の記録方法において、
  設計判断の文脈が失われ同じ議論が繰り返される問題に直面したため、
  構造化された意思決定の記録と将来の参照性を達成するために、
  テンプレートの学習コストが発生することを受け入れ、
  MADR形式のADRを採用することを決定した。
---

# MADR形式をADRフォーマットとして使用する

## Context and Problem Statement

プロジェクトの設計判断が口頭やチャットでのみ議論され、正式な記録として残されていない。新しいメンバーがプロジェクトに参加した際、「なぜこの技術を選んだのか」「なぜこのアーキテクチャなのか」を理解する手段がなく、同じ議論が繰り返されている。

## Decision Drivers

* 設計判断の経緯をコードベースと一緒にバージョン管理したい
* 新メンバーのオンボーディングコストを削減したい
* テンプレートが構造化されており、記述の品質を均一化したい
* ツール（Linter等）による自動検証が可能であること

## Considered Options

* MADR (Markdown Architectural Decision Records)
* Nygard Basic（5セクション形式）
* Y-Statement単体
* ADRを導入しない

## Decision Outcome

Chosen option: "MADR", because 構造化されたセクション（Decision Drivers, Considered Options, Pros/Cons）により、決定の背景と比較検討が体系的に記録でき、markdownlintによる自動検証も可能であるため。

### Consequences

* Good, because 決定の背景、代替案、トレードオフが構造的に記録される
* Good, because Markdown形式でGitリポジトリに自然に統合できる
* Good, because テンプレートのオプションセクションにより、記述量を柔軟に調整できる
* Bad, because テンプレートのセクション構造を覚える学習コストが発生する
* Bad, because 軽微な決定に対してはオーバーヘッドに感じる可能性がある

### Confirmation

* 新しいADRが作成された際のコードレビューで、MADR形式に従っているかを確認する
* Y-Statementフロントマターが含まれていることを確認する

## Pros and Cons of the Options

### MADR

構造化されたMarkdownテンプレート（v4.0.0）。Decision Drivers、Considered Options、Pros/Consのセクションが明確に定義されている。

* Good, because 必須/オプションセクションの区別があり柔軟
* Good, because markdownlintによる自動検証が可能
* Good, because GitHub/GitLabでの表示に最適化されている
* Neutral, because v4.0.0が安定版であり、今後の大きな変更は予想されない
* Bad, because フルテンプレートはやや長い

### Nygard Basic

Title, Status, Context, Decision, Consequencesの5セクションのみのシンプルな形式。

* Good, because 学習コストが最小
* Good, because 記述のオーバーヘッドが少ない
* Bad, because 代替案の比較検討が構造化されていない
* Bad, because Decision Driversが明示されない

### Y-Statement単体

1文で決定の本質を表現する軽量形式。

* Good, because 極めて軽量で記述が速い
* Good, because 決定の核心を簡潔に伝える
* Bad, because 詳細な背景や代替案の記録には不十分
* Bad, because 複雑な決定の文書化には向かない

### ADRを導入しない

現状維持。設計判断は口頭やチャットで共有する。

* Good, because 新しいプロセスの導入コストがゼロ
* Bad, because 設計判断の文脈が失われ続ける
* Bad, because 同じ議論が繰り返されるコストが蓄積する

## More Information

* [MADR公式サイト](https://adr.github.io/madr/)
* [ADR GitHub Organization](https://adr.github.io/)
* Y-StatementをMADRのフロントマターに統合することで、「一行要約 + 詳細記録」の二層構造を実現する
