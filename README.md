# dotfiles

chezmoi を使用した dotfiles 管理リポジトリです。

## 前提条件

chezmoi がインストールされていること。インストール方法は公式ドキュメントを参照してください。

## セットアップ

```bash
chezmoi init suuchee
```

## 使い方

**⚠️ `chezmoi apply` は確認なしで上書きされ、元に戻せません。事前に `chezmoi diff` で差分を確認し、バックアップを推奨します。**

### 差分確認・適用

```bash
# 現在の状態との差分を表示
chezmoi diff

# 特定ファイルの差分を表示
chezmoi diff ~/.zshrc

# 特定ディレクトリの差分を表示
chezmoi diff -r ~/.claude

# ドライラン
chezmoi apply -nv

# 全適用
chezmoi apply -v

# 特定ファイルの適用
chezmoi apply -v ~/.zshrc

# 特定ディレクトリの適用
chezmoi apply -v ~/.claude
```

### ファイルの追加・更新

```bash
# 特定のファイルを追加/更新
chezmoi add ~/.zshrc

# 既存の管理ファイルを現在の状態で上書き
chezmoi add --force ~/.zshrc

# 複数ファイルを一度に追加
chezmoi add ~/.bashrc ~/.profile

# テンプレートとして追加（変数展開を使う場合）
chezmoi add --template ~/.config/some-config

# 管理している全ファイルを現在の状態で一括反映
chezmoi re-add
```

### 機密ファイルの追加

```bash
chezmoi add --encrypt ~/.ssh/id_rsa
```

### 注意点

- `chezmoi add` はホームディレクトリ → ソースディレクトリの方向
- `chezmoi apply` はソースディレクトリ → ホームディレクトリの方向
