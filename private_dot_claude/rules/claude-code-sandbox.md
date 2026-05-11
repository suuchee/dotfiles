# Claude Code サンドボックスの一時的な回避策

## git commit

SSH 署名（`gpg.format = ssh`）が有効な環境では、サンドボックス内の `git commit` が SSH エージェントへのソケット通信をブロックされてハングする。

**暫定対処**: `git commit` 実行時は `dangerouslyDisableSandbox: true` を付けて実行すること。

* `settings.json` で `Bash(git commit:*)` を `ask` に設定済みなので、ユーザー確認は必ず入る
* サンドボックス自体は他のコマンドの保護として有効なので無効化しない
* 根本対応（サンドボックスが SSH ソケットを許可する仕組み等）が整い次第、この対処は廃止する

## trash コマンド

サンドボックス内から `trash` で `.git` 等の VCS メタデータディレクトリを削除しようとすると、macOS の TCC レイヤーで AFP エラー（`afpAccessDenied`, `NSOSStatus -5000`）が発生して失敗する。`com.apple.provenance` 拡張属性が付与されたディレクトリのうち、`.git` のような保護名のものに対する macOS の挙動。Claude Code 側にはコマンド単位でサンドボックスを解除する設定は無い。

**暫定対処**: `trash` 実行時は `dangerouslyDisableSandbox: true` を付けて実行すること。

* `trash` は `~/.Trash` への移動なので、誤って消しても復元可能（`rm` 直接削除よりも安全）
* サンドボックス自体は他のコマンドの保護として有効なので無効化しない
* 根本対応が整い次第、この対処は廃止する
