# docs-rules で README と docs を校正する（トークンを抑える手順）

docs-rules のスキルを読み込んで手順どおりに進めると、`rules/` のファイル（合わせて10万字を超える）を読み、AI による評価と書き直しを最大3回繰り返す。公開前の校正では、そこまでしない。機械の採点だけを使い、違反の箇所だけを直す。

## 1. 採点のスクリプトを探す

docs-rules のスキルは読み込まない（Skill ツールで呼ばない）。採点のスクリプトだけを使う。

```bash
# bash で実行する。zsh では、一致しないパターンが1つでもあると、コマンド全体が止まるため
SCORE=$(bash -c 'ls -t ~/.claude/plugins/cache/*/docs-rules/*/skills/docs-rules/evaluators/score.mjs \
              ~/.claude/plugins/marketplaces/*/skills/docs-rules/evaluators/score.mjs \
              ~/.claude/skills/*/docs-rules/evaluators/score.mjs \
              ~/.claude/skills/docs-rules/evaluators/score.mjs 2>/dev/null | head -1')
```

プラグインの置き場所は、入れたマーケットプレイスによって変わる（`docs-rules` から入れたか、`knk1313-skills` から入れたか）。そのため、マーケットプレイスの名前の部分は `*` にしている。

見つからない、または `node` がない場合は、校正を飛ばし、そのことを報告する。docs-rules のスキルに切り替えない。

## 2. 対象を絞って、1回で採点する

- 対象は、このスキルで書いたり直したりした日本語の Markdown だけ（README.md、SECURITY.md、CONTRIBUTING.md など）。英語の文書、テンプレート（`.github/` の中）、変えていない文書は対象にしない
- 文書を全部まとめて1回で渡す（textlint の起動が1回で済む）。`--type` は付けない

```bash
node "$SCORE" README.md SECURITY.md CONTRIBUTING.md > /tmp/score.json; echo "exit=$?"
```

終了コードが0なら違反なし。出力のJSONは全部を読まない。違反が数十件を超えることも多いので、先にルールごとの件数を見て、次に一覧を取り出す。

```bash
jq -r '[(if type=="array" then . else [.] end)[] | .violations[]?.rule_id] | group_by(.) | map("\(.[0])\t\(length)") | .[]' /tmp/score.json
```

```bash
jq -r '(if type=="array" then . else [.] end)[] | .file as $f | .violations[]? | "\($f):\(.line)\t\(.rule_id)\t\(.excerpt)\t\(.fix // "")"' /tmp/score.json | head -50
```

## 3. 違反の箇所だけを直す

- 違反のある行の前後だけを読んで直す。文書全体を書き直さない
- メッセージだけで直し方が分からないルールIDがあれば、そのIDの定義だけを grep で引く。`rules/` のファイルを丸ごと読まない

```bash
grep -rn -A6 "<ルールID>" "$(dirname "$SCORE")/../rules/" | head -20
```

- コード、コマンド、ファイル名、固有名詞（製品名など）に当たる違反は直さない
- 直した後にもう一度採点し、残った違反は直さずに報告する（書き直しは1回だけ）

## 利用者が「しっかり校正して」と頼んだとき

そのときだけ、docs-rules のスキルを読み込んで、その手順どおりに進める。トークンを多く使うことを先に伝える。
