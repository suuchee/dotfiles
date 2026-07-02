# chezmoi 管理下 dotfile の編集

`~/.claude` `~/.agents` `~/.cursor` 等は home を直接編集せず chezmoi 経由で扱い、コミットは source 側で行う。向きは「誰がそのファイルを書くか」で決める。

- **人間が編集する dotfile**: source-first。`chezmoi source-path` で source を特定 → 編集 → `chezmoi apply`。
- **アプリが書き込むファイル**（`~/.claude/settings.json`・エディタ設定等）: home-first。ランタイムが home を書き換えるため home が正。丸ごと apply するとモデル・トグル等を巻き戻す。home を変更後 `chezmoi re-add` で取り込む。

apply / re-add / コミットの前に `chezmoi diff` で意図した差分だけかを確認する（home は並行セッション・ランタイムに書き換えられている前提）。
