# dotfiles

chezmoi を使用した dotfiles 管理リポジトリです。

## 前提条件

chezmoi がインストールされていること。インストール方法は公式ドキュメントを参照してください。

## セットアップ

```bash
chezmoi init suuchee
```

## 使い方

※ 適用先に同名ファイルがある場合は上書きされるため、事前にバックアップを推奨します。

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
