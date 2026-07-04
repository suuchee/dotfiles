# 概要

ここでは、GitHub上のリモートリポジトリをVSCodeを主体として操作するための環境構築の手順を記述する。

<!-- @import "common.md" -->

# 手順

1. SSHキーの生成

    1. 秘密鍵のファイルパスを決める

        公開鍵のファイル名でコンピュータの識別もできるような名前をつけておけば、GitHubへ公開鍵登録時に公開鍵のタイトルをファイル名にすれば悩む必要はなくなる（パスの入力間違えを予防するため、一時的に環境変数を設定している）

        - RSA の場合、以下のようなファイル名推奨

            ```zsh
            % private_key_path=~/.ssh/id_rsa_github_macbookair
            ```

        - ED25519 の場合、以下のようなファイル名推奨

            ```zsh
            % private_key_path=~/.ssh/id_ed25519_github_macbookair
            ```

        以下のコマンドを打ち、0と表示されれば既にファイルが存在しているため、ファイル名を考え直す必要がある。1と表示されればOK。

        1. 秘密鍵の確認

            ```zsh
            % ls ${private_key_path} > /dev/null 2>&1 ; echo $?
            ```

         2. 公開鍵の確認

            ```zsh
            % ls ${private_key_path}.pub > /dev/null 2>&1 ; echo $?
            ```

    2. 秘密鍵と公開鍵の生成

        パスワード入力を求められたら、秘密鍵に設定する新規パスワードを入力する。`-C` はコメントの指定で、自分のメールアドレスを入力してもOK。

        ```zsh
        % ssh-keygen -t ed25519 -C "" -f ${private_key_path}
        ```

    3. 鍵が生成されたかどうか確認

        いずれも0と表示されればOK。

       1. 秘密鍵の生成確認

        ```zsh
        % ls ${private_key_path} > /dev/null 2>&1 ; echo $?
        ```

       2. 公開鍵の生成確認

        ```zsh
        % ls ${private_key_path}.pub > /dev/null 2>&1 ; echo $?
        ```

    4. ファイルパーミッションの変更

        ```zsh
        % chmod 600 ${private_key_path}
        ```

2. GitHubへSSHキー（公開鍵）の登録

    1. 公開鍵を登録する

        以下にアクセスし、「New SSH key」ボタンを押す。

        [https://github.com/settings/keys](https://github.com/settings/keys)

      1. Titleに公開鍵のファイル名を入力（自分で区別できればなんでもOK）

      2. 以下コマンドを入力し、公開鍵をクリップボードへコピーする

        ```zsh
        % cat ${private_key_path}.pub | pbcopy
        ```

      3. Keyに `2.` でコピーした公開鍵を貼り付け、「Add SSH key」を押し、公開鍵の登録を完了させる。

3. SSHの設定ファイルを開く

    VSCode Remote Development 拡張機能から `SSH Targets` の設定マークを押す。

    または、Finderを開いた状態で `command + shift + G` を押し、`~/.ssh/config` と入力して `return` キーを押す。

4. SSHの設定ファイルの編集

    `IdentityFile` のパスは ssh-agent デーモンに秘密鍵を登録した時のコマンド入力時と同じパスを入力する。

    GitHubの場合、`User` は `git` でないとダメ。

    `identityFile` は秘密鍵への実際の絶対パスを入力する（以下はあくまでも例）。

    なお、`UseKeychain` と `AddKeysToAgent` については、毎回パスワードを入力しないために設定している（macOSのキーチェーンアプリを利用するためのオプション）。

    ```plaintext
    # GitHub
    Host github github.com
      User git
      HostName github.com
      IdentityFile ~/.ssh/id_ed25519_github_macbookair
      IdentitiesOnly yes
      UseKeychain yes
      AddKeysToAgent yes
    ```

5. 接続確認

    以下コマンドを打ち込むと、フィンガープリントの確認をされるので `yes` と入力し、秘密鍵生成時に設定したパスワードを入力して確定する。（GitHubの場合、なぜかこのコマンドを入力しないと認証がうまくいかない事がある）

    ```zsh
    % ssh -T git@github.com
    ```

    なおVSCodeから自動でfetchコマンドを実行させたりしたい場合に、`UseKeychain` や `AddKeysToAgent` を設定しないと、上記のようにパスワード入力を定期的に求められたり、あるいはインタラクティブに処理ができないために裏でエラーが起きてしまったりする。

6. リポジトリのクローン

    - コマンドの場合

        ```zsh
        % cd ${リポジトリをクローンしたいディレクトリ}
        % git clone ${git_ssh_url}
        ```

    - VSCodeの場合

        `command` + `shift` + `P` でコマンドパレットを開き、`git clone` と入力する。

        作成した確認用のリポジトリをコピペして `return` を押す。

        クローンするディレクトリを選んで `return` を押す。

7. リポジトリへのプッシュ

    最初は、ブランチが複数あるため、一括でプッシュするためにコマンドを入力する

    ここについては、VSCodeでやる方法がわからない

    ```zsh
    % git push -u --all origin
    ```

# 参考

- [Testing your SSH connection](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh/testing-your-ssh-connection)

<!-- @import "terms.md" -->
