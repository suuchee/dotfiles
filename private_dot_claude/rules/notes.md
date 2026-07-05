# notes

作業コンテキスト（ブランチ相当の作業単位）を管理する仕組み。専用の `notes` orphan ブランチを worktree（`.worktrees/notes/`）経由で扱う。正式なドキュメントは `docs/` 配下、検討中・個人作業のメモ・ノート類は notes worktree 側にコンテキスト単位で集約する。

## 常に守ること

- **パスの読み替え**: notes 側のパス（`context/...` 等）は notes worktree（`.worktrees/notes/`）内の実パスに読み替える。**新規はフラット構成**（worktree 直下がそのまま content ルート。例: `context/...` → `.worktrees/notes/context/...`）。既存 repo に旧構成の `.worktrees/notes/.notes/...` があれば、そのレイアウトに従う（既存は移行しない）。`.worktrees/notes/` が未展開なら `notes-system` スキルの `references/setup.md` に従って展開してから作業する。
- **公開境界（一方向のみ）**: main/master（及びその派生ブランチ）にコミットされるファイル（コード・`docs/`・README 等、他コントリビューターと共有される全て）には notes 側（`.worktrees/notes/...`）への参照・リンク・言及を書かない。逆に notes 側から main 側・公開 URL への参照は可。理由: notes は push しないローカル専用ブランチで他者は持たないため、共有ファイルが notes を参照すると辿れない・壊れた参照になる。main 側は notes 無しで単独完結させる。
- **notes は push しない**: `notes` ブランチはローカル専用。`git push origin notes` / `git push -u origin notes` を実行しない。push 系コマンドは `&&` で他コマンドに連結せず常に独立実行し、対象ブランチを毎回明示的に確認する。
