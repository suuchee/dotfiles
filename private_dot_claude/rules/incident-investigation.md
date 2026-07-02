# インシデント調査の一般規約

マルウェア感染 / データ漏洩 / 設定事故 / パフォーマンス障害 等、
「証跡を残しながら進める必要がある調査」で共通に守る原則。

## タイムスタンプ信頼度階層

**原則: サーバ上で FTP / 一般ユーザ権限で変更できない時刻源を優先して信用する。**
変更容易な時刻源 (mtime 等) は「集計 / クラスタ検出」の材料としては使ってよいが、
値そのものを「侵入時刻」として引用してはいけない。

### 信頼度の階層

| 時刻源 | 信頼度 | 取得手段 | 偽装容易さ |
| --- | --- | --- | --- |
| **access log / error log** | ◎ | サーバの `~/log/` (さくら) や `/var/log/` (Linux) | 一般ユーザ書き込み不可 = 偽装ほぼ不可 |
| **FTP / SSH ログ** (`~/log/ftp.log` 等) | ◎ | ホスティング側の daemon が書き込む | 同上 |
| **btime / crtime** (ファイル作成時刻) | ○ | SSH `stat -c %W` (Linux, 対応 FS のみ) / `stat -f %B` (BSD) | `touch` では変わらない。ただし対応していない FS ではゼロ |
| **ctime** (inode 変更時刻) | △ | SSH `stat -c %Z` (Linux) / `stat -f %c` (BSD) | `touch -t` では変わらないが `chmod` / `chown` で更新される |
| **mtime** (内容変更時刻) | ✗ | FTP LIST / `stat -c %Y` / `ls -la` | `touch -t <YYYYMMDDhhmm>` で 1 秒で任意値に偽装可能 |
| **atime** (最終参照時刻) | ✗ | `stat -c %X` | 参照するだけで変わる。`noatime` mount では停止 |

### 実務での適用

- 侵入時刻を特定したいとき、まず **access log / error log** を先に確認する
- ファイルシステム側から時刻を取るなら **btime → ctime → mtime** の順で信頼度が下がる
- FTP プロトコルからは mtime しか取れない (`MDTM` コマンド) → FTP 経路単独では時刻を確定できない
- SSH 経路が使えれば `stat -c '%W %Z %Y %n'` で btime/ctime/mtime を一度に取れる
- 「同一 mtime に集中しているファイル群」の検出は有効 (`touch -t` による偽装痕跡そのもの)。
  ただし「そのタイムスタンプ = 侵入時刻」とは限らない (攻撃者は正規更新日に合わせて偽装する)

### 報告書での書き方

- ○: 「サーバの access log では `2026-03-14 03:22 UTC` にこのパスへの POST が記録されている」
- ○: 「`bdroot.php` の btime は `2026-03-14 03:22:15` (SSH `stat -c %W` で取得、`touch` では変更不可)」
- △: 「複数ファイルの mtime が `2024-10-23 12:37:**` に統一されており touch 偽装の兆候」
  (「兆候」までは書いてよい、確定的な侵入時刻としては書かない)
- ✗: 「`bdroot.php` の mtime は `2024-10-23 12:37:12` なので侵入時刻はこの時点」
  (mtime だけを根拠にした断定はしない)

## 関連

- 具体的な検出セクションは `~/.claude/skills/wp-malware-sweep/references/attack-patterns.md` の P-10
- FTP 経路での時刻取得の制約は `~/.claude/skills/wp-malware-sweep/references/ftp-tooling.md`
