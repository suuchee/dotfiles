# notes

作業コンテキスト（ブランチ相当の作業単位）を管理する仕組み。専用の `notes` orphan ブランチを worktree（`.worktrees/notes/`）経由で扱う。正式なドキュメントは `docs/` 配下、検討中・個人作業のメモ・ノート類は notes worktree 側にコンテキスト単位で集約する。

## 常に守ること

- **パスの読み替え**: notes 側のパス（`context/...` 等）は notes worktree（`.worktrees/notes/`）内の実パスに読み替える。**新規はフラット構成**（worktree 直下がそのまま content ルート。例: `context/...` → `.worktrees/notes/context/...`）。既存 repo に旧構成の `.worktrees/notes/.notes/...` があれば、そのレイアウトに従う（既存は移行しない）。`.worktrees/notes/` が未展開ならセットアップ手順に従って展開してから作業する。
- **公開境界（一方向のみ）**: notes → `docs/` / 公開 URL への参照は可。`docs/` → notes（`.worktrees/notes/...`）の逆参照は禁止（流動的な notes に安定した公開 docs を依存させない。公開 docs は notes 無しで単独完結させる）。
- **notes は push しない**: `notes` ブランチはローカル専用。`git push origin notes` / `git push -u origin notes` を実行しない。push 系コマンドは `&&` で他コマンドに連結せず常に独立実行し、対象ブランチを毎回明示的に確認する。

## 詳細リファレンス

セットアップ（orphan ブランチ / worktree 展開 / LFS 設定）・ディレクトリ構造・CONTEXT.md フォーマット・命名規則・運用・worktree 内 Bash 操作の注意は `~/.claude/skills/notes-system/SKILL.md` を参照する。
