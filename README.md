# repo-kit

GitHubのリポジトリを整え、診断する作業を、Claude Codeに進めてもらうためのスキル集です。開発を始めるとき、開発の途中で品質や安全性を確かめるとき、公開する前に使います。

## 何をするか

### setup：開発の土台を足す

開発の開始時でも途中でも使えます。次のファイルのうち、足りないものだけを、リポジトリに合わせて埋めて置きます。すでにあるファイルは上書きしません。

- Issue・PRのテンプレート
- AGENTS.md、CLAUDE.md（AIエージェント向けの決まり）
- CONTRIBUTING.md
- .gitignore、.env.example
- 権限を読み取りに絞ったCI、Dependabotの設定
- LICENSE、SECURITY.md

### publish：公開する前に整える

次の5つを、この順に進めます。1と2は読み取りだけで、結果を見てから3以降に進みます。

1. 点検：ファイル、CIのワークフロー、GitHubの設定を調べ、足りないものを一覧にする
2. 秘密情報・個人情報の検査：鍵やトークン、メールアドレス、電話番号、ローカルのパスを、コミット履歴も含めて探す
3. ファイルの追加と削除：作業用の文書を消し、足りないファイルをsetupのテンプレートで足す
4. READMEの仕上げと校正：足りない節を書き、[docs-rules](https://github.com/knk1313/docs-rules)の採点で校正する
5. GitHubの設定：About、topics、mainの保護、secret scanningなどを、承認を得てから設定する

### 診断：開発中の品質と安全性を確かめる

リポジトリを読み取りだけで調べ、重要度・確信度・根拠（ファイルと行）・影響・改善案をつけて、重要な問題を最大10件ほど報告します。コードは変えません（test-addだけは、テストのファイルを足します）。

| スキル | 調べること |
| --- | --- |
| health-check | 全体を広く浅く調べ、優先すべき領域だけを下のスキルで深掘りし、費用対効果の高い改善を3件示す |
| security-audit | 認証・認可、入力の検証とインジェクション、秘密情報の扱い、危険な設定、依存の既知の脆弱性 |
| bug-hunt | 境界値、例外処理、競合状態、データの整合性などの潜在的なバグ |
| architecture-review | 責務の分離、依存の向き、循環参照、密結合、設計の一貫性 |
| test-gap | 重要な機能と失敗ケースに対するテストの不足 |
| test-add | 不足しているテストを、既存の書き方に合わせて足し、承認を得てから実行する |
| performance-review | N+1、計算量、不要な処理、キャッシュ、資源の使い方 |
| ux-review | 画面やCLIの操作の手間、遷移、入力、フィードバック、エラーのときの体験 |
| a11y-review | WCAG 2.2のAAを目安にした、アクセシビリティの問題 |
| dependency-review | 使っていない・重なっている・更新が止まった・脆弱な依存 |
| docs-drift | README、docs、API仕様と実装の食い違い |
| tech-debt | 保守性を損なう負債を、変更の頻度と直すコストで並べる |
| ops-review | ログ、監視、障害への備え、バックアップ、デプロイの堅さ |

診断のスキルは、外部のネットワークにアクセスせず、インストールやテストなど副作用のあるコマンドも勝手に実行しません。コミット履歴まで含めた秘密情報の検査とGitHubの設定は、publishで行います。

## インストール

### Claude Codeプラグイン

```text
/plugin marketplace add knk1313/repo-kit
/plugin install repo-kit@repo-kit
```

### 手動配置

`skills/`の中の`setup/`と`publish/`を、両方とも`~/.claude/skills/`に置きます。publishはsetupのテンプレートを使うため、片方だけでは動きません。

診断のスキルは、一つずつ置いても動きます。health-checkは、ほかの診断のスキルを呼んで深掘りするため、一緒に置きます（なければ、health-checkが自分で調べます）。

### Claudeアプリ

診断のスキルだけを、Claudeアプリでも使えます。setupとpublishは、手元のGitとGitHub CLIを使うため、アプリでは使えません。

[Releases](https://github.com/knk1313/repo-kit/releases)から、zipを取ります。zipは1つにつき1スキルで、リリースを公開したときにGitHub Actionsが作ります。

- まとめて使うなら`repo-review.zip`：診断の観点を一つにまとめたスキルです。これ1つで、健康診断も、観点を決めた診断もできます。頼まれた観点の手順だけを読みます
- 観点ごとに入れるなら`health-check.zip`、`security-audit.zip`など：使うものだけを入れます。health-checkを使うなら、深掘りに使う診断のスキルも一緒に入れます
- テストを足すなら`test-add.zip`：書き込みを伴うため、`repo-review.zip`には入っていません

zipは、Claudeアプリの設定の、スキルの画面からアップロードします。アプリでは、コード実行を有効にし、調べるリポジトリをzipで添付します。新しい版を使うときは、新しい版のzipをアップロードし直します。

## 使い方

対象のリポジトリで、Claude Codeに次のように頼みます。

```text
このリポジトリをセットアップして
```

```text
このリポジトリを公開する前に整えて
```

診断は、観点を決めずに頼めばhealth-checkが、観点を決めて頼めばその観点のスキルが動きます。

```text
このリポジトリの健康診断をして
```

```text
セキュリティ上の問題を探して
```

```text
設計の悪いところを見つけて
```

```text
テストが足りないところを教えて
```

プラグインとして入れた場合は、スラッシュコマンドでも呼べます。

| 用途 | コマンド |
| --- | --- |
| 開発の土台を足す | `/repo-kit:setup` |
| 公開する前に整える | `/repo-kit:publish` |
| 全体の健康診断 | `/repo-kit:health-check` |
| 観点ごとの診断 | `/repo-kit:security-audit`、`/repo-kit:bug-hunt`、`/repo-kit:architecture-review`、`/repo-kit:test-gap`、`/repo-kit:performance-review`、`/repo-kit:ux-review`、`/repo-kit:a11y-review`、`/repo-kit:dependency-review`、`/repo-kit:docs-drift`、`/repo-kit:tech-debt`、`/repo-kit:ops-review` |
| テストを足す | `/repo-kit:test-add` |

Claude Codeに組み込みの`/security-review`は、今のブランチの差分を見ます。security-auditは、リポジトリ全体を見ます。

## 動作環境

- Claude Code（診断のスキルは、Claudeアプリでも使える）
- Git、jq
- publishに、[GitHub CLI](https://cli.github.com/)（`gh auth login`済み）
- publishの校正に、Node.js 18以上と[docs-rules](https://github.com/knk1313/docs-rules)（なければ校正を飛ばす）
- [gitleaks](https://github.com/gitleaks/gitleaks)（任意。あればpublishの検査で使う）

## ディレクトリ構成

```text
repo-kit/
├── .claude-plugin/     # プラグインとして配布するための設定
├── app/
│   └── repo-review/    # Claudeアプリ向けにまとめたスキル。Releaseのときに診断のスキルを写して zip にする
└── skills/
    ├── setup/
    │   ├── SKILL.md
    │   ├── scripts/    # 足りないファイルを調べる（check.sh）
    │   └── assets/     # 足すファイルのテンプレート
    ├── publish/
    │   ├── SKILL.md
    │   ├── scripts/    # 点検（audit.sh）と検査（scan.sh）
    │   ├── references/ # GitHubの設定のコマンド、校正の手順
    │   └── assets/     # mainを守るRulesetの設定
    ├── health-check/
    │   └── SKILL.md    # 診断のスキルは、どれもSKILL.mdだけ
    └── security-audit/ など、観点ごとの診断のスキル
```
