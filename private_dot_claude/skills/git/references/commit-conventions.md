# コミットメッセージ規約

[Conventional Commits](https://www.conventionalcommits.org/) に基づく Git 運用規約。

## フォーマット

```text
<type>(<scope>): <description>
```

- **type**: 変更の種類（必須）
- **scope**: 変更対象の領域（任意、例: `infra/stg`, `frontend`, `api`）
- **description**: 変更内容の説明（必須）

## type 一覧

### 標準（Conventional Commits 仕様）

| type | 対象 | 例 |
| --- | --- | --- |
| `feat` | エンドユーザー向けの新機能 | 新API、新画面、新しい振る舞い |
| `fix` | バグ修正 | 不具合の修正、エラーハンドリング修正 |

### 推奨（Angular convention ベース）

| type | 対象 | 例 |
| --- | --- | --- |
| `build` | ビルドシステム・外部依存の変更 | webpack設定、npm scripts |
| `chore` | 上記以外のメンテナンス | 設定ファイル整理 |
| `ci` | CI/CD設定の変更 | GitHub Actions、cloudbuild.yaml |
| `docs` | ドキュメントのみの変更 | README、APIドキュメント |
| `perf` | パフォーマンス改善 | 速度向上、メモリ最適化 |
| `refactor` | 機能変更を伴わないコード改善 | 可読性向上、構造整理 |
| `style` | コードの意味に影響しない変更 | フォーマット、UI調整 |
| `test` | テストの追加・修正 | 新規テスト、テスト修正 |

## scope の使い方

scope は任意だが、変更対象を明確にしたい場合に使用する。

### よく使われる scope

| scope | 用途 | 例 |
| --- | --- | --- |
| `deps` | 依存関係の更新 | `chore(deps): lodash を更新` |
| `security` | セキュリティ修正 | `fix(security): XSS脆弱性を修正` |
| `ui` | UI/見た目の調整 | `style(ui): ボタンの余白を調整` |
| `a11y` | アクセシビリティ | `feat(a11y): スクリーンリーダー対応` |

### scope の指針

- シンプルに保つ（1語が理想）
- プロジェクト内で一貫性を持たせる
- モノレポの場合はパッケージ名を使うことが多い

## 判断ガイドライン

### UI変更の判断

| 変更内容 | 推奨 | 理由 |
| --- | --- | --- |
| ボタンの色・余白調整 | `style(ui):` | 視覚的調整のみ |
| デザインリニューアル | `feat:` | ビジネス的意図あり |
| ダークモード対応 | `feat:` | 新機能 |
| アクセシビリティ改善 | `feat(a11y):` | ユーザー体験の向上 |

### 依存関係更新の判断

| 変更内容 | 推奨 | 理由 |
| --- | --- | --- |
| 通常の更新 | `chore(deps):` | メンテナンス |
| セキュリティ修正 | `fix(deps):` または `fix(security):` | バグ修正扱い |
| ビルド影響あり | `build(deps):` | ビルドシステムへの影響 |

## 記述ルール

- 変更の「理由」を可能な限り記述する
- 日本語の場合は文章の途中に改行を入れない
- 1行目は簡潔に（50文字程度を目安）
- 詳細が必要な場合は空行を挟んで本文を記述

## ブランチ命名規則

### フォーマット

```text
<type>/<description>
<type>/<issue>-<description>
```

- **type**: コミットプレフィックスの type に対応（`feature`, `fix`, `refactor` 等）
- **description**: ケバブケース（小文字、ハイフン区切り）
- **issue**: Issue 番号（任意）

### 例

| ブランチ名 | 説明 |
| --- | --- |
| `feature/add-auth` | 認証機能の追加 |
| `fix/123-login-error` | Issue #123 のログインエラー修正 |
| `refactor/api-client` | APIクライアントのリファクタリング |
| `docs/update-readme` | README の更新 |

### type の対応

| ブランチ type | コミット type |
| --- | --- |
| `feature` | `feat` |
| `fix` | `fix` |
| `refactor` | `refactor` |
| `docs` | `docs` |
| `chore` | `chore` |

**補足**: ブランチ名では `feat` より `feature` が一般的（可読性のため）
