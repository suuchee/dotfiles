# Branch Strategy Pivot

ブランチの選択・切替・性格変更の判断と操作。

## 1. 既存ブランチで作業を始めるか、新ブランチを切るか

CLAUDE.md 方針 2 (セッション開始時のブランチ確認) で「現ブランチが今の作業に適切か」を判定する。

### 適切でないと判断するサイン

- 現ブランチ名から想起される作業と、今の話題が一致しない
- 既コミットの commit message の prefix がブランチ名の意図と乖離している (例: `docs:` を `feature/` に積んでいる)
- ユーザーから「この作業は別性格」「○○とは別」のような指摘がある

### 選択肢

| 選択肢 | 適する場合 |
| --- | --- |
| 別ブランチを新規に切る | 既ブランチで他に進める作業がある / 既コミットは現性格を保ちたい |
| 現ブランチをリネーム + 元名を別 base から再生成 | 既コミットが「今の作業」側の性格 / 元ブランチ名で別作業を後で再開したい |
| 既コミットを cherry-pick で別ブランチに分離 | 既コミットの中に複数性格が混在 |

## 2. 作業ブランチの性格が当初想定と変わった場合のリカバリ

「現ブランチで別性格の作業を始めてしまい、既コミットも別性格寄り」のパターン。

### 判断フロー

1. `git log --oneline <base>..HEAD` で既コミットを確認
2. 既コミットの性格を判定:
   - **「今の作業」側** → リネーム + 元名を base から再生成 (本セクションの「操作」)
   - **「ブランチ本来の作業」側** → 別ブランチを「今の作業」用に切る (既ブランチは触らない)
   - **混在** → cherry-pick で分離 (セクション 3)

### 操作 (リネーム + 再生成)

```bash
# 1. 現ブランチを「今の作業」用にリネーム (既コミットをそのまま引き継ぐ)
git branch -m <current> <renamed-for-current-work>

# 2. 元のブランチ名を base から再生成 (HEAD は移動しない)
git branch <current> <base>
# <base> は main / origin/main / 特定の commit hash 等
```

**メリット**:
- stash / cherry-pick / reset 不要
- 既コミットをそのまま引き継ぐ (履歴の連続性が保たれる)
- 元のブランチ名で別作業を後で再開できる

### 関連手順との違い

- `git checkout -b <new>`: 新ブランチを作成して checkout するだけ。元のブランチに既コミットが残る。「現在の履歴ごと名前を付け替える」場合は `git branch -m` を使う
- `git stash` + `git switch -c`: 未コミット変更だけを別ブランチに移す。本手順は「コミット済みの履歴ごと移す」ケース

## 3. 既コミットを別ブランチに分離する (cherry-pick)

複数性格が混在する場合の操作。

```bash
# 別ブランチを新規作成 + checkout
git switch -c <new-branch>

# 対象コミットを cherry-pick (元ブランチで対象が HEAD なら不要)
git cherry-pick <commit-hash>

# 元ブランチに戻り、対象コミットを除去
git switch <original-branch>
# 対象が HEAD の場合: git reset --hard HEAD~1
# 中間にある場合: git rebase -i で対象行を drop
```

cherry-pick 後の元ブランチ整理の詳細は SKILL.md「cherry-pick 後のブランチ整理」を参照。

## 具体例 (パターン)

機能ブランチ `feature/X` で `feat:` のコミットを積む想定だったが、`docs:` や `refactor:` のコミットを 2 本積んでしまい、続きの作業もそちらにシフトする見込みになった場合:

```bash
git branch -m feature/X docs/refactor-Y    # リネーム
git branch feature/X main                  # 元名を base から再生成
```

結果:
- `docs/refactor-Y` で既コミット 2 本を引き継いで作業継続
- `feature/X` は main から再開可能な状態で待機

## 関連

- CLAUDE.md 方針 2 (セッション開始時のブランチ確認)
- `~/.claude/rules/git-tips.md` (ベースブランチからの移行・マージ戦略・worktree)
- SKILL.md「コミット前の確認」(現在のブランチ確認の段)
- SKILL.md「cherry-pick 後のブランチ整理」
