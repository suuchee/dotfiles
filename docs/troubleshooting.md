# トラブルシューティング

## zsh 補完が効かない場合

`compaudit` を実行して、補完システムに問題がないか確認してください。

```bash
compaudit
```

安全でないディレクトリやファイルが表示された場合は、パーミッションを修正します。

```bash
# 例: /opt/homebrew/share が insecure と表示された場合
% compaudit
There are insecure directories:
/opt/homebrew/share

# グループの書き込み権限を外す
% chmod go-w /opt/homebrew/share
```

まとめて修正する場合は以下でも可能です。

```bash
compaudit | xargs chmod go-w
```

## Claude Code サンドボックス下で `gh` が TLS 証明書エラーで失敗する

### 症状

Claude Code のサンドボックス有効時、`gh`（GitHub CLI）が以下で失敗する。

```
Post "https://api.github.com/graphql": tls: failed to verify certificate: x509: OSStatus -26276
```

`gh pr list` / `gh api user` など、GitHub API を叩くコマンド全般で発生する。

### 切り分け結果

同じサンドボックス下で以下を確認した。

| コマンド | 結果 |
| --- | --- |
| `curl https://api.github.com` | ✅ 200 |
| `curl https://github.com` | ✅ 200 |
| `gh api user` | ❌ `tls: failed to verify certificate: OSStatus -26276` |
| `gh pr list` | ❌ 同上 |

`github.com` / `api.github.com` は `~/.claude/settings.json` の `sandbox.network.allowedDomains` に登録済みで、curl は 200 を返す（＝ホスト到達性の問題ではない）。落ちるのは `gh`（Go バイナリ）だけ。

### 原因

Claude Code のサンドボックスは全通信を **MITM プロキシ経由**（`HTTPS_PROXY=http://…@localhost:<port>`、Basic 認証付き）に強制し、そこで TLS を終端してドメイン許可リストを検査している。

- `curl` は macOS キーチェーン経由でこの中継証明書を信頼するため通る
- `gh`（Go）は macOS Security framework 検証で中継証明書を信頼せず、`OSStatus -26276` で拒否する

つまり **`allowedDomains` レイヤーの問題ではなく、TLS 中継証明書の信頼の問題**。プロキシのポート・証明書はセッションごとに変わる。

### 対処

**`gh` はサンドボックスを外して実行する**（Claude Code なら `dangerouslyDisableSandbox: true`）。読み取り系 `gh`（`gh pr list` / `gh pr view` / `gh api` 等）は permission allow に登録済みのため、サンドボックスを外しても追加の許可プロンプトは出ない。対象が GitHub への読み取りに限られる限り、除外のリスクは低い。

### やっても無駄なこと・非推奨

- **`allowedDomains` への GitHub ホスト追加**: 既に登録済みで到達可能。ホスト不足ではないため無効。
- **中継 CA を `SSL_CERT_FILE` 等で `gh` に信頼させる**: プロキシのポート・証明書がセッションごとに変わるため恒久設定にできず、堅牢性の観点で非推奨。

*記録日: 2026-07-05*
