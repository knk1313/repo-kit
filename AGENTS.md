# AGENTS.md

このファイルは、このリポジトリで動くAIコーディングエージェント（Claude Code、OpenAI Codexなど）が共通で参照する**禁止事項と最低限のチェック**を集めた索引である。

- **Claude Code**：ルートの`CLAUDE.md`が`@AGENTS.md`で取り込む
- **OpenAI Codex**：ルートの`AGENTS.md`を直接読み込む

本ファイルは、AIが**コードを書く・直す・出す**ときに踏み外してはいけない事項に絞る。

## プロジェクト概要

`README.md`を参照（技術スタック・ディレクトリ構成）。

## コマンド

作業はリポジトリのルートで行う。検査は次のとおり。「CI」の列が「回る」のものは、CI（`.github/workflows/ci.yml`）でも同じ検査をする。

| 用途 | コマンド | CI |
| --- | --- | --- |
| スクリプトの文法 | `for f in skills/*/scripts/*.sh; do bash -n "$f"; done` | 回る |
| スクリプトの静的検査 | `shellcheck -S warning skills/*/scripts/*.sh` | 回る |
| JSONの検証 | `for f in .claude-plugin/*.json skills/*/assets/*.json; do jq empty "$f"; done` | 回る |
| YAMLの検証 | `ruby -ryaml -e 'ARGV.each { \|f\| YAML.load_file(f) }' skills/setup/assets/dependabot.yml skills/setup/assets/workflows/*.yml .github/*.yml .github/workflows/*.yml` | 回る |
| SKILL.mdの先頭の検査（`name`と`description`があり、`name`がディレクトリ名と同じ） | `ci.yml`の該当のステップを写して実行する | 回る |
| `app/repo-review`が参照するスキルの実在 | `ci.yml`の該当のステップを写して実行する | 回る |
| プラグインの検証 | `claude plugin validate .` | 回らない（手元で実行する） |
| 試しに動かす | `bash skills/setup/scripts/check.sh <リポジトリ>`、`bash skills/publish/scripts/audit.sh <リポジトリ>` | 回らない |

スキルの手順（SKILL.md）を変えたときは、どこかのリポジトリのコピーで実際にスキルを動かして確かめる。本物のリポジトリやGitHubの設定は変えない。

## git操作

**gitを操作しない**。次の操作は、すべて人間が行う。人間が明示的に依頼したときだけ実行する。

- ブランチの作成・切り替え
- `add`、`commit`、`push`、`merge`、`rebase`、`reset`、`stash`
- PRの作成

コードの変更は、作業ツリーに残すところまでで止める。状態を確認する読み取り専用のコマンド（`git status`、`git log`、`git diff`など）は実行してよい。

## ドキュメントとコードの食い違い

**ドキュメントと既存のコードが食い違うときは、コードの書き方に従う**。READMEや注記の説明が古いまま残っていることがあるため、動いているコードを正とする。

見つけた食い違いは、その場で黙って直さず、作業の最後の返答ですべて挙げる。ドキュメントを直すかどうかは、人間が決める。

## 規約

- **コミットメッセージ**：日本語。1行目に`feat:`などの種別prefixを付ける（`feat`、`fix`、`refactor`、`perf`、`chore`、`docs`、`test`、`ci`）。
- **Issue**：タイトルに種別prefixを付ける。本文は`.github/ISSUE_TEMPLATE/`のテンプレート（`機能追加.md`か`バグ修正.md`）を選び、その見出し構成のまま全項目を埋める。調査タスクは`機能追加.md`を使う。
- **PR**：`.github/pull_request_template.md`の見出し構成のまま全項目を埋める。
- **コードのコメント・ドキュメント文字列**：日本語で書く。
- **スクリプト**：`scripts/`のスクリプトは読み取りだけにする。ファイルやGitHubの設定を変える操作は、SKILL.mdの手順の中で、利用者の承認を得てから行う。
- **テンプレート**：`skills/setup/assets/`か`skills/publish/assets/`を変えたら、setupとpublishの両方のSKILL.mdの表を見直す。
