#!/usr/bin/env bash
# 秘密情報・個人情報・見本データの検査（読み取りだけ）。追跡中のファイルと、コミット履歴の両方を見る。
# 使い方: scan.sh [リポジトリのパス]
# 出るのは「候補」。誤検出を含むので、1件ずつ中身を見て判断する。
set -u
cd "${1:-.}" || exit 2
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "git リポジトリではない" >&2; exit 2; }
EXCL=(':!*.lock' ':!package-lock.json' ':!*.min.js' ':!*.svg' ':!*.png' ':!*.jpg')
lim() { head -n "${1:-20}"; }

echo "# 秘密情報・個人情報の検査"
echo
if command -v gitleaks >/dev/null; then
  echo "## gitleaks（履歴を含む）"
  gitleaks detect --no-banner --redact -v 2>&1 | grep -E 'RuleID|File|Commit|leaks found|no leaks' | lim 40
  echo
fi

KEYS='(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,}|sk-(ant-|proj-)?[A-Za-z0-9_-]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(api[_-]?key|secret|token|password|passwd)["'\'' ]*[:=] *["'\''][^"'\'' ]{8,})'
echo "## 鍵・トークンらしい文字列（現在のファイル）"
git grep -nIiE "$KEYS" -- "${EXCL[@]}" | lim 20 || true
echo
echo "## 鍵・トークンらしい文字列（履歴。現在のファイルと重なるものも出る）"
git log -p --all -G"$KEYS" --pretty=format:'commit %h %s' -i 2>/dev/null | grep -E "^commit |^\+.*" | grep -iE "^commit |$KEYS" | grep -B1 -E '^\+' | lim 30 || true
echo
echo "## 消したが履歴に残るファイル（.env・鍵・作業用の文書など）"
git log --all --diff-filter=D --name-only --pretty=format: | sort -u | grep -iE '\.env$|\.env\.|\.pem$|\.key$|id_rsa|credentials|secret|PROGRESS|TODO|memo|メモ|作業|\.sqlite|\.db$' | grep -vE '\.env\.(example|sample)$' | lim 30 || true
echo
echo "## メールアドレス（現在のファイル。example.* と noreply は除く）"
git grep -nIhoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' -- "${EXCL[@]}" | sed 's/^[0-9]*://' | grep -viE '@(example\.(com|jp|org|net)|users\.noreply\.github\.com|noreply\.|anthropic\.com)' | sort | uniq -c | sort -rn | lim 20 || true
echo
echo "## 実在しうる電話番号（見本は 000-0000-0000 の形にする）"
git grep -nIE '(^|[^0-9])0[1-9]0?-?[0-9]{2,4}-[0-9]{3,4}([^0-9]|$)' -- "${EXCL[@]}" | grep -vE '000-0000|0000-0000' | lim 20 || true
echo
echo "## ローカルの絶対パス・ユーザー名"
git grep -nIE "/Users/[A-Za-z0-9_-]+|C:\\\\Users\\\\|/home/[a-z0-9_-]+/" -- "${EXCL[@]}" | lim 20 || true
echo
echo "## コミットの作者・コミッターのメールアドレス"
git log --all --format='%ae%n%ce' | sort | uniq -c | sort -rn
echo "  （個人のアドレスを出したくないなら、GitHub の noreply アドレスに切り替える。過去の分を変えるには履歴の書き換えが要る）"
