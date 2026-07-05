# ディレクトリ構造と運用

content ルート（`<ROOT>`）の定義は `../SKILL.md` の「content ルート（`<ROOT>`）」節を参照する。

## 構造

```text
<ROOT>/                          # notes worktree の content ルート（新規: .worktrees/notes/）
└── context/
    └── <NNN>_<prefix>_<name>/
        ├── CONTEXT.md           # メタ情報（目的、背景、ステータス等）
        ├── intent/              # 意思決定レイヤー（goal / constraints / decisions 等。使い方は各自）
        ├── plan/                # 計画・実装設計
        ├── research/            # 調査・技術検証
        ├── requirements/        # 要望・要件
        ├── deliberation/        # 検討・比較
        ├── conversation/        # 会話ログ
        ├── spec/                # 仕様（検討中。正式版は docs/ へ）
        ├── evidence/            # 証跡・検証の集積レイヤー（使い方は各自。下は例）
        │   ├── forensic/        #   例: マルウェア/インシデント調査の証跡（改変せず保持）
        │   └── trail/           #   例: 監査証跡・操作ログ
        └── assets/              # 素材レイヤー（動画/画像/参考メモ等、必要時のみ）
            ├── recordings/      #   画面収録・録画
            ├── screenshots/     #   スクリーンショット（日付などで階層化）
            └── references/      #   外部ドキュメント・配布資料
```

コンテキストは必ず `<ROOT>/context/` 配下に置く。`<ROOT>` 直下にコンテキストディレクトリを作らない（将来 `<ROOT>` 直下を別用途に使えるよう、中間層 `context/` を維持する）。

各レイヤーは必要に応じて追加するもので、すべてのコンテキストで揃える必要はない（軽いタスクなら plan/ や research/ だけでよい）。

`assets/` は元素材（動画・画像・配布資料など）を集めるためのもので、コンテキスト独自の派生ファイル（要約・対応表など）は `research/` 等の通常レイヤーに置く。素材と分析を分けることで原本を変更せず参照できる。

## 運用

- 新しい作業を始める際、連番を振ってコンテキストを作成
- ブランチを作成する場合、コンテキスト名とブランチ名を一致させる
- ブランチを作成しない場合でも、同じ形式で命名
- 既存コンテキストへの追記は、その番号のディレクトリに行う
- plan 確定後、plan ファイルを該当コンテキストの `plan/` に保存
- コンテキストへの変更は notes ブランチ上でコミットする（worktree 内で `git add` / `git commit`）
- worktree が展開されていない場合（`.worktrees/notes/` が存在しない場合）は、`setup.md` に従って展開してから作業する
- 検討が固まり正式化する内容は `docs/` 配下へ昇格させる
