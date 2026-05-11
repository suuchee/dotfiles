# Slack

## MCP

* **プライベートチャンネルの検索**: `slack_search_channels` はデフォルトで `public_channel` のみ検索する。プライベートチャンネルを含める場合は `channel_types: "public_channel,private_channel"` を指定すること
* **GitHub Bot メッセージの制限**: GitHub 連携の Bot メッセージは attachment/block 形式で送信されるため、Slack MCP の `slack_read_channel` / `slack_search_public_and_private` では本文（Text）が空になる。GitHub の情報を取得したい場合は `gh` CLI で直接 GitHub API を叩く方が確実
* **Slackの書式制限**: Slack はMarkdownテーブルを表示できない。共有用メッセージは箇条書き形式で作成すること。ブロック引用（`>`）は使わず、太字見出し・箇条書き・絵文字を使った平文で作成する
