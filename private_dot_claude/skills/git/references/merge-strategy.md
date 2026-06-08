# マージ戦略

作業ブランチを統合する際のマージ方式の選択。

## 既定: --no-ff を使う

作業ブランチを統合する際は **`git merge --no-ff <branch>` でマージコミットを残す**のを既定にする。`--ff-only` / `--squash` / rebase + ff は明示的に選んだ場合だけ使う。

**既定を --no-ff にする理由**:
- 履歴上で「どの commit 群が 1 つの作業ブランチだったか」が一目で分かる
- 後から `git revert <merge-commit> -m 1` で作業ブランチ単位の取り消しが可能
- 既存リポジトリのマージ履歴（過去のマージコミット）と整合する
- PR / コードレビュー単位が履歴に永続化される

```bash
# 既定: マージコミットを残す
git switch main
git merge --no-ff <branch>
```

## 各方式のメリデメと使い所

| 方式 | メリット | デメリット | 使い所 |
| --- | --- | --- | --- |
| `merge --no-ff` | ブランチ境界が履歴に残る / `revert -m 1` で機能単位ロールバック / PR・レビュー単位が永続化 | 履歴が分岐合流で非線形になる / 1 commit でも余分なマージコミットが作られる | 複数 commit の feature / refactor、レビュー対象、チーム開発で経緯を追いたい場面（**推奨デフォルト**） |
| `merge --ff-only` | 履歴が線形 / 余分なマージコミットなし / リベース忘れを強制的にエラーで検出 | ブランチ境界が消える / 機能単位 revert ができない / ベース更新時はリベースが必要 | 単発 hot-fix、線形履歴を厳格に維持するチーム |
| `merge`（既定の自動判断） | ff 可能なら ff、無理ならマージコミット | 同コマンドで結果が変わり予測困難 | 使わない（明示的に `--no-ff` か `--ff-only` を選ぶ） |
| `merge --squash` | feature の細かい WIP コミットを main に残さない / main の log がきれい | 粒度・著者・タイムスタンプが失われる / 機能単位より粗い revert になる / 元コミットへのリンクが切れる | WIP 多めの feature を 1 commit で統合（GitHub の Squash and Merge 相当） |
| `rebase` + ff マージ | 線形履歴 / feature commit が main の最新の上に並ぶ | rebase の衝突対応コスト / 共有ブランチでは force push が必要 / PR の差分と履歴が乖離 | 線形履歴を維持しつつ commit 粒度を保ちたいチーム合意がある場合 |

## 事前にリポジトリのマージ履歴を確認する

新しいリポジトリで作業を始める時は `git log --merges --oneline -20` で既存のマージ運用を見てから合わせる。

- `Merge branch 'feature/xxx'` のマージコミットが並んでいる → --no-ff 運用
- マージコミットがほぼ無い線形履歴 → --ff-only or rebase 運用
- 1 PR = 1 commit の履歴 → squash 運用

リポジトリの既存運用と外れた方式で merge すると履歴が崩れて他メンバーが混乱するので、**既存運用に合わせるのが最優先**。既存運用が無い（新規リポジトリ）場合のみ上記の既定（--no-ff）を採用する。

## fast-forward してしまった場合のリカバリ

作業ブランチの ref が残っていれば、main を戻して --no-ff で再マージできる。

```bash
# 例: main を 1 つ前 (M) に戻して --no-ff で再マージ
git switch main
git reset --hard <previous-commit>     # ※ 作業ブランチ ref が残っていることを確認
git merge --no-ff <branch>
```

作業ブランチの ref が消えていても、`git reflog` でコミット hash を辿れば復元可能。`reset --hard` は destructive なので、ブランチ ref か reflog で対象 commit を確認してから実行する。
