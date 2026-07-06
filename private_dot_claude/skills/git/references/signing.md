# 署名ポリシー（GPG / SSH）

## 原則

Git コミット・タグの署名は **人間が行う場合のみ** とする。エージェントは署名しない。

## エージェントのコミット・タグ

`commit.gpgsign` / `tag.gpgsign` が有効な環境でも、エージェントが作成するコミット・タグは **署名なし** とする。グローバル設定（人間の署名用）は変更しない。

エージェント環境では **Claude Code の `settings.json` の `env` で署名を無効化**しており、コマンドに `--no-gpg-sign` を付ける必要はない。

```jsonc
// ~/.claude/settings.json の env（git が読む GIT_CONFIG_* で config を上書き）
"GIT_CONFIG_COUNT": "2",
"GIT_CONFIG_KEY_0": "commit.gpgsign",  "GIT_CONFIG_VALUE_0": "false",
"GIT_CONFIG_KEY_1": "tag.gpgsign",     "GIT_CONFIG_VALUE_1": "false"
```

この env は `git commit` に加えて `merge` / `cherry-pick` / `revert`（いずれも `commit.gpgsign` を参照）と軽量タグまで一律に無署名化する。`-S` / `-s` を明示した場合だけ config を上書きするので署名が残るが、エージェントは署名系オプションを付けない。

> この env はエージェントのプロセス内でのみ効き、人間の端末での署名には影響しない。以前は `no-gpg-sign-guard.sh`（PreToolUse hook）で `--no-gpg-sign` を強制していたが、compound コマンドを丸ごと deny する副作用とコミット本文の誤検知があったため env による根絶へ移行した。

## サンドボックス

サンドボックス内では SSH エージェントへのソケット通信がブロックされるため、署名付きの `git commit` / `git tag` はハングまたは失敗する。

**これは意図した挙動**である。サンドボックスで署名を通すための回避策は取らない。

## 人間による署名

署名が必要なコミット・タグ（本番リリース等）は、制限のない環境でユーザーが実行する。
