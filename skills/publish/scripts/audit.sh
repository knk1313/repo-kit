#!/usr/bin/env bash
# 公開前の点検（読み取りだけ）。リポジトリのファイルと GitHub の設定を調べ、Markdown のチェックリストを出す。
# 使い方: audit.sh [リポジトリのパス]   （省略時はカレントディレクトリ）
# 結果の記号: OK=揃っている / NG=足りない / --=判断が要る・対象外
set -u
REPO_DIR="${1:-.}"
cd "$REPO_DIR" || { echo "ディレクトリがない: $REPO_DIR" >&2; exit 2; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "git リポジトリではない: $REPO_DIR" >&2; exit 2; }

ok()  { echo "- [x] OK $1"; }
ng()  { echo "- [ ] NG $1"; }
na()  { echo "- [ ] -- $1"; }
has() { [ -e "$1" ]; }

echo "# 公開前の点検: $(basename "$(git rev-parse --show-toplevel)")"
echo

echo "## 1. 公開してはいけないもの"
work=$(git ls-files | grep -iE '(^|/)(PROGRESS|TODO|NOTES?|MEMO|WIP|scratch|作業|メモ)[^/]*\.(md|txt)$' || true)
[ -z "$work" ] && ok "作業用の文書は追跡されていない" || ng "作業用らしい文書が追跡されている: $(echo $work)"
envf=$(git ls-files | grep -E '(^|/)\.env($|\.)' | grep -vE '\.env\.(example|sample|template)$' || true)
[ -z "$envf" ] && ok ".env は追跡されていない" || ng ".env が追跡されている: $envf"
has .gitignore && ok ".gitignore がある" || ng ".gitignore がない"
if git ls-files | grep -qE '(^|/)\.env\.example$'; then ok ".env.example がある"
elif git grep -qE 'os\.environ|process\.env|getenv' -- ':!*.lock' ':!*.md' ':!*.sh' 2>/dev/null; then na "環境変数を読むコードがある。設定が要るなら .env.example を置く"
else na ".env.example（環境変数を使わないなら不要）"; fi
big=$(git ls-files -z | xargs -0 du -k 2>/dev/null | awk '$1>5120{print $2" ("$1"KB)"}' | head -5)
[ -z "$big" ] && ok "5MB を超える追跡ファイルはない" || na "大きいファイル: $(echo $big)"
echo "  - 秘密情報・個人情報・見本データの検査は scan.sh で行う"
echo

echo "## 2. ファイル"
for f in README.md LICENSE SECURITY.md CONTRIBUTING.md .github/pull_request_template.md .github/dependabot.yml; do
  has "$f" && ok "$f" || ng "$f"
