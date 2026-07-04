# SSHを使う理由

- リモートリポジトリ操作時にパスワード入力を省くため
- SSHを利用したこの方法なら、OSやGitのホスティングサービスが違っても基本的には同様の手順でVSCodeからのGit操作が行えるようになるため

# 事前に必要な環境構築

1. Git, Git-Flowプラグインのインストール

    ```bash
    % brew install git git-flow
    ```

2.  Gitの初期設定

    ```zsh
    % git config --global user.name "my-sample-macbook-air"
    % git config --global user.email "sample@gmail.com"
    % git config --global --list
    ```

3. VSCode 拡張機能インストール

    - [Remote Development](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack)
    - [Git Graph](https://marketplace.visualstudio.com/items?itemName=mhutchie.git-graph)
    - [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens)

5. Gitホスティングサービスのアカウント作成（持っていない場合）

# リモートリポジトリの開始

主に以下のいずれかの方法でリモートリポジトリを開始できる。

1. リモートリポジトリを作成してからローカルにクローンし、作業する方法

2. ローカルでリポジトリを作成し、作業してからリモートリポジトリを作成し、ローカルリポジトリにリモートリポジトリの情報を設定してプッシュする方法
