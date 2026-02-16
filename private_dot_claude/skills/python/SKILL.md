---
name: python
description: This skill should be used when the user asks to "create Python project", "Pythonプロジェクト作成", "uv", "ruff", "Python開発", "仮想環境", "パッケージ管理", or mentions Python development, linting, formatting, or package management with uv/ruff.
---

# Python Development

Python 開発環境の規約とベストプラクティスを定義する。

## 概要

このスキルは以下の場面で使用する：
- Python プロジェクトのセットアップ
- 仮想環境の作成・管理
- パッケージの追加・削除
- リンター・フォーマッターの実行
- エラーハンドリングの実装

## パッケージ管理: uv

Python 仮想環境およびパッケージ管理は **uv** を使用する。

### プロジェクト初期化

```sh
# 新規プロジェクト作成
uv init project-name
cd project-name

# 既存ディレクトリで初期化
uv init
```

### 仮想環境

```sh
# 仮想環境作成（自動）
uv sync

# パッケージ追加
uv add requests

# 開発用パッケージ追加
uv add --dev pytest

# パッケージ削除
uv remove requests
```

### スクリプト実行

```sh
# 仮想環境内でスクリプト実行
uv run python script.py

# 仮想環境内でコマンド実行
uv run pytest
```

## リンター・フォーマッター: ruff

リンターおよびフォーマッターは **ruff** を使用する。

ruff は uv に同梱されているため、明示的な依存関係追加は不要。

```sh
# リント実行
uv run ruff check .

# リント + 自動修正
uv run ruff check --fix .

# フォーマット実行
uv run ruff format .

# フォーマットチェック（変更なし）
uv run ruff format --check .
```

## エラーハンドリング

### logger.exception() の使用

try-except 内でログを出力する場合は `logger.exception()` を使用する。

```python
import logging

logger = logging.getLogger(__name__)

try:
    do_something()
except Exception:
    logger.exception("エラーが発生しました")
    raise
```

**理由**: `logger.exception()` は自動的にスタックトレースを含めるため、デバッグ情報が充実する。

### 避けるべきパターン

```python
# ❌ 避ける: スタックトレースが失われる
except Exception as e:
    logger.error(f"エラー: {e}")

# ❌ 避ける: 例外を握りつぶす
except Exception:
    pass
```

## pyproject.toml 設定例

```toml
[project]
name = "project-name"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP"]
```
