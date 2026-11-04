# repo-kit

GitHubのリポジトリを整える作業を、Claude Codeに進めてもらうためのスキル集です。開発を始めるときと、公開する前に使います。

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

## インストール

### Claude Codeプラグイン

```text
/plugin marketplace add knk1313/repo-kit
/plugin install repo-kit@repo-kit
```

### 手動配置

`skills/`の中の`setup/`と`publish/`を、両方とも`~/.claude/skills/`に置きます。publishはsetupのテンプレートを使うため、片方だけでは動きません。

## 使い方

対象のリポジトリで、Claude Codeに次のように頼みます。

```text
このリポジトリをセットアップして
```

```text
このリポジトリを公開する前に整えて
```

プラグインとして入れた場合は、`/repo-kit:setup`、`/repo-kit:publish`でも呼べます。

## 動作環境

- Claude Code
- Git、jq
- publishに、[GitHub CLI](https://cli.github.com/)（`gh auth login`済み）
- publishの校正に、Node.js 18以上と[docs-rules](https://github.com/knk1313/docs-rules)（なければ校正を飛ばす）
- [gitleaks](https://github.com/gitleaks/gitleaks)（任意。あればpublishの検査で使う）

## ディレクトリ構成

```text
repo-kit/
├── .claude-plugin/     # プラグインとして配布するための設定
└── skills/
    ├── setup/
    │   ├── SKILL.md
    │   ├── scripts/    # 足りないファイルを調べる（check.sh）
    │   └── assets/     # 足すファイルのテンプレート
    └── publish/
        ├── SKILL.md
        ├── scripts/    # 点検（audit.sh）と検査（scan.sh）
        ├── references/ # GitHubの設定のコマンド、校正の手順
        └── assets/     # mainを守るRulesetの設定
```

## ライセンス

[MIT License](LICENSE)
