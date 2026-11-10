---
name: setup
description: リポジトリに開発の土台になるファイルを足すときに使う。新しく作ったリポジトリでも、開発の途中のリポジトリでも使える。「リポジトリをセットアップして」「Issueテンプレートを入れて」「AGENTS.mdとCLAUDE.mdを作って」「PRテンプレートがほしい」「CIとDependabotを入れて」「いつもの構成にして」「足りないファイルを持ってきて」と頼まれたとき、新しいプロジェクトを始めたときに使う。Issue・PRのテンプレート、AGENTS.md・CLAUDE.md、REVIEW.md、.gitignore、.env.example、Dependabot、権限を絞ったCIのうち、足りないものだけを、リポジトリに合わせて埋めて置く。公開の前の点検やGitHubの設定、OSSとして出すときのLICENSE・SECURITY.md・CONTRIBUTING.mdは、このスキルではなくpublishで行う。
---

# setup

開発の土台になるファイルのうち、足りないものだけをリポジトリに足す。開発の開始時でも途中でも使える。ファイルを足すだけで、GitHub の設定は変えない（それは publish の仕事）。

`LICENSE`、`SECURITY.md`、`CONTRIBUTING.md` は足さない。リポジトリを OSS にするとは限らないため、OSS として出すと決めたときに publish で足す。

`<SKILL>` は、この SKILL.md があるディレクトリの絶対パス（Claude Code では「Base directory for this skill」）。

## 1. 足りないものを調べる

```bash
bash <SKILL>/scripts/check.sh <リポジトリのパス>
```

`missing` の項目を、次の表に照らして足すかどうかを決め、一覧にして利用者に見せる。

既存のファイルは、書き換えも消しもしない。既存のファイルには、利用者がそのリポジトリ用に書き足した内容が入っているため。扱いは次の3通りに分ける。

- 聞かずに追記してよい：`.gitignore`（足りない行だけ）と、`AGENTS.md`（足りない節だけ）。既存の行や節には触れず、末尾に足す。足したことは報告に書く
- 聞かずに残してよい：既存のファイルが、テンプレートと同じ役割をすでに果たしているとき（例：CLAUDE.md の中身が `@AGENTS.md` だけ）
- 聞いてから：既存の内容を直す、移す、消す必要があるとき

`AGENTS.md` が `create-next-app` などのツールで作られていて、そのツール向けの決まりしか書かれていないことがある。そのときは、ツールの決まりを先頭にそのまま残し、テンプレートの節（コマンド、git 操作、規約など）のうち、ない節を下に足す。

| ファイル | 足す時期の目安 |
|---|---|
| `.gitignore` | いつでも。最初に足す（秘密情報を誤って追跡しないため） |
| `.env.example` | コードが環境変数を読むとき |
| `AGENTS.md`、`CLAUDE.md` | いつでも。AI エージェントと開発するなら最初に足す |
| `.github/ISSUE_TEMPLATE/`、`.github/pull_request_template.md` | いつでも |
| CI（`.github/workflows/`） | テストか lint が一つでもあれば |
| `.github/dependabot.yml` | 依存パッケージがあれば。GitHub に置くまでは動かないが、置いておいて困ることはない |
| `REVIEW.md` | AI にレビューさせるとき（`/code-review`、Code Review、repo-kit の診断のスキル）。同じ指摘が繰り返し出始めたら |

利用者が「全部」「いつもの構成」と言ったときは、表の全部を足す。

## 2. テンプレートを埋めて置く

テンプレートは `<SKILL>/assets/` にある。中の `{{...}}` は、リポジトリを読んで埋める。埋められないものは、利用者に聞くか、`<!-- TODO: -->` を残して最後に報告する。

| 置く先 | テンプレート | リポジトリに合わせること |
|---|---|---|
| `.gitignore` | `gitignore-base` | 言語の分を足す（Node：`node_modules/`、`dist/`。Python：`.venv/`、`__pycache__/`、`.pytest_cache/`）。既存の `.gitignore` があれば、足りない行だけを追記する。既存の `.env*` のような行は `.env.example` まで除外してしまうので、その下に `!.env.example` を足し、`git check-ignore -v .env.example` で除外されていないことを確かめる |
| `.env.example` | なし | コードが読む環境変数の名前を並べ、値は空にする。名前ごとに一行のコメントで用途を書く |
| `AGENTS.md` | `AGENTS.md` | `{{COMMANDS}}` を、依存のインストール・テスト・lint・ビルド・起動のコマンドの表にする（`package.json` の scripts、`Makefile`、README から拾う）。どこで実行するか（`web/` など）も書く。スクリプトがない用途（テストがない、など）は、行ごと消す。`next build` のようにビルドが型の検査を兼ねるときは、「ビルド（型の検査を含む）」と書く。「完了の前に確かめる」の節は、`REVIEW.md` を置かないなら、`REVIEW.md` へのリンクを外して「このファイル」だけにする |
| `REVIEW.md` | `REVIEW.md` | `{{FAILURES}}` を、このリポジトリで「壊れた」とみなすものの箇条書きにする（例：ドキュメントが実装と違うことを書く、設定が誤った先に向く、データを失う）。`{{SENSITIVE_PATHS}}` を、認証・課金・CI のワークフロー・リリースやインストールの仕組みのパスにする。`{{IGNORED_PATHS}}` を、生成物・ロックファイル・`vendor/` などにする。どれもリポジトリを読んで埋め、該当がなければ「なし」と書く |
| `CLAUDE.md` | `CLAUDE.md` | そのまま。既に CLAUDE.md があって AGENTS.md がない場合は、CLAUDE.md の中身を AGENTS.md に移して、CLAUDE.md をこのラッパーにするかを利用者に聞く |
| `.github/ISSUE_TEMPLATE/` | `ISSUE_TEMPLATE/` | そのまま |
| `.github/pull_request_template.md` | `pull_request_template.md` | そのまま |
| `.github/workflows/ci.yml` | `workflows/ci-node.yml`、`workflows/ci-python.yml` | 実在するスクリプトのステップだけを残す。ない検査を足さない。ビルドが型の検査を兼ねるなら、型の検査のステップは置かない。マニフェストが `web/` などにあるなら `working-directory` を付ける。両方の言語があれば、ファイルを分けて `paths:` で絞る |
| `.nvmrc`、`.python-version` | なし | CI のテンプレートが読む。今の手元の版（`node -v`、`python3 --version` のメジャー）か、`package.json` の `engines` に合わせる |
| `.github/dependabot.yml` | `dependabot.yml` | 使うエコシステムのブロックだけを残し、`directory` をマニフェストのある場所にする。`github-actions` は CI があれば残す |

AGENTS.md の規約（git を操作しない、コミットの prefix など）は、利用者のいつもの決まりである。リポジトリに既に別の決まり（英語のコミット、Conventional Commits の scope など）があれば、そちらに合わせて書き換える。

## 3. 確かめて報告する

- `check.sh` をもう一度実行し、`missing` が残っていれば理由を添えて報告する
- CI と dependabot.yml を足したときは、YAML として読めるかを確かめる。macOS に最初から入っている Ruby を使う（`ruby -ryaml -e 'YAML.load_file(ARGV[0])' <ファイル>`）。Ruby がなければ、PyYAML のある Python で読む。外部のパッケージを取ってきて実行する方法（`npx --yes` など）は使わない。どれも使えなければ、確かめずに報告する
- 足したファイルの一覧と、`TODO` を残した箇所を報告する
- コミットは利用者が頼んだときだけ。頼まれたら `chore: Issue と PR のテンプレートを追加する` のように、種類ごとに分ける
