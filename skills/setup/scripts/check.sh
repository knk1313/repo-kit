#!/usr/bin/env bash
# 開発の土台になるファイルが揃っているかを調べる（読み取りだけ）。
# 使い方: check.sh [リポジトリのパス]
# 出力: 1行に1項目。「有無<TAB>パス<TAB>補足」。有無は have / missing / skip。
set -u
cd "${1:-.}" || { echo "ディレクトリがない: ${1:-.}" >&2; exit 2; }

row() { printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}"; }
chk() { if [ -e "$1" ]; then row have "$1" "${2:-}"; else row missing "$1" "${2:-}"; fi; }

# 言語の推定（CI と dependabot の中身を決めるため）
langs=""
[ -f package.json ] || ls */package.json >/dev/null 2>&1 && langs="$langs node"
{ [ -f requirements.txt ] || [ -f pyproject.toml ] || ls */requirements.txt */pyproject.toml >/dev/null 2>&1; } && langs="$langs python"
row info "言語" "${langs:- 不明}"
row info "git" "$(git rev-parse --is-inside-work-tree >/dev/null 2>&1 && echo あり || echo なし)"
vis=$(gh repo view --json visibility -q .visibility 2>/dev/null || true)
row info "公開" "${vis:-GitHub にない（または gh 未ログイン）}"

chk .gitignore
if git grep -qE 'os\.environ|process\.env|getenv|import\.meta\.env' -- ':!*.md' ':!*.sh' ':!*.lock' 2>/dev/null; then
  chk .env.example "コードが環境変数を読んでいる"
else row skip .env.example "環境変数を読むコードが見つからない"; fi
chk LICENSE
chk README.md
chk AGENTS.md
chk CLAUDE.md
chk CONTRIBUTING.md
chk REVIEW.md "AI にレビューさせるときの決まり"
chk SECURITY.md
if ls .github/ISSUE_TEMPLATE/*.md >/dev/null 2>&1; then row have .github/ISSUE_TEMPLATE/ "$(ls .github/ISSUE_TEMPLATE | tr '\n' ' ')"
else row missing .github/ISSUE_TEMPLATE/; fi
chk .github/pull_request_template.md
chk .github/dependabot.yml
if ls .github/workflows/*.y*ml >/dev/null 2>&1; then
  for w in .github/workflows/*.y*ml; do
    grep -qE '^permissions:' "$w" && row have "$w" "permissions あり" || row missing "$w: permissions" "トップレベルに permissions がない"
  done
else row missing .github/workflows/ "CI がない"; fi
[ -f package.json ] && { [ -f .nvmrc ] || [ -f .node-version ]; } && row have .nvmrc || { [ -f package.json ] && row missing .nvmrc "CI の Node の版を固定するため"; }
{ [ -f requirements.txt ] || [ -f pyproject.toml ]; } && { [ -f .python-version ] && row have .python-version || row missing .python-version "CI の Python の版を固定するため"; }
exit 0
