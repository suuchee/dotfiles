# MADR Template

[MADR (Markdown Architectural Decision Records)](https://adr.github.io/madr/) v4.0.0 の公式テンプレートをベースに、本スキル独自の追加要素を加えたもの。

公式ソース: [adr/madr - template/adr-template.md (develop branch)](https://github.com/adr/madr/blob/develop/template/adr-template.md)

## 公式 MADR からの追加要素

本スキルは公式 MADR を以下のように拡張している:

- **frontmatter に `y-statement` フィールドを追加** — Y-Statement形式の決定要約（ADR-0000 で「使う」を選んだ場合のみ）
- **`## Revisit Triggers` セクションを追加** — この決定を見直すべき条件を明示する任意セクション
- **`Consequences` 配下の `#### Updates` サブセクション** — 受理済みADRに対し、決定の妥当性を補強する事後観測のみ追記できる任意サブセクション。`Consequences` 以外への事後追記は原則禁止（決定時に揃えるべき不備として扱う）。詳細は `adr-conventions.md` の「受理済みADRの変更ルール」を参照

それ以外は公式テンプレートに従う。

## テンプレート

以下は公式 MADR テンプレート（develop branch）に本スキルの拡張を加えたもの。

```markdown
---
# These are optional metadata elements. Feel free to remove any of them.
status: "{proposed | rejected | accepted | deprecated | … | superseded by ADR-0123}"
date: {YYYY-MM-DD when the decision was last updated}
decision-makers: {list everyone involved in the decision}
consulted: {list everyone whose opinions are sought (typically subject-matter experts); and with whom there is a two-way communication}
informed: {list everyone who is kept up-to-date on progress; and with whom there is a one-way communication}
# 本スキル独自フィールド（ADR-0000 で「使う」を選んだ場合のみ）:
y-statement: >
  <ユースケース>の文脈において、
  <懸念事項>に直面したため、
  <品質目標>を達成するために、
  <欠点>を受け入れ、
  <選択肢>を採用することを決定した。
---

# {short title, representative of solved problem and found solution}

## Context and Problem Statement

{Describe the context and problem statement, e.g., in free form using two to three sentences or in the form of an illustrative story. You may want to articulate the problem in form of a question. Consider adding links to collaboration boards or issue management systems. Make the scope of the decision explicit, for instance, by calling out or pointing at structural architecture elements (components, connectors, ...).}

<!-- This is an optional element. Feel free to remove. -->

## Decision Drivers

* {decision driver 1, for instance, a desired software quality, faced concern, constraint or force}
* {decision driver 2}
* … <!-- numbers of drivers can vary -->

## Considered Options

* {title of option 1}
* {title of option 2}
* {title of option 3}
* … <!-- numbers of options can vary -->

## Decision Outcome

Chosen option: "{title of option 1}", because {justification. e.g., only option, which meets k.o. criterion decision driver | which resolves force {force} | … | comes out best (see below)}.

<!-- This is an optional element. Feel free to remove. -->

### Consequences

* Good, because {positive consequence, e.g., improvement of one or more desired qualities, …}
* Bad, because {negative consequence, e.g., compromising one or more desired qualities, …}
* … <!-- numbers of consequences can vary -->

<!-- 本スキル独自サブセクション。受理済みADRへの事後追記はここのみ許可。決定の妥当性を補強する事後観測（想定通りの効果、別方面の検証、結論を支持する裏付け事実等）を日付付きで残す。既存の Good/Bad 行は書き換えない。結論や根拠を否定する事実が出た場合は追記ではなく supersede。 -->

#### Updates

* {YYYY-MM-DD}: {決定の妥当性を補強する事後観測。例: 想定通り p99 が改善した / 別計測でも採用案が優位 / Bad で挙げた懸念は顕在化しなかった}

<!-- This is an optional element. Feel free to remove. -->

### Confirmation

{Describe how the implementation / compliance of the ADR can/will be confirmed. Is there any automated or manual fitness function? If so, list it and explain how it is applied. Is the chosen design and its implementation in line with the decision? E.g., a design/code review or a test with a library such as ArchUnit can help validate this. Note that although we classify this element as optional, it is included in many ADRs.}

<!-- This is an optional element. Feel free to remove. -->

## Pros and Cons of the Options

### {title of option 1}

<!-- This is an optional element. Feel free to remove. -->

{example | description | pointer to more information | …}

* Good, because {argument a}
* Good, because {argument b}
<!-- use "neutral" if the given argument weights neither for good nor bad -->
* Neutral, because {argument c}
* Bad, because {argument d}
* … <!-- numbers of pros and cons can vary -->

### {title of other option}

{example | description | pointer to more information | …}

* Good, because {argument a}
* Neutral, because {argument b}
* Bad, because {argument c}
* …

<!-- This is an optional element. Feel free to remove. 本スキル独自セクション -->

## Revisit Triggers

* {この決定を見直すべき条件 1: 例「想定する負荷を3倍超えた時点」}
* {条件 2: 例「ライブラリのメジャーバージョン更新で破壊的変更が入った時」}

<!-- This is an optional element. Feel free to remove. -->

## More Information

{You might want to provide additional evidence/confidence for the decision outcome here and/or document the team agreement on the decision and/or define when/how this decision the decision should be realized and if/when it should be re-visited. Links to other decisions and resources might appear here as well.}
```

## セクションの必須/任意

公式 MADR の分類に従う（`<!-- This is an optional element. -->` のコメントが付いているセクションが任意）:

| セクション | 必須/任意 | 備考 |
| --- | --- | --- |
| Title | 必須 | |
| Context and Problem Statement | 必須 | |
| Decision Drivers | 任意 | |
| Considered Options | 必須 | |
| Decision Outcome | 必須 | |
| Consequences (h3) | 任意 | Decision Outcome のサブセクション |
| Confirmation (h3) | 任意（多くのADRで含まれる） | Decision Outcome のサブセクション。ADR-0000 の選択次第で出し分け |
| Pros and Cons of the Options | 任意 | |
| Revisit Triggers | 任意 | **本スキル独自セクション** |
| More Information | 任意 | |