done
ls .github/ISSUE_TEMPLATE/*.md >/dev/null 2>&1 && ok ".github/ISSUE_TEMPLATE/ ($(ls .github/ISSUE_TEMPLATE | tr '\n' ' '))" || ng ".github/ISSUE_TEMPLATE/"
has README.en.md && ok "README.en.md" || na "README.en.md（テンプレートなど海外の利用者を見込むときだけ）"
has AGENTS.md || has CLAUDE.md && ok "AGENTS.md / CLAUDE.md" || na "AGENTS.md / CLAUDE.md"
has REVIEW.md && ok "REVIEW.md" || na "REVIEW.md（AI にレビューさせるなら置く）"
if has .github/pull_request_template.md; then
  grep -qE '戻し方|How to revert' .github/pull_request_template.md && ok "PR テンプレートに戻し方の節" || na "PR テンプレートに確かめたこと・リスク・戻し方の節がない"
fi
if has README.md; then
  for kw in "ライセンス|License|利用条件" "使い方|使う|Usage|はじめ方" "動作環境|Requirements|必要"; do
    grep -qE "^#+ .*($kw)" README.md && ok "README に「${kw%%|*}」の節" || ng "README に「${kw%%|*}」の節がない"
  done
  grep -qE '!\[|<img' README.md && ok "README に画像がある" || na "README に画像がない（画面があるなら撮る）"
fi
if has package.json; then
  name=$(jq -r '.name // ""' package.json); repo=$(basename "$(git rev-parse --show-toplevel)")
  [ "$name" = "$repo" ] && ok "package.json の name がリポジトリ名" || ng "package.json の name ($name) がリポジトリ名 ($repo) と違う"
  for k in description repository license; do jq -e ".$k" package.json >/dev/null && ok "package.json の $k" || ng "package.json に $k がない"; done
fi
echo

echo "## 3. CI とワークフロー"
wfs=$(ls .github/workflows/*.y*ml 2>/dev/null || true)
if [ -z "$wfs" ]; then ng "ワークフローがない（CI を置く）"; else
  for w in $wfs; do
    grep -qE '^permissions:' "$w" && ok "$w: permissions を絞っている" || ng "$w: トップレベルの permissions がない"
    unpinned=$(grep -E '^\s*-?\s*uses:\s' "$w" | grep -vE '@[0-9a-f]{40}' | grep -vE 'uses:\s*\./' | wc -l | tr -d ' ')
    [ "$unpinned" = 0 ] && ok "$w: アクションを SHA で固定" || na "$w: タグ指定のアクションが ${unpinned} 件（SHA 固定にするか判断）"
  done
  grep -lqE 'pull_request_target' $wfs 2>/dev/null && grep -lE 'pull_request_target' $wfs | while read w; do grep -q 'actions/checkout' "$w" && ng "$w: pull_request_target で checkout している（危険）"; done
fi
echo

echo "## 4. GitHub の設定"
slug=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
if [ -z "$slug" ]; then na "GitHub 上のリポジトリが見つからない（作成後にもう一度点検する）"; else
  j=$(gh repo view "$slug" --json visibility,description,homepageUrl,repositoryTopics,hasWikiEnabled,hasDiscussionsEnabled,deleteBranchOnMerge,isTemplate,defaultBranchRef)
  echo "  - 対象: $slug ($(echo "$j" | jq -r .visibility))"
  [ -n "$(echo "$j" | jq -r '.description // ""')" ] && ok "About の説明" || ng "About の説明がない"
  nt=$(echo "$j" | jq '[.repositoryTopics[]?] | length'); [ "$nt" -gt 0 ] && ok "topics ($nt 件)" || ng "topics がない"
  [ -n "$(echo "$j" | jq -r '.homepageUrl // ""')" ] && ok "ホームページの URL" || na "ホームページの URL（Pages や README の URL）"
  [ "$(echo "$j" | jq .hasWikiEnabled)" = false ] && ok "Wiki が無効" || ng "Wiki が有効のまま"
  [ "$(echo "$j" | jq .deleteBranchOnMerge)" = true ] && ok "マージ後にブランチを自動で消す" || ng "マージ後のブランチ削除が無効"
  echo "  - テンプレートリポジトリ: $(echo "$j" | jq .isTemplate) / Discussions: $(echo "$j" | jq .hasDiscussionsEnabled)（用途に応じて判断）"
  br=$(echo "$j" | jq -r '.defaultBranchRef.name')
  rs=$(gh api "repos/$slug/rulesets" -q 'length' 2>/dev/null || echo 0)
  bp=$(gh api "repos/$slug/branches/$br/protection" >/dev/null 2>&1 && echo yes || echo no)
  if [ "$rs" -gt 0 ] || [ "$bp" = yes ]; then ok "$br の保護（Ruleset ${rs} 件 / Branch protection: ${bp}）"; else ng "$br が保護されていない"; fi
  tr_=$(gh api "repos/$slug/rules/branches/$br" -q '[.[] | select(.type=="pull_request") | .parameters.required_review_thread_resolution] | any' 2>/dev/null || echo false)
  [ "$tr_" = true ] && ok "未解決のレビューのスレッドがあるとマージできない" || na "未解決のレビューのスレッドがあってもマージできる（AI のレビューを使うなら Ruleset で必須にする）"
  sa=$(gh api "repos/$slug" -q '.security_and_analysis' 2>/dev/null)
  for k in secret_scanning secret_scanning_push_protection dependabot_security_updates; do
    [ "$(echo "$sa" | jq -r ".$k.status // \"\"")" = enabled ] && ok "$k" || ng "$k が無効"
  done
  pv=$(gh api "repos/$slug/private-vulnerability-reporting" -q .enabled 2>/dev/null || echo "?")
  [ "$pv" = true ] && ok "非公開の脆弱性報告" || ng "非公開の脆弱性報告が無効（SECURITY.md の案内先が動かない）"
  nr=$(gh release list -R "$slug" -L 1 2>/dev/null | wc -l | tr -d ' ')
  [ "$nr" -gt 0 ] && ok "Release がある" || na "Release がない（配布物があるならタグを打つ）"
fi
