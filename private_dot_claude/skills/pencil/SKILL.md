---
name: pencil
description: Pencil（pencil.dev）の `.pen` デザインファイルを読み書き・編集するときに使う。`.pen` の閲覧・ノード編集・レイアウト変更、Pencil MCP ツール（batch_design / batch_get 等）の利用、対応する `.structure.md` の運用が必要な場面で発火する。
---

# Pencil（.pen ファイル）

Pencil（pencil.dev）は Figma のようなデザインツールで、`.pen` ファイルで UI デザインを管理する。

## アクセス方法

* `.pen` ファイルの実体は plain JSON だが、Pencil MCP server 自体が `Read` / `Grep` を禁じている（schema 整合性とエディタの編集状態との同期を MCP に集約する設計）。したがって `.pen` の読み書きは Pencil MCP ツール経由で行う
* Pencil MCP には明示的な「保存」操作がない。`batch_design` の変更はエディタのメモリ上に反映されるが、ディスクへの永続化はユーザーが Pencil エディタ側で保存する必要がある
* 大きな変更の区切りごとにユーザーへ保存を促す

## 構造ファイル（.structure.md）

* `.pen` ファイルと同じディレクトリに `<ファイル名>.structure.md` を配置し、ノードツリー構造（ID・名前・主要プロパティ）を記録する
* `.pen` ファイルを操作する前に、対応する `.structure.md` があれば先に `Read` で読み込み、既知の ID と構造を把握してから作業する
* `batch_get` は結果が巨大になりやすいため、構造ファイルで既知の情報を活用し、必要なノードだけをピンポイントで取得する
* `.pen` ファイルの構造を変更した場合は、`.structure.md` も更新する
* `.structure.md` の更新はコンテキストを圧迫するため、サブエージェント（Agent ツール）に委任する
  * ただし、バックグラウンド実行（`run_in_background: true`）のサブエージェントはファイル編集の許可プロンプトがブロックされるため、ファイル編集を含むタスクはフォアグラウンドで実行するか、メインで直接編集する
