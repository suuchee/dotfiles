# chezmoi 管理下 dotfile の編集

`~/.claude` `~/.agents` `~/.cursor` など chezmoi 管理下のファイルを変更するときは、**home の実ファイルを直接編集せず、chezmoi source を編集して apply する**。home を直接編集すると source と乖離し、次の `chezmoi apply` で変更が巻き戻る／別の変更を上書きする事故につながる。

## 手順

1. 対象が chezmoi 管理下か確認する: `chezmoi source-path <target>`（管理外ならエラー）
2. `source-path` が返すパス（例: `~/.claude/settings.json` → `private_dot_claude/private_settings.json`）を編集する
3. `chezmoi diff <target>` で反映内容を確認する
4. `chezmoi apply <target>` で home に反映する
5. コミットは chezmoi リポジトリ（source）側で行う

## home は自分以外も書き換える

home の設定ファイルは、次の要因で source より新しくなっていることがある。source を「常に正」と決めつけない。

* Claude Code やエディタのランタイムが直接書き込む（モデル変更・権限プロンプトの保存・トグル等）
* 並行して別セッションが編集・`chezmoi re-add` する

このため:

* `chezmoi apply` の前に必ず `chezmoi diff` で差分を確認する。丸ごと apply が想定外の巻き戻しを起こさないか見る（＝レースガード。意図した差分だけかを確認してから apply する）
* source が古いと判明したら、どちらを正とするかを中身で判断し、home を正とするなら `chezmoi re-add <target>` で同期してから目的の変更を加える
* 差分が想定を超えて大きい、または別セッションの編集痕跡があるときは、apply せず状況を報告する

## 関連: Claude Code のコマンドマッチングは quote-aware

permission ルール（allow/deny/ask）と hook の `if: "Bash(...)"` は、複合コマンドを演算子（`&& || ; | & 改行`, `$()`, backtick）で分割し、各サブコマンドを独立評価する。**先頭一致ではなく、引用符内の演算子・コマンドは区切りとみなさない（quote-aware）**。

* `deny: Bash(rm -rf:*)` は `cd x && rm -rf y` もブロックする
* `if: "Bash(rm:*)"` は `cd x && rm -rf y` でも発火する（`rm` サブコマンドが一致するため）
* `git commit -m "... rm ..."` は引用符内なので `rm` サブコマンド扱いされず発火しない
* したがって、自前フックで生のコマンド文字列を正規表現マッチすると quote 非対応で誤検知する。可能な限り判定は Claude Code 側のマッチング（`if` / permission ルール）に委ね、スクリプトは通過後の処理に絞る
