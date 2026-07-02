---
name: slack
description: Slack を MCP 経由で検索・読み取り・投稿するときに使う。「Slack で共有」「チャンネルを検索」「スレッドを読んで」等の指示で発火する。プライベートチャンネルが検索に出てこない・GitHub Bot メッセージの本文が空になる・Markdown テーブルやブロック引用が表示されない、といった Slack MCP 特有の落とし穴を回避するための注意点をまとめている。
---

# Slack

## MCP 利用時の注意

* **プライベートチャンネルの検索**: `slack_search_channels` はデフォルトで `public_channel` のみ検索する。プライベートチャンネルを含める場合は `channel_types: "public_channel,private_channel"` を指定する
* **GitHub Bot メッセージの制限**: GitHub 連携の Bot メッセージは attachment/block 形式で送信されるため、`slack_read_channel` / `slack_search_public_and_private` では本文（Text）が空になる。GitHub の情報を取得したい場合は `gh` CLI で直接 GitHub API を叩く方が確実
* **書式の制限**: Slack は Markdown テーブルを表示できない。共有用メッセージは箇条書き形式で作成する。ブロック引用（`>`）は使わず、太字見出し・箇条書き・絵文字を使った平文で作成する
