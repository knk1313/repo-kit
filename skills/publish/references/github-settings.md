# GitHub の設定を変えるコマンド

`O/R` は `owner/repo`。どれも外から見える変更なので、まとめて利用者に見せ、承認を得てから実行する。

## About とリポジトリの機能

```bash
gh repo edit O/R \
  --description "一文の説明" \
  --homepage "https://github.com/O/R#readme" \   # Pages があればその URL
  --add-topic python,cli \
  --enable-wiki=false \
  --delete-branch-on-merge
# 用途に応じて: --template（テンプレートとして配る） / --enable-discussions（質問を Issue から分けたい）
```

topics は、言語・フレームワーク・用途（cli、template など）・対象（japanese など）から 5〜10 個。

## セキュリティ

```bash
gh api -X PATCH repos/O/R \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
gh api -X PUT repos/O/R/vulnerability-alerts          # Dependabot alerts
gh api -X PUT repos/O/R/automated-security-fixes      # Dependabot security updates
gh api -X PUT repos/O/R/private-vulnerability-reporting  # SECURITY.md の報告先。OSS にするときだけ
```

secret scanning は、非公開のリポジトリでは有料プランでしか有効にできない。公開してから実行する。

## main の保護（Ruleset）

`assets/ruleset-main.json` の `{{CI のジョブ名}}` を、CI のジョブ名（GitHub のチェック名）に置き換える。ジョブ名は `gh pr checks` や直近の実行（`gh run view --json jobs -q '.jobs[].name'`）で確かめる。CI がまだ一度も動いていなければ、`required_status_checks` のブロックを消して入れ、CI が動いた後に足す。

```bash
gh api -X POST repos/O/R/rulesets --input ruleset.json
# 既にあるときは一覧で ID を調べて PUT で置き換える
gh api repos/O/R/rulesets -q '.[] | [.id, .name] | @tsv'
gh api -X PUT repos/O/R/rulesets/<ID> --input ruleset.json
```

一人で開発するリポジトリでは承認数を 0 にする（自分の PR を自分でマージできるように）。

この Ruleset を入れると、管理者でも main に直接 push できなくなる。変更は、ブランチを切って PR を作り、必須チェックが通ってからマージする流れになる。入れる前に、このことを利用者に伝える。このスキルの作業で残りのコミットがあれば、先に main へ push してから Ruleset を入れる。

## 公開する

```bash
gh repo edit O/R --visibility public --accept-visibility-change-consequences
```

これは取り消しても、公開していた間に複製・キャッシュされた内容は戻らない。必ず最後に、利用者がはっきり頼んだときだけ実行する。

## Release

```bash
git tag v0.1.0 && git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0" --notes-file notes.md
```

Release の本文は、利用者に向けて、何ができるようになったかを段落で書く。コミットの一覧を貼らない。
