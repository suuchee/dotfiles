---
status: "accepted"
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

プロジェクトの設計判断が口頭やチャットでのみ議論され、正式な記録として残されていない。新しいメンバーがプロジェクトに参加した際、「なぜこの技術を選んだのか」「なぜこのアーキテクチャなのか」を理解する手段がなく、同じ議論が繰り返されている。今後のADR運用ルートを確立するため、フォーマットを決定する必要がある。

## Decision Drivers

* 構造化されたテンプレートで記述品質を均一化したい
* ツール（markdownlint等）による自動検証が可能であること
* GitHub/GitLab上でのレンダリングと相互参照のしやすさ
* 将来の参照性とSupersedeのしやすさ

## Considered Options

* MADR (Markdown Architectural Decision Records)
* Nygard Basic（5セクション形式）
* Y-Statement単体
* ADRを導入しない

## Decision Outcome

Chosen option: "MADR", because 構造化されたセクション（Decision Drivers, Considered Options, Pros and Cons）により決定の背景と比較検討が体系的に記録でき、markdownlint による自動検証も可能であるため。

### このプロジェクトでの書式選択（本スキル独自）

- Y-Statement: 使う

Confirmation / Revisit Triggers / Pros and Cons of the Options 等の任意セクションは、ADR ごとの書き手判断で記載する。

### Consequences

* Good, because 決定の背景、代替案、トレードオフが構造的に記録される
* Good, because Markdown形式でGitリポジトリに自然に統合できる
* Good, because テンプレートの任意セクションにより、記述量を柔軟に調整できる
* Bad, because テンプレートのセクション構造を覚える学習コストが発生する
* Bad, because 軽微な決定に対してはオーバーヘッドに感じる可能性がある

### Confirmation

* 新しいADRが作成された際のコードレビューで、MADR形式に従っているかを確認する
* Y-Statement が frontmatter に含まれていることを確認する

## Pros and Cons of the Options

### MADR

構造化されたMarkdownテンプレート（v4.0.0）。Decision Drivers、Considered Options、Pros and Cons of the Options のセクションが明確に定義されている。

* Good, because 必須/任意セクションの区別があり柔軟
* Good, because markdownlint による自動検証が可能
* Good, because GitHub/GitLab での表示に最適化されている
* Neutral, because v4.0.0 が安定版であり、今後の大きな変更は予想されない
* Bad, because フルテンプレートはやや長い

### Nygard Basic

Title, Status, Context, Decision, Consequencesの5セクションのみのシンプルな形式。

* Good, because 学習コストが最小
* Good, because 記述のオーバーヘッドが少ない
* Bad, because 代替案の比較検討が構造化されていない
* Bad, because Decision Drivers が明示されない

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

## Revisit Triggers

* ADR数が50を超え、現在のフラットなディレクトリ構造での検索性が悪化した時
* チームが分散し、より重い承認プロセスが必要になった時
* MADR が v5 以上にメジャー更新され、現在の書式と互換性が失われた時

## More Information

* [MADR公式サイト](https://adr.github.io/madr/)
* [ADR GitHub Organization](https://adr.github.io/)
* Y-Statement を MADR の frontmatter に統合することで、「一行要約 + 詳細記録」の二層構造を実現する
