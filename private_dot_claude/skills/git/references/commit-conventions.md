# コミットメッセージ規約

[Conventional Commits](https://www.conventionalcommits.org/) を土台とし、本リポジトリ独自のルールを加えた Git 運用規約。

## フォーマット

```text
<type>(<scope>): <description>
wip(<scope>): <description>
```

- **type**: 変更の種類（必須）。作業途中のチェックポイントは `wip`（後述）
- **scope**: 変更対象の領域（任意、例: `infra/stg`, `frontend`, `api`）
- **description**: 変更内容の説明（必須）

### 作業途中（wip）

未完成・断片的な変更を履歴に残す場合、type に `wip` を使う。

| 例 | 用途 |
| --- | --- |
| `wip(auth): OAuth コールバックの骨組みを追加` | 機能実装の途中地点 |
| `wip(deps): lodash を 4.x に更新中` | 依存更新の途中地点 |
| `wip: 設定ファイルの整理中` | scope 不要な場合 |

- Conventional Commits の標準 type ではない（本規約の独自拡張）
- `feat` / `fix` 等へ置き換えてもよいが、必須ではない
- マージ前に squash 等で整理する場合は、最終コミットを本来 type にする

**draft はコミットに付けない**

ドラフトはブランチ名の `-draft` サフィックスで表現する（「ブランチ命名規則」を参照）。

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

### 独自拡張

| type | 対象 | 例 |
| --- | --- | --- |
| `wip` | 作業途中のチェックポイント | `wip(auth): OAuth コールバックの骨組みを追加` |

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

- **type**: ブランチプレフィックス（下表参照）
- **description**: ケバブケース（小文字、ハイフン区切り）
- **issue**: Issue 番号（任意）

### ドラフト（`-draft` サフィックス）

ブランチ名末尾の `-draft` で、ドラフト作業であることを示す。

```text
<type>/<description>-draft
<type>/<issue>-<description>-draft
```

| ブランチ名 | 意味 |
| --- | --- |
| `feature/add-auth-draft` | ドラフト作業。レビュー・マージ可能だが最終版ではない |
| `feature/add-auth` | 通常作業。最終版として取り込む意図 |

- コミットメッセージには付けない
- 最終版として取り込む場合は `-draft` なしのブランチ名を使う
- ドラフトのまま取り込む場合は `-draft` サフィックスのままでよい

### description の付け方

**「何をするか（What）」を表す名前にする。「なぜ（Why）」や背景を名前にしない。**

ブランチ名を見ただけで、どんな変更が含まれているか分かる名前にする。

| 観点 | 良い例 | 悪い例 | 理由 |
| --- | --- | --- | --- |
| What vs Why | `feature/singleton-gcp-clients` | `feature/cloud-run-memory-optimization` | 後者は背景（メモリ問題）であり、変更内容（シングルトン化）が伝わらない |
| 具体的 | `bugfix/fix-null-pointer-in-login` | `bugfix/login-error` | 何を直すかが明確 |
| 簡潔 | `feature/add-email-verification` | `feature/add-email-verification-to-signup-flow-for-security` | 長すぎない |

### Git-Flow プロジェクトの場合

Git-Flow を採用しているプロジェクトでは、ブランチプレフィックスは Git-Flow の規約に従う。
リファクタリングやパフォーマンス改善など Git-Flow に専用プレフィックスがないものは `feature/` を使用する。

| ブランチ type | 用途 | コミット type |
| --- | --- | --- |
| `feature` | 新機能・リファクタリング・改善 | `feat`, `refactor`, `perf` 等 |
| `bugfix` | develop からのバグ修正 | `fix` |
| `hotfix` | 本番（main/master）の緊急修正 | `fix` |
| `release` | リリース準備 | `chore` |
| `support` | 旧バージョンの保守 | `fix` |

### 例

| ブランチ名 | 説明 |
| --- | --- |
| `feature/add-auth` | 認証機能の追加 |
| `feature/add-auth-draft` | 認証機能のドラフト作業 |
| `feature/singleton-gcp-clients` | GCP Client のシングルトン化 |
| `bugfix/123-login-error` | Issue #123 のログインエラー修正 |
| `hotfix/critical-crash` | 本番の緊急クラッシュ修正 |

### Git-Flow 以外のプロジェクトの場合

| ブランチ type | コミット type |
| --- | --- |
| `feat` | `feat` |
| `fix` | `fix` |
| `refactor` | `refactor` |
| `docs` | `docs` |
| `chore` | `chore` |
