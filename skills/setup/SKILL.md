---
name: setup
description: リポジトリに開発の土台になるファイルを足すときに使う。新しく作ったリポジトリでも、開発の途中のリポジトリでも使える。「リポジトリをセットアップして」「Issueテンプレートを入れて」「AGENTS.mdとCLAUDE.mdを作って」「PRテンプレートがほしい」「CIとDependabotを入れて」「いつもの構成にして」「足りないファイルを持ってきて」と頼まれたとき、新しいプロジェクトを始めたときに使う。Issue・PRのテンプレート、AGENTS.md・CLAUDE.md、CONTRIBUTING.md、.gitignore、.env.example、LICENSE、SECURITY.md、Dependabot、権限を絞ったCIのうち、足りないものだけを、リポジトリに合わせて埋めて置く。公開の前の点検やGitHubの設定は、このスキルではなくpublishで行う。
---

# setup

開発の土台になるファイルのうち、足りないものだけをリポジトリに足す。開発の開始時でも途中でも使える。ファイルを足すだけで、GitHub の設定は変えない（それは publish の仕事）。

`<SKILL>` は、この SKILL.md があるディレクトリの絶対パス（Claude Code では「Base directory for this skill」）。

## 1. 足りないものを調べる

```bash
bash <SKILL>/scripts/check.sh <リポジトリのパス>
```

`missing` の項目を、次の表に照らして足すかどうかを決め、一覧にして利用者に見せる。すでにあるファイルは上書きしない。中身が古い・足りないと思っても、直すかどうかは利用者に聞く。既存のファイルには、利用者がそのリポジトリ用に書き足した内容が入っているため。

| ファイル | 足す時期の目安 |
|---|---|
| `.gitignore` | いつでも。最初に足す（秘密情報を誤って追跡しないため） |
| `.env.example` | コードが環境変数を読むとき |
| `AGENTS.md`、`CLAUDE.md` | いつでも。AI エージェントと開発するなら最初に足す |
| `.github/ISSUE_TEMPLATE/`、`.github/pull_request_template.md` | いつでも |
| CI（`.github/workflows/`） | テストか lint が一つでもあれば |
| `.github/dependabot.yml` | 依存パッケージがあれば。GitHub に置くまでは動かないが、置いておいて困ることはない |
| `CONTRIBUTING.md` | 自分以外が触る、または AI エージェントに Issue・PR を書かせるとき |
| `LICENSE`、`SECURITY.md` | 公開を考え始めたら。非公開のままなら、利用者に聞いてから |

利用者が「全部」「いつもの構成」と言ったときは、表の全部を足す。

## 2. テンプレートを埋めて置く

テンプレートは `<SKILL>/assets/` にある。中の `{{...}}` は、リポジトリを読んで埋める。埋められないものは、利用者に聞くか、`<!-- TODO: -->` を残して最後に報告する。

| 置く先 | テンプレート | リポジトリに合わせること |
|---|---|---|
| `.gitignore` | `gitignore-base` | 言語の分を足す（Node：`node_modules/`、`dist/`。Python：`.venv/`、`__pycache__/`、`.pytest_cache/`）。既存の `.gitignore` があれば、足りない行だけを追記する |
| `.env.example` | なし | コードが読む環境変数の名前を並べ、値は空にする。名前ごとに一行のコメントで用途を書く |
| `AGENTS.md` | `AGENTS.md` | `{{COMMANDS}}` を、依存のインストール・テスト・lint・ビルド・起動のコマンドの表にする（`package.json` の scripts、`Makefile`、README から拾う）。どこで実行するか（`web/` など）も書く |
| `CLAUDE.md` | `CLAUDE.md` | そのまま。既に CLAUDE.md があって AGENTS.md がない場合は、CLAUDE.md の中身を AGENTS.md に移して、CLAUDE.md をこのラッパーにするかを利用者に聞く |
| `.github/ISSUE_TEMPLATE/` | `ISSUE_TEMPLATE/` | そのまま |
| `.github/pull_request_template.md` | `pull_request_template.md` | そのまま |
| `.github/workflows/ci.yml` | `workflows/ci-node.yml`、`workflows/ci-python.yml` | 実在するスクリプトのステップだけを残す。ない検査を足さない。マニフェストが `web/` などにあるなら `working-directory` を付ける。両方の言語があれば、ファイルを分けて `paths:` で絞る |
| `.nvmrc`、`.python-version` | なし | CI のテンプレートが読む。今の手元の版（`node -v`、`python3 --version` のメジャー）か、`package.json` の `engines` に合わせる |
| `.github/dependabot.yml` | `dependabot.yml` | 使うエコシステムのブロックだけを残し、`directory` をマニフェストのある場所にする。`github-actions` は CI があれば残す |
| `CONTRIBUTING.md` | `CONTRIBUTING.md` | `{{CHECK_COMMANDS}}` を CI と同じ検査のコマンドにする。画面があるリポジトリなら、スクリーンショットの決まりを足す |
| `LICENSE` | `LICENSE-MIT` | 年と著作権者。著作権者は `git config user.name` か、利用者の他のリポジトリの LICENSE にそろえる。MIT 以外にしたいかは、足す前に聞く |
| `SECURITY.md` | `SECURITY.md` | 想定している使い方、対象と対象外、owner/repo（`gh repo view --json nameWithOwner` か `git remote`） |

AGENTS.md の規約（git を操作しない、コミットの prefix など）は、利用者のいつもの決まりである。リポジトリに既に別の決まり（英語のコミット、Conventional Commits の scope など）があれば、そちらに合わせて書き換える。

## 3. 確かめて報告する

- `check.sh` をもう一度実行し、`missing` が残っていれば理由を添えて報告する
- CI を足したときは、YAML として読めるかを確かめる（`python3 -c 'import sys,yaml; yaml.safe_load(open(sys.argv[1]))' <ファイル>` か `npx --yes yaml-lint`。どちらもなければ省いて報告する）
- 足したファイルの一覧と、`TODO` を残した箇所を報告する
- コミットは利用者が頼んだときだけ。頼まれたら `chore: Issue と PR のテンプレートを追加する` のように、種類ごとに分ける
