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
